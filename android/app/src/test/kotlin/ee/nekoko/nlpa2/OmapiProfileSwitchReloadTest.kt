package ee.nekoko.nlpa2

import kotlin.concurrent.thread
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OmapiProfileSwitchReloadTest {
    private fun bytes(vararg values: Int) = ByteArray(values.size) { values[it].toByte() }

    /** STORE DATA as BaseChannel sends it: CLA carries the logical channel, no Le. */
    private fun switchCommand(
            tag: Int = 0x31,
            cla: Int = 0x81,
            p1: Int = 0x91,
            p2: Int = 0x00,
    ): ByteArray {
        val iccid = bytes(0x98, 0x10, 0x32, 0x54, 0x76, 0x98, 0x10, 0x32, 0x54, 0xF6)
        val body =
                bytes(0xBF, tag, 0x11, 0xA0, 0x0C, 0x5A, 0x0A) + iccid + bytes(0x81, 0x01, 0xFF)
        return bytes(cla, 0xE2, p1, p2, body.size) + body
    }

    @Test
    fun recognizesFinalEnableAndDisableBlocksOnAnyLogicalChannel() {
        for (cla in listOf(0x80, 0x81, 0x82, 0x83)) {
            assertNotNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand(cla = cla)))
        }
        assertNotNull(OmapiProfileSwitchReload.forCommand("SIM1", switchCommand(tag = 0x32)))
        assertNotNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand() + bytes(0x00)))
    }

    @Test
    fun ignoresOtherCommandsAndReaders() {
        val command = switchCommand()
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand(tag = 0x2D)))
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand(p1 = 0x11)))
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand(p2 = 0x01)))
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand(cla = 0x00)))
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", command.copyOf(command.size - 1)))
        assertNull(OmapiProfileSwitchReload.forCommand("SIM2", command + bytes(0x00, 0x00)))
        for (reader in listOf("SIM0", "SIM", "eSE1", "SIMx")) {
            assertNull(reader, OmapiProfileSwitchReload.forCommand(reader, command))
        }
    }

    @Test
    fun requiresTheSameSlotToResetAndComeBack() {
        val reload = requireNotNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand()))

        reload.observe(0, "NOT_READY")
        reload.observe(0, "LOADED")
        reload.observe(1, "LOADED")
        assertFalse(reload.awaitReload(0))

        reload.observe(1, "NOT_READY")
        reload.observe(1, "READY")
        assertFalse(reload.awaitReload(0))

        reload.observe(1, "LOADED")
        assertTrue(reload.awaitReload(0))
    }

    @Test
    fun aPinLockedTargetProfileCompletesTheReload() {
        val reload = requireNotNull(OmapiProfileSwitchReload.forCommand("SIM1", switchCommand()))
        reload.observe(0, "NOT_READY")
        reload.observe(0, "LOCKED")
        assertTrue(reload.awaitReload(0))
    }

    @Test
    fun aBroadcastOnAnotherThreadWakesTheWaitingTransmit() {
        val reload = requireNotNull(OmapiProfileSwitchReload.forCommand("SIM2", switchCommand()))
        assertFalse(reload.awaitReload(20))

        val receiver = thread {
            Thread.sleep(50)
            reload.observe(1, "NOT_READY")
            reload.observe(1, "LOADED")
        }
        assertTrue(reload.awaitReload(5_000))
        receiver.join()
    }

    private class FakeChannel(val open: Boolean = false, val basic: Boolean = false, val binderDead: Boolean = false)

    private fun closedByService(vararg channels: FakeChannel) =
            channelsClosedByService(
                    channels.toList(),
                    isOpen = { it.open },
                    isBasicChannel = {
                        if (it.binderDead) throw IllegalStateException(null as String?)
                        it.basic
                    },
            )

    @Test
    fun onlyAnsweringClosedLogicalChannelsCountAsInvalidated() {
        assertTrue(closedByService(FakeChannel(), FakeChannel()))
        assertFalse(closedByService())
        assertFalse(closedByService(FakeChannel(), FakeChannel(open = true)))
        assertFalse(closedByService(FakeChannel(basic = true)))
        assertFalse(closedByService(FakeChannel(binderDead = true)))
    }
}
