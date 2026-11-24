package ee.nekoko.nlpa2

import java.io.IOException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OmapiOpenFailuresTest {
    private fun failures(vararg errors: Exception?) =
            OmapiOpenFailures().apply { errors.forEach(::record) }

    @Test
    fun aRefusalIsTheAnswerWhenNothingElseFailed() {
        val restricted = SecurityException("Restricted AID is not allowed in UICC terminal")
        val result = failures(restricted, NoSuchElementException("6A82"), null)
        assertTrue(result.permissionDenied)
        assertEquals("Restricted AID is not allowed in UICC terminal", result.deniedMessage())
    }

    @Test
    fun aLaterMissingAidDoesNotHideTheRefusal() {
        assertTrue(failures(NoSuchElementException(), SecurityException("denied")).permissionDenied)
        assertTrue(failures(SecurityException("denied"), NoSuchElementException()).permissionDenied)
    }

    @Test
    fun anIoFailureOrNoRefusalIsNotAPermissionError() {
        assertFalse(failures(SecurityException("denied"), IOException("io")).permissionDenied)
        assertFalse(failures(NoSuchElementException(), null).permissionDenied)
        assertFalse(failures().permissionDenied)
    }
}
