package ee.nekoko.nlpa2

/**
 * Why no candidate AID opened a logical channel.
 *
 * OMAPI answers an AID it refuses to open with a SecurityException (the ARA-M rules, or since
 * Android 17 on Pixels, "Restricted AID is not allowed in UICC terminal" for the ISD-R) and an AID
 * the card does not have with NoSuchElementException or a null channel. When a refusal is the only
 * real failure, it is the answer: reporting it as a generic channel failure sent the app into a
 * session reset and retry that could not succeed.
 */
internal class OmapiOpenFailures {
    var lastError: Exception? = null
        private set
    private var refusal: SecurityException? = null
    private var otherFailure = false

    /** Records one candidate's failure; `null` for a channel the service did not return. */
    fun record(error: Exception?) {
        if (error != null) lastError = error
        when (error) {
            is SecurityException -> refusal = error
            null, is NoSuchElementException -> Unit
            else -> otherFailure = true
        }
    }

    /** At least one candidate was refused, and every other one simply was not there. */
    val permissionDenied: Boolean
        get() = refusal != null && !otherFailure

    /** The message of the refusal, for the error the app shows. */
    fun deniedMessage(): String? = refusal?.message
}
