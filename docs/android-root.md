# OTBridge and the rooted app

Both approaches need a rooted Android device and compatible firmware/card access. They are optional: ordinary Bluetooth/USB readers and permitted OMAPI access do not require either module. **Android VoWiFi remains disabled in every build.**

| | Normal app with OTBridge | Full rooted app |
| --- | --- | --- |
| What is privileged? | The small `ee.nekoko.nbridge` helper | The complete `ee.nekoko.nlpa2` app |
| Where does the UI run? | The normal installed NekokoLPA app | The systemless privileged app |
| Internal SIM access | Helper exposes OMAPI/TMAPI through `content://ee.nekoko.nbridge.provider` | App can use its built-in Telephony reader directly |
| Installation | Install the OTBridge Magisk/KernelSU module, reboot, then use the normal app | Install the full-app Magisk module and reboot |
| Card access rules | May still apply; optional LSPosed hook is a separate bypass | Privileged permissions alone do not guarantee OMAPI access |

## OTBridge

The source now lives in [`otbridge/`](../otbridge/), including its original MIT license and source provenance. The app prefers the external bridge provider when available. The helper's screen exposes the detected SIM slots and per-slot switches.

1. Download `otbridge-magisk-kernelsu-v*.zip` from the NekokoLPA2 release.
2. Install it with Magisk or KernelSU and reboot. Installing only the APK does not grant the required privileged permissions.
3. Open OTBridge to check the available slots and switches, then enable the relevant OMAPI/Telephony connector in NekokoLPA.

The optional LSPosed entry targets `com.android.se` and disables its ARA/ARF access checks. It is separate from the privileged module and must be enabled/scoped in LSPosed to take effect. Its scope is the Secure Element service, not an approval grant for one caller. The current bridge provider is exported and does not implement per-caller approval; this is an access tool for a trusted rooted device, not a per-app SIM permission boundary.

New public helper builds use the already-public community signing certificate. An older helper signed with another certificate may require removal/reinstallation before Android accepts an update. The helper keeps its package and provider authority.

## Full rooted app

The `privileged` flavor sets `PRIVILEGED_BUILD=true`, requests the privileged telephony/eSIM permissions, and enables the built-in Telephony path. Enable its connector in reader settings. Device firmware can still restrict what that path permits.

Public artifacts are named `ee.nekoko.nlpa2.community-<version>-rooted-arm64-v8a.apk` and `ee.nekoko.nlpa2.community-<version>-magisk.zip`. The APK's actual package is `ee.nekoko.nlpa2`, matching the module's permission allowlist. Install the module for privileged operation; installing the APK normally does not make it a system app. Public builds use the community certificate. Kasutera separately retains its vendor-signed privileged APK/module; switching signers can require uninstalling the other build.

Build from the public repository with its pinned Flutter/Rust/Android toolchains:

```sh
flutter pub get
flutter build apk --release --flavor privileged --target-platform android-arm64 \
  --dart-define=PRIVILEGED_BUILD=true
python3 scripts/package_rooted_android.py \
  --apk build/app/outputs/flutter-apk/app-privileged-release.apk \
  --output release/nekokolpa-rooted-magisk.zip --version 2.4.0+600
```

Use the version from `pubspec.yaml` for module packaging. The packager puts the APK, permission XML and installer permissions at matching paths; the native release build and packaging checks do not establish hardware/card interoperability.

## Release builds

The public **Build NekokoLPA2** workflow builds the normal app, full rooted app/module, and OTBridge APK/module for releases. Its manual `android_tools_only` option builds and attaches the rooted/bridge artifacts to the existing release for the current app version without rebuilding desktop/web packages. These supplemental artifacts record their source in the linked Actions run; they can be added after the original app release tag.

Kasutera's **Publish Android** workflow retains the `privileged` variant on normal release runs. Its manual `rooted_only` option rebuilds just that variant. Neither rooted path publishes to Google Play.
