package ee.nekoko.nlpa2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.IccOpenLogicalChannelResponse
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Method

private fun ByteArray.toHex(): String =
        joinToString(separator = "") { eachByte -> "%02x".format(eachByte) }

private fun hexStringToByteArray(hex: String): ByteArray {
    val cleanHex = hex.replace(" ", "").replace("\n", "")
    require(cleanHex.length % 2 == 0) { "Hex string must have an even length" }
    return ByteArray(cleanHex.length / 2) { i ->
        val index = i * 2
        cleanHex.substring(index, index + 2).toInt(16).toByte()
    }
}

class TelephonyPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var telephonyManager: TelephonyManager? = null

    // Dedicated background thread for hardware operations
    private var backgroundHandler: android.os.Handler? = null
    private var backgroundThread: android.os.HandlerThread? = null

    private val simStateReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == "android.intent.action.SIM_STATE_CHANGED" ||
                                    intent?.action ==
                                            "android.telephony.action.SIM_CARD_STATE_CHANGED" ||
                                    intent?.action ==
                                            "android.telephony.action.SIM_APPLICATION_STATE_CHANGED"
                    ) {
                        val state = intent.getStringExtra("ss") ?: "UNKNOWN"
                        Log.d(TAG, "SIM state changed event: ${intent.action}, state: $state")
                        Handler(Looper.getMainLooper()).post {
                            eventSink?.success(
                                    mapOf(
                                            "type" to "sim_state_changed",
                                            "state" to state,
                                            "action" to intent.action
                                    )
                            )
                        }
                    }
                }
            }

    companion object {
        private const val TAG = "TelephonyPlugin"
        private const val CHANNEL_NAME = "ee.nekoko.telephony_plugin"
        private const val EVENT_CHANNEL_NAME = "ee.nekoko.telephony_plugin/event"

        // Hidden APIs via reflection
        private val getUiccCardsInfo: Method? by lazy {
            try {
                TelephonyManager::class.java.getMethod("getUiccCardsInfo")
            } catch (e: Exception) {
                null
            }
        }

        private val iccOpenLogicalChannelBySlot: Method? by lazy {
            try {
                TelephonyManager::class.java.getMethod(
                        "iccOpenLogicalChannelBySlot",
                        Int::class.java,
                        String::class.java,
                        Int::class.java
                )
            } catch (e: Exception) {
                null
            }
        }

        private val iccOpenLogicalChannelByPort: Method? by lazy {
            val tmClass = TelephonyManager::class.java
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    tmClass.getMethod(
                            "iccOpenLogicalChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            String::class.java,
                            Int::class.java
                    )
                } else {
                    tmClass.getMethod(
                            "iccOpenLogicalChannelByPort",
                            Int::class.java,
                            String::class.java,
                            Int::class.java
                    )
                }
            } catch (e: Exception) {
                null
            }
        }

        private val iccCloseLogicalChannelBySlot: Method? by lazy {
            try {
                TelephonyManager::class.java.getMethod(
                        "iccCloseLogicalChannelBySlot",
                        Int::class.java,
                        Int::class.java
                )
            } catch (e: Exception) {
                null
            }
        }

        private val iccCloseLogicalChannelByPort: Method? by lazy {
            val tmClass = TelephonyManager::class.java
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    tmClass.getMethod(
                            "iccCloseLogicalChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            Int::class.java
                    )
                } else {
                    tmClass.getMethod(
                            "iccCloseLogicalChannelByPort",
                            Int::class.java,
                            Int::class.java
                    )
                }
            } catch (e: Exception) {
                null
            }
        }

        private val iccTransmitApduLogicalChannelBySlot: Method? by lazy {
            try {
                TelephonyManager::class.java.getMethod(
                        "iccTransmitApduLogicalChannelBySlot",
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        String::class.java
                )
            } catch (e: Exception) {
                null
            }
        }

        private val iccTransmitApduLogicalChannelByPort: Method? by lazy {
            val tmClass = TelephonyManager::class.java
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    tmClass.getMethod(
                            "iccTransmitApduLogicalChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            String::class.java
                    )
                } else {
                    tmClass.getMethod(
                            "iccTransmitApduLogicalChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            String::class.java
                    )
                }
            } catch (e: Exception) {
                null
            }
        }

        private val iccTransmitApduBasicChannelBySlot: Method? by lazy {
            try {
                TelephonyManager::class.java.getMethod(
                        "iccTransmitApduBasicChannelBySlot",
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        Int::class.java,
                        String::class.java
                )
            } catch (e: Exception) {
                null
            }
        }

        private val iccTransmitApduBasicChannelByPort: Method? by lazy {
            val tmClass = TelephonyManager::class.java
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    tmClass.getMethod(
                            "iccTransmitApduBasicChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            String::class.java
                    )
                } else {
                    tmClass.getMethod(
                            "iccTransmitApduBasicChannelByPort",
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            Int::class.java,
                            String::class.java
                    )
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    private fun iccOpenLogicalChannel(
            tm: TelephonyManager,
            slotIndex: Int,
            portIndex: Int,
            aid: String?,
            p2: Int
    ): IccOpenLogicalChannelResponse {
        return if (iccOpenLogicalChannelByPort != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                iccOpenLogicalChannelByPort!!.invoke(tm, slotIndex, portIndex, aid, p2) as
                        IccOpenLogicalChannelResponse
            } else {
                iccOpenLogicalChannelByPort!!.invoke(tm, portIndex, aid, p2) as
                        IccOpenLogicalChannelResponse
            }
        } else if (iccOpenLogicalChannelBySlot != null) {
            iccOpenLogicalChannelBySlot!!.invoke(tm, slotIndex, aid, p2) as
                    IccOpenLogicalChannelResponse
        } else {
            throw Exception("Logical channel APIs not available")
        }
    }

    private fun iccCloseLogicalChannel(
            tm: TelephonyManager,
            slotIndex: Int,
            portIndex: Int,
            channel: Int
    ) {
        if (iccCloseLogicalChannelByPort != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                iccCloseLogicalChannelByPort!!.invoke(tm, slotIndex, portIndex, channel)
            } else {
                iccCloseLogicalChannelByPort!!.invoke(tm, portIndex, channel)
            }
        } else if (iccCloseLogicalChannelBySlot != null) {
            iccCloseLogicalChannelBySlot!!.invoke(tm, slotIndex, channel)
        } else {
            throw Exception("Logical channel APIs not available")
        }
    }

    private fun iccTransmitApduLogicalChannel(
            tm: TelephonyManager,
            slotIndex: Int,
            portIndex: Int,
            channel: Int,
            cla: Int,
            ins: Int,
            p1: Int,
            p2: Int,
            p3: Int,
            data: String?
    ): String? {
        return if (iccTransmitApduLogicalChannelByPort != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                iccTransmitApduLogicalChannelByPort!!.invoke(
                        tm,
                        slotIndex,
                        portIndex,
                        channel,
                        cla,
                        ins,
                        p1,
                        p2,
                        p3,
                        data
                ) as
                        String?
            } else {
                iccTransmitApduLogicalChannelByPort!!.invoke(
                        tm,
                        portIndex,
                        channel,
                        cla,
                        ins,
                        p1,
                        p2,
                        p3,
                        data
                ) as
                        String?
            }
        } else if (iccTransmitApduLogicalChannelBySlot != null) {
            iccTransmitApduLogicalChannelBySlot!!.invoke(
                    tm,
                    slotIndex,
                    channel,
                    cla,
                    ins,
                    p1,
                    p2,
                    p3,
                    data
            ) as
                    String?
        } else {
            throw Exception("Logical channel APIs not available")
        }
    }

    private fun iccTransmitApduBasicChannel(
            tm: TelephonyManager,
            slotIndex: Int,
            portIndex: Int,
            cla: Int,
            ins: Int,
            p1: Int,
            p2: Int,
            p3: Int,
            data: String?
    ): String? {
        return if (iccTransmitApduBasicChannelByPort != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                iccTransmitApduBasicChannelByPort!!.invoke(
                        tm,
                        slotIndex,
                        portIndex,
                        cla,
                        ins,
                        p1,
                        p2,
                        p3,
                        data
                ) as
                        String?
            } else {
                iccTransmitApduBasicChannelByPort!!.invoke(
                        tm,
                        portIndex,
                        cla,
                        ins,
                        p1,
                        p2,
                        p3,
                        data
                ) as
                        String?
            }
        } else if (iccTransmitApduBasicChannelBySlot != null) {
            iccTransmitApduBasicChannelBySlot!!.invoke(tm, slotIndex, cla, ins, p1, p2, p3, data) as
                    String?
        } else {
            throw Exception("Basic channel APIs not available")
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
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

        context = binding.applicationContext
        val filter = IntentFilter("android.intent.action.SIM_STATE_CHANGED")
        filter.addAction("android.telephony.action.SIM_CARD_STATE_CHANGED")
        filter.addAction("android.telephony.action.SIM_APPLICATION_STATE_CHANGED")
        binding.applicationContext.registerReceiver(simStateReceiver, filter)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null

        // The activity detaches first and clears `context`, so unregister through the binding.
        try {
            binding.applicationContext.unregisterReceiver(simStateReceiver)
        } catch (e: Exception) {
            // Likely not registered
        }

        stopBackgroundThread()
    }

    private fun startBackgroundThread() {
        if (backgroundThread == null) {
            backgroundThread = android.os.HandlerThread("TelephonyPluginBackend")
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
        context = binding.activity.applicationContext
        telephonyManager = context?.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        startBackgroundThread()
    }

    override fun onDetachedFromActivityForConfigChanges() {}
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = binding.activity.applicationContext
        telephonyManager = context?.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
    }

    override fun onDetachedFromActivity() {
        stopBackgroundThread()
        context = null
        telephonyManager = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        backgroundHandler?.post {
            try {
                when (call.method) {
                    "hasPrivilegedPermission" -> handleHasPrivilegedPermission(result)
                    "listSlots" -> handleListSlots(result)
                    "openChannel" -> handleOpenChannel(call, result)
                    "closeChannel" -> handleCloseChannel(call, result)
                    "cleanupAllChannels" -> handleCleanupAllChannels(call, result)
                    "transmit" -> handleTransmit(call, result)
                    "sendTerminalCapabilities" -> handleSendTerminalCapabilities(call, result)
                    else -> runOnUiThread { result.notImplemented() }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in background method: ${call.method}", e)
                runOnUiThread { result.error("ERROR", e.message, e.stackTraceToString()) }
            }
        }
                ?: run { result.error("ERROR", "Background thread not available", null) }
    }

    private fun handleHasPrivilegedPermission(result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val hasPermission =
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        // For Android O+, check if we have carrier privileges (which implies we can
                        // do TS 43 operations)
                        // or if we have MODIFY_PHONE_STATE.
                        // However, MODIFY_PHONE_STATE is system-only.
                        // The user specifically asked to check
                        // "android.permission.MODIFY_PHONE_STATE".
                        context?.checkSelfPermission("android.permission.MODIFY_PHONE_STATE") ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                    } else {
                        context?.checkSelfPermission("android.permission.MODIFY_PHONE_STATE") ==
                                android.content.pm.PackageManager.PERMISSION_GRANTED
                    }
                } catch (e: Exception) {
                    false
                }
        runOnUiThread { result.success(hasPermission) }
    }

    private fun runOnUiThread(action: () -> Unit) {
        context?.let {
            val mainHandler = android.os.Handler(it.mainLooper)
            mainHandler.post { action() }
        }
                ?: action()
    }

    private fun handleListSlots(result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }

        val slots = mutableListOf<Map<String, Any>>()

        // Try getUiccCardsInfo (System API)
        if (getUiccCardsInfo != null) {
            try {
                val cardsInfo = getUiccCardsInfo!!.invoke(tm) as? List<*>
                cardsInfo?.forEach { card ->
                    if (card == null) return@forEach
                    val cardMap = mutableMapOf<String, Any>()
                    var slotIndex = -1

                    // Use reflection to get properties of UiccCardInfo
                    try {
                        val cardClass = card.javaClass

                        slotIndex =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    try {
                                        cardClass.getMethod("getPhysicalSlotIndex").invoke(card) as?
                                                Int
                                                ?: -1
                                    } catch (e: Exception) {
                                        try {
                                            cardClass.getMethod("getSlotIndex").invoke(card) as? Int
                                                    ?: -1
                                        } catch (e2: Exception) {
                                            -1
                                        }
                                    }
                                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    try {
                                        cardClass.getMethod("getSlotIndex").invoke(card) as? Int
                                                ?: -1
                                    } catch (e: Exception) {
                                        -1
                                    }
                                } else {
                                    -1
                                }

                        if (slotIndex == -1) {
                            Log.d(
                                    TAG,
                                    "Skipping card with invalid slot index (likely inactive eSIM)"
                            )
                            return@forEach
                        }

                        val isEuiccVal =
                                try {
                                    val isEuiccMethod = cardClass.getMethod("isEuicc")
                                    isEuiccMethod.invoke(card) as? Boolean ?: false
                                } catch (e: Exception) {
                                    false
                                }

                        val cardIdVal =
                                try {
                                    val getCardId = cardClass.getMethod("getCardId")
                                    getCardId.invoke(card)
                                } catch (e: Exception) {
                                    null
                                }

                        val isRemovableVal =
                                try {
                                    val getIsRemovable = cardClass.getMethod("isRemovable")
                                    getIsRemovable.invoke(card) as? Boolean ?: true
                                } catch (e: Exception) {
                                    true
                                }

                        cardMap["slotIndex"] = slotIndex
                        cardMap["isEuicc"] = isEuiccVal
                        cardMap["cardId"] = cardIdVal ?: ""
                        cardMap["isRemovable"] = isRemovableVal
                    } catch (e: Exception) {
                        Log.w(TAG, "Dynamic access failed for card: ${e.message}")
                    }

                    // Handle ports (Tiramisu+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        try {
                            val getPorts = card.javaClass.getMethod("getPorts")
                            val ports = getPorts.invoke(card) as? Collection<*>
                            val portList = mutableListOf<Map<String, Any>>()
                            ports?.forEach { port ->
                                if (port == null) return@forEach
                                try {
                                    val portMap = mutableMapOf<String, Any>()
                                    val portClass = port.javaClass
                                    val getPortIndex = portClass.getMethod("getPortIndex")
                                    val getLogicalSlotIndex =
                                            portClass.getMethod("getLogicalSlotIndex")
                                    portMap["portIndex"] = getPortIndex.invoke(port) as? Int ?: 0
                                    portMap["logicalSlotIndex"] =
                                            getLogicalSlotIndex.invoke(port) as? Int ?: 0
                                    portList.add(portMap)
                                } catch (e: Exception) {
                                    Log.w(TAG, "Failed to get port info: ${e.message}")
                                }
                            }
                            cardMap["ports"] = portList
                        } catch (e: Exception) {
                            // Fallback for non-MEP or older
                            cardMap["ports"] =
                                    listOf(mapOf("portIndex" to 0, "logicalSlotIndex" to slotIndex))
                        }
                    } else {
                        cardMap["ports"] =
                                listOf(mapOf("portIndex" to 0, "logicalSlotIndex" to slotIndex))
                    }

                    // Add generic sim state
                    try {
                        cardMap["simState"] = tm.getSimState(slotIndex)
                    } catch (e: Exception) {
                        cardMap["simState"] = 0 // UNKNOWN
                    }

                    slots.add(cardMap)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to getUiccCardsInfo: ${e.message}")
            }
        }

        // Fallback to active count if nothing found
        if (slots.isEmpty()) {
            val count =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) tm.activeModemCount else 1
            for (i in 0 until count) {
                val state =
                        try {
                            tm.getSimState(i)
                        } catch (e: Exception) {
                            0
                        }
                slots.add(
                        mapOf(
                                "slotIndex" to i,
                                "isEuicc" to true,
                                "ports" to listOf(mapOf("portIndex" to 0, "logicalSlotIndex" to i)),
                                "simState" to state
                        )
                )
            }
        }

        runOnUiThread { result.success(slots) }
    }

    private fun handleOpenChannel(call: MethodCall, result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val slotIndex = call.argument<Int>("slotIndex") ?: 0
        val portIndex = call.argument<Int>("portIndex") ?: 0
        val aid = call.argument<String>("aid") ?: ""

        // SGP.22: Send Terminal Capabilities on basic channel before opening logical channel
        try {
            Log.d(
                    TAG,
                    "Sending Terminal Capabilities on basic channel (Slot $slotIndex Port $portIndex)..."
            )
            iccTransmitApduBasicChannel(
                    tm,
                    slotIndex,
                    portIndex,
                    0x80,
                    0xAA,
                    0x00,
                    0x00,
                    0x0A,
                    "A9088100820101830107"
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to send Terminal Capabilities on BASIC channel: ${e.message}")
        }

        try {
            val response = iccOpenLogicalChannel(tm, slotIndex, portIndex, aid, 0)
            if (response.status == IccOpenLogicalChannelResponse.STATUS_NO_ERROR) {
                val resultMap =
                        mapOf(
                                "channel" to response.channel,
                                "selectResponse" to response.selectResponse?.toHex()
                        )
                runOnUiThread { result.success(resultMap) }
            } else {
                runOnUiThread { result.error("OPEN_FAILED", "Status: ${response.status}", null) }
            }
        } catch (e: Exception) {
            val root = e.rootCause()
            runOnUiThread { result.error("OPEN_FAILED", root.readableMessage(), root.stackTraceToString()) }
        }
    }

    private fun handleCloseChannel(call: MethodCall, result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val slotIndex = call.argument<Int>("slotIndex") ?: 0
        val portIndex = call.argument<Int>("portIndex") ?: 0
        val channel = call.argument<Int>("channel") ?: -1

        try {
            iccCloseLogicalChannel(tm, slotIndex, portIndex, channel)
            runOnUiThread { result.success(true) }
        } catch (e: Exception) {
            val root = e.rootCause()
            runOnUiThread { result.error("CLOSE_FAILED", root.readableMessage(), root.stackTraceToString()) }
        }
    }

    private fun handleCleanupAllChannels(call: MethodCall, result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val slotIndex = call.argument<Int>("slotIndex") ?: 0
        val portIndex = call.argument<Int>("portIndex") ?: 0

        try {
            // Attempt to close all possible logical channels (1..19)
            for (channel in 1..19) {
                try {
                    iccCloseLogicalChannel(tm, slotIndex, portIndex, channel)
                } catch (e: Exception) {
                    // Ignore errors for individual channels (likely not open)
                }
            }
            runOnUiThread { result.success(true) }
        } catch (e: Exception) {
            val root = e.rootCause()
            runOnUiThread { result.error("CLEANUP_FAILED", root.readableMessage(), root.stackTraceToString()) }
        }
    }

    private fun handleTransmit(call: MethodCall, result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val slotIndex = call.argument<Int>("slotIndex") ?: 0
        val portIndex = call.argument<Int>("portIndex") ?: 0
        val channel = call.argument<Int>("channel") ?: -1
        val apdu = call.argument<String>("apdu") ?: ""

        try {
            val tx = hexStringToByteArray(apdu)
            if (tx.size < 4) throw Exception("APDU too short")

            val cla = tx[0].toUByte().toInt()
            val ins = tx[1].toUByte().toInt()
            val p1 = tx[2].toUByte().toInt()
            val p2 = tx[3].toUByte().toInt()
            var p3 = 0
            var data: String? = null

            if (tx.size > 4) {
                p3 = tx[4].toUByte().toInt()
                if (tx.size > 5) {
                    data = tx.sliceArray(5 until tx.size).toHex()
                }
            }

            val response =
                    if (channel == 0) {
                        iccTransmitApduBasicChannel(
                                tm,
                                slotIndex,
                                portIndex,
                                cla,
                                ins,
                                p1,
                                p2,
                                p3,
                                data
                        )
                    } else {
                        iccTransmitApduLogicalChannel(
                                tm,
                                slotIndex,
                                portIndex,
                                channel,
                                cla,
                                ins,
                                p1,
                                p2,
                                p3,
                                data
                        )
                    }

            runOnUiThread { result.success(response) }
        } catch (e: Exception) {
            val root = e.rootCause()
            runOnUiThread { result.error("TRANSMIT_FAILED", root.readableMessage(), root.stackTraceToString()) }
        }
    }

    private fun handleSendTerminalCapabilities(call: MethodCall, result: Result) {
        val tm =
                telephonyManager
                        ?: return runOnUiThread {
                            result.error("NOT_AVAILABLE", "TelephonyManager not available", null)
                        }
        val slotIndex = call.argument<Int>("slotIndex") ?: 0
        val portIndex = call.argument<Int>("portIndex") ?: 0

        try {
            val response =
                    iccTransmitApduBasicChannel(
                            tm,
                            slotIndex,
                            portIndex,
                            0x80,
                            0xAA,
                            0x00,
                            0x00,
                            0x0A,
                            "A9088100820101830107"
                    )
            runOnUiThread { result.success(response) }
        } catch (e: Exception) {
            val root = e.rootCause()
            runOnUiThread { result.error("ERROR", root.readableMessage(), root.stackTraceToString()) }
        }
    }

    private fun Throwable.rootCause(): Throwable {
        return if (this is InvocationTargetException && targetException != null) {
            targetException.rootCause()
        } else {
            cause?.takeIf { it !== this }?.rootCause() ?: this
        }
    }

    private fun Throwable.readableMessage(): String {
        val message = message
        return if (message.isNullOrBlank()) {
            this::class.java.name
        } else {
            "${this::class.java.name}: $message"
        }
    }
}
