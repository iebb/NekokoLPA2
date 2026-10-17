package ee.nekoko.nlpa2

import android.util.Log
import android.os.IBinder
import android.os.Parcel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicLongArray
import kotlin.system.exitProcess

/**
 * The privileged half of the QRTR reader: the socket on the modem's bus.
 *
 * Shizuku starts this class in a process of its own under the `shell` user,
 * which is the only user allowed to open such a socket; the app may not open
 * one and may not use one this process opened either. So the socket stays
 * here, and the app asks for what a transport needs from it — where it is
 * addressed, one datagram out, one datagram in — and drives the modem from the
 * answers.
 *
 * The SE HAL reader is served from here too, for the same reason: only `shell`
 * may call the Secure Element HAL. Its methods start with `hal`. A channel this
 * service opened is closed, only while the SIM is unchanged, when the app
 * disconnects or after a few idle seconds outside an approved download; the
 * reader stays connected and the next APDU opens ISD-R again. A channel it
 * borrowed is never closed from here.
 *
 * The Shizuku server instantiates this class reflectively, so it has to stay
 * public and keep a constructor without arguments.
 */
class QrtrUserService : IQrtrService.Stub() {
    /** Descriptors handed out, so stopping the service can close them. */
    private val sockets = mutableSetOf<Int>()

    /** Reserved by the Shizuku server, which calls it to stop the service. */
    override fun destroy() {
        Log.i(TAG, "destroy")

        synchronized(sockets) {
            sockets.forEach { nativeCloseBus(it) }
            sockets.clear()
        }

        synchronized(this) {
            // Shutdown may follow a failed Dart teardown or app death. We cannot
            // prove these numbers are still ours; only explicit live disconnect
            // may close them. Abandon without a deferred close or card I/O.
            invalidation.invalidate(0)
            abandonInvalidatedSessions()
            clearDownload()
        }
        exitProcess(0)
    }

    override fun prepare(libraryDir: String, apkPath: String, abi: String) {
        if (loaded) return

        load(libraryDir, apkPath, abi)
        loaded = true
    }

    override fun openBus(): Int {
        val fd = nativeOpenBus()

        synchronized(sockets) { sockets.add(fd) }

        return fd
    }

    override fun busNode(fd: Int): Int = nativeBusNode(fd)

    override fun send(fd: Int, node: Int, port: Int, data: ByteArray) {
        nativeSend(fd, node, port, data)
    }

    override fun receive(fd: Int, timeoutMs: Int): ByteArray? = nativeReceive(fd, timeoutMs)

    override fun closeBus(fd: Int) {
        synchronized(sockets) { sockets.remove(fd) }
        nativeCloseBus(fd)
    }

    /**
     * Load the library the native calls live in.
     *
     * The build usually ships compressed in the package, so the loader is given
     * the entry inside it; if that is not where it is, it is taken out of the
     * package and loaded from somewhere this process certainly may read.
     */
    private fun load(libraryDir: String, apkPath: String, abi: String) {
        val entry = "lib/$abi/$LIBRARY"
        val candidates = listOf("$libraryDir/$LIBRARY", "$apkPath!/$entry")

        for (path in candidates) {
            try {
                System.load(path)
                Log.i(TAG, "loaded $path")
                return
            } catch (e: Throwable) {
                Log.w(TAG, "could not load $path", e)
            }
        }

        // Nothing else is tried on purpose: this process may run as `shell`,
        // and a library taken out of the package into a directory other
        // processes can write would be a way to have this privilege run
        // somebody else's code.
        throw IllegalStateException("the modem library is not where the package says it is: ${candidates.joinToString()}")
    }

    // Owned mode selects ISD-R for the reader connection, but an idle channel is
    // closed while its number is still unambiguous (parked) and selected again
    // on the next APDU. A SIM broadcast that was not a reset then has no open
    // number to strand. Legacy mode borrows channel 1: never SELECT, close or
    // reset that channel.
    private val borrowedSlots = mutableSetOf<Int>()
    private val ownedChannels = mutableMapOf<Int, Pair<IBinder, Int>>()
    private val parkedSlots = mutableSetOf<Int>()
    private var halSlot = 1
    private val invalidation = HalSessionInvalidation()
    private val idleTimer = Executors.newSingleThreadScheduledExecutor { Thread(it, "hal-idle").apply { isDaemon = true } }
    private var idleClose: ScheduledFuture<*>? = null
    private var lastUse = 0L

