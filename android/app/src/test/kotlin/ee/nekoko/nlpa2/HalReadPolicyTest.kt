package ee.nekoko.nlpa2
import org.junit.Assert.*
import org.junit.Test
class HalReadPolicyTest {
    private fun hex(s: String) = s.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    @Test fun unchangedSessionStillAllowsNormalOwnedCleanup() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2, 2 to 3)
        val borrowed = mutableSetOf<Int>()
        assertFalse(invalidation.hasChanged(1))
        assertFalse(invalidation.apply(1, owned, borrowed))
        assertEquals(2, owned.remove(1)) // Normal halCloseOwned gate.
        assertEquals(3, owned[2])
    }

    @Test fun externalResetAbandonsReassignedNumberWithoutClosingOtherClient() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2, 2 to 3)
        val borrowed = mutableSetOf<Int>()
        val modem = mutableMapOf(2 to "another-client", 3 to "other-slot")
        invalidation.invalidate(1)
        assertTrue(invalidation.hasChanged(1))
        assertFalse(invalidation.hasChanged(2))
        assertTrue(invalidation.apply(1, owned, borrowed))
        owned.remove(1)?.let { modem.remove(it) } // No stale close possible.
        assertEquals("another-client", modem[2])
        assertEquals(3, owned[2])
        assertFalse(invalidation.apply(2, owned, borrowed))
        assertFalse(invalidation.apply(1, owned, borrowed))
    }

    @Test fun unknownSlotResetAbandonsOwnedAndBorrowedSessionsAndDownload() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2)
        val borrowed = mutableSetOf(2)
        var downloadApproved = true
        invalidation.invalidate(0)
        for (slot in 1..2) {
            // This is the cleanup gate in abandonInvalidatedSessions.
            if (invalidation.apply(slot, owned, borrowed) && slot == 2) downloadApproved = false
        }
        assertTrue(owned.isEmpty())
        assertTrue(borrowed.isEmpty())
        assertFalse(downloadApproved)
    }

    @Test fun repeatedResetNotificationsDoNotInvalidateFreshlyReconnectedChannel() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2)
        val borrowed = mutableSetOf<Int>()
        repeat(3) { invalidation.invalidate(1) }
        assertTrue(invalidation.apply(1, owned, borrowed))
        owned[1] = 4 // Newly opened after the reset was acknowledged.
        assertFalse(invalidation.apply(1, owned, borrowed))
        assertFalse(invalidation.hasChanged(1))
        assertEquals(4, owned[1])
        invalidation.invalidate(1)
        assertTrue(invalidation.apply(1, owned, borrowed))
        assertFalse(owned.containsKey(1))
    }

    @Test fun resetEndsParkedSessionSoItIsNotReopenedOnTheNewCard() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf<Int, Int>()
        val borrowed = mutableSetOf<Int>()
        val parked = mutableSetOf(1, 2) // Closed while idle; no number held.
        invalidation.invalidate(1)
        assertTrue(invalidation.apply(1, owned, borrowed, parked))
        assertFalse(invalidation.apply(2, owned, borrowed, parked))
        assertEquals(setOf(2), parked)
    }

    @Test fun observedGenerationMovesOnlyWhenASessionIsEnded() {
        // parkIdleChannels parks a slot only if no reset ended it during close.
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2)
        val borrowed = mutableSetOf<Int>()
        val seen = invalidation.observed(1)
        assertFalse(invalidation.apply(1, owned, borrowed))
        assertEquals(seen, invalidation.observed(1))
        invalidation.invalidate(0)
        assertEquals(seen, invalidation.observed(1)) // Not yet applied.
        assertTrue(invalidation.apply(1, owned, borrowed))
        assertNotEquals(seen, invalidation.observed(1))
    }

    @Test fun resetWhileOpenIsInFlightAbandonsReturnedChannelBeforeCleanup() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf<Int, Int>()
        val borrowed = mutableSetOf<Int>()
        assertFalse(invalidation.apply(1, owned, borrowed)) // Before open.
        invalidation.invalidate(1) // Modem resets before the open reply arrives.
        owned[1] = 2 // The reply does not prove this number still belongs to us.
        assertTrue(invalidation.apply(1, owned, borrowed))
        assertNull(owned.remove(1)) // The failed-open cleanup must not close it.
    }

    @Test fun invalidationDoesNotWaitForTheCardOperationLock() {
        val invalidation = HalSessionInvalidation()
        val operationLock = Any()
        synchronized(operationLock) {
            val notification = Thread { invalidation.invalidate(1) }.apply { isDaemon = true }
            notification.start()
            notification.join(2000)
            assertFalse("Notification must not block behind a download", notification.isAlive)
            assertTrue(invalidation.hasChanged(1)) // Stop before the next APDU.
        }
    }

    @Test fun externalResetOverridesEvenAConfirmedSwitchRejection() {
        val invalidation = HalSessionInvalidation()
        val owned = mutableMapOf(1 to 2)
        val borrowed = mutableSetOf<Int>()
        halRefreshOperation(owned, 1, 0xBF31) {
            invalidation.invalidate(1)
            hex("BF31038001039000")
        }
        // A rejection alone retains ownership, but an external reset supersedes it.
        assertTrue(invalidation.apply(1, owned, borrowed))
        assertTrue(owned.isEmpty())
    }

    @Test fun invalidResetSlotCannotInvalidateAnySession() {
        val invalidation = HalSessionInvalidation()
        for (slot in listOf(-1, 3)) {
            try { invalidation.invalidate(slot); fail("Invalid slot admitted") }
            catch (_: IllegalArgumentException) {}
        }
        assertFalse(invalidation.hasChanged(1))
        assertFalse(invalidation.hasChanged(2))
    }

    @Test fun refreshAbandonsOwnershipBeforeCleanupEvenIfNumberWasReassigned() {
        for (response in listOf(hex("BF31038001009000"), hex("9101"))) {
            val owned = mutableMapOf(1 to 2, 2 to 3)
            val modem = mutableMapOf(2 to "us", 3 to "other-slot")
            val result = halRefreshOperation(owned, 1, 0xBF31) {
                assertEquals(2, owned[1]) // Needed while transmitting.
                modem[2] = "another-client" // REFRESH reassigns the number.
                response
            }
            assertArrayEquals(response, result)
            assertFalse(owned.containsKey(1))
            assertEquals(3, owned[2])
            // This is the ownership-removal gate used by halCloseOwned.
            owned.remove(1)?.let { modem.remove(it) }
            assertEquals("another-client", modem[2])
            owned[1] = 4 // A fresh channel can now be acquired.
            assertEquals(4, owned[1])
        }
    }

    @Test fun lostSwitchReplyAlsoAbandonsOwnershipWithoutRetry() {
        val owned = mutableMapOf(1 to 2)
        val failure = IllegalStateException("Lost switch reply")
        var requests = 0
        try {
            halRefreshOperation(owned, 1, 0xBF31) { requests++; throw failure }
            fail("Expected failure")
        } catch (e: IllegalStateException) {
            assertSame(failure, e.cause)
            assertTrue(e.message!!.contains("reply uncertain"))
        }
        assertEquals(1, requests)
        assertTrue(owned.isEmpty())
    }

    @Test fun getResponseSessionLossIsUncertainForTheWholeSwitch() {
        val owned = mutableMapOf(1 to 2)
        var writes = 0
        var reads = 0
        val failure = IllegalStateException("SE HAL channel session lost; reconnect reader (no APDU sent)")
        try {
            halRefreshOperation(owned, 1, 0xBF31) {
                writes++ // The switch produced 61xx before SIM invalidation.
                reads++ // GET RESPONSE cannot use the invalidated session.
                throw failure
            }
            fail("Expected uncertain switch")
        } catch (e: IllegalStateException) {
            assertTrue(e.message!!.contains("reply uncertain"))
            assertSame(failure, e.cause)
        }
        assertEquals(1, writes)
        assertEquals(1, reads)
        assertTrue(owned.isEmpty())
    }

    @Test fun confirmedSwitchRejectionsRetainOwnershipUntilNormalClose() {
        for ((tag, codes) in listOf(
            0xBF31 to listOf(1, 2, 3, 4, 5, 6, 7, 9, 10),
            0xBF32 to listOf(1, 2, 3, 5, 6, 7, 9)
        )) for (code in codes) {
            val owned = mutableMapOf(1 to 2, 2 to 3)
            val response = halTlv(tag, halTlv(0x80, byteArrayOf(code.toByte()))) + hex("9000")
            var requests = 0
            repeat(3) {
                assertArrayEquals(response, halRefreshOperation(owned, 1, tag) { requests++; response })
                assertEquals(2, owned[1])
                assertEquals(3, owned[2])
            }
            assertEquals(3, requests)
            // The normal halCloseOwned removal gate can still close this channel.
            assertEquals(2, owned.remove(1))
            assertEquals(3, owned[2])
        }
    }

    @Test fun successfulRefreshAndUncertainSwitchRepliesAbandonOwnership() {
        for (tag in listOf(0xBF31, 0xBF32)) for (response in listOf(
            halTlv(tag, halTlv(0x80, hex("00"))) + hex("9000"),
            halTlv(tag, halTlv(0x80, hex("03"))) + hex("9101"),
            halTlv(tag, halTlv(0x80, hex("7F"))) + hex("9000"),
            halTlv(tag, halTlv(0x80, hex("FF"))) + hex("9000"),
            halTlv(tag, halTlv(0x80, hex("08"))) + hex("9000"),
            hex("BF32038001049000"),
            hex("BF320380010A9000"),
            hex(""), hex("90"), hex("9000"), hex("6400"), hex("6985"),
            hex("BF31038001039000BF3103800103"),
            hex("BF3104800200039000"), hex("BF31038001039000") + hex("00"),
            halTlv(if (tag == 0xBF31) 0xBF32 else 0xBF31, halTlv(0x80, hex("03"))) + hex("9000"),
            halTlv(tag, halTlv(0x80, hex("03")) + halTlv(0x80, hex("03"))) + hex("9000")
        )) {
            val owned = mutableMapOf(1 to 2, 2 to 3)
            var requests = 0
            val certain = runCatching { halResultOk(response, tag) }.getOrDefault(false) ||
                (response.size >= 2 && response[response.size - 2] == 0x91.toByte())
            try {
                val result = halRefreshOperation(owned, 1, tag) { requests++; response }
                assertTrue("Uncertain response must not escape classification", certain)
                assertArrayEquals(response, result)
            } catch (e: IllegalStateException) {
                assertFalse(certain)
                assertTrue(e.message!!.contains("reply uncertain"))
            }
            assertFalse(owned.containsKey(1))
            assertEquals(3, owned[2])
            assertEquals(1, requests)
        }
    }

    @Test fun mapsOwnedChannelWithoutChangingRequestBody() {
        for (channel in 1..19) for (cla in listOf(0x01, 0x81)) {
            val apdu = hex("81E2910006BF3E035C015A").also { it[0] = cla.toByte() }
            val mapped = halOwnedApdu(apdu, channel)
            val expected = (cla and 0x80) or if (channel < 4) channel else (0x40 or (channel - 4))
            assertEquals(expected, mapped[0].toInt() and 255)
            assertArrayEquals(apdu.copyOfRange(1, apdu.size), mapped.copyOfRange(1, mapped.size))
            assertEquals(cla, apdu[0].toInt() and 255)
        }
    }
    @Test fun rejectsInvalidOwnedChannelMapping() {
        for (channel in listOf(0, 20, -1)) {
            try { halOwnedApdu(hex("81C0000000"), channel); fail("channel=$channel") } catch (_: IllegalArgumentException) {}
        }
        for (apdu in listOf("", "81E2", "80E2910003BF2D00", "82C0000000")) {
            try { halOwnedApdu(hex(apdu), 2); fail(apdu) } catch (_: IllegalArgumentException) {}
        }
    }
    @Test fun allowsReads() {
        for (s in listOf("81E2910006BF3E035C015A", "81E2910003BF2D00", "81E2910003BF2000", "81E2910003BF2200", "01C0000000", "81C0000000"))
            assertTrue(s, isAllowedHalReadApdu(hex(s)))
    }
    @Test fun rejectsWritesAndChannelManagement() {
        for (s in listOf("81E2910003BF3100", "81E2910003BF3200", "81E2910003BF3300", "81E2910003BF3600", "81E2910003BF2C00", "0070800100", "01A4040000", "80E2910003BF2D00", "81E2110003BF2D00", "81E2910103BF2D00", "81E2910006BF2D00BF3100", "81E2910003BF2D80", "", "81E2"))
            assertFalse(s, isAllowedHalReadApdu(hex(s)))
    }
    @Test fun validatesWholeDownloadRequestsBeforeAnyTransmission() {
        for (s in listOf("BF2E00", "BF3803800100", "BF2103800100", "BF3603BF2300")) {
            val p = hex(s); validateHalDownload(p, intArrayOf(p.size))
        }
        val bpp = hex("BF3603BF2300")
        validateHalDownload(bpp, intArrayOf(3, 3))
    }
    @Test fun rejectsDestructiveCommandsAndMalformedDownloads() {
        for (s in listOf("BF3100", "BF3200", "BF3300", "BF2C00", "BF4100", "80E60000", "BF2E00BF3300", "BF3680", "BF368401000000", "BF368203", "BF3800", "BF2E0100", "BF3603BF23", "")) {
            val p = hex(s)
            try { validateHalDownload(p, intArrayOf(p.size)); fail(s) } catch (_: IllegalArgumentException) {}
        }
        for (segments in listOf(intArrayOf(), intArrayOf(0, 6), intArrayOf(5), intArrayOf(-1, 7), intArrayOf(Int.MAX_VALUE, Int.MAX_VALUE))) {
            try { validateHalDownload(hex("BF3603BF2300"), segments); fail(segments.contentToString()) } catch (_: IllegalArgumentException) {}
        }
        try { validateHalDownload(hex("BF3803800100"), intArrayOf(3, 3)); fail("authentication must not be segmented like a BPP") } catch (_: IllegalArgumentException) {}
    }
    @Test fun downloadBlocksUseOnlyChannelOneStoreDataAndResetSequencePerSegment() {
        val payload = ByteArray(30725) { (it and 255).toByte() }
        val blocks = halDownloadBlocks(payload, intArrayOf(30721, 4)).toList()
        assertEquals(258, blocks.size)
        assertEquals(0x11, blocks.first()[2].toInt() and 255)
        assertEquals(0x91, blocks[256][2].toInt() and 255)
        assertEquals(0, blocks[256][3].toInt() and 255) // sequence wraps at 256
        assertEquals(0x91, blocks.last()[2].toInt() and 255)
        assertEquals(0, blocks.last()[3].toInt() and 255) // new segment
        for (b in blocks) {
            assertEquals(0x81, b[0].toInt() and 255)
            assertEquals(0xE2, b[1].toInt() and 255)
            assertEquals(b.size - 5, b[4].toInt() and 255)
            assertTrue(b.size <= 125)
        }
        assertArrayEquals(payload, blocks.flatMap { it.drop(5) }.toByteArray())
    }

    @Test fun switchBuildsOnlyEnableOrDisableWithRefreshAndValidIdentity() {
        val iccid = hex("980000000000000000F0")
        val eid = hex("89049032000000000000000000000000")
        assertArrayEquals(hex("BF3111A00C5A0A980000000000000000F08101FF"), halSwitchRequest(iccid, eid, true))
        assertArrayEquals(hex("BF3211A00C5A0A980000000000000000F08101FF"), halSwitchRequest(iccid, eid, false))
        assertEquals(mapOf(iccid.toList() to 0), halProfileStates(hex("BF2D14A012E3105A0A980000000000000000F09F7001009000")))
        for (bad in listOf(byteArrayOf(), hex("980000000000000000AF"), hex("9800000000000000F000"), hex("00000000000000000000"))) {
            try { halSwitchRequest(bad, eid, true); fail("Invalid ICCID admitted") } catch (_: IllegalArgumentException) {}
        }
        for (bad in listOf(byteArrayOf(), ByteArray(16) { 0xFA.toByte() })) {
            try { halSwitchRequest(iccid, bad, true); fail("Invalid EID admitted") } catch (_: IllegalArgumentException) {}
        }
        val enable = halSwitchRequest(iccid, eid, true)
        try { validateHalDownload(enable, intArrayOf(enable.size)); fail("Enable admitted as download") } catch (_: IllegalArgumentException) {}
        assertFalse(isAllowedHalReadApdu(hex("81E2910014") + enable))
    }
    private fun tlv(tag: String, value: ByteArray, longLength: Boolean = false): ByteArray =
        hex(tag) + (if (longLength || value.size >= 128) byteArrayOf(0x81.toByte(), value.size.toByte()) else byteArrayOf(value.size.toByte())) + value
    private fun profile(id: String, state: Int, reversed: Boolean = false): ByteArray {
        val i = tlv("5A", hex(id)); val st = tlv("9F70", byteArrayOf(state.toByte()))
        return tlv("E3", if (reversed) st + i else i + st)
    }
    private fun list(vararg entries: ByteArray): ByteArray =
        tlv("BF2D", tlv("A0", entries.fold(byteArrayOf()) { a, b -> a + b })) + hex("9000")
    @Test fun readsMultipleProfilesIncludingLongLengthsAndFieldReordering() {
        assertTrue(halProfileStates(hex("BF2D02A0009000")).isEmpty())
        val entries = (0..9).map { profile("980000000000000000" + "%02X".format(it), if (it == 0) 1 else 0, it % 2 == 0) }.toTypedArray()
        val states = halProfileStates(list(*entries))
        assertEquals(10, states.size); assertEquals(1, states.values.count { it == 1 })
        assertEquals(states, halProfileStates(tlv("BF2D", tlv("A0", entries.fold(byteArrayOf()) { a, b -> a + b }, true), true) + hex("9000")))
    }
    @Test fun ignoresOptionalProfileFieldsBeyondTheTagList() {
        val id = "980000000000000000F0"
        val extra = tlv("E3", tlv("90", "nick".toByteArray()) + tlv("5A", hex(id)) + tlv("91", "sp".toByteArray()) + tlv("9F70", byteArrayOf(1)) + tlv("95", byteArrayOf(2)))
        assertEquals(mapOf(hex(id).toList() to 1), halProfileStates(list(extra)))
        val missingState = tlv("E3", tlv("5A", hex(id)) + tlv("90", "nick".toByteArray()))
        try { halProfileStates(list(missingState)); fail("Profile without state admitted") } catch (_: IllegalArgumentException) {}
    }
    @Test fun rejectsMalformedOrAmbiguousProfileLists() {
        val id = "980000000000000000F0"; val p = profile(id, 0)
        val invalid = listOf(
            hex("BF2D02A0006A82"), hex("BF2D80A0009000"), hex("BF2D02A000009000"), hex("BF2D038101009000"),
            list(p, p), list(profile(id, 2)), list(profile(id, 1), profile("980000000000000000F1", 1)),
            list(tlv("E3", tlv("5A", hex(id)))),
            list(tlv("E3", tlv("5A", hex(id)) + tlv("5A", hex(id)) + hex("9F700100"))),
            list(tlv("E3", tlv("5A", hex("980000000000000000FA")) + hex("9F700100")))
        )
        for (r in invalid) { try { halProfileStates(r); fail("Malformed profile list admitted") } catch (_: IllegalArgumentException) {} catch (_: NoSuchElementException) {} }
    }
    @Test fun addedProfileMustPreserveAllExistingIdentitiesAndStates() {
        val a = hex("980000000000000000F0").toList(); val b = hex("980000000000000000F1").toList()
        checkHalAddedProfile(mapOf(a to 1), mapOf(a to 1, b to 0))
        checkHalAddedProfile(emptyMap(), mapOf(a to 0))
        for (after in listOf(mapOf(a to 1), mapOf(b to 0), mapOf(a to 0, b to 0), mapOf(a to 1, b to 1))) {
            try { checkHalAddedProfile(mapOf(a to 1), after); fail("Existing profile changed or missing installation") } catch (_: IllegalStateException) {}
        }
    }

    @Test fun managementBuildersAreBoundedAndCannotEnterRawOrDownloadPaths() {
        val id = hex("980000000000000000F0"); val eid = hex("89049032000000000000000000000000")
        assertArrayEquals(hex("BF330C5A0A980000000000000000F0"), halDeleteRequest(id, eid))
        assertArrayEquals(hex("BF29115A0A980000000000000000F09003616263"), halRenameRequest(id, eid, "abc".toByteArray()))
        val japanese = "日本語".toByteArray(Charsets.UTF_8)
        assertArrayEquals(halTlv(0xBF29, halTlv(0x5A, id) + halTlv(0x90, japanese)), halRenameRequest(id, eid, japanese))
        halRenameRequest(id, eid, "日".repeat(64).toByteArray(Charsets.UTF_8))
        for (bad in listOf(hex("FF"), "日".repeat(65).toByteArray(Charsets.UTF_8), byteArrayOf(0))) {
            try { halRenameRequest(id, eid, bad); fail("Invalid nickname admitted") } catch (_: IllegalArgumentException) {}
        }
        for (p in listOf(halDeleteRequest(id, eid), halRenameRequest(id, eid, japanese), halNotificationRequest(0xBF30, 1))) {
            assertFalse(isAllowedHalReadApdu(hex("81E29100") + byteArrayOf(p.size.toByte()) + p))
            try { validateHalDownload(p, intArrayOf(p.size)); fail("Management admitted as download") } catch (_: IllegalArgumentException) {}
        }
    }
    @Test fun notificationSequencesUsePositiveBerIntegers() {
        assertArrayEquals(hex("BF3003800100"), halNotificationRequest(0xBF30, 0))
        assertArrayEquals(hex("BF300480020080"), halNotificationRequest(0xBF30, 128))
        assertArrayEquals(hex("BF2B08A00680047FFFFFFF"), halNotificationRequest(0xBF2B, Int.MAX_VALUE))
        for ((tag, seq) in listOf(0xBF30 to -1, 0xBF33 to 0)) {
            try { halNotificationRequest(tag, seq); fail("Invalid removal admitted") } catch (_: IllegalArgumentException) {}
        }
    }
    @Test fun managementResultsCannotHideCardPolicyRejectionOrWrongResponse() {
        assertTrue(halResultOk(hex("BF29038001009000"), 0xBF29))
        assertFalse(halResultOk(hex("BF33038001019000"), 0xBF33))
        for (r in listOf("BF29038001006A82", "BF33038001009000", "BF29008001009000", "BF2904800200009000")) {
            try { halResultOk(hex(r), 0xBF29); fail("Invalid result admitted") } catch (_: IllegalArgumentException) {} catch (_: NoSuchElementException) {}
        }
    }
}
