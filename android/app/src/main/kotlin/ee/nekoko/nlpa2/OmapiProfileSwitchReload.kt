package ee.nekoko.nlpa2

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

internal const val OMAPI_PROFILE_SWITCH_RESPONSE_LOST = "OMAPI_PROFILE_SWITCH_RESPONSE_LOST"

internal class OmapiProfileSwitchReload private constructor(private val slot: Int) {
    private val reloaded = CountDownLatch(1)
    private var sawNotReady = false

    @Synchronized
    fun observe(changedSlot: Int, state: String) {
        if (slot != changedSlot) return
        when (state) {
            "NOT_READY" -> sawNotReady = true
            // LOCKED: the reset finished and the newly enabled profile is waiting for its PIN.
            "LOADED", "LOCKED" -> if (sawNotReady) reloaded.countDown()
        }
    }

    fun awaitReload(timeoutMillis: Long): Boolean =
            try {
                reloaded.await(timeoutMillis, TimeUnit.MILLISECONDS)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
                false
            }

    companion object {
        fun forCommand(reader: String, apdu: ByteArray): OmapiProfileSwitchReload? {
            if (!isFinalSwitchStoreData(apdu)) return null
            val index = reader.removePrefix("SIM").takeIf { it != reader }?.toIntOrNull()
            return index?.takeIf { it > 0 }?.let { OmapiProfileSwitchReload(it - 1) }
        }

        /** Final STORE DATA block carrying ES10c EnableProfile (BF31) or DisableProfile (BF32). */
        private fun isFinalSwitchStoreData(apdu: ByteArray): Boolean {
            if (apdu.size < 8 ||
                            (apdu[0].toInt() and 0xFC) != 0x80 ||
                            apdu[1] != 0xE2.toByte() ||
                            apdu[2] != 0x91.toByte() ||
                            apdu[3] != 0.toByte() ||
                            apdu[5] != 0xBF.toByte() ||
                            (apdu[6] != 0x31.toByte() && apdu[6] != 0x32.toByte())
            ) return false
            val length = apdu[4].toInt() and 0xFF
            return length >= 3 && apdu.size in (5 + length)..(6 + length)
        }
    }
}

/**
 * True only when the service reports every channel closed and still answers for it. Channel.isOpen()
 * also returns false after a Binder failure, whereas isBasicChannel() throws in that case.
 */
internal fun <C> channelsClosedByService(
        channels: Collection<C>,
        isOpen: (C) -> Boolean,
        isBasicChannel: (C) -> Boolean,
): Boolean =
        channels.isNotEmpty() &&
                try {
                    channels.none { isOpen(it) || isBasicChannel(it) }
                } catch (_: Exception) {
                    false
                }