    // Do not wait for a long-running download to release the service lock.
    override fun halInvalidateSessions(slot: Int) { invalidation.invalidate(slot) }

    private fun abandonInvalidatedSessions() {
        for (slot in 1..2) {
            if (invalidation.apply(slot, ownedChannels, borrowedSlots, parkedSlots) && slot == halSlot) clearDownload()
        }
    }

    private fun touch() {
        lastUse = System.nanoTime()
        idleClose?.cancel(false)
        idleClose = idleTimer.schedule({ parkIdleChannels() }, IDLE_CLOSE_MS, TimeUnit.MILLISECONDS)
    }

    @Synchronized
    private fun parkIdleChannels() {
        // A stale timer may get the lock right after a new operation.
        if (System.nanoTime() - lastUse < TimeUnit.MILLISECONDS.toNanos(IDLE_CLOSE_MS)) return
        abandonInvalidatedSessions()
        if (downloadEid != null) return // An approved download keeps its ISD-R session.
        for (slot in ownedChannels.keys.toList()) {
            val seen = invalidation.observed(slot)
            try { releaseOwned(slot) } catch (e: Throwable) {
                Log.w(TAG, "SIM$slot idle close failed; ownership abandoned without retry", e)
            }
            // A reset seen during the close ends the session instead of parking it.
            if (invalidation.observed(slot) == seen) parkedSlots.add(slot)
        }
    }

    private fun selectHalSlot(slot: Int) {
        require(slot in 1..2) { "Invalid SIM slot" }
        abandonInvalidatedSessions()
        check(downloadEid == null || slot == halSlot) { "Another SIM slot has an active download session" }
        halSlot = slot
    }

    private fun hal(): IBinder {
        val manager = Class.forName("android.os.ServiceManager")
        return manager.getMethod("getService", String::class.java)
            .invoke(null, "android.hardware.secure_element.ISecureElement/SIM$halSlot") as? IBinder
            ?: throw IllegalStateException("SIM$halSlot HAL is unavailable")
    }

    @Synchronized
    override fun halUseBorrowed(slot: Int) {
        selectHalSlot(slot)
        check(slot !in ownedChannels && slot !in parkedSlots) { "Disconnect owned channel first" }
        borrowedSlots.add(slot)
    }

    @Synchronized
    override fun halOpenOwned(slot: Int) {
        selectHalSlot(slot)
        check(slot !in ownedChannels && slot !in parkedSlots && slot !in borrowedSlots) { "Channel already connected; disconnect first" }
        openIsdR(slot)
        touch()
    }

