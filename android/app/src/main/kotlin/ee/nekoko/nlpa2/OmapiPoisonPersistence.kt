package ee.nekoko.nlpa2

import android.content.Context
import android.provider.Settings
import java.io.File

internal data class OmapiBootIdentity(
        val bootCount: Long?,
        val kernelBootId: String?,
) {
    val isUsable: Boolean
        get() = bootCount != null || kernelBootId != null

    /** Returns true only when every comparable, reboot-scoped identifier changed. */
    fun definitelyChangedSince(previous: OmapiBootIdentity?): Boolean {
        if (previous == null) return false
        val comparisons =
                buildList {
                    if (bootCount != null && previous.bootCount != null) {
                        add(bootCount != previous.bootCount)
                    }
                    if (kernelBootId != null && previous.kernelBootId != null) {
                        add(kernelBootId != previous.kernelBootId)
                    }
                }
        return comparisons.isNotEmpty() && comparisons.all { it }
    }
}

internal enum class PersistedOmapiSafetyKind {
    ARMED,
    POISONED,
}

internal data class PersistedOmapiSafetyState(
        val kind: PersistedOmapiSafetyKind,
        val info: OmapiPoisonInfo?,
        val bootIdentity: OmapiBootIdentity?,
        val recordedAtEpochMillis: Long,
)

internal interface OmapiSafetyStore {
    fun load(): PersistedOmapiSafetyState?

    /** Establishes crash safety synchronously before the first OMAPI hardware access. */
    fun saveArmed(bootIdentity: OmapiBootIdentity, recordedAtEpochMillis: Long): Boolean

    /** Upgrades an existing armed marker. A failed write must leave the durable guard armed. */
    fun savePoison(poison: PersistedOmapiSafetyState): Boolean

    /** Returns false when durable removal could not be confirmed. */
    fun clear(): Boolean
}

internal fun interface OmapiBootIdentityProvider {
    fun currentBootIdentity(): OmapiBootIdentity?
}

