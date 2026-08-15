package ee.nekoko.nlpa2

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OmapiProcessHandoffTest {
    private data class SharedState(var persisted: PersistedOmapiSafetyState? = null)

    private class ProcessAwareStore(
            private val state: SharedState,
            override val processScopeKey: Any,
    ) : OmapiSafetyStore {
        override fun load(): PersistedOmapiSafetyState? = state.persisted

        override fun saveArmed(
                bootIdentity: OmapiBootIdentity,
                recordedAtEpochMillis: Long,
        ): Boolean {
            state.persisted =
                    PersistedOmapiSafetyState(
                            kind = PersistedOmapiSafetyKind.ARMED,
                            info = null,
                            bootIdentity = bootIdentity,
                            recordedAtEpochMillis = recordedAtEpochMillis,
                    )
            return true
        }

        override fun savePoison(poison: PersistedOmapiSafetyState): Boolean {
            state.persisted = poison
            return true
        }

        override fun clear(): Boolean {
            state.persisted = null
            return true
        }
    }

    private fun coordinator(store: OmapiSafetyStore): OmapiCleanupCoordinator<String> =
            OmapiCleanupCoordinator(
                    backend =
                            object : OmapiCleanupBackend<String> {
                                override fun closeChannel(channel: String) = Unit
                                override fun closeSessionChannels(readerName: String) = Unit
                                override fun closeSession(readerName: String) = Unit
                                override fun closeReaderSessions(readerName: String) = Unit
                                override fun reconnectService() = Unit
                            },
                    readerKeys = { emptySet() },
                    detachChannel = { _, _ -> null },
                    detachReader = { emptyList() },
                    clearAllLocalState = {},
                    safetyStore = store,
                    bootIdentityProvider = OmapiBootIdentityProvider { BOOT },
                    nowEpochMillis = { 1234L },
            )

    @Test
    fun replacementEngineWaitsForLiveSameProcessOwnerWithoutPoisoning() {
        val state = SharedState()
        val scope = Any()
        val first = coordinator(ProcessAwareStore(state, scope))
        assertNull(first.enterHardware(OmapiHardwareEntry.CONNECT))
        assertEquals(PersistedOmapiSafetyKind.ARMED, state.persisted?.kind)

        val replacement = coordinator(ProcessAwareStore(state, scope))
        assertNull(replacement.poisonInfo)

        val pending = replacement.enterHardware(OmapiHardwareEntry.CONNECT)
        assertEquals(OMAPI_PROCESS_HANDOFF_PENDING_REASON, pending?.reason)
        assertNull(replacement.poisonInfo)

        assertNull(first.confirmCleanShutdown())
        assertNull(state.persisted)

        assertNull(replacement.enterHardware(OmapiHardwareEntry.CONNECT))
        assertEquals(PersistedOmapiSafetyKind.ARMED, state.persisted?.kind)
        assertNull(replacement.confirmCleanShutdown())
    }

    @Test
    fun realProcessLossStillTreatsSurvivingArmedMarkerAsRebootRequired() {
        val firstState = SharedState()
        val first = coordinator(ProcessAwareStore(firstState, Any()))
        assertNull(first.enterHardware(OmapiHardwareEntry.TRANSMIT))
        val persistedAfterCrash = firstState.persisted
        assertEquals(PersistedOmapiSafetyKind.ARMED, persistedAfterCrash?.kind)

        // A new process has a new in-memory scope but sees the same durable marker.
        val restartedState = SharedState(persistedAfterCrash)
        val restarted = coordinator(ProcessAwareStore(restartedState, Any()))

        assertTrue(restarted.poisonInfo != null)
        assertTrue(restarted.enterHardware(OmapiHardwareEntry.TRANSMIT) != null)
    }

    @Test
    fun replacementEngineInheritsPoisonInsteadOfBypassingIt() {
        val state = SharedState()
        val scope = Any()
        val first = coordinator(ProcessAwareStore(state, scope))
        assertNull(first.enterHardware(OmapiHardwareEntry.OPEN_CHANNEL))
        first.markPoisoned("SIM1", "INVALID_ARGUMENTS", true)

        val replacement = coordinator(ProcessAwareStore(state, scope))

        assertTrue(replacement.poisonInfo != null)
        assertEquals("INVALID_ARGUMENTS", replacement.poisonInfo?.reason)
    }

    private companion object {
        val BOOT = OmapiBootIdentity(bootCount = 40L, kernelBootId = "boot-one")
    }
}