    private fun openIsdR(slot: Int) {
        val binder = hal()
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.hardware.secure_element.ISecureElement")
            data.writeByteArray(byteArrayOf(0xA0.toByte(), 0, 0, 5, 0x59, 0x10, 0x10, -1, -1, -1, -1, 0x89.toByte(), 0, 0, 1, 0))
            data.writeByte(0)
            check(binder.transact(6, data, reply, 0)) { "SE HAL rejected channel open" }
            reply.readException()
            check(reply.readInt() == 1) { "Missing logical channel response" }
            val start = reply.dataPosition()
            val size = reply.readInt()
            check(size >= 12 && size <= reply.dataSize() - start) { "Invalid logical channel response" }
            val channel = reply.readByte().toInt() and 255
            check(channel in 1..19) { "Invalid owned channel number" }
            ownedChannels[slot] = binder to channel
            abandonInvalidatedSessions()
            check(!invalidation.hasChanged(slot) && slot in ownedChannels) { "SIM changed while opening channel; reconnect reader" }
            val selected = reply.createByteArray()
            check(selected != null && successful(selected)) { "ISD-R selection did not succeed" }
        } catch (e: Throwable) {
            // Only close an unambiguous number whose reset generation is current.
            if (slot in ownedChannels) try { halCloseOwned(slot) } catch (close: Throwable) { e.addSuppressed(close) }
            throw e
        } finally { data.recycle(); reply.recycle() }
    }

    @Synchronized
    override fun halCloseOwned(slot: Int) {
        selectHalSlot(slot)
        clearDownload()
        borrowedSlots.remove(slot) // No SELECT or close for legacy channels.
        parkedSlots.remove(slot) // Already closed while idle.
        releaseOwned(slot)
    }

    private fun releaseOwned(slot: Int) {
        // Consume ownership before close: a failed/lost reply does not prove
        // the old number still belongs to us after modem REFRESH.
        val (binder, channel) = ownedChannels.remove(slot) ?: return
        if (invalidation.hasChanged(slot)) { abandonInvalidatedSessions(); return }
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            data.writeInterfaceToken("android.hardware.secure_element.ISecureElement")
            data.writeByte(channel.toByte())
            if (invalidation.hasChanged(slot)) { abandonInvalidatedSessions(); return }
            check(binder.transact(1, data, reply, 0)) { "SE HAL rejected channel close" }
            reply.readException()
        } catch (e: RuntimeException) {
            // ServiceSpecificException is a hidden framework class.
            if (e.javaClass.name != "android.os.ServiceSpecificException" ||
                e.javaClass.getField("errorCode").getInt(e) != 1) throw e
            // FAILED is not proof of closure. Abandon this number, never
            // close it again, and let reconnect acquire a new ISD-R channel.
            Log.w(TAG, "SIM$slot channel $channel close unconfirmed; ownership abandoned without retry", e)
        } finally { data.recycle(); reply.recycle() }
    }

    @Synchronized
    override fun halAtr(slot: Int): ByteArray {
        selectHalSlot(slot)
        return halCall(2, null)
    }

    @Synchronized
    override fun halEndDownload(slot: Int) {
        selectHalSlot(slot)
        clearDownload()
        touch() // The download no longer holds the channel open.
    }

    @Synchronized
    override fun halRead(slot: Int, apdu: ByteArray): ByteArray {
        selectHalSlot(slot)
        require(isAllowedHalReadApdu(apdu)) {
            "SE HAL is read-only: profile changes and channel management are blocked"
        }
        return halCall(8, apdu)
    }

    private var downloadEid: ByteArray? = null
    private var downloadProfiles: Map<List<Byte>, Int>? = null
    private var stagedDownload: ByteArrayOutputStream? = null

    @Synchronized
    override fun halBeginDownload(slot: Int) {
        selectHalSlot(slot)
        clearDownload()
        val eid = downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, 6, 0xBF.toByte(), 0x3E, 3, 0x5C, 1, 0x5A))
        require(eid.size == 23 && eid.take(5) == listOf(0xBF.toByte(), 0x3E.toByte(), 0x12.toByte(), 0x5A.toByte(), 0x10.toByte()) && successful(eid)) { "ISD-R is no longer selected; no download started" }
        downloadProfiles = readProfileStates()
        downloadEid = eid.copyOf()
    }

    @Synchronized
    private fun clearDownload() { downloadEid = null; downloadProfiles = null; stagedDownload = null }

    @Synchronized
    override fun halStageDownload(slot: Int, chunk: ByteArray, first: Boolean) {
        selectHalSlot(slot)
        check(downloadEid != null) { "Download is not approved" }
        try {
            require(chunk.size in 1..(128 * 1024)) { "Invalid staging chunk size" }
            if (first) stagedDownload = ByteArrayOutputStream()
            val buffer = stagedDownload ?: error("No download package was started")
            require(buffer.size().toLong() + chunk.size <= 16 * 1024 * 1024) { "Download package too large" }
            buffer.write(chunk)
        } catch (e: Throwable) {
            clearDownload()
            throw e
        }
    }

    // Validate whole requests before sending any block. Only GSMA ES10b
    // challenge/authentication/download are admitted, never raw GP commands.
    // One Binder call owns all segments and GET RESPONSEs within this service;
    // this cannot exclude a separate modem client, hence the UI warning.
    @Synchronized
    override fun halDownload(slot: Int, payload: ByteArray, segmentLengths: IntArray): ByteArray {
        selectHalSlot(slot)
        val approved = downloadEid ?: error("Download is not approved; open preview again")
        try {
            val request = stagedDownload?.let {
                require(it.size().toLong() + payload.size <= 16 * 1024 * 1024) { "Download package too large" }
                it.toByteArray() + payload
            } ?: payload
            stagedDownload = null
            validateHalDownload(request, segmentLengths)
            val current = downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, 6, 0xBF.toByte(), 0x3E, 3, 0x5C, 1, 0x5A))
            check(current.contentEquals(approved)) { "Card or channel changed; download stopped without retry" }
            val tag = request[1].toInt() and 255
            val before = downloadProfiles ?: error("No approved profile snapshot")
            if (tag in listOf(0x21, 0x36)) check(readProfileStates() == before) { "Profiles changed during preview; no write sent" }
            var response = byteArrayOf()
            for (apdu in halDownloadBlocks(request, segmentLengths)) {
                response = downloadResponse(apdu)
                if (!successful(response)) {
                    clearDownload()
                    return response // Preserve the actual SW for the existing UI.
                }
            }
            if (tag == 0x36) {
                checkHalAddedProfile(before, readProfileStates())
                clearDownload() // Package approval is single-use.
            }
            return response
        } catch (e: Throwable) {
            clearDownload() // Never retry uncertain writes automatically.
            throw e
        }
    }

    private fun readProfileStates(): Map<List<Byte>, Int> = halProfileStates(downloadResponse(
        byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, 8, 0xBF.toByte(), 0x2D, 5, 0x5C, 3, 0x5A, 0x9F.toByte(), 0x70)))

    @Synchronized
    override fun halSwitchProfile(slot: Int, iccid: ByteArray, expectedEid: ByteArray, enable: Boolean): ByteArray {
        selectHalSlot(slot)
        clearDownload()
        val request = halSwitchRequest(iccid, expectedEid, enable)
        val eidCommand = byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, 6, 0xBF.toByte(), 0x3E, 3, 0x5C, 1, 0x5A)
        val eid = downloadResponse(eidCommand)
        check(eid.contentEquals(byteArrayOf(0xBF.toByte(), 0x3E, 0x12, 0x5A, 0x10) + expectedEid + byteArrayOf(0x90.toByte(), 0))) { "Card changed; no switch sent" }
        val before = readProfileStates()
        check(before[iccid.toList()] == if (enable) 0 else 1) { "Target profile is missing or not in the expected state; no switch sent" }
        check(downloadResponse(eidCommand).contentEquals(eid) && readProfileStates() == before) { "Card or profiles changed; no switch sent" }
        // EnableProfile atomically replaces the active profile. Do not disable
        // the old profile first. Card policy decides whether switching is allowed.
        // Let the modem handle REFRESH; never close/reset/fetch or retry.
        return halRefreshOperation(ownedChannels, slot, if (enable) 0xBF31 else 0xBF32) {
            downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, request.size.toByte()) + request)
        }
    }

    private fun readCheckedEid(expected: ByteArray): ByteArray {
        require(expected.size == 16 && expected.all { (it.toInt() and 15) <= 9 && ((it.toInt() and 255) ushr 4) <= 9 }) { "Invalid EID BCD" }
        val r = downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, 6, 0xBF.toByte(), 0x3E, 3, 0x5C, 1, 0x5A))
        check(r.contentEquals(byteArrayOf(0xBF.toByte(), 0x3E, 0x12, 0x5A, 0x10) + expected + byteArrayOf(0x90.toByte(), 0))) { "Card changed; no mutation sent" }
        return r
    }

    @Synchronized
    override fun halRenameProfile(slot: Int, iccid: ByteArray, expectedEid: ByteArray, nickname: ByteArray): ByteArray {
        selectHalSlot(slot)
        return mutateProfile(iccid, expectedEid, halRenameRequest(iccid, expectedEid, nickname), false)
    }

    @Synchronized
    override fun halDeleteProfile(slot: Int, iccid: ByteArray, expectedEid: ByteArray): ByteArray {
        selectHalSlot(slot)
        return mutateProfile(iccid, expectedEid, halDeleteRequest(iccid, expectedEid), true)
    }

    private fun mutateProfile(iccid: ByteArray, eid: ByteArray, request: ByteArray, delete: Boolean): ByteArray {
        clearDownload()
        readCheckedEid(eid)
        val before = readProfileStates()
        check(before.containsKey(iccid.toList()) && (!delete || before[iccid.toList()] == 0)) { "Target missing or enabled; no mutation sent" }
        readCheckedEid(eid)
        check(readProfileStates() == before) { "Profiles changed; no mutation sent" }
        var response = byteArrayOf()
        for (apdu in halDownloadBlocks(request, intArrayOf(request.size))) {
            response = downloadResponse(apdu)
            if (!successful(response)) return response
        }
        if (halResultOk(response, if (delete) 0xBF33 else 0xBF29)) {
            val expected = if (delete) before.filterKeys { it != iccid.toList() } else before
            check(readProfileStates() == expected) { "Mutation state not verified; do not retry" }
        }
        return response
    }

    @Synchronized
    override fun halRemoveNotification(slot: Int, sequence: Int, expectedEid: ByteArray, expectedResponse: ByteArray): ByteArray {
        selectHalSlot(slot)
        val remove = halNotificationRequest(0xBF30, sequence)
        require(expectedResponse.size in 7..(128 * 1024)) { "Invalid notification snapshot" }
        val root = halBerFields(expectedResponse).single()
        require(root.first == 0xBF2B) { "Invalid notification response root" }
        val list = halBerFields(root.second).single()
        require(list.first == 0xA0 && halBerFields(list.second).size == 1) { "Require one backed-up notification" }
        clearDownload()
        readCheckedEid(expectedEid)
        val before = readProfileStates()
        val retrieve = halNotificationRequest(0xBF2B, sequence)
        val current = downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, retrieve.size.toByte()) + retrieve)
        check(current.contentEquals(expectedResponse + byteArrayOf(0x90.toByte(), 0))) { "Notification changed or missing; no removal sent" }
        readCheckedEid(expectedEid)
        val response = downloadResponse(byteArrayOf(0x81.toByte(), 0xE2.toByte(), 0x91.toByte(), 0, remove.size.toByte()) + remove)
        check(readProfileStates() == before) { "Profile state changed during notification removal; do not retry" }
        return response
    }

    private fun successful(r: ByteArray) = r.size >= 2 && r[r.lastIndex - 1] == 0x90.toByte() && r.last() == 0.toByte()

    private fun downloadResponse(apdu: ByteArray): ByteArray {
        var command = apdu
        val all = ByteArrayOutputStream()
        repeat(2048) {
            val r = halCall(8, command)
            check(r.size >= 2) { "Short SE HAL reply; download stopped without retry" }
            all.write(r, 0, r.size - 2)
            val sw1 = r[r.lastIndex - 1].toInt() and 255
            val sw2 = r.last().toInt() and 255
            if (sw1 != 0x61) {
                all.write(sw1); all.write(sw2)
                return all.toByteArray()
            }
            check(all.size() <= 1024 * 1024) { "SE HAL response too large" }
            command = byteArrayOf(0x81.toByte(), 0xC0.toByte(), 0, 0, sw2.toByte())
        }
        error("Too many GET RESPONSEs; download stopped without retry")
    }

    private fun halCall(code: Int, apdu: ByteArray?): ByteArray {
        abandonInvalidatedSessions()
        val data = Parcel.obtain()
        val reply = Parcel.obtain()
        try {
            if (code == 8 && halSlot !in ownedChannels && parkedSlots.remove(halSlot)) openIsdR(halSlot)
            data.writeInterfaceToken("android.hardware.secure_element.ISecureElement")
            val owned = ownedChannels[halSlot]
            check(code != 8 || owned != null || halSlot in borrowedSlots) { "SE HAL channel session lost; reconnect reader (no APDU sent)" }
            if (apdu != null) data.writeByteArray(if (code == 8 && owned != null) halOwnedApdu(apdu, owned.second) else apdu)
            check(code != 8 || !invalidation.hasChanged(halSlot)) { "SIM changed; reconnect reader (no APDU sent)" }
            check((owned?.first ?: hal()).transact(code, data, reply, 0)) { "SE HAL rejected the request" }
            reply.readException()
            check(code != 8 || !invalidation.hasChanged(halSlot)) { "SIM changed during APDU; reply uncertain, do not retry" }
            return reply.createByteArray() ?: throw IllegalStateException("SE HAL returned no data")
        } catch (e: Throwable) {
            if (code == 8) {
                ownedChannels.remove(halSlot)
                borrowedSlots.remove(halSlot)
                clearDownload() // Lost/failed APDU replies cannot prove ownership.
            }
            throw e
        } finally {
            data.recycle()
            reply.recycle()
            touch()
        }
    }

    private external fun nativeOpenBus(): Int
    private external fun nativeBusNode(fd: Int): Int
    private external fun nativeSend(fd: Int, node: Int, port: Int, data: ByteArray): Int
    private external fun nativeReceive(fd: Int, timeoutMs: Int): ByteArray?
    private external fun nativeCloseBus(fd: Int)

    companion object {
        private const val TAG = "QrtrUserService"
        private const val IDLE_CLOSE_MS = 3000L
        private const val LIBRARY = "librust_lib_nlpa2.so"

        @Volatile
        private var loaded = false
    }
}

