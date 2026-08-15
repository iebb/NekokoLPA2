package ee.nekoko.nlpa2

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OmapiCleanupCoordinatorTest {
    private class FakePoisonStore(
            @Volatile var persisted: PersistedOmapiSafetyState? = null,
            var armSucceeds: Boolean = true,
            var poisonSaveSucceeds: Boolean = true,
            var clearSucceeds: Boolean = true,
    ) : OmapiSafetyStore {
        val armCalls = AtomicInteger()
        val poisonSaveCalls = AtomicInteger()
        val clearCalls = AtomicInteger()

        @Synchronized
        override fun load(): PersistedOmapiSafetyState? = persisted

        @Synchronized
        override fun saveArmed(
                bootIdentity: OmapiBootIdentity,
                recordedAtEpochMillis: Long,
        ): Boolean {
            armCalls.incrementAndGet()
            if (armSucceeds) {
                persisted =
                        PersistedOmapiSafetyState(
                                PersistedOmapiSafetyKind.ARMED,
                                info = null,
                                bootIdentity,
                                recordedAtEpochMillis,
                        )
            }
            return armSucceeds
        }

        @Synchronized
        override fun savePoison(poison: PersistedOmapiSafetyState): Boolean {
            poisonSaveCalls.incrementAndGet()
            if (poisonSaveSucceeds) persisted = poison
            return poisonSaveSucceeds
        }

        @Synchronized
        override fun clear(): Boolean {
            clearCalls.incrementAndGet()
            if (clearSucceeds) persisted = null
            return clearSucceeds
        }
    }

    private class FakeBackend : OmapiCleanupBackend<String> {
        val closed = mutableListOf<String>()
        var failOn: String? = null
        var closeSessionChannelsCalls = 0
        var closeSessionCalls = 0
        var closeReaderSessionsCalls = 0
        var reconnectCalls = 0

        override fun closeChannel(channel: String) {
            closed += channel
            if (channel == failOn) throw IllegalArgumentException("INVALID_ARGUMENTS")
        }

        override fun closeSessionChannels(readerName: String) {
            closeSessionChannelsCalls++
        }

        override fun closeSession(readerName: String) {
            closeSessionCalls++
        }

        override fun closeReaderSessions(readerName: String) {
            closeReaderSessionsCalls++
        }

        override fun reconnectService() {
            reconnectCalls++
        }
    }

    private class Fixture(
            val backend: FakeBackend = FakeBackend(),
            val sessions: MutableSet<String> = mutableSetOf(),
            val channels: MutableMap<String, MutableList<String>> = mutableMapOf(),
            val successfulReaders: MutableSet<String> = mutableSetOf(),
            val safetyStore: FakePoisonStore = FakePoisonStore(),
            val bootIdentity: OmapiBootIdentity? = BOOT_ONE,
    ) {
        val coordinator =
                OmapiCleanupCoordinator(
                        backend = backend,
                        readerKeys = { sessions + channels.keys + successfulReaders },
                        detachReader = { reader ->
                            sessions.remove(reader)
                            successfulReaders.remove(reader)
                            channels.remove(reader)?.toList() ?: emptyList()
                        },
                        clearAllLocalState = {
                            sessions.clear()
                            channels.clear()
                            successfulReaders.clear()
                        },
                        safetyStore = safetyStore,
                        bootIdentityProvider = OmapiBootIdentityProvider { bootIdentity },
                        nowEpochMillis = { 1234L },
                )
    }

    companion object {
        private val BOOT_ONE = OmapiBootIdentity(bootCount = 40L, kernelBootId = "boot-one")
        private val BOOT_TWO = OmapiBootIdentity(bootCount = 41L, kernelBootId = "boot-two")
    }

    @Test
    fun allChannelClosesSucceed() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("a", "b")))

        assertEquals(OmapiCleanupResult.Success, fixture.coordinator.cleanupReader("SIM1"))
        assertEquals(listOf("a", "b"), fixture.backend.closed)
        assertFalse(fixture.coordinator.poisonInfo != null)
    }

    @Test
    fun firstCloseFailurePoisonsAndNeverCallsBulkCleanupOrReconnect() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("a", "b")))
        fixture.backend.failOn = "a"

        assertTrue(fixture.coordinator.cleanupReader("SIM1") is OmapiCleanupResult.RebootRequired)
        assertEquals(listOf("a"), fixture.backend.closed)
        assertEquals(0, fixture.backend.closeSessionChannelsCalls)
        assertEquals(0, fixture.backend.closeSessionCalls)
        assertEquals(0, fixture.backend.closeReaderSessionsCalls)
        assertEquals(0, fixture.backend.reconnectCalls)
    }

    @Test
    fun secondCloseFailureStopsBeforeLaterChannels() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("a", "b", "c")))
        fixture.backend.failOn = "b"

        fixture.coordinator.cleanupReader("SIM1")

        assertEquals(listOf("a", "b"), fixture.backend.closed)
    }

    @Test
    fun firstReaderFailureStopsOtherReaders() {
        val fixture =
                Fixture(
                        sessions = linkedSetOf("SIM1", "SIM2"),
                        channels =
                                linkedMapOf(
                                        "SIM1" to mutableListOf("bad"),
                                        "SIM2" to mutableListOf("other"),
                                ),
                )
        fixture.backend.failOn = "bad"

        fixture.coordinator.cleanupAll()

        assertEquals(listOf("bad"), fixture.backend.closed)
    }

    @Test
    fun poisonedStateRejectsLaterCleanupAndCannotReconnect() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("bad")))
        fixture.backend.failOn = "bad"
        fixture.coordinator.cleanupReader("SIM1")
        fixture.channels["SIM1"] = mutableListOf("never")

        assertTrue(fixture.coordinator.cleanupAll() is OmapiCleanupResult.RebootRequired)
        assertEquals(listOf("bad"), fixture.backend.closed)
        assertEquals(0, fixture.backend.reconnectCalls)
    }

    @Test
    fun channelOnlyReaderIsIncludedByUnion() {
        val fixture = Fixture(channels = mutableMapOf("SIM2" to mutableListOf("orphan")))

        fixture.coordinator.cleanupAll()

        assertEquals(listOf("orphan"), fixture.backend.closed)
    }

    @Test
    fun profileSwitchFailureLatchesUncertainOutcomeWithoutRemoteCleanup() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("untouched")))

        val info =
                fixture.coordinator.markPoisoned(
                        "SIM1",
                        "6F00 during profile switch",
                        operationMayHaveSucceeded = true,
                )

        assertTrue(info.operationMayHaveSucceeded)
        assertTrue(fixture.channels.isEmpty())
        assertTrue(fixture.backend.closed.isEmpty())
    }

    @Test
    fun consecutiveCleanupCannotPassPoisonedState() {
        val fixture = Fixture(channels = mutableMapOf("SIM1" to mutableListOf("bad")))
        fixture.backend.failOn = "bad"

        fixture.coordinator.cleanupReader("SIM1")
        fixture.coordinator.cleanupReader("SIM1")

        assertEquals(1, fixture.backend.closed.size)
    }

    @Test
    fun concurrentCleanupRunsOnlyOneDangerousCloseAfterFailure() {
        val entered = CountDownLatch(1)
        val release = CountDownLatch(1)
        val closeCalls = AtomicInteger()
        val local = mutableMapOf("SIM1" to mutableListOf("bad"))
        val backend =
                object : OmapiCleanupBackend<String> {
                    override fun closeChannel(channel: String) {
                        closeCalls.incrementAndGet()
                        entered.countDown()
                        assertTrue(release.await(2, TimeUnit.SECONDS))
                        throw IllegalStateException("INVALID_ARGUMENTS")
                    }

                    override fun closeSessionChannels(readerName: String) = Unit
                    override fun closeSession(readerName: String) = Unit
                    override fun closeReaderSessions(readerName: String) = Unit
                    override fun reconnectService() = Unit
                }
        val coordinator =
                OmapiCleanupCoordinator(
                        backend,
                        readerKeys = { local.keys },
                        detachReader = { local.remove(it)?.toList() ?: emptyList() },
                        clearAllLocalState = { local.clear() },
                        safetyStore = FakePoisonStore(),
                        bootIdentityProvider = OmapiBootIdentityProvider { BOOT_ONE },
                )
        val executor = Executors.newFixedThreadPool(2)

        val first = executor.submit<OmapiCleanupResult> { coordinator.cleanupReader("SIM1") }
        assertTrue(entered.await(2, TimeUnit.SECONDS))
        val second = executor.submit<OmapiCleanupResult> { coordinator.cleanupReader("SIM1") }
        release.countDown()

        assertTrue(first.get(2, TimeUnit.SECONDS) is OmapiCleanupResult.RebootRequired)
        assertTrue(second.get(2, TimeUnit.SECONDS) is OmapiCleanupResult.RebootRequired)
        assertEquals(1, closeCalls.get())
        executor.shutdownNow()
    }

    @Test
    fun poisonSurvivesCoordinatorRecreation() {
        val first = Fixture()
        first.coordinator.markPoisoned("SIM1", "INVALID_ARGUMENTS", false)

        val recreated = Fixture(safetyStore = first.safetyStore, bootIdentity = BOOT_ONE)

        assertTrue(recreated.coordinator.poisonInfo != null)
        assertEquals("INVALID_ARGUMENTS", recreated.coordinator.poisonInfo?.reason)
    }

    @Test
    fun sameBootIdentityRemainsPoisonedAfterAppRestart() {
        val store = poisonedStore(BOOT_ONE)

        val restarted = Fixture(safetyStore = store, bootIdentity = BOOT_ONE)

        assertTrue(restarted.coordinator.poisonInfo != null)
        assertEquals(0, store.clearCalls.get())
    }

    @Test
    fun verifiedDifferentBootIdentityClearsPersistedPoison() {
        val store = poisonedStore(BOOT_ONE)

        val restarted = Fixture(safetyStore = store, bootIdentity = BOOT_TWO)

        assertTrue(restarted.coordinator.poisonInfo == null)
        assertTrue(store.persisted == null)
        assertEquals(1, store.clearCalls.get())
    }

    @Test
    fun unavailableBootIdentityFailsClosed() {
        val store = poisonedStore(BOOT_ONE)

        val restarted = Fixture(safetyStore = store, bootIdentity = null)

        assertTrue(restarted.coordinator.poisonInfo != null)
        assertEquals(0, store.clearCalls.get())
    }

    @Test
    fun failedDurableClearFailsClosedEvenAfterVerifiedReboot() {
        val store = poisonedStore(BOOT_ONE).apply { clearSucceeds = false }

        val restarted = Fixture(safetyStore = store, bootIdentity = BOOT_TWO)

        assertTrue(restarted.coordinator.poisonInfo != null)
        assertEquals(1, store.clearCalls.get())
    }

    @Test
    fun persistedPoisonRejectsEveryHardwareEntry() {
        val coordinator =
                Fixture(safetyStore = poisonedStore(BOOT_ONE), bootIdentity = BOOT_ONE).coordinator

        for (entry in OmapiHardwareEntry.entries) {
            assertTrue("$entry must be rejected", coordinator.rejectionForHardwareEntry(entry) != null)
        }
    }

    @Test
    fun activityRecreationDoesNotClearPoison() {
        assertRecreationDoesNotClearPoison()
    }

    @Test
    fun flutterEngineRecreationDoesNotClearPoison() {
        assertRecreationDoesNotClearPoison()
    }

    @Test
    fun processRecreationDoesNotClearPoison() {
        assertRecreationDoesNotClearPoison()
    }

    @Test
    fun onlyVerifiedDeviceRebootCanRestoreHealthyState() {
        val store = poisonedStore(BOOT_ONE)
        assertTrue(Fixture(safetyStore = store, bootIdentity = null).coordinator.poisonInfo != null)
        assertTrue(Fixture(safetyStore = store, bootIdentity = BOOT_ONE).coordinator.poisonInfo != null)
        assertTrue(Fixture(safetyStore = store, bootIdentity = BOOT_TWO).coordinator.poisonInfo == null)
    }

    @Test
    fun concurrentPoisoningPersistsOneConsistentFirstState() {
        val store = FakePoisonStore()
        val fixture = Fixture(safetyStore = store)
        val start = CountDownLatch(1)
        val executor = Executors.newFixedThreadPool(2)
        val calls =
                listOf(
                        executor.submit<OmapiPoisonInfo> {
                            start.await()
                            fixture.coordinator.markPoisoned("SIM1", "first", false)
                        },
                        executor.submit<OmapiPoisonInfo> {
                            start.await()
                            fixture.coordinator.markPoisoned("SIM2", "second", true)
                        },
                )

        start.countDown()
        val results = calls.map { it.get(2, TimeUnit.SECONDS) }

        assertEquals(1, store.armCalls.get())
        assertEquals(1, store.poisonSaveCalls.get())
        assertEquals(results[0], results[1])
        assertEquals(results[0].reason, store.persisted?.info?.reason)
        executor.shutdownNow()
    }

    @Test
    fun poisonIsPersistedBeforeRemainingLocalStateIsCleared() {
        val events = mutableListOf<String>()
        val store =
                object : OmapiSafetyStore {
                    override fun load(): PersistedOmapiSafetyState? = null

                    override fun saveArmed(
                            bootIdentity: OmapiBootIdentity,
                            recordedAtEpochMillis: Long,
                    ): Boolean {
                        events += "arm"
                        return true
                    }

                    override fun savePoison(poison: PersistedOmapiSafetyState): Boolean {
                        events += "persist-poison"
                        return true
                    }

                    override fun clear(): Boolean = true
                }
        val coordinator =
                OmapiCleanupCoordinator(
                        backend =
                                object : OmapiCleanupBackend<String> {
                                    override fun closeChannel(channel: String) {
                                        events += "close"
                                        throw IllegalArgumentException("INVALID_ARGUMENTS")
                                    }

                                    override fun closeSessionChannels(readerName: String) = Unit
                                    override fun closeSession(readerName: String) = Unit
                                    override fun closeReaderSessions(readerName: String) = Unit
                                    override fun reconnectService() = Unit
                                },
                        readerKeys = { setOf("SIM1") },
                        detachReader = {
                            events += "detach-reader"
                            listOf("bad")
                        },
                        clearAllLocalState = { events += "clear-all" },
                        safetyStore = store,
                        bootIdentityProvider = OmapiBootIdentityProvider { BOOT_ONE },
                )

        coordinator.cleanupReader("SIM1")

        assertEquals(
                listOf("detach-reader", "arm", "close", "persist-poison", "clear-all"),
                events,
        )
    }

    @Test
    fun persistenceFailureRemainsPoisonedAndIsReported() {
        val fixture = Fixture(safetyStore = FakePoisonStore(poisonSaveSucceeds = false))

        val info = fixture.coordinator.markPoisoned("SIM1", "failure", false)

        assertTrue(fixture.coordinator.poisonInfo != null)
        assertFalse(info.persistenceConfirmed)
    }

    @Test
    fun contradictoryBootSignalsDoNotClearPoison() {
        val store = poisonedStore(BOOT_ONE)
        val contradictory = OmapiBootIdentity(bootCount = 41L, kernelBootId = "boot-one")

        val restarted = Fixture(safetyStore = store, bootIdentity = contradictory)

        assertTrue(restarted.coordinator.poisonInfo != null)
        assertEquals(0, store.clearCalls.get())
    }

    @Test
    fun guardPersistenceFailurePreventsHardwareInvocation() {
        val fixture = Fixture(safetyStore = FakePoisonStore(armSucceeds = false))
        val hardwareCalls = AtomicInteger()

        if (fixture.coordinator.enterHardware(OmapiHardwareEntry.OPEN_CHANNEL) == null) {
            hardwareCalls.incrementAndGet()
        }

        assertEquals(0, hardwareCalls.get())
        assertTrue(fixture.coordinator.poisonInfo != null)
    }

    @Test
    fun armedMarkerRejectsProcessRecreationOnSameBoot() {
        val first = Fixture()
        assertTrue(first.coordinator.enterHardware(OmapiHardwareEntry.TRANSMIT) == null)

        val recreated = Fixture(safetyStore = first.safetyStore, bootIdentity = BOOT_ONE)

        assertTrue(recreated.coordinator.enterHardware(OmapiHardwareEntry.TRANSMIT) != null)
    }

    @Test
    fun armedMarkerMayRecoverAfterVerifiedReboot() {
        val first = Fixture()
        assertTrue(first.coordinator.enterHardware(OmapiHardwareEntry.OPEN_SESSION) == null)

        val restarted = Fixture(safetyStore = first.safetyStore, bootIdentity = BOOT_TWO)

        assertTrue(restarted.coordinator.poisonInfo == null)
        assertEquals(1, first.safetyStore.clearCalls.get())
    }

    @Test
    fun cleanShutdownClearsGuardAndAllowsLaterNormalUse() {
        val fixture = Fixture()
        assertTrue(fixture.coordinator.enterHardware(OmapiHardwareEntry.CONNECT) == null)

        assertTrue(fixture.coordinator.confirmCleanShutdown() == null)
        assertTrue(fixture.safetyStore.persisted == null)
        assertTrue(fixture.coordinator.enterHardware(OmapiHardwareEntry.CONNECT) == null)
        assertEquals(2, fixture.safetyStore.armCalls.get())
    }

    @Test
    fun cleanShutdownClearFailureFailsClosed() {
        val store = FakePoisonStore(clearSucceeds = false)
        val fixture = Fixture(safetyStore = store)
        assertTrue(fixture.coordinator.enterHardware(OmapiHardwareEntry.CONNECT) == null)

        val failure = fixture.coordinator.confirmCleanShutdown()

        assertTrue(failure != null)
        assertTrue(fixture.coordinator.enterHardware(OmapiHardwareEntry.CONNECT) != null)
        assertEquals(PersistedOmapiSafetyKind.ARMED, store.persisted?.kind)
    }

    @Test
    fun armedProcessCrashFailsClosedOnSameBoot() {
        val store = FakePoisonStore()
        Fixture(safetyStore = store).coordinator.enterHardware(OmapiHardwareEntry.INITIALIZE_SERVICE)

        val afterCrash = Fixture(safetyStore = store, bootIdentity = BOOT_ONE)

        assertTrue(afterCrash.coordinator.poisonInfo != null)
        assertEquals(PersistedOmapiSafetyKind.ARMED, store.persisted?.kind)
    }

    @Test
    fun failedPoisonWriteStillLeavesDurableArmedGuardForRecreatedProcess() {
        val store = FakePoisonStore(poisonSaveSucceeds = false)
        val first = Fixture(safetyStore = store)
        assertTrue(first.coordinator.enterHardware(OmapiHardwareEntry.TRANSMIT) == null)

        val info = first.coordinator.markPoisoned("SIM1", "INVALID_ARGUMENTS", true)
        val recreated = Fixture(safetyStore = store, bootIdentity = BOOT_ONE)

        assertFalse(info.persistenceConfirmed)
        assertEquals(PersistedOmapiSafetyKind.ARMED, store.persisted?.kind)
        assertTrue(recreated.coordinator.enterHardware(OmapiHardwareEntry.TRANSMIT) != null)
    }

    private fun assertRecreationDoesNotClearPoison() {
        val store = poisonedStore(BOOT_ONE)
        repeat(2) {
            assertTrue(Fixture(safetyStore = store, bootIdentity = BOOT_ONE).coordinator.poisonInfo != null)
        }
        assertEquals(0, store.clearCalls.get())
    }

    private fun poisonedStore(identity: OmapiBootIdentity?): FakePoisonStore =
            FakePoisonStore(
                    PersistedOmapiSafetyState(
                            kind = PersistedOmapiSafetyKind.POISONED,
                            info = OmapiPoisonInfo("SIM1", "persisted", true),
                            bootIdentity = identity,
                            recordedAtEpochMillis = 1000L,
                    )
            )
}
