package ee.nekoko.nlpa2

import java.util.concurrent.CountDownLatch
import java.util.concurrent.atomic.AtomicReference
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

internal const val OMAPI_SESSION_CORRUPTED = "OMAPI_SESSION_CORRUPTED"
internal const val OMAPI_PROCESS_HANDOFF_PENDING_REASON =
        "OMAPI same-process engine handoff is still cleaning up"

internal data class OmapiPoisonInfo(
        val readerName: String?,
        val reason: String,
        val operationMayHaveSucceeded: Boolean,
        val persistenceConfirmed: Boolean = true,
)

internal sealed class OmapiCleanupResult {
    data object Success : OmapiCleanupResult()

    data class RebootRequired(val info: OmapiPoisonInfo) : OmapiCleanupResult()
}

internal enum class OmapiHardwareEntry {
    INITIALIZE_SERVICE,
    LIST_READERS,
    CONNECT,
    OPEN_SESSION,
    OPEN_CHANNEL,
    TRANSMIT,
    RESET,
    DISCONNECT,
    CLEANUP,
}

/**
 * The deliberately forbidden methods make the Samsung workaround auditable and regression-testable.
 * Cleanup is only allowed to close individually tracked channels.
 */
internal interface OmapiCleanupBackend<C> {
    fun closeChannel(channel: C)

    fun closeSessionChannels(readerName: String)

    fun closeSession(readerName: String)

    fun closeReaderSessions(readerName: String)

    fun reconnectService()
}

/**
 * Process-local ownership complements the durable ARMED marker. A surviving in-process owner means
 * an overlapping Flutter engine must wait for that owner's asynchronous cleanup instead of treating
 * the marker as evidence of a process crash. The registry disappears on real process death, while
 * the durable marker does not.
 */
private object OmapiProcessArmRegistry {
    private data class Key(val scope: Any, val bootIdentity: OmapiBootIdentity)
    private data class OwnerRecord(val owner: Any, val released: CountDownLatch = CountDownLatch(1))

    private val owners = mutableMapOf<Key, OwnerRecord>()

    fun isOwnedByOther(scope: Any, bootIdentity: OmapiBootIdentity, owner: Any): Boolean =
            synchronized(owners) {
                val current = owners[Key(scope, bootIdentity)]
                current != null && current.owner !== owner
            }

    fun tryAcquire(scope: Any, bootIdentity: OmapiBootIdentity, owner: Any): Boolean =
            synchronized(owners) {
                val key = Key(scope, bootIdentity)
                val current = owners[key]
                if (current == null) {
                    owners[key] = OwnerRecord(owner)
                    true
                } else {
                    current.owner === owner
                }
            }

    fun awaitOtherOwnerRelease(
            scope: Any,
            bootIdentity: OmapiBootIdentity,
            owner: Any,
    ): Boolean {
        val latch =
                synchronized(owners) {
                    val current = owners[Key(scope, bootIdentity)]
                    if (current != null && current.owner !== owner) current.released else null
                }
                        ?: return true
        return try {
            latch.await()
            true
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            false
        }
    }

    fun release(scope: Any, bootIdentity: OmapiBootIdentity, owner: Any) {
        val released =
                synchronized(owners) {
                    val key = Key(scope, bootIdentity)
                    val current = owners[key]
                    if (current != null && current.owner === owner) owners.remove(key) else null
                }
        released?.released?.countDown()
    }
}