// Validate at the privileged boundary, not only in Dart/UI. Each E2 APDU
// must contain exactly one complete, short-form read-only ES10 request.
internal fun isAllowedHalReadApdu(a: ByteArray): Boolean {
    fun b(i: Int) = a[i].toInt() and 255
    if (a.size < 5) return false
    if (b(1) == 0xC0) return a.size == 5 && b(0) in listOf(0x01, 0x81) && b(2) == 0 && b(3) == 0
    if (a.size < 8 || b(0) != 0x81 || b(1) != 0xE2 || b(2) != 0x91 || b(3) != 0) return false
    val lc = b(4)
    if (a.size != 5 + lc && a.size != 6 + lc) return false
    if (b(5) != 0xBF || b(6) !in listOf(0x20, 0x22, 0x28, 0x2B, 0x2D, 0x3E)) return false
    return b(7) < 128 && lc == 3 + b(7)
}

// Notifications only update atomic generations. Map/session cleanup happens
// under the service's existing operation lock, before another card operation.
internal class HalSessionInvalidation {
    private val generations = AtomicLongArray(3)
    private val observed = LongArray(3)

    fun invalidate(slot: Int) {
        require(slot in 0..2) { "Invalid SIM slot" }
        if (slot == 0) for (s in 1..2) generations.incrementAndGet(s)
        else generations.incrementAndGet(slot)
    }

