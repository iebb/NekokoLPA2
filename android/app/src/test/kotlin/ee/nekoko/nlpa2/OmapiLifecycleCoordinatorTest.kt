package ee.nekoko.nlpa2

import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class OmapiLifecycleCoordinatorTest {
    @Test
    fun detachDoesNotWaitForHardwareAndQueuedWorkCannotEnterAfterDetach() {
        val executor = Executors.newSingleThreadExecutor()
        val coordinator =
                OmapiLifecycleCoordinator { task ->
                    executor.execute(task)
                    true
                }
        val initialized = CountDownLatch(1)
        assertTrue(
                coordinator.attach {
                    initialized.countDown()
                    true
                }
        )
        assertTrue(initialized.await(2, TimeUnit.SECONDS))

        val hardwareStarted = CountDownLatch(1)
        val releaseHardware = CountDownLatch(1)
        assertTrue(
                coordinator.enqueueHardware(
                        onRejected = {},
                        operation = {
                            hardwareStarted.countDown()
                            assertTrue(releaseHardware.await(2, TimeUnit.SECONDS))
                        },
                )
        )
        assertTrue(hardwareStarted.await(2, TimeUnit.SECONDS))

        val queuedHardwareRan = AtomicBoolean(false)
        val queuedHardwareRejected = CountDownLatch(1)
        assertTrue(
                coordinator.enqueueHardware(
                        onRejected = { queuedHardwareRejected.countDown() },
                        operation = { queuedHardwareRan.set(true) },
                )
        )

        val shutdownRan = CountDownLatch(1)
        val detachStarted = System.nanoTime()
        assertTrue(coordinator.detach { shutdownRan.countDown() })
        val detachMillis = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - detachStarted)
        val postDetachHardwareRan = AtomicBoolean(false)
        val postDetachHardwareRejected = CountDownLatch(1)
        assertTrue(
                coordinator.enqueueHardware(
                        onRejected = { postDetachHardwareRejected.countDown() },
                        operation = { postDetachHardwareRan.set(true) },
                )
        )

        assertTrue("detach blocked for $detachMillis ms", detachMillis < 250)
        assertFalse(coordinator.isAcceptingHardwareOperations)
        assertFalse(shutdownRan.await(100, TimeUnit.MILLISECONDS))

        releaseHardware.countDown()
        assertTrue(queuedHardwareRejected.await(2, TimeUnit.SECONDS))
        assertTrue(shutdownRan.await(2, TimeUnit.SECONDS))
        assertTrue(postDetachHardwareRejected.await(2, TimeUnit.SECONDS))
        assertFalse(queuedHardwareRan.get())
        assertFalse(postDetachHardwareRan.get())
        executor.shutdownNow()
    }

    @Test
    fun purePoisonProbeDoesNotPersistArmedGuardBeforeAdmission() {
        val armCalls = AtomicInteger()
        val store =
                object : OmapiSafetyStore {
                    override fun load(): PersistedOmapiSafetyState? = null

                    override fun saveArmed(
                            bootIdentity: OmapiBootIdentity,
                            recordedAtEpochMillis: Long,
                    ): Boolean {
                        armCalls.incrementAndGet()
                        return true
                    }

                    override fun savePoison(poison: PersistedOmapiSafetyState): Boolean = true

                    override fun clear(): Boolean = true
                }
        val cleanup =
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
                        bootIdentityProvider =
                                OmapiBootIdentityProvider {
                                    OmapiBootIdentity(bootCount = 40L, kernelBootId = "boot-one")
                                },
                )

        assertNull(cleanup.rejectionForHardwareEntry(OmapiHardwareEntry.CONNECT))
        assertEquals(0, armCalls.get())

        assertNull(cleanup.enterHardware(OmapiHardwareEntry.CONNECT))
        assertEquals(1, armCalls.get())
    }
}
