# NekokoLPA2
[![Crowdin](https://badges.crowdin.net/nekokolpa2/localized.svg)](https://crowdin.com/project/nekokolpa2)


[![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white&style=for-the-badge)](https://apps.apple.com/en/app/nekokolpa-2/id6757540723)
[![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Download-34A853?logo=googleplay&logoColor=white&style=for-the-badge)](https://play.google.com/store/apps/details?id=ee.nekoko.nlpa)


**Language:** **English** | [日本語](./README_ja-JP.md) | [简体中文](./README_zh-CN.md)


NekokoLPA2 is a cross-platform eSIM management app for working with local eUICCs, external readers, and remote reader endpoints. It is designed for users who need more control over profile operations, transport choices, and card visibility than a typical carrier app exposes.

## Highlights

- Works across Android, iOS, macOS, Linux, Windows, and Chrome
- Supports BLE readers, USB CCID readers, OMAPI, Telephony/TMAPI, remote readers, and browser-side WebUSB paths
- Includes profile organization tools such as custom icons, notes, tags, and scheduled notifications
- On rooted Android devices, `OTBridge` can enable Telephony support and help bypass OMAPI ARA-M restrictions without requiring NekokoLPA2 itself to be installed as a privileged app

## Platform Support

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
- **Rooted Android path**: `OTBridge` can enable Telephony support and bypass OMAPI ARA-M restrictions while keeping the main app unprivileged
- **Profile organization**: Custom icons, notes, tags, and compact management tools
- **Scheduled notifications**: Reminders for expiry and other profile-related events
- **Cross-platform UI**: Responsive layout with platform-aware reader flows

## Android Notes

- NekokoLPA2 prefers the external `OTBridge` provider on Android when it is installed.
- On rooted Android devices, `OTBridge` can expose Telephony/TMAPI access and help bypass OMAPI ARA-M restrictions while keeping NekokoLPA2 itself on the normal app path.
- `OTBridge` releases are available at: [iebb/OTBridge](https://github.com/iebb/OTBridge/releases)

## Download

- [![Download on the App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white&style=for-the-badge)](https://apps.apple.com/en/app/nekokolpa-2/id6757540723)
- [![Get it on Google Play](https://img.shields.io/badge/Google%20Play-Download-34A853?logo=googleplay&logoColor=white&style=for-the-badge)](https://play.google.com/store/apps/details?id=ee.nekoko.nlpa)
- **GitHub Releases**: [iebb/NekokoLPA2 releases](https://github.com/iebb/NekokoLPA2/releases)
- **TestFlight**: [Join TestFlight](https://testflight.apple.com/join/bP38fzC4)
- **Web**: [web.lpa.ee](https://web.lpa.ee)

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