    fun hasChanged(slot: Int) = generations.get(slot) != observed[slot]

    /** Changes exactly when [apply] ends a session. */
    fun observed(slot: Int) = observed[slot]

    fun apply(
        slot: Int, owned: MutableMap<Int, *>, borrowed: MutableSet<Int>,
        parked: MutableSet<Int> = mutableSetOf()
    ): Boolean {
        val generation = generations.get(slot)
        if (generation == observed[slot]) return false
        owned.remove(slot)
        borrowed.remove(slot)
        parked.remove(slot)
        observed[slot] = generation
        return true
    }
}

// No arbitrary APDU entry point: only complete, definite-length ES10b TLVs.
// REFRESH can invalidate/reassign the number even when the reply is lost.
// Retain ownership only for a definite rejection without a pending REFRESH.
internal inline fun halRefreshOperation(
    ownedChannels: MutableMap<Int, *>, slot: Int, responseTag: Int,
    transmit: () -> ByteArray
): ByteArray {
    var rejected = false
    try {
        val response = try { transmit() } catch (e: Throwable) {
            // A later GET RESPONSE can fail after the switch was already sent.
            // Classify the whole operation as uncertain, not just the last APDU.
            throw IllegalStateException("SE HAL switch reply uncertain; do not retry", e)
        }
        rejected = runCatching {
            // halResultOk validates 9000 and the complete, single result TLV.
            // Match concrete errors in Enable/DisableProfileResponse; unknown
            // and undefinedError replies cannot establish channel ownership.
            !halResultOk(response, responseTag) &&
                (response[response.size - 3].toInt() and 255) in
                (if (responseTag == 0xBF31) listOf(1, 2, 3, 4, 5, 6, 7, 9, 10)
                 else if (responseTag == 0xBF32) listOf(1, 2, 3, 5, 6, 7, 9)
                 else emptyList())
        }.getOrDefault(false)
        val confirmed = runCatching { halResultOk(response, responseTag) }.getOrDefault(false)
        val proactive = response.size >= 2 && response[response.size - 2] == 0x91.toByte()
        if (!rejected && !confirmed && !proactive) {
            throw IllegalStateException("SE HAL switch reply uncertain; do not retry")
        }
        return response
    } finally {
        if (!rejected) ownedChannels.remove(slot)
    }
}

