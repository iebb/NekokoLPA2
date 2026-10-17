package ee.nekoko.nlpa2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ComponentName
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * The app's way to the modem's bus.
 *
 * The socket has to be opened by the `shell` user, which is what Shizuku runs
 * [QrtrUserService] as, and it has to stay there: an app is refused a socket
 * of its own and refused the use of one this process opened. What crosses to
 * the app therefore is not a descriptor but the traffic itself — Dart asks for
 * a datagram to go out, or waits for one to come in, and the answering happens
 * in the process that holds the socket.
 *
 * The SE HAL reader rides on the same service, since the Secure Element HAL
 * also answers only to `shell`. Its calls start with `hal`, and a change of SIM
 * state is passed on to the service so that it drops channels it can no
 * longer vouch for.
 *
 * Waiting for the modem can take longer than a frame, so none of it runs on
 * the thread the app draws on.
 */
class QrtrPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    /** Where the user service finds the library it reaches the socket with. */
    private lateinit var libraryDir: String
    private lateinit var apkPath: String
    private lateinit var abi: String

    /** Where calls that wait for the modem run, one after the other. */
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var service: IQrtrService? = null
    private var receiverContext: Context? = null
    private val pendingInvalidations = AtomicInteger(0)
    private val simStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            intent ?: return
            val slot = if (intent.action == "android.se.omapi.action.SECURE_ELEMENT_STATE_CHANGED") {
                when (intent.getStringExtra("android.se.omapi.extra.READER_NAME")) {
                    "SIM1" -> 1
                    "SIM2" -> 2
                    else -> return // eSE is not one of our SIM readers.
                }
            } else {
                // Telephony's physical/phone indices are not a verified mapping
                // to SIM1/2 HAL reader names (especially with built-in eSIM/MEP).
                0
            }
            val connected = service
            try {
                if (connected == null) queueInvalidation(slot)
                else connected.halInvalidateSessions(slot) // No HAL init, reset or close.
            } catch (e: Throwable) {
                queueInvalidation(slot)
                Log.w(TAG, "SIM change invalidation deferred until next SE HAL operation", e)
            }
        }
    }

    private fun queueInvalidation(slot: Int) {
        val mask = if (slot == 0) 3 else 1 shl (slot - 1)
        pendingInvalidations.getAndUpdate { it or mask }
    }

    private fun applyPendingInvalidations(service: IQrtrService) {
        val mask = pendingInvalidations.getAndSet(0)
        try {
            if (mask == 3) service.halInvalidateSessions(0)
            else if (mask != 0) service.halInvalidateSessions(if (mask == 1) 1 else 2)
        } catch (e: Throwable) {
            pendingInvalidations.getAndUpdate { it or mask }
            throw e // Never perform a card operation before invalidation succeeds.
        }
    }

    /** Set while a binding is in flight, and counted down when it lands. */
    @Volatile
    private var connecting: CountDownLatch? = null

    /** The call waiting for the user to answer Shizuku's permission prompt. */
    private var pendingPermission: MethodChannel.Result? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) {
            Log.i(TAG, "user service connected")

            val service = IQrtrService.Stub.asInterface(binder)

            try {
                service.prepare(libraryDir, apkPath, abi)
            } catch (e: Throwable) {
                Log.e(TAG, "the user service could not load the modem library", e)
                connecting?.countDown()
                return
            }

            this@QrtrPlugin.service = service
            connecting?.countDown()
        }

        override fun onServiceDisconnected(name: ComponentName) {
            Log.i(TAG, "user service disconnected")
            service = null
        }
    }

    private val permissionListener =
        Shizuku.OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode != REQUEST_PERMISSION) return@OnRequestPermissionResultListener

            val granted = grantResult == PackageManager.PERMISSION_GRANTED
            Log.i(TAG, "permission answer: granted=$granted")
            pendingPermission?.let { result ->
                pendingPermission = null
                result.success(granted)
            }
        }

    private val serviceArgs = Shizuku.UserServiceArgs(
        ComponentName(BuildConfig.APPLICATION_ID, QrtrUserService::class.java.name),
    )
        .daemon(false)
        .processNameSuffix("qrtr")
        .debuggable(BuildConfig.DEBUG)
        .version(BuildConfig.VERSION_CODE)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        val context = binding.applicationContext
        val filter = IntentFilter().apply {
            addAction("android.intent.action.SIM_STATE_CHANGED")
            addAction("android.telephony.action.SIM_CARD_STATE_CHANGED")
            addAction("android.telephony.action.SIM_APPLICATION_STATE_CHANGED")
            addAction("android.se.omapi.action.SECURE_ELEMENT_STATE_CHANGED")
        }
        try {
            if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(simStateReceiver, filter, Context.RECEIVER_EXPORTED)
            else context.registerReceiver(simStateReceiver, filter)
            receiverContext = context
        } catch (e: RuntimeException) {
            Log.e(TAG, "SE HAL state monitoring unavailable; direct access disabled", e)
        }

        val application = binding.applicationContext.applicationInfo
        libraryDir = application.nativeLibraryDir
        apkPath = application.sourceDir
        abi = Build.SUPPORTED_ABIS.firstOrNull() ?: "arm64-v8a"

        try {
            Shizuku.addRequestPermissionResultListener(permissionListener)
        } catch (e: Throwable) {
            Log.w(TAG, "Shizuku is not available", e)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)

        try {
            Shizuku.removeRequestPermissionResultListener(permissionListener)
            Shizuku.unbindUserService(serviceArgs, connection, true)
        } catch (e: Throwable) {
            Log.w(TAG, "could not let the user service go", e)
        }

        receiverContext?.unregisterReceiver(simStateReceiver)
        receiverContext = null
        service = null
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isQualcomm())
            "isAvailable" -> result.success(isAvailable())
            "hasPermission" -> result.success(hasPermission())
            "requestPermission" -> requestPermission(result)

            "halInvalidateSessions" -> withService(result, retrySafe = false, seHal = true) { service -> service.halInvalidateSessions(call.number("slot")); null }
            "halUseBorrowed" -> withService(result, retrySafe = false, seHal = true) { service -> service.halUseBorrowed(call.number("slot")); null }
            "halOpenOwned" -> withService(result, retrySafe = false, seHal = true) { service -> service.halOpenOwned(call.number("slot")); null }
            "halCloseOwned" -> withService(result, retrySafe = false, seHal = true) { service -> service.halCloseOwned(call.number("slot")); null }
            "halAtr" -> withService(result, seHal = true) { service -> service.halAtr(call.number("slot")) }
            "halRead" -> withService(result, seHal = true) { service ->
                service.halRead(call.number("slot"), call.argument<ByteArray>("data") ?: invalid("data"))
            }

            "halRenameProfile" -> withService(result, retrySafe = false, seHal = true) { service ->
                service.halRenameProfile(call.number("slot"), call.argument<ByteArray>("iccid") ?: invalid("iccid"), call.argument<ByteArray>("eid") ?: invalid("eid"), call.argument<ByteArray>("nickname") ?: invalid("nickname"))
            }
            "halDeleteProfile" -> withService(result, retrySafe = false, seHal = true) { service ->
                service.halDeleteProfile(call.number("slot"), call.argument<ByteArray>("iccid") ?: invalid("iccid"), call.argument<ByteArray>("eid") ?: invalid("eid"))
            }
            "halRemoveNotification" -> withService(result, retrySafe = false, seHal = true) { service ->
                service.halRemoveNotification(call.number("slot"), call.number("sequence"), call.argument<ByteArray>("eid") ?: invalid("eid"), call.argument<ByteArray>("response") ?: invalid("response"))
            }
            "halSwitchProfile" -> withService(result, retrySafe = false, seHal = true, switchOperation = true) { service ->
                service.halSwitchProfile(call.number("slot"), call.argument<ByteArray>("iccid") ?: invalid("iccid"), call.argument<ByteArray>("eid") ?: invalid("eid"), call.argument<Boolean>("enable") ?: invalid("enable"))
            }
            "halBeginDownload" -> withService(result, seHal = true) { service -> service.halBeginDownload(call.number("slot")); null }
            "halEndDownload" -> withService(result, seHal = true) { service -> service.halEndDownload(call.number("slot")); null }
            "halDownload" -> withService(result, retrySafe = false, seHal = true) { service ->
                val payload = call.argument<ByteArray>("data") ?: invalid("data")
                val segments = call.argument<IntArray>("segments") ?: invalid("segments")
                require(payload.size in 3..(16 * 1024 * 1024)) { "Invalid ES10b size" }
                require(segments.size in 1..65536) { "Invalid segment count" }
                // Binder has a shared ~1 MiB transaction buffer. Transfer the
                // package as small data-only chunks, then validate and send it
                // inside one native call. Staging never talks to the card.
                try {
                    var offset = 0
                    while (offset < payload.size) {
                        val end = minOf(offset + 128 * 1024, payload.size)
                        service.halStageDownload(call.number("slot"), payload.copyOfRange(offset, end), offset == 0)
                        offset = end
                    }
                    service.halDownload(call.number("slot"), byteArrayOf(), segments)
                } catch (e: Throwable) {
                    try { service.halEndDownload(call.number("slot")) } catch (_: Throwable) {}
                    throw e
                }
            }

            "openBus" -> withService(result) { service -> service.openBus() }
            "busNode" -> withService(result) { service ->
                service.busNode(call.number("fd"))
            }
            "send" -> withService(result) { service ->
                service.send(
                    call.number("fd"),
                    call.number("node"),
                    call.number("port"),
                    call.argument<ByteArray>("data") ?: invalid("data"),
                )
                null
            }
            "receive" -> withService(result) { service ->
                service.receive(call.number("fd"), call.number("timeoutMs"))
            }
            "closeBus" -> withService(result) { service ->
                service.closeBus(call.number("fd"))
                null
            }

            else -> result.notImplemented()
        }
    }

    private fun invalid(name: String): Nothing = throw IllegalArgumentException("$name is missing")

    /**
     * One number out of a call.
     *
     * Dart's `int` arrives as either width, depending on how the channel and
     * the Dart runtime felt that day, so what is asked for is a number of some
     * kind and narrowed here.
     */
    private fun MethodCall.number(name: String): Int =
        (argument<Number>(name) ?: invalid(name)).toInt()

    /**
     * Run `call` against the user service, off the thread the app draws on.
     */
    private fun withService(result: MethodChannel.Result, retrySafe: Boolean = true, seHal: Boolean = false, switchOperation: Boolean = false, call: (IQrtrService) -> Any?) {
        if (seHal && receiverContext == null) {
            result.error("NO_STATE_MONITOR", "SE HAL state monitoring is unavailable", null)
            return
        }
        if (!hasPermission()) {
            result.error("NO_PERMISSION", "Shizuku permission was not granted", null)
            return
        }

        worker.execute {
            var attempt = 0

            while (true) {
                val service = try {
                    connect()
                } catch (e: Throwable) {
                    fail(result, "NO_SERVICE", e)
                    return@execute
                }

                try {
                    if (seHal) applyPendingInvalidations(service)
                    val value = call(service)
                    main.post { result.success(value) }
                    return@execute
                } catch (e: Throwable) {
                    Log.w(TAG, "the user service could not answer", e)

                    if (!retrySafe || e !is android.os.DeadObjectException) {
                        if (switchOperation && e is android.os.DeadObjectException) {
                            // The service may have sent the switch before its IPC reply was lost.
                            // Rebind for verification only; never retry this mutation.
                            forget(service)
                            fail(result, "HAL_SWITCH_UNCERTAIN", e)
                        } else {
                            fail(result, "SERVICE_ERROR", e)
                        }
                        return@execute
                    }

                    // The binder Shizuku hands over is not always one whose
                    // process is ready for it: right after a bind, and right
                    // after the app is reinstalled, calls into it fail even
                    // though the service is starting correctly. Let that one
                    // go and ask for a live one.
                    forget(service)

                    if (++attempt >= MAX_ATTEMPTS) {
                        fail(result, "NO_SERVICE", e)
                        return@execute
                    }

                    Thread.sleep(RETRY_DELAY_MS)
                }
            }
        }
    }

    /** The user service, waiting for it to come up if it is not there yet. */
    private fun connect(): IQrtrService {
        service?.let { return it }

        val latch = CountDownLatch(1)
        connecting = latch
        main.post { bind() }

        if (!latch.await(BIND_TIMEOUT_MS, TimeUnit.MILLISECONDS)) {
            connecting = null
            throw IllegalStateException("the QRTR user service did not start")
        }

        connecting = null

        return service ?: throw IllegalStateException("the QRTR user service is not available")
    }

    private fun bind() {
        try {
            Shizuku.bindUserService(serviceArgs, connection)
        } catch (e: Throwable) {
            Log.w(TAG, "could not start the QRTR user service", e)
            connecting?.countDown()
        }
    }

    /** Let a service that did not answer go, so the next call binds a new one. */
    private fun forget(service: IQrtrService) {
        if (this.service !== service) return

        this.service = null

        try {
            Shizuku.unbindUserService(serviceArgs, connection, true)
        } catch (e: Throwable) {
            Log.w(TAG, "could not let the stale user service go", e)
        }
    }

    private fun fail(result: MethodChannel.Result, code: String, error: Throwable) {
        val message = error.message?.takeIf { it.isNotBlank() } ?: error.toString()
        main.post { result.error(code, message, null) }
    }

    /** Whether Shizuku is installed, running, and new enough for user services. */
    private fun isAvailable(): Boolean {
        return try {
            Shizuku.pingBinder() && Shizuku.getVersion() >= MIN_VERSION
        } catch (e: Throwable) {
            Log.w(TAG, "Shizuku is not available", e)
            false
        }
    }

    /**
     * Whether this device is a Qualcomm one.
     *
     * A QRTR bus cannot be enumerated, and opening its socket takes Shizuku, so
     * the only sign the app has before asking anything of the user is the SoC:
     * Qualcomm devices name themselves in `ro.hardware` and, on newer releases,
     * in `ro.soc.manufacturer`.
     */
    private fun isQualcomm(): Boolean {
        val hardware = Build.HARDWARE
        val socManufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Build.SOC_MANUFACTURER
        } else {
            ""
        }

        return hardware.contains("qcom", ignoreCase = true) ||
            socManufacturer.contains("qcom", ignoreCase = true) ||
            socManufacturer.contains("qualcomm", ignoreCase = true)
    }

    private fun hasPermission(): Boolean {
        return try {
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        } catch (e: Throwable) {
            Log.w(TAG, "Shizuku is not available", e)
            false
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (hasPermission()) {
            result.success(true)
            return
        }

        if (!isAvailable()) {
            result.error("NO_SHIZUKU", "Shizuku is not running", null)
            return
        }

        pendingPermission?.success(false)
        pendingPermission = result

        try {
            Shizuku.requestPermission(REQUEST_PERMISSION)
        } catch (e: Throwable) {
            pendingPermission = null
            Log.w(TAG, "could not ask Shizuku for permission", e)
            result.error("NO_PERMISSION_REQUEST", e.message, null)
        }
    }

    companion object {
        private const val TAG = "QrtrPlugin"
        private const val CHANNEL = "nlpa2/qrtr"
        private const val REQUEST_PERMISSION = 0x7271

        /** User services arrived in Shizuku API 10. */
        private const val MIN_VERSION = 10

        /** How long to wait for the user service to come up. */
        private const val BIND_TIMEOUT_MS = 20_000L

        /** How many times a call is offered to a fresh service. */
        private const val MAX_ATTEMPTS = 3

        /** How long to let a user service finish starting before asking again. */
        private const val RETRY_DELAY_MS = 250L
    }
}