internal class AndroidOmapiBootIdentityProvider(private val context: Context) :
        OmapiBootIdentityProvider {
    override fun currentBootIdentity(): OmapiBootIdentity? {
        val bootCount =
                try {
                    Settings.Global.getInt(
                                    context.contentResolver,
                                    Settings.Global.BOOT_COUNT,
                            )
                            .toLong()
                } catch (_: Exception) {
                    null
                }
        val kernelBootId =
                try {
                    File(KERNEL_BOOT_ID_PATH)
                            .readText()
                            .trim()
                            .lowercase()
                            .takeIf { BOOT_ID_PATTERN.matches(it) }
                } catch (_: Exception) {
                    null
                }
        return OmapiBootIdentity(bootCount, kernelBootId).takeIf { it.isUsable }
    }

    private companion object {
        private const val KERNEL_BOOT_ID_PATH = "/proc/sys/kernel/random/boot_id"
        private val BOOT_ID_PATTERN =
                Regex("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
    }
}

internal class SharedPreferencesOmapiSafetyStore(context: Context) : OmapiSafetyStore {
    private val preferences =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)

    override fun load(): PersistedOmapiSafetyState? {
        if (!preferences.getBoolean(KEY_PRESENT, false)) return null
        val schemaVersion = preferences.getInt(KEY_SCHEMA_VERSION, 0)
        if (schemaVersion == LEGACY_POISON_SCHEMA_VERSION) return loadLegacyPoison()
        if (schemaVersion != SCHEMA_VERSION) {
            return unreadablePersistedState("Unsupported persisted OMAPI safety schema")
        }

        val kind =
                try {
                    PersistedOmapiSafetyKind.valueOf(
                            preferences.getString(KEY_KIND, null)
                                    ?: return unreadablePersistedState(
                                            "Persisted OMAPI safety state has no kind"
                                    )
                    )
                } catch (_: IllegalArgumentException) {
                    return unreadablePersistedState("Unknown persisted OMAPI safety state")
                }
        val bootCount =
                if (preferences.contains(KEY_BOOT_COUNT)) {
                    preferences.getLong(KEY_BOOT_COUNT, 0L)
                } else {
                    null
                }
        val kernelBootId = preferences.getString(KEY_KERNEL_BOOT_ID, null)
        val identity = OmapiBootIdentity(bootCount, kernelBootId).takeIf { it.isUsable }
        val info = if (kind == PersistedOmapiSafetyKind.POISONED) loadPoisonInfo() else null
        if (kind == PersistedOmapiSafetyKind.POISONED && info == null) {
            return unreadablePersistedState("Persisted OMAPI poison state is incomplete")
        }

        return PersistedOmapiSafetyState(
                kind = kind,
                info = info,
                bootIdentity = identity,
                recordedAtEpochMillis = preferences.getLong(KEY_RECORDED_AT, 0L),
        )
    }

    override fun saveArmed(
            bootIdentity: OmapiBootIdentity,
            recordedAtEpochMillis: Long,
    ): Boolean =
            baseEditor(PersistedOmapiSafetyKind.ARMED, bootIdentity, recordedAtEpochMillis)
                    .remove(KEY_READER_NAME)
                    .remove(KEY_REASON)
                    .remove(KEY_OPERATION_MAY_HAVE_SUCCEEDED)
                    .commit()

    override fun savePoison(poison: PersistedOmapiSafetyState): Boolean {
        require(poison.kind == PersistedOmapiSafetyKind.POISONED)
        val info = requireNotNull(poison.info)
        val identity = requireNotNull(poison.bootIdentity)
        return baseEditor(poison.kind, identity, poison.recordedAtEpochMillis)
                .putString(KEY_READER_NAME, info.readerName)
                .putString(KEY_REASON, info.reason)
                .putBoolean(
                        KEY_OPERATION_MAY_HAVE_SUCCEEDED,
                        info.operationMayHaveSucceeded,
                )
                .commit()
    }

    override fun clear(): Boolean = preferences.edit().clear().commit()

    private fun baseEditor(
            kind: PersistedOmapiSafetyKind,
            bootIdentity: OmapiBootIdentity,
            recordedAtEpochMillis: Long,
    ) =
            preferences.edit()
                    .putInt(KEY_SCHEMA_VERSION, SCHEMA_VERSION)
                    .putBoolean(KEY_PRESENT, true)
                    .putString(KEY_KIND, kind.name)
                    .putLong(KEY_RECORDED_AT, recordedAtEpochMillis)
                    .apply {
                        if (bootIdentity.bootCount != null) {
                            putLong(KEY_BOOT_COUNT, bootIdentity.bootCount)
                        } else {
                            remove(KEY_BOOT_COUNT)
                        }
                        if (bootIdentity.kernelBootId != null) {
                            putString(KEY_KERNEL_BOOT_ID, bootIdentity.kernelBootId)
                        } else {
                            remove(KEY_KERNEL_BOOT_ID)
                        }
                    }

    private fun loadPoisonInfo(): OmapiPoisonInfo? {
        val reason = preferences.getString(KEY_REASON, null)?.takeIf { it.isNotBlank() } ?: return null
        return OmapiPoisonInfo(
                readerName = preferences.getString(KEY_READER_NAME, null),
                reason = reason,
                operationMayHaveSucceeded =
                        preferences.getBoolean(KEY_OPERATION_MAY_HAVE_SUCCEEDED, false),
                persistenceConfirmed = true,
        )
    }

    private fun loadLegacyPoison(): PersistedOmapiSafetyState {
        val bootCount =
                if (preferences.contains(KEY_BOOT_COUNT)) {
                    preferences.getLong(KEY_BOOT_COUNT, 0L)
                } else {
                    null
                }
        val kernelBootId = preferences.getString(KEY_KERNEL_BOOT_ID, null)
        val identity = OmapiBootIdentity(bootCount, kernelBootId).takeIf { it.isUsable }
        val info =
                loadPoisonInfo()
                        ?: return unreadablePersistedState(
                                "Legacy persisted OMAPI poison state is incomplete"
                        )
        return PersistedOmapiSafetyState(
                kind = PersistedOmapiSafetyKind.POISONED,
                info = info,
                bootIdentity = identity,
                recordedAtEpochMillis = preferences.getLong(KEY_RECORDED_AT, 0L),
        )
    }

    private fun unreadablePersistedState(reason: String): PersistedOmapiSafetyState =
            PersistedOmapiSafetyState(
                    kind = PersistedOmapiSafetyKind.POISONED,
                    info =
                            OmapiPoisonInfo(
                                    readerName = null,
                                    reason = reason,
                                    operationMayHaveSucceeded = true,
                                    persistenceConfirmed = true,
                            ),
                    bootIdentity = null,
                    recordedAtEpochMillis = preferences.getLong(KEY_RECORDED_AT, 0L),
            )

    private companion object {
        private const val PREFERENCES_NAME = "omapi_reboot_required"
        private const val LEGACY_POISON_SCHEMA_VERSION = 1
        private const val SCHEMA_VERSION = 2
        private const val KEY_SCHEMA_VERSION = "schema_version"
        private const val KEY_PRESENT = "present"
        private const val KEY_KIND = "kind"
        private const val KEY_READER_NAME = "reader_name"
        private const val KEY_REASON = "reason"
        private const val KEY_OPERATION_MAY_HAVE_SUCCEEDED = "operation_may_have_succeeded"
        private const val KEY_BOOT_COUNT = "boot_count"
        private const val KEY_KERNEL_BOOT_ID = "kernel_boot_id"
        private const val KEY_RECORDED_AT = "recorded_at_epoch_millis"
    }
}