internal fun validateHalDownload(p: ByteArray, segments: IntArray) {
    require(p.size in 3..(16 * 1024 * 1024) && p[0] == 0xBF.toByte()) { "Invalid ES10b request" }
    val tag = p[1].toInt() and 255
    require(tag in listOf(0x2E, 0x38, 0x21, 0x36)) { "Only ES10b download commands are allowed" }
    var header = 3
    var size = p[2].toInt() and 255
    if (size >= 128) {
        val count = size and 127
        require(count in 1..3 && p.size >= 3 + count) { "Invalid BER length" }
        size = 0
        repeat(count) { size = (size shl 8) or (p[3 + it].toInt() and 255) }
        header += count
    }
    require(header + size == p.size && (if (tag == 0x2E) size == 0 else size > 0)) { "Incomplete or trailing ES10b data" }
    require(segments.isNotEmpty() && segments.size <= 65536 && segments.all { it > 0 } && segments.sumOf { it.toLong() } == p.size.toLong()) { "Invalid BPP segmentation" }
    require(tag == 0x36 || (segments.size == 1 && segments[0] == p.size)) { "Only BPP may have multiple segments" }
}

internal fun halDownloadBlocks(p: ByteArray, segments: IntArray): Sequence<ByteArray> = sequence {
    var offset = 0
    for (length in segments) {
        val end = offset + length
        var block = 0
        while (offset < end) {
            val n = minOf(120, end - offset)
            val last = offset + n == end
            yield(byteArrayOf(0x81.toByte(), 0xE2.toByte(), (if (last) 0x91 else 0x11).toByte(), (block++ and 255).toByte(), n.toByte()) + p.copyOfRange(offset, offset + n))
            offset += n
        }
    }
}

