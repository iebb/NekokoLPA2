# eUICC notifications

Profile installation, enabling, disabling and deletion can create signed notifications for the operator’s SM-DP+ server. Automatic sending and automatic card removal are separate settings for each operation.

A successfully delivered notification stays visible in the card’s notification list when automatic removal is off. Its status is **Sent**. Use the card entry’s delete action to remove it from the eUICC without sending it again. Removal is reported as successful only after the card confirms the entry is absent.

**Delete local history entry** removes the saved payload and response from this app’s history. It does not remove anything from the eUICC. The app retains only the EID, ICCID, sequence number and a SHA-256 hash as a delivery receipt, so later automatic processing does not resend the deleted history entry. Receipts are included in database exports; resetting the database clears them.

Automatic processing runs in a serialized card session after the applicable profile operation or refresh. It does not require the notification page to be open. It still requires a connected reader, a running app and access to the notification’s server; iOS does not guarantee execution while the app is suspended.

The fixes for issues #42 and #43 are covered by automated card and network-failure simulations. Physical iOS/9eSIM V3 confirmation remains pending; these changes are newer than release 2.4.2+602.