internal class OmapiCleanupCoordinator<C>(
        private val backend: OmapiCleanupBackend<C>,
        private val readerKeys: () -> Set<String>,
        private val detachChannel: (String, String) -> C?,
        private val detachReader: (String) -> List<C>,
        private val clearAllLocalState: () -> Unit,
        private val safetyStore: OmapiSafetyStore,
        private val bootIdentityProvider: OmapiBootIdentityProvider,
        private val nowEpochMillis: () -> Long = System::currentTimeMillis,
) {
    private val cleanupLock = ReentrantLock()
    private val poison = AtomicReference<OmapiPoisonInfo?>()
    private val processOwnerToken = Any()
    private var pendingProcessHandoffIdentity: OmapiBootIdentity? = null
    private var armed = false
    private var armedBootIdentity: OmapiBootIdentity? = null

    init {
        poison.set(restorePersistedState())
    }

    val poisonInfo: OmapiPoisonInfo?
        get() = poison.get()

    fun rejectionForHardwareEntry(entry: OmapiHardwareEntry): OmapiPoisonInfo? =
            when (entry) {
                OmapiHardwareEntry.INITIALIZE_SERVICE,
                OmapiHardwareEntry.LIST_READERS,
                OmapiHardwareEntry.CONNECT,
                OmapiHardwareEntry.OPEN_SESSION,
                OmapiHardwareEntry.OPEN_CHANNEL,
                OmapiHardwareEntry.TRANSMIT,
                OmapiHardwareEntry.RESET,
                OmapiHardwareEntry.DISCONNECT,
                OmapiHardwareEntry.CLEANUP -> poison.get()
            }

    /** Must succeed before the caller touches SEService, Reader, Session, Channel, or APDU. */
    fun enterHardware(entry: OmapiHardwareEntry): OmapiPoisonInfo? {
        while (true) {
            var waitTarget: Pair<Any, OmapiBootIdentity>? = null
            val result =
                    cleanupLock.withLock {
                        rejectionForHardwareEntry(entry)?.let { return@withLock it }

                        if (entry == OmapiHardwareEntry.INITIALIZE_SERVICE) {
                            val pendingIdentity = pendingProcessHandoffIdentity
                            val scope = safetyStore.processScopeKey
                            if (pendingIdentity != null &&
                                            scope != null &&
                                            OmapiProcessArmRegistry.isOwnedByOther(
                                                    scope,
                                                    pendingIdentity,
                                                    processOwnerToken,
                                            )
                            ) {
                                waitTarget = scope to pendingIdentity
                                return@withLock null
                            }
                        }

                        val handoff = refreshProcessHandoffLocked()
                        if (handoff != null) {
                            if (entry == OmapiHardwareEntry.INITIALIZE_SERVICE &&
                                            handoff.reason == OMAPI_PROCESS_HANDOFF_PENDING_REASON
                            ) {
                                val pendingIdentity = pendingProcessHandoffIdentity
                                val scope = safetyStore.processScopeKey
                                if (pendingIdentity != null && scope != null) {
                                    waitTarget = scope to pendingIdentity
                                    return@withLock null
                                }
                            }
                            return@withLock handoff
                        }

                        val armResult = armLocked()
                        if (entry == OmapiHardwareEntry.INITIALIZE_SERVICE &&
                                        armResult?.reason == OMAPI_PROCESS_HANDOFF_PENDING_REASON
                        ) {
                            val pendingIdentity = pendingProcessHandoffIdentity
                            val scope = safetyStore.processScopeKey
                            if (pendingIdentity != null && scope != null) {
                                waitTarget = scope to pendingIdentity
                                return@withLock null
                            }
                        }
                        armResult
                    }

            val target = waitTarget ?: return result
            if (!OmapiProcessArmRegistry.awaitOtherOwnerRelease(
                            target.first,
                            target.second,
                            processOwnerToken,
                    )
            ) {
                return processHandoffPendingInfo()
            }
        }
    }

    /** Clears the durable guard only after local cleanup and SEService shutdown both succeeded. */
    fun confirmCleanShutdown(): OmapiPoisonInfo? =
            cleanupLock.withLock {
                poison.get()?.let { return@withLock it }
                if (readerKeys().isNotEmpty()) {
                    return@withLock markPoisonedLocked(
                            readerName = null,
                            reason = "Clean shutdown was requested while local OMAPI state remained",
                            operationMayHaveSucceeded = true,
                    )
                }
                if (!armed) return@withLock null

                val cleared =
                        try {
                            safetyStore.clear()
                        } catch (_: Exception) {
                            false
                        }
                if (cleared) {
                    releaseProcessOwnershipLocked()
                    armed = false
                    armedBootIdentity = null
                    return@withLock null
                }

                val info =
                        OmapiPoisonInfo(
                                readerName = null,
                                reason = "Unable to durably clear the OMAPI safety guard",
                                operationMayHaveSucceeded = true,
                                persistenceConfirmed = true,
                        )
                poison.set(info)
                releaseProcessOwnershipLocked()
                info
            }

    fun cleanupReader(readerName: String): OmapiCleanupResult =
            cleanupLock.withLock {
                poison.get()?.let { return@withLock OmapiCleanupResult.RebootRequired(it) }
                cleanupReaderLocked(readerName)
            }

    fun cleanupChannel(
            readerName: String,
            channelKey: String,
            operationMayHaveSucceeded: Boolean = false,
    ): OmapiCleanupResult =
            cleanupLock.withLock {
                poison.get()?.let { return@withLock OmapiCleanupResult.RebootRequired(it) }

                val channel =
                        detachChannel(readerName, channelKey)
                                ?: return@withLock OmapiCleanupResult.Success
                armLocked()?.let {
                    clearAllLocalState()
                    return@withLock OmapiCleanupResult.RebootRequired(it)
                }

                try {
                    backend.closeChannel(channel)
                    OmapiCleanupResult.Success
                } catch (e: Exception) {
                    val info =
                            markPoisonedLocked(
                                    readerName,
                                    e.message ?: e.javaClass.simpleName,
                                    operationMayHaveSucceeded,
                            )
                    clearAllLocalState()
                    OmapiCleanupResult.RebootRequired(info)
                }
            }

    fun cleanupAll(): OmapiCleanupResult =
            cleanupLock.withLock {
                poison.get()?.let { return@withLock OmapiCleanupResult.RebootRequired(it) }

                for (readerName in readerKeys()) {
                    val result = cleanupReaderLocked(readerName)
                    if (result is OmapiCleanupResult.RebootRequired) return@withLock result
                }
                OmapiCleanupResult.Success
            }

    fun markPoisoned(
            readerName: String?,
            reason: String,
            operationMayHaveSucceeded: Boolean,
    ): OmapiPoisonInfo =
            cleanupLock.withLock {
                val info = markPoisonedLocked(readerName, reason, operationMayHaveSucceeded)
                clearAllLocalState()
                info
            }

    private fun cleanupReaderLocked(readerName: String): OmapiCleanupResult {
        // Detach first so re-entrant work can never rediscover this Session or its Channels.
        val channels = detachReader(readerName)
        if (channels.isNotEmpty()) {
            armLocked()?.let {
                clearAllLocalState()
                return OmapiCleanupResult.RebootRequired(it)
            }
        }
        for (channel in channels) {
            try {
                backend.closeChannel(channel)
            } catch (e: Exception) {
                val info =
                        markPoisonedLocked(
                                readerName,
                                e.message ?: e.javaClass.simpleName,
                                operationMayHaveSucceeded = false,
                        )
                clearAllLocalState()
                return OmapiCleanupResult.RebootRequired(info)
            }
        }
        return OmapiCleanupResult.Success
    }

    private fun markPoisonedLocked(
            readerName: String?,
            reason: String,
            operationMayHaveSucceeded: Boolean,
    ): OmapiPoisonInfo {
        poison.get()?.let { return it }

        // This is normally already armed. Keeping the check here makes direct error paths safe.
        armLocked()?.let { return it }

        val candidate =
                OmapiPoisonInfo(
                        readerName = readerName,
                        reason = reason,
                        operationMayHaveSucceeded = operationMayHaveSucceeded,
                        persistenceConfirmed = false,
                )
        // Latch memory first. No later operation can pass the coordinator after this point.
        poison.set(candidate)
        val persisted =
                try {
                    safetyStore.savePoison(
                            PersistedOmapiSafetyState(
                                    kind = PersistedOmapiSafetyKind.POISONED,
                                    info = candidate,
                                    bootIdentity = armedBootIdentity,
                                    recordedAtEpochMillis = nowEpochMillis(),
                            )
                    )
                } catch (_: Exception) {
                    false
                }
        val finalInfo = candidate.copy(persistenceConfirmed = persisted)
        poison.set(finalInfo)
        releaseProcessOwnershipLocked()
        return finalInfo
    }

    private fun armLocked(): OmapiPoisonInfo? {
        poison.get()?.let { return it }
        if (armed) return null
        refreshProcessHandoffLocked()?.let { return it }

        val identity = currentBootIdentityOrNull()
        if (identity == null) {
            return OmapiPoisonInfo(
                            readerName = null,
                            reason = "Unable to establish a reboot-scoped OMAPI safety guard",
                            operationMayHaveSucceeded = false,
                            persistenceConfirmed = false,
                    )
                    .also { poison.set(it) }
        }

        val scope = safetyStore.processScopeKey
        if (scope != null &&
                        !OmapiProcessArmRegistry.tryAcquire(scope, identity, processOwnerToken)
        ) {
            pendingProcessHandoffIdentity = identity
            return processHandoffPendingInfo()
        }

        val persisted =
                try {
                    safetyStore.saveArmed(identity, nowEpochMillis())
                } catch (_: Exception) {
                    false
                }
        if (!persisted) {
            if (scope != null) {
                OmapiProcessArmRegistry.release(scope, identity, processOwnerToken)
            }
            return OmapiPoisonInfo(
                            readerName = null,
                            reason = "Unable to durably arm the OMAPI safety guard",
                            operationMayHaveSucceeded = false,
                            persistenceConfirmed = false,
                    )
                    .also { poison.set(it) }
        }

        armedBootIdentity = identity
        armed = true
        return null
    }

    private fun refreshProcessHandoffLocked(): OmapiPoisonInfo? {
        val pendingIdentity = pendingProcessHandoffIdentity ?: return null
        val scope = safetyStore.processScopeKey
        if (scope != null &&
                        OmapiProcessArmRegistry.isOwnedByOther(
                                scope,
                                pendingIdentity,
                                processOwnerToken,
                        )
        ) {
            return processHandoffPendingInfo()
        }

        pendingProcessHandoffIdentity = null
        val persisted = loadPersistedState()
        poison.get()?.let { return it }
        if (persisted == null) return null

        val currentIdentity = currentBootIdentityOrNull()
        if (currentIdentity?.definitelyChangedSince(persisted.bootIdentity) == true) {
            val cleared =
                    try {
                        safetyStore.clear()
                    } catch (_: Exception) {
                        false
                    }
            if (cleared) return null
        }

        val restored = persistedStateToPoison(persisted)
        poison.set(restored)
        return restored
    }

    private fun restorePersistedState(): OmapiPoisonInfo? {
        val persisted = loadPersistedState()
        poison.get()?.let { return it }
        if (persisted == null) return null

        val currentIdentity = currentBootIdentityOrNull()
        if (currentIdentity?.definitelyChangedSince(persisted.bootIdentity) == true) {
            val cleared =
                    try {
                        safetyStore.clear()
                    } catch (_: Exception) {
                        false
                    }
            if (cleared) return null
        }

        if (persisted.kind == PersistedOmapiSafetyKind.ARMED) {
            val scope = safetyStore.processScopeKey
            val persistedIdentity = persisted.bootIdentity
            if (scope != null &&
                            persistedIdentity != null &&
                            OmapiProcessArmRegistry.isOwnedByOther(
                                    scope,
                                    persistedIdentity,
                                    processOwnerToken,
                            )
            ) {
                pendingProcessHandoffIdentity = persistedIdentity
                return null
            }
        }

        return persistedStateToPoison(persisted)
    }

    private fun loadPersistedState(): PersistedOmapiSafetyState? =
            try {
                safetyStore.load()
            } catch (e: Exception) {
                val info =
                        OmapiPoisonInfo(
                                readerName = null,
                                reason =
                                        "Unable to verify persisted OMAPI safety state: " +
                                                (e.message ?: e.javaClass.simpleName),
                                operationMayHaveSucceeded = true,
                                persistenceConfirmed = false,
                        )
                poison.set(info)
                null
            }

    private fun persistedStateToPoison(persisted: PersistedOmapiSafetyState): OmapiPoisonInfo =
            when (persisted.kind) {
                PersistedOmapiSafetyKind.ARMED ->
                        OmapiPoisonInfo(
                                readerName = null,
                                reason =
                                        "OMAPI safety guard survived an unclean process exit on this boot",
                                operationMayHaveSucceeded = true,
                                persistenceConfirmed = true,
                        )
                PersistedOmapiSafetyKind.POISONED ->
                        requireNotNull(persisted.info).copy(persistenceConfirmed = true)
            }

    private fun currentBootIdentityOrNull(): OmapiBootIdentity? =
            try {
                bootIdentityProvider.currentBootIdentity()
            } catch (_: Exception) {
                null
            }

    private fun processHandoffPendingInfo(): OmapiPoisonInfo =
            OmapiPoisonInfo(
                    readerName = null,
                    reason = OMAPI_PROCESS_HANDOFF_PENDING_REASON,
                    operationMayHaveSucceeded = false,
                    persistenceConfirmed = true,
            )

    private fun releaseProcessOwnershipLocked() {
        val scope = safetyStore.processScopeKey ?: return
        val identity = armedBootIdentity ?: return
        OmapiProcessArmRegistry.release(scope, identity, processOwnerToken)
    }
}