internal fun halSwitchRequest(iccid: ByteArray, eid: ByteArray, enable: Boolean): ByteArray {
    require(iccid.size == 10 && iccid[0] == 0x98.toByte()) { "Invalid ICCID" }
    require(iccid.withIndex().all { (i, b) ->
        val n = b.toInt() and 255
        (n and 15) <= 9 && ((n ushr 4) <= 9 || (i == 9 && (n ushr 4) == 15))
    }) { "Invalid ICCID BCD" }
    require(eid.size == 16 && eid.all { (it.toInt() and 15) <= 9 && ((it.toInt() and 255) ushr 4) <= 9 }) { "Invalid EID BCD" }
    return byteArrayOf(0xBF.toByte(), (if (enable) 0x31 else 0x32).toByte(), 0x11, 0xA0.toByte(), 0x0C, 0x5A, 0x0A) + iccid + byteArrayOf(0x81.toByte(), 1, 0xFF.toByte())
}

// Narrow BER parser for the minimum ProfileInfoList response. No indefinite
// lengths, trailing data, duplicate identities/fields, or unknown states.
// Optional fields a card returns beyond the tag list are ignored.
internal fun halProfileStates(response: ByteArray): Map<List<Byte>, Int> {
    require(response.size in 7..(1024 * 1024) && response.takeLast(2) == listOf(0x90.toByte(), 0.toByte())) { "Invalid profile-list status" }
    val root = halBerFields(response.copyOfRange(0, response.size - 2)).single()
    require(root.first == 0xBF2D) { "Wrong profile-list root" }
    val list = halBerFields(root.second).single()
    require(list.first == 0xA0) { "Profile list returned an error" }
    val profiles = linkedMapOf<List<Byte>, Int>()
    for ((tag, value) in halBerFields(list.second)) {
        require(tag == 0xE3) { "Wrong profile tag" }
        val items = halBerFields(value)
        require(items.count { it.first == 0x5A } == 1 && items.count { it.first == 0x9F70 } == 1) { "Missing or duplicate profile fields" }
        val iccid = items.single { it.first == 0x5A }.second
        halSwitchRequest(iccid, ByteArray(16), true) // Reuse BCD validation.
        val state = items.single { it.first == 0x9F70 }.second
        require(state.size == 1 && state[0].toInt() in 0..1) { "Unknown profile state" }
        require(profiles.put(iccid.toList(), state[0].toInt()) == null) { "Duplicate ICCID" }
    }
    require(profiles.values.count { it == 1 } <= 1) { "Multiple enabled ports are not supported" }
    return profiles
}

