![NekokoLPA2 — cross-platform eSIM manager](docs/assets/readme-banner.png)

# NekokoLPA2
[![Crowdin](https://badges.crowdin.net/nekokolpa2/localized.svg)](https://crowdin.com/project/nekokolpa2)


[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white&style=for-the-badge)](https://apps.apple.com/en/app/nekokolpa-2/id6757540723)
[![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Download-34A853?logo=googleplay&logoColor=white&style=for-the-badge)](https://play.google.com/store/apps/details?id=ee.nekoko.nlpa)


**Language:** **English** | [日本語](./README_ja-JP.md) | [简体中文](./README_zh-CN.md)


NekokoLPA2 is a cross-platform eSIM management app for working with local eUICCs, external readers, and remote reader endpoints. It is designed for users who need more control over profile operations, transport choices, and card visibility than a typical carrier app exposes.

[Get started](#get-started) · [Readers and platforms](#platform-support) · [VoWiFi and IMS](#vowifi-and-ims) · [Build from source](#build-from-source) · [Troubleshooting](#troubleshooting)

Choosing a download: [Android variants and desktop builds](docs/build-variants.md) · [OTBridge versus the rooted app](docs/android-root.md).

Android OMAPI: [restart regression and recovery](docs/omapi-recovery.md).

## Get started

1. Install the app from an [official download channel](#download).
2. Connect an eUICC reader and enable its connection type in reader settings. For Bluetooth, allow the requested Bluetooth permissions and scan for the advertised reader name.
3. Select the reader and load its profiles. Use an activation code or QR code to download a profile; enable, rename, or delete profiles from the reader's profile list.

An external reader manages the card connected to that reader. It does not turn an iPhone's internal eSIM into an externally accessible card. Android's internal-card access depends on the available OMAPI, bridge, or modem interface and the card's access rules.

## Highlights

- Works across Android, iOS, macOS, Linux, Windows, and Chrome
- Supports BLE readers, USB CCID readers, OMAPI, Telephony/TMAPI, remote readers, and browser-side WebUSB paths
- Includes profile organization tools such as custom icons, notes, tags, and scheduled notifications
- On rooted Android devices, `OTBridge` can enable Telephony support and help bypass OMAPI ARA-M restrictions without requiring NekokoLPA2 itself to be installed as a privileged app

## Platform Support

Experimental reader-backed Wi-Fi calling is available through the iOS Manage
screen. It requires an external SIM reader, not the phone's internal SIM;
see [build instructions and limitations](docs/ios-vowifi.txt).

Experimental desktop VoWiFi/SMS is also included on Windows, macOS and Linux.
**VoWiFi is disabled on Android and for OMAPI adapters.** Desktop sessions
require a reader with direct raw basic-channel APDUs; see [setup and restrictions](#vowifi-and-ims).

| Connection Type | Android | iOS | macOS | Linux | Windows | Chrome |
| --- | --- | --- | --- | --- | --- | --- |
| BLE readers | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ |
| USB CCID readers | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Remote readers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| OMAPI | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Telephony / TMAPI | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `OTBridge` provider | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| SE HAL (Shizuku) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| WebUSB SCRP / WebCard | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

Notes:
- `Telephony / TMAPI` and `OTBridge` are Android-only paths.
- `OTBridge` is intended for rooted Android setups where Telephony access or OMAPI policy bypass is needed.
- `SE HAL` is experimental and off by default. It needs Shizuku, and works only where the device lets `shell` call the Secure Element HAL.
- Chrome support refers to the web build running in a Chromium browser with the required browser APIs available.

## Translation

Translations are managed on [Crowdin](https://crowdin.com/project/nekokolpa2).


## Features

- **Multi-reader support**: BLE, USB CCID, OMAPI, Telephony API, remote readers, and browser-based transports
- **TYBLE readers**: Tianyu readers with names such as `SCT-BT-<UID>` and `TES-BT-<UID>`, plus 9eSIM B0 Plus readers named `9eSIM` followed by eight digits. Six-character 9eSIM suffixes continue to use the NineESIM protocol. TYBLE uses the BLE platforms listed above.
- **SIM probing**: Plain SIMs can show their operator and identity details on the unsupported-card screen when the connected reader permits raw APDUs.
- **Desktop VoWiFi/SMS**: Optional experimental SMS sessions backed by an external SIM reader on Windows, macOS and Linux
- **Rooted Android path**: `OTBridge` can enable Telephony support and bypass OMAPI ARA-M restrictions while keeping the main app unprivileged
- **Provider integrations**: eSIM.cc rewards/portal, eSIM.gg number/balance/package status, and 3HK number/expiry/package status are maintained here in the public repository.
- **Profile organization**: Custom icons, notes, tags, and compact management tools
- **Scheduled notifications**: Reminders for expiry and other profile-related events
- **Cross-platform UI**: Responsive layout with platform-aware reader flows

## Android Notes

- The public Android edition is **NekokoLPA 2 Community**, using the dolphin/sekiu artwork. It replaces the Open name while retaining the existing package and signing identity for updates. [Compare the Android variants](docs/build-variants.md).
- NekokoLPA2 prefers the external `OTBridge` provider on Android when it is installed.
- On rooted Android devices, `OTBridge` can expose Telephony/TMAPI access and help bypass OMAPI ARA-M restrictions while keeping NekokoLPA2 itself on the normal app path.
- OTBridge source and builds now live in this repository: [source](otbridge/), [release downloads](https://github.com/iebb/NekokoLPA2/releases).
- The separate full rooted app/module is also maintained. [Compare OTBridge and the rooted app, with installation/build instructions](docs/android-root.md).
- VoWiFi remains disabled on Android, including when an external reader or bridge is available. OMAPI profile management remains available separately.

## VoWiFi and IMS

| Feature | Windows / macOS / Linux | iOS | Android | Browser |
| --- | --- | --- | --- | --- |
| Experimental desktop SMS over IMS | Opt-in, external raw-APDU reader | — | Disabled | — |
| Reader-backed Wi-Fi calling | — | External USB CCID or supported RED BLE reader | Disabled | — |
| VoWiFi through OMAPI | Disabled | Disabled | Disabled | — |

### Desktop setup

1. Use a non-9eSIM-branded build on Windows, macOS or Linux.
2. Connect an external SIM/eUICC reader that permits raw APDUs on the basic channel. OMAPI and SE HAL readers are not eligible.
3. In Settings, enable **VoWiFi** and accept the experimental-feature notice.
4. On the reader page, choose **Load current SIM to VoWiFi**. The app derives the IMS realm, ePDG address and SMSC from the SIM where available.
5. Use the VoWiFi tab to view sessions and exchange SMS. Disable VoWiFi or disconnect a session to stop it.

The desktop implementation provides SMS. The iOS Manage screen uses a separate reader-backed calling implementation; see its [build instructions, background limits and verification notes](docs/ios-vowifi.txt).

### Protocol behavior and limits

The desktop IMS client handles AKA resynchronization with AUTS, binary RES values, quoted Digest challenges, `auth`/`auth-int` quality-of-protection negotiation, nonce counts, and supported MD5/SHA-256 digest variants. It correlates final SIP responses to the outstanding transaction, retains the registrar's ordered `Service-Route` values, and honors a valid `423 Min-Expires` response with one bounded retry.

These paths have unit and local SIP-peer regression tests. Carrier provisioning, ePDG access, SIM policy and network behavior still determine whether a real subscription registers and exchanges SMS. This is experimental software, and the project does not claim universal carrier compatibility. See [implementation details, research references and remaining limits](docs/desktop-ims.md).

## Build from source

The public repository includes TYBLE readers, SIM probing and desktop VoWiFi/SMS without a private overlay. Use the Flutter version pinned in [CI](.github/workflows/build.yml), currently **3.47.2**. Android's QRTR transport also requires **Rust 1.89 or later**. Native desktop builds require that platform's Flutter build toolchain.

```sh
git clone --branch master https://github.com/iebb/NekokoLPA2.git
cd NekokoLPA2
flutter pub get
flutter devices
flutter run -d macos  # choose an available device from flutter devices
```

For reader-backed iOS calling, first follow the [source-built Go framework and codec instructions](docs/ios-vowifi.txt). `GM_PSK_URL` can be supplied as a non-secret `--dart-define`; leaving it empty still builds the app, with GM PSKs limited to those already cached.

### Validate a change

```sh
dart analyze lib test
flutter test --no-pub
flutter build web --release --no-pub
```

Format the Dart files you change. Add user-facing strings only to `l10n/app_en.arb`, then run `flutter gen-l10n`; Crowdin owns the translated ARB files. When adding a plugin, regenerate its registry with `dart run scripts/generate_plugin_registry.dart`. Maintainers working with a private overlay should use `--public` for the committed registry.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Bluetooth reader is missing | Enable Bluetooth, allow the platform permissions, enable that reader type and scan again. Linux has no BLE transport in this app. |
| An Android card refuses OMAPI | Check its access rules or use a supported bridge/reader. VoWiFi is unavailable through OMAPI. |
| The VoWiFi setting is absent | Desktop VoWiFi is unavailable on Android, iOS and 9eSIM-branded builds. iOS calling has its own Manage entry. |
| IMS registration or SMS fails | Check reader eligibility, SIM carrier provisioning, the reported SIP status and the [IMS limitations](docs/desktop-ims.md). A passing build does not establish carrier support. |

When reporting a problem, include the app version, operating system, reader model and a redacted error. Remove subscriber identities, activation codes, phone numbers, raw APDUs and authentication material from shared logs.

## Download

- [![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white&style=for-the-badge)](https://apps.apple.com/en/app/nekokolpa-2/id6757540723)
- [![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Download-34A853?logo=googleplay&logoColor=white&style=for-the-badge)](https://play.google.com/store/apps/details?id=ee.nekoko.nlpa)
- **GitHub Releases**: [iebb/NekokoLPA2 releases](https://github.com/iebb/NekokoLPA2/releases)
- **TestFlight**: [Join TestFlight](https://testflight.apple.com/join/bP38fzC4)
- **Web**: [web.lpa.ee](https://web.lpa.ee) — [release deployment guide](docs/web-release.md)

## Star History

[![Star History Chart](https://api.star-history.com/chart?repos=iebb/NekokoLPA2%2Ciebb/NekokoLPA&type=date&legend=top-left)](https://www.star-history.com/?repos=iebb%2FNekokoLPA2%2Ciebb%2FNekokoLPA&type=date&legend=top-left)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history and user-facing changes.

## Wiki

- [Wiki Home](https://github.com/iebb/NekokoLPA2/wiki)
- [Getting Started](https://github.com/iebb/NekokoLPA2/wiki/Getting-Started)
- [Features](https://github.com/iebb/NekokoLPA2/wiki/Features)
- [Readers and Platforms](https://github.com/iebb/NekokoLPA2/wiki/Readers-and-Platforms)
- [Troubleshooting](https://github.com/iebb/NekokoLPA2/wiki/Troubleshooting)

## Support

For issues, feature requests, or questions, please visit our [GitHub Issues](https://github.com/iebb/NekokoLPA2/issues).

## License

NekokoLPA2 is released under the [MIT License](LICENSE).

The NekokoLPA cat mascot artwork was created by @sanzennami. Reference use is OK, but the mascot SHOULD NOT be used as your own logo, app icon, shop avatar, or dominant brand mark without agreement. You may include it as part of a logo or image only when it does not exceed 10% of the entire logo or image and the use does not imply official endorsement. See [NOTICE](NOTICE) and [BRANDING.md](BRANDING.md).

---

© 2026 Nekoko.
