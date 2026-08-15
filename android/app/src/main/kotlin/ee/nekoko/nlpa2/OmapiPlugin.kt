package ee.nekoko.nlpa2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.se.omapi.Channel
import android.se.omapi.Reader
import android.se.omapi.SEService
import android.se.omapi.Session
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

private fun ByteArray.toHex(): String =
        joinToString(separator = "") { eachByte -> "%02x".format(eachByte) }

private fun hexStringToByteArray(hex: String): ByteArray {
    require(hex.length % 2 == 0) { "Hex string must have an even length" }
    return ByteArray(hex.length / 2) { i ->
        val index = i * 2
        hex.substring(index, index + 2).toInt(16).toByte()
    }
}

class OmapiPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var seService: SEService? = null

    // Track open sessions and channels per reader - using thread-safe maps
    private val readerSessions = java.util.concurrent.ConcurrentHashMap<String, Session>()
    private val readerChannels =
            java.util.concurrent.ConcurrentHashMap<String, MutableMap<String, Channel>>()

    // Cache for reader status - using thread-safe map
    private val readerStatusCache = java.util.concurrent.ConcurrentHashMap<String, String>()
    @Volatile private var lastScanTime = 0L

    // Track readers that have successfully opened at least one logical channel
    private val readersWithSuccessfulChannel =
            java.util.concurrent.ConcurrentHashMap.newKeySet<String>()

    @Volatile private var profileSwitchInProgress = false
    @Volatile private var acceptingHardwareOperations = false

    private lateinit var cleanupCoordinator: OmapiCleanupCoordinator<Channel>
    private val hardwareLock = ReentrantLock()

    private fun createCleanupCoordinator(appContext: Context): OmapiCleanupCoordinator<Channel> =
            OmapiCleanupCoordinator(
                    backend =
                            object : OmapiCleanupBackend<Channel> {
                                override fun closeChannel(channel: Channel) = channel.close()

                                override fun closeSessionChannels(readerName: String): Nothing =
                                        error("Session.closeChannels() is forbidden by the Samsung workaround")

                                override fun closeSession(readerName: String): Nothing =
                                        error("Session.close() is forbidden by the Samsung workaround")

                                override fun closeReaderSessions(readerName: String): Nothing =
                                        error("Reader.closeSessions() is forbidden by the Samsung workaround")

                                override fun reconnectService(): Nothing =
                                        error("SEService reconnect is forbidden after poisoning")
                            },
                    readerKeys = {
                        (readerSessions.keys +
                                        readerChannels.keys +
                                        readersWithSuccessfulChannel)
                                .toSet()
                    },
                    detachReader = { readerName ->
                        // Detach every local reference before making a remote Binder call.
                        readerSessions.remove(readerName)
                        readersWithSuccessfulChannel.remove(readerName)
                        readerChannels.remove(readerName)?.values?.toList() ?: emptyList()
                    },
                    clearAllLocalState = {
                        readerSessions.clear()
                        readerChannels.clear()
                        readersWithSuccessfulChannel.clear()
                    },
                    safetyStore = SharedPreferencesOmapiSafetyStore(appContext),
                    bootIdentityProvider = AndroidOmapiBootIdentityProvider(appContext),
            )

    // Dedicated background thread for hardware operations
    private var backgroundHandler: android.os.Handler? = null
    private var backgroundThread: android.os.HandlerThread? = null

    // SIM state receiver to handle proactive refreshes transparently
    private val simStateReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val action = intent?.action ?: return
                    if (action == "android.intent.action.SIM_STATE_CHANGED") {
                        val state = intent.getStringExtra("ss") ?: ""
                        Log.d(TAG, "SIM state changed: $state")
                        // Post to background handler to ensure it runs after any current operation
                        backgroundHandler?.post {
                            if (!acceptingHardwareOperations) return@post
                            hardwareLock.withLock {
                                if (!acceptingHardwareOperations) return@withLock
                                Log.i(
                                        TAG,
                                        "SIM state change detected ($state), cleaning up stale sessions/channels",
                                )
                                if (cleanupCoordinator.poisonInfo == null) {
                                    val cleanup = cleanupAllSessions()
                                    if (cleanup is OmapiCleanupResult.RebootRequired) {
                                        Log.e(
                                                TAG,
                                                "SIM refresh cleanup poisoned OMAPI; reboot is required",
                                        )
                                    }
                                }

                                val eventMap = mapOf("type" to "sim_state_changed", "state" to state)
                                runOnUiThread { sendEvent(eventMap) }
                            }
                        }
                    }
                }
            }

    companion object {
        private const val TAG = "OmapiPlugin"
        private const val CHANNEL_NAME = "ee.nekoko.omapi_plugin"
        private const val EVENT_CHANNEL_NAME = "ee.nekoko.omapi_plugin/event"
        private const val CORRUPTED_MESSAGE =
                "SIM/eSIM channel became invalid. The profile operation may already have taken effect. " +
                        "Restart the device, reopen the app, and refresh profile status before retrying."

        // Default eUICC AID
        private const val DEFAULT_EUICC_AID = "A0000005591010FFFFFFFF8900000100"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onAttachedToEngine")
        // Restore reboot-required state before registering any callable hardware entry point.
        val appContext = binding.applicationContext
        context = appContext
        cleanupCoordinator = createCleanupCoordinator(appContext)
        cleanupCoordinator.poisonInfo?.let {
            Log.e(TAG, "Persisted OMAPI poison restored; hardware access remains blocked until reboot")
        }

        methodChannel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                }
        )

        // Register SIM state receiver
        val filter = IntentFilter("android.intent.action.SIM_STATE_CHANGED")
        binding.applicationContext.registerReceiver(simStateReceiver, filter)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.i(TAG, "onDetachedFromEngine")
        acceptingHardwareOperations = false
        try {
            binding.applicationContext.unregisterReceiver(simStateReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to unregister simStateReceiver", e)
        }
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel = null
        eventSink = null

        if (::cleanupCoordinator.isInitialized) shutdownServiceAfterCleanup("engine detach")

        stopBackgroundThread()
        context = null
    }

    private fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = android.os.HandlerThread("OmapiPluginBackend")
            backgroundThread?.start()
            backgroundHandler = android.os.Handler(backgroundThread!!.looper)
        }
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        backgroundThread = null
        backgroundHandler = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.i(TAG, "onAttachedToActivity")
        context = binding.activity.applicationContext
        startBackgroundThread()
        acceptingHardwareOperations = true
        hardwareLock.withLock { initializeSEService() }
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = binding.activity.applicationContext
        acceptingHardwareOperations = true
    }

    override fun onDetachedFromActivity() {
        Log.i(TAG, "onDetachedFromActivity")
        acceptingHardwareOperations = false
        shutdownServiceAfterCleanup("activity detach")
    }

    private fun initializeSEService(wait: Boolean = false): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            Log.w(TAG, "OMAPI requires Android 9.0 or higher")
            return false
        }

        val appContext = context ?: return false
        if (cleanupCoordinator.enterHardware(OmapiHardwareEntry.INITIALIZE_SERVICE) != null) {
            Log.e(TAG, "Refusing to initialize SEService without a durable OMAPI safety guard")
            return false
        }

        val latch = CountDownLatch(1)
        seService =
                SEService(appContext, { obj: Runnable -> obj.run() }) {
                    Log.d(TAG, "SE service connected")
                    sendEvent(mapOf("type" to "se_service_connected"))
                    latch.countDown()
                }

        if (wait) {
            try {
                if (!latch.await(3, TimeUnit.SECONDS)) {
                    Log.w(TAG, "Timeout waiting for SE service connection")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error waiting for SE service connection", e)
            }
        }
        return true
    }

    private fun shutdownServiceAfterCleanup(reason: String): Boolean = hardwareLock.withLock {
        val cleanup = cleanupAllSessions()
        if (cleanup is OmapiCleanupResult.RebootRequired) {
            Log.e(TAG, "Skipping SEService.shutdown() during $reason because OMAPI is poisoned")
            return@withLock false
        }

        try {
            seService?.shutdown()
            seService = null
        } catch (e: Exception) {
            cleanupCoordinator.markPoisoned(
                    readerName = null,
                    reason = "SEService.shutdown() failed during $reason: ${e.message ?: e.javaClass.simpleName}",
                    operationMayHaveSucceeded = true,
            )
            Log.e(TAG, "SEService.shutdown() failed during $reason", e)
            return@withLock false
        }

        val unsafe = cleanupCoordinator.confirmCleanShutdown()
        if (unsafe != null) {
            Log.e(TAG, "OMAPI safety guard could not be cleared during $reason")
            return@withLock false
        }
        true
    }

    private fun sendEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }

    @RequiresApi(Build.VERSION_CODES.P)
    override fun onMethodCall(call: MethodCall, result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            result.error("UNSUPPORTED", "OMAPI requires Android 9.0 or higher", null)
            return
        }

        if (call.method == "setProfileSwitchInProgress") {
            profileSwitchInProgress = call.argument<Boolean>("value") == true
            result.success(true)
            return
        }

        val entry =
                when (call.method) {
                    "listReaders" -> OmapiHardwareEntry.LIST_READERS
                    "connect" -> OmapiHardwareEntry.CONNECT
                    "openChannel" -> OmapiHardwareEntry.OPEN_CHANNEL
                    "transmit", "transmitOnChannel" -> OmapiHardwareEntry.TRANSMIT
                    "reset" -> OmapiHardwareEntry.RESET
                    "disconnect", "closeChannel", "closeChannels" ->
                            OmapiHardwareEntry.DISCONNECT
                    else -> OmapiHardwareEntry.OPEN_SESSION
                }
        if (rejectIfPoisoned(result, entry)) return

        // Methods that interact with hardware are moved to background threads
        val backgroundMethods =
                hashSetOf(
                        "connect",
                        "transmit",
                        "openChannel",
                        "closeChannel",
                        "closeChannels",
                        "transmitOnChannel",
                        "disconnect",
                        "reset",
                        "listReaders",
                )

        if (backgroundMethods.contains(call.method)) {
            backgroundHandler?.post {
                if (!acceptingHardwareOperations) {
                    runOnUiThread { result.error("NOT_CONNECTED", "OMAPI lifecycle is detached", null) }
                } else hardwareLock.withLock {
                    if (!acceptingHardwareOperations) {
                        runOnUiThread {
                            result.error("NOT_CONNECTED", "OMAPI lifecycle is detached", null)
                        }
                        return@withLock
                    }
                    try {
                        when (call.method) {
                            "connect" -> handleConnect(call, result)
                            "disconnect" -> handleDisconnect(call, result)
                            "reset" -> handleReset(result)
                            "transmit" -> handleTransmit(call, result)
                            "openChannel" -> handleOpenChannel(call, result, false)
                            "closeChannel" -> handleCloseChannel(call, result)
                            "closeChannels" -> handleCloseChannels(call, result)
                            "transmitOnChannel" -> handleTransmitOnChannel(call, result)
                            "listReaders" -> handleListReaders(result)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in background method: ${call.method}", e)
                        runOnUiThread { result.error("ERROR", e.message, null) }
                    }
                }
            }
                    ?: run {
                        // Fallback if background handler is not available
                        Log.e(TAG, "Background handler not available for method: ${call.method}")
                        result.error("ERROR", "Background thread not available", null)
                    }
        } else {
            result.notImplemented()
        }
    }

    private fun runOnUiThread(action: () -> Unit) {
        context?.let {
            val mainHandler = android.os.Handler(it.mainLooper)
            mainHandler.post { action() }
        }
                ?: action()
    }

    private fun rejectIfPoisoned(
            result: Result,
            entry: OmapiHardwareEntry = OmapiHardwareEntry.OPEN_SESSION,
    ): Boolean {
        val info = cleanupCoordinator.enterHardware(entry) ?: return false
        runOnUiThread {
            result.error(
                    OMAPI_SESSION_CORRUPTED,
                    CORRUPTED_MESSAGE,
                    poisonDetails(info),
            )
        }
        return true
    }

    private fun poisonDetails(info: OmapiPoisonInfo): Map<String, Any?> =
            mapOf(
                    "rebootRequired" to true,
                    "operationMayHaveSucceeded" to info.operationMayHaveSucceeded,
                    "persistenceConfirmed" to info.persistenceConfirmed,
                    "reader" to info.readerName,
                    "reason" to info.reason,
            )

    private fun reportCleanupFailure(result: Result, cleanup: OmapiCleanupResult): Boolean {
        if (cleanup !is OmapiCleanupResult.RebootRequired) return false
        runOnUiThread {
            result.error(
                    OMAPI_SESSION_CORRUPTED,
                    CORRUPTED_MESSAGE,
                    poisonDetails(cleanup.info),
            )
        }
        return true
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleListReaders(result: Result) {
        if (rejectIfPoisoned(result)) return
        if (seService == null || !seService!!.isConnected) {
            runOnUiThread { result.error("NOT_CONNECTED", "SE Service not connected", null) }
            return
        }

        val currentTime = System.currentTimeMillis()
        val allReaders = seService!!.readers.filter { it.name.startsWith("SIM") }

        // Only re-probe if the list of readers changed or 10 seconds have passed since last probe
        val currentNames = allReaders.map { it.name }.toSet()
        val cachedNames = readerStatusCache.keys

        if (currentNames != cachedNames || currentTime - lastScanTime > 10000) {
            try {
                // Reader discovery must not create a disposable Session: Session.close()
                // calls closeChannels() internally on affected Samsung firmware.
                val results =
                        allReaders.map { reader ->
                            if (cleanupCoordinator.poisonInfo != null) {
                                throw IllegalStateException(OMAPI_SESSION_CORRUPTED)
                            }
                            if (!reader.isSecureElementPresent) {
                                reader.name to "No SIM card|Card not detected in slot"
                            } else {
                                reader.name to null
                            }
                        }
                readerStatusCache.clear()
                for (res in results) {
                    if (res.second != null) {
                        readerStatusCache[res.first] = res.second!!
                    }
                }
                lastScanTime = currentTime
                runOnUiThread { result.success(formatReaderList(allReaders)) }
            } catch (e: Exception) {
                if (cleanupCoordinator.poisonInfo != null) {
                    rejectIfPoisoned(result)
                    return
                }
                Log.e(TAG, "Background probing failed", e)
                runOnUiThread { result.success(allReaders.map { it.name }) }
            }
        } else {
            runOnUiThread { result.success(formatReaderList(allReaders)) }
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun formatReaderList(allReaders: List<Reader>): List<String> {
        return allReaders.map { reader ->
            val errorInfo = readerStatusCache[reader.name]
            if (errorInfo != null) {
                "${reader.name}|$errorInfo"
            } else {
                reader.name
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleConnect(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }

        if (seService == null || !seService!!.isConnected) {
            return runOnUiThread { result.error("NOT_CONNECTED", "SE Service not connected", null) }
        }

        if (!readerName.startsWith("SIM")) {
            return runOnUiThread {
                result.error("INVALID_READER", "Only SIM readers are supported", null)
            }
        }

        val reader =
                seService!!.readers.firstOrNull { it.name == readerName.split('|').first() }
                        ?: return runOnUiThread {
                            result.error("READER_NOT_FOUND", "Reader $readerName not found", null)
                        }

        try {
            // Close old session if exists to avoid leaks
            val cleanup = cleanupReaderSessions(readerName)
            if (reportCleanupFailure(result, cleanup)) return

            // Open basic session
            val session = reader.openSession()
            readerSessions[readerName] = session
            readerChannels[readerName] = java.util.concurrent.ConcurrentHashMap()

            val atr = session.atr?.toHex() ?: ""
            Log.i(TAG, "Connected to reader: $readerName, ATR: $atr")

            val responseMap = mapOf("success" to true, "atr" to atr)
            runOnUiThread { result.success(responseMap) }
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception connecting to reader: $readerName", e)
            runOnUiThread {
                result.error("SECURITY_EXCEPTION", "Access denied by ARA-M: ${e.message}", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to reader: $readerName", e)
            runOnUiThread { result.error("CONNECTION_FAILED", e.message, null) }
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun getOrCreateSession(readerName: String): Session? {
        if (cleanupCoordinator.poisonInfo != null) return null
        val existingSession = readerSessions[readerName]
        if (existingSession != null) {
            return existingSession
        }

        Log.i(TAG, "No session for reader $readerName, attempting to open new session...")
        val service = seService
        if (service == null || !service.isConnected) {
            Log.e(TAG, "SE Service not connected")
            return null
        }

        val reader = service.readers.firstOrNull { it.name == readerName }
        if (reader == null) {
            Log.e(TAG, "Reader $readerName not found")
            return null
        }

        return try {
            val newSession = reader.openSession()
            readerSessions[readerName] = newSession
            if (readerChannels[readerName] == null) {
                readerChannels[readerName] = java.util.concurrent.ConcurrentHashMap()
            }
            newSession
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open session for reader $readerName", e)
            null
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleDisconnect(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }

        val cleanup = cleanupReaderSessions(readerName)
        if (reportCleanupFailure(result, cleanup)) return
        runOnUiThread { result.success(true) }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleReset(result: Result) {
        if (rejectIfPoisoned(result)) return
        Log.i(TAG, "Resetting SEService")
        val cleanup = cleanupAllSessions()
        if (reportCleanupFailure(result, cleanup)) return
        try {
            seService?.shutdown()
            seService = null
        } catch (e: Exception) {
            val info =
                    cleanupCoordinator.markPoisoned(
                            readerName = null,
                            reason =
                                    "SEService.shutdown() failed during reset: " +
                                            (e.message ?: e.javaClass.simpleName),
                            operationMayHaveSucceeded = true,
                    )
            return runOnUiThread {
                result.error(OMAPI_SESSION_CORRUPTED, CORRUPTED_MESSAGE, poisonDetails(info))
            }
        }
        if (!initializeSEService(wait = true)) {
            return runOnUiThread {
                result.error("NOT_CONNECTED", "SEService could not be initialized", null)
            }
        }
        runOnUiThread { result.success(true) }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleTransmit(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }
        val apduHex =
                call.argument<String>("apdu")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "apdu required", null)
                        }

        val session =
                getOrCreateSession(readerName)
                        ?: return runOnUiThread {
                            result.error("NOT_CONNECTED", "No session for reader $readerName", null)
                        }

        try {
            val apduBytes = hexStringToByteArray(apduHex)

            // OMAPI requires logical channel, open with default eUICC AID
            val aidBytes = hexStringToByteArray(DEFAULT_EUICC_AID)
            val currentSession = readerSessions[readerName] ?: session
            val channel =
                    currentSession.openLogicalChannel(aidBytes)
                            ?: return runOnUiThread {
                                result.error(
                                        "CHANNEL_FAILED",
                                        "Failed to open logical channel",
                                            null
                                    )
                            }

            // Track before transmit so every exceptional path remains individually cleanable.
            readerChannels
                    .getOrPut(readerName) { java.util.concurrent.ConcurrentHashMap() }[
                            DEFAULT_EUICC_AID] = channel

            // Android OMAPI automatically handles CLA byte modification for logical channels.
            val response = channel.transmit(apduBytes)
            val responseHex = response.toHex()
            if (profileSwitchInProgress && responseHex.endsWith("6f00", ignoreCase = true)) {
                val info =
                        cleanupCoordinator.markPoisoned(
                                readerName,
                                "6F00 during profile switch",
                                operationMayHaveSucceeded = true,
                        )
                return runOnUiThread {
                    result.error(OMAPI_SESSION_CORRUPTED, CORRUPTED_MESSAGE, poisonDetails(info))
                }
            }
            try {
                channel.close()
                readerChannels[readerName]?.remove(DEFAULT_EUICC_AID, channel)
            } catch (closeError: Exception) {
                val info =
                        cleanupCoordinator.markPoisoned(
                                readerName,
                                closeError.message ?: closeError.javaClass.simpleName,
                                operationMayHaveSucceeded = profileSwitchInProgress,
                        )
                return runOnUiThread {
                    result.error(
                            OMAPI_SESSION_CORRUPTED,
                            CORRUPTED_MESSAGE,
                            poisonDetails(info),
                    )
                }
            }
            runOnUiThread { result.success(responseHex) }
        } catch (e: Exception) {
            Log.e(TAG, "Transmit failed", e)
            val info =
                    cleanupCoordinator.markPoisoned(
                            readerName,
                            e.message ?: e.javaClass.simpleName,
                            operationMayHaveSucceeded = profileSwitchInProgress,
                    )
            runOnUiThread {
                result.error(OMAPI_SESSION_CORRUPTED, CORRUPTED_MESSAGE, poisonDetails(info))
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleOpenChannel(call: MethodCall, result: Result, isRetry: Boolean = false) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }

        val singleAid = call.argument<String>("aid")
        val aidsList = call.argument<List<String>>("aids")

        if (singleAid == null && (aidsList == null || aidsList.isEmpty())) {
            return runOnUiThread { result.error("INVALID_ARGUMENT", "aid or aids required", null) }
        }

        val session =
                getOrCreateSession(readerName)
                        ?: return runOnUiThread {
                            result.error("NOT_CONNECTED", "No session for reader $readerName", null)
                        }

        val targets =
                if (aidsList != null && aidsList.isNotEmpty()) aidsList else listOf(singleAid!!)
        var lastError: Exception? = null

        // Background thread work
        for (targetAid in targets) {
            try {
                val aidBytes = hexStringToByteArray(targetAid)
                val currentSession = session
                val channel = currentSession.openLogicalChannel(aidBytes)

                if (channel != null) {
                    // Success!
                    val channels =
                            readerChannels.getOrPut(readerName) {
                                java.util.concurrent.ConcurrentHashMap()
                            }
                    channels[targetAid.uppercase()] = channel
                    readersWithSuccessfulChannel.add(readerName)

                    Log.i(TAG, "Opened logical channel for AID: $targetAid on reader: $readerName")

                    val responseMap =
                            mutableMapOf<String, Any>("success" to true, "aid" to targetAid)
                    channel.selectResponse?.let { responseMap["selectResponse"] = it.toHex() }
                    runOnUiThread { result.success(responseMap) }
                    return
                }
            } catch (e: Exception) {
                // Check if fatal or just not found
                lastError = e
                val message = e.message ?: ""

                // If specific access control or other fatal error, might want to stop?
                // For now, assume iteration continues unless it's a session death.
                if (e is SecurityException) {
                    Log.w(TAG, "Security exception for AID $targetAid: ${e.message}")
                }
            }
        }

        // If we get here, no AID worked.
        // Check if we should retry (only if single AID really, or if session looks dead)
        if (!isRetry && lastError != null) {
            val message = lastError!!.message ?: ""
            // "OpenLogicalChannel() failed" and NoSuchElementException are typically native/driver
            // state issues.
            // We should retry these even if we haven't successfully opened a channel before,
            // because the session might be stale from a previous run or background event.
            val isInfrastructureError =
                    message.contains("OpenLogicalChannel() failed", ignoreCase = true) ||
                            lastError is java.util.NoSuchElementException

            // "Failed to select any valid AID" is generic, maybe just not found?
            // If we really want to be robust, we retry infrastructure errors always once.

            if (isInfrastructureError ||
                            (readersWithSuccessfulChannel.contains(readerName) &&
                                    message.isNotEmpty())
            ) {
                Log.w(
                        TAG,
                        "Infrastructure error or persistent failure ($message), retrying session..."
                )
                val cleanup = cleanupReaderSessions(readerName)
                if (reportCleanupFailure(result, cleanup)) return
                try {
                    // Small delay before retry
                    Thread.sleep(150)
                    val reader = seService!!.readers.firstOrNull { it.name == readerName }
                    if (reader != null) {
                        val newSession = reader.openSession()
                        readerSessions[readerName] = newSession
                        readerChannels[readerName] = java.util.concurrent.ConcurrentHashMap()
                        handleOpenChannel(call, result, true)
                        return
                    }
                } catch (retryEx: Exception) {
                    Log.e(TAG, "Session re-open failed during retry", retryEx)
                }
            }
        }
        runOnUiThread {
            result.error("CHANNEL_FAILED", lastError?.message ?: "No AID opened", null)
        }
    }
    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleCloseChannel(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }
        val aidHex =
                call.argument<String>("aid")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "aid required", null)
                        }

        Log.i(TAG, "Closing tracked channels for AID request: $aidHex")
        val cleanup = cleanupReaderSessions(readerName)
        if (reportCleanupFailure(result, cleanup)) return
        runOnUiThread { result.success(true) }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleCloseChannels(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }

        val cleanup = cleanupReaderSessions(readerName)
        if (reportCleanupFailure(result, cleanup)) return
        runOnUiThread { result.success(true) }
    }

    @RequiresApi(Build.VERSION_CODES.P)
    private fun handleTransmitOnChannel(call: MethodCall, result: Result) {
        if (rejectIfPoisoned(result)) return
        val readerName =
                call.argument<String>("reader")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "reader name required", null)
                        }
        val aidHex =
                call.argument<String>("aid")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "aid required", null)
                        }
        val apduHex =
                call.argument<String>("apdu")
                        ?: return runOnUiThread {
                            result.error("INVALID_ARGUMENT", "apdu required", null)
                        }

        var attempt = 0
        var currentDelay = 1000L
        val maxAttempts = 8

        while (true) {
            if (rejectIfPoisoned(result)) return
            val channels = readerChannels[readerName]
            var channel = channels?.get(aidHex.uppercase())

            if (channel == null) {
                // If we don't have a channel, attempt to re-open it (only if we're in a retry loop)
                if (attempt > 0) {
                    try {
                        val session = getOrCreateSession(readerName)
                        if (session != null) {
                            val aidBytes = hexStringToByteArray(aidHex)
                            channel = session.openLogicalChannel(aidBytes)
                            if (channel != null) {
                                readerChannels
                                        .getOrPut(readerName) {
                                            java.util.concurrent.ConcurrentHashMap()
                                        }[aidHex.uppercase()] = channel
                                Log.i(TAG, "Re-opened channel for AID $aidHex during retry $attempt")
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to re-open channel for $aidHex during retry $attempt", e)
                    }
                } else {
                    // First attempt and no channel? Error out as before.
                    val availableAids = channels?.keys?.joinToString(", ") ?: "none"
                    Log.e(TAG, "CHANNEL_NOT_FOUND: Reader=$readerName, AID=${aidHex.uppercase()}. Available: $availableAids")
                    return runOnUiThread {
                        result.error("CHANNEL_NOT_FOUND", "No channel for AID: $aidHex", null)
                    }
                }
            }

            if (channel != null) {
                try {
                    val apduBytes = hexStringToByteArray(apduHex)
                    Log.i(TAG, "[$readerName] >> $apduHex")
                    val response = channel.transmit(apduBytes)
                    val responseHex = response.toHex()
                    Log.i(TAG, "[$readerName] << $responseHex")

                    // Check for retryable status codes:
                    // 6D00 (Instruction code not supported or invalid)
                    // 6881 (Logical channel not available - often transient during refresh)
                    val sw1 = response[response.size - 2]
                    val sw2 = response[response.size - 1]
                    val is6D00 = sw1 == 0x6D.toByte() && sw2 == 0x00.toByte()
                    val is6881 = sw1 == 0x68.toByte() && sw2 == 0x81.toByte()
                    val is6F00 = sw1 == 0x6F.toByte() && sw2 == 0x00.toByte()

                    if (profileSwitchInProgress && (is6F00 || is6D00 || is6881)) {
                        val info =
                                cleanupCoordinator.markPoisoned(
                                        readerName,
                                        "${responseHex.takeLast(4).uppercase()} during profile switch",
                                        operationMayHaveSucceeded = true,
                                )
                        return runOnUiThread {
                            result.error(
                                    OMAPI_SESSION_CORRUPTED,
                                    CORRUPTED_MESSAGE,
                                    poisonDetails(info),
                            )
                        }
                    }

                    if (!is6D00 && !is6881) {
                        // Mark this reader as having had at least one successful exchange
                        readersWithSuccessfulChannel.add(readerName)
                    }

                    if (is6881) {
                        if (readersWithSuccessfulChannel.contains(readerName)) {
                            Log.w(
                                    TAG,
                                    "6881 (Proactive Refresh) on reader $readerName. Returning BUSY error to Dart and cleaning up."
                            )
                            val cleanup = cleanupReaderSessions(readerName)
                            if (reportCleanupFailure(result, cleanup)) return
                            runOnUiThread {
                                result.error(
                                        "BUSY",
                                        "Card busy - session unavailable",
                                        response.toHex()
                                )
                            }
                        } else {
                            Log.e(
                                    TAG,
                                    "Got 6881 on reader $readerName with no previous successful APDUs. Likely logical channel not supported."
                            )
                            runOnUiThread {
                                result.error(
                                        "ERROR",
                                        "Card returned 6881 - Logical channel not supported or card busy",
                                        response.toHex()
                                )
                            }
                        }
                        return
                    }

                    if (is6D00) {
                        Log.w(
                                TAG,
                                "Got 6D00 on reader $readerName, AID $aidHex. Attempt ${attempt + 1}/$maxAttempts"
                        )
                        
                        if (attempt < maxAttempts) {
                            // 6D00 often means the card OS state changed.
                            // Close ALL channels and the session for this reader to be safe.
                            val cleanup = cleanupReaderSessions(readerName)
                            if (reportCleanupFailure(result, cleanup)) return

                            Thread.sleep(currentDelay)
                            currentDelay = (currentDelay * 1.5).toLong()
                            attempt++
                            continue
                        }
                    }

                    // Success or non-retryable status
                    runOnUiThread { result.success(response.toHex()) }
                    return
                } catch (e: Exception) {
                    Log.e(TAG, "Channel transmit failed for AID $aidHex (attempt $attempt)", e)
                    val info =
                            cleanupCoordinator.markPoisoned(
                                    readerName,
                                    e.message ?: e.javaClass.simpleName,
                                    operationMayHaveSucceeded = profileSwitchInProgress,
                            )
                    return runOnUiThread {
                        result.error(
                                OMAPI_SESSION_CORRUPTED,
                                CORRUPTED_MESSAGE,
                                poisonDetails(info),
                        )
                    }
                }
            } else if (attempt < maxAttempts) {
                // We don't have a channel and re-open failed, but have retries left
                Thread.sleep(currentDelay)
                currentDelay = (currentDelay * 1.5).toLong()
                attempt++
            } else {
                // Exhausted retries and no channel
                runOnUiThread {
                    result.error("TRANSMIT_FAILED", "Exhausted retries for AID $aidHex", null)
                }
                return
            }
        }
    }

    private fun cleanupReaderSessions(readerName: String): OmapiCleanupResult {
        val result = cleanupCoordinator.cleanupReader(readerName)
        if (result is OmapiCleanupResult.RebootRequired) {
            Log.e(
                    TAG,
                    "Channel close failed for $readerName; local references were dropped and OMAPI is poisoned",
            )
        }
        return result
    }

    private fun cleanupAllSessions(): OmapiCleanupResult = cleanupCoordinator.cleanupAll()
}