internal fun checkHalAddedProfile(before: Map<List<Byte>, Int>, after: Map<List<Byte>, Int>) {
    check(after.size == before.size + 1 && before.all { (iccid, state) -> after[iccid] == state } &&
        after.filterKeys { it !in before }.values.single() == 0) { "Installation state not verified or existing profiles changed; do not retry" }
}

internal fun halBerFields(data: ByteArray): List<Pair<Int, ByteArray>> {
    var offset = 0
    fun next(): Int { require(offset < data.size) { "Truncated profile TLV" }; return data[offset++].toInt() and 255 }
    val result = mutableListOf<Pair<Int, ByteArray>>()
    while (offset < data.size) {
        var tag = next()
        if ((tag and 31) == 31) { val second = next(); require((second and 128) == 0) { "Unsupported profile tag" }; tag = (tag shl 8) or second }
        var length = next()
        if (length >= 128) { val count = length and 127; require(count in 1..3) { "Invalid profile BER length" }; length = 0; repeat(count) { length = (length shl 8) or next() } }
        require(length <= data.size - offset) { "Truncated profile value" }
        result.add(tag to data.copyOfRange(offset, offset + length)); offset += length
    }
    return result
}

internal fun halTlv(tag: Int, value: ByteArray): ByteArray {
    require(value.size <= 65535)
    val t = if (tag <= 255) byteArrayOf(tag.toByte()) else byteArrayOf((tag ushr 8).toByte(), tag.toByte())
    val length = if (value.size < 128) byteArrayOf(value.size.toByte()) else if (value.size < 256) byteArrayOf(0x81.toByte(), value.size.toByte()) else byteArrayOf(0x82.toByte(), (value.size ushr 8).toByte(), value.size.toByte())
    return t + length + value
}
internal fun halDeleteRequest(iccid: ByteArray, eid: ByteArray): ByteArray {
    halSwitchRequest(iccid, eid, true)
    return halTlv(0xBF33, halTlv(0x5A, iccid))
}
internal fun halRenameRequest(iccid: ByteArray, eid: ByteArray, nickname: ByteArray): ByteArray {
    halSwitchRequest(iccid, eid, true)
    require(nickname.size <= 256) { "Nickname too long" }
    val name = nickname.toString(Charsets.UTF_8)
    require(name.toByteArray(Charsets.UTF_8).contentEquals(nickname) && name.codePointCount(0, name.length) <= 64 && !name.contains('\u0000')) { "Invalid UTF-8 nickname or more than 64 characters" }
    return halTlv(0xBF29, halTlv(0x5A, iccid) + halTlv(0x90, nickname))
}
internal fun halNotificationRequest(tag: Int, sequence: Int): ByteArray {
    require(tag in listOf(0xBF2B, 0xBF30) && sequence >= 0) { "Invalid notification operation or sequence" }
    val value = halTlv(0x80, java.math.BigInteger.valueOf(sequence.toLong()).toByteArray())
    return halTlv(tag, if (tag == 0xBF2B) halTlv(0xA0, value) else value)
}
internal fun halResultOk(response: ByteArray, tag: Int): Boolean {
    require(response.size >= 2 && response.takeLast(2) == listOf(0x90.toByte(), 0.toByte())) { "Invalid mutation status" }
    val root = halBerFields(response.copyOfRange(0, response.size - 2)).single()
    require(root.first == tag) { "Wrong mutation response" }
    val result = halBerFields(root.second).single()
    require(result.first == 0x80 && result.second.size == 1) { "Missing mutation result" }
    return result.second[0].toInt() == 0
}

// Dart and request validators keep virtual channel 1. Only the privileged
// transport maps it to the channel returned by its own successful open.
internal fun halOwnedApdu(apdu: ByteArray, channel: Int): ByteArray {
    require(channel in 1..19 && apdu.size >= 5) { "Invalid owned-channel APDU" }
    val cla = apdu[0].toInt() and 255
    require(cla == 0x81 || cla == 0x01) { "Expected virtual channel 1" }
    val proprietary = cla and 0x80
    val mapped = proprietary or if (channel < 4) channel else (0x40 or (channel - 4))
    return apdu.copyOf().also { it[0] = mapped.toByte() }
}
