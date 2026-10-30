# OMAPI restart investigation: 2.3.0 to 2.4.1+602

Investigated on 2026-10-31. [Issue #58](https://github.com/iebb/NekokoLPA2/issues/58) shows **2.4.1 build 601** reading SIM1/SIM2 on first launch, followed by Android's recent-apps cleanup, then `OMAPI_SESSION_CORRUPTED` on relaunch. Its reason is `OMAPI safety guard survived an unclean process exit on this boot`. This is a restored safety marker, before reader enumeration; it is not evidence that the SIM disappeared or that its applet is unsupported.

## What actually changed

The published 9eSIM ARM64 APKs were compared, including their native `ee.nekoko.nlpa2.OmapiPlugin` entry point. Both verify with the same signing certificate, SHA-256 `6966004ad0161165335f9204f8f5a52df49fe068c9545c0c589c23221af8d3a4`.

| Published APK | SHA-256 | Native plugin behavior |
| --- | --- | --- |
| [2.3.0+589](https://github.com/iebb/NekokoLPA2/releases/tag/v2.3.0%2B589), `ee.nekoko.nlpa.flavor1-2.3.0-589-arm64-v8a.apk` | `3b9be301aaa1637b61199d35ab86b2fd00f191326e7d0972f230024dec75d0f6` | Registers channels and initializes the service without wiring the persistent cleanup coordinator into engine attachment. |
| [2.4.1+601](https://github.com/iebb/NekokoLPA2/releases/tag/v2.4.1%2B601), `ee.nekoko.nlpa.flavor1-2.4.1-601-arm64-v8a.apk` | `945ddd48c19b1e3ef924ebf86c3ee215d13415fad8dbb387cce9bef7c16a684a` | Creates the cleanup coordinator, restores its durable safety marker on engine attachment and rejects same-boot access after an unclean exit. |

The older APK contains guard-related classes/strings, and the public 2.3.0 source tag already contains guard source. Neither alone proves that the released native entry point used it. Comparing the actual APK entry points explains why source-tag inspection initially missed the difference. The identical certificates rule out a signing-key change **between these two 9eSIM artifacts**, not every possible card authorization problem.

## The remaining 601 lifecycle gap

Dart keeps a released OMAPI logical channel open for three seconds to reuse it for nearby requests. The native clean-idle checkpoint can clear the safety marker only after all tracked channels have closed. If Android suspends timers or terminates the process during this interval, a released channel can leave the marker armed. Android does not guarantee `onDestroy()` when killing a process; see the [process lifecycle documentation](https://developer.android.com/guide/components/activities/process-lifecycle).

This is a code-supported explanation consistent with #58. It has not been reproduced on the reporter's physical Xiaomi device. An actually interrupted profile operation can also legitimately leave the marker armed.

## 602 behavior

- On Flutter `hidden`/`paused`, close only cached channels whose owners have already released them, without waiting for the three-second timer.
- Keep live references used by downloads and profile operations. If they finish while backgrounded, close immediately on release.
- Recheck ownership and reference count after acquiring the serialized operation lock, so a queued close cannot close a newly borrowed channel.
- Keep the native verified-idle checkpoint and the reboot-required guard after real cleanup failure. Do not call bulk session cleanup to recover.

Five Dart regression tests cover background flushing, active operations, reuse, foreground restoration and a close queued behind a reborrow. These establish adapter behavior with a mock native channel; they do not establish physical Xiaomi/HyperOS compatibility.

If an older build already left a reboot-required marker, installing 602 does not erase it. Restart the phone once, then test first launch, Home/resume, clearing recent apps and reopening. A real `Channel.close()` failure must still require reboot; [Samsung issue #46](https://github.com/iebb/NekokoLPA2/issues/46) explains why blindly clearing this protection is unsafe.
