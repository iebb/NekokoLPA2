# Changelog

All notable changes to NekokoLPA2 will be documented in this file.

## [2.2.5+587] - 2026-09-24

### Changed
- The macOS app requires macOS 12 or later.

### Fixed
- eUICC signing requests from websites accept a non-standard IMEI or TAC given as integers, instead of failing with "IMEI integer must contain exactly 15 decimal digits".
- When a profile fails to install, the reason (such as insufficient memory) is shown even on cards holding many install notifications, instead of an APDU error over Bluetooth readers.

## [2.2.4+586] - 2026-08-29

### Fixed
- Confirmation codes are hashed over the transaction identifier itself rather than its text form, so a server that issues a short identifier no longer rejects a correct code.
- Carrier eSIM transfers send the device IMEI in the right digit order; carriers that validate it no longer refuse the transfer.
- USB card readers release their connection when disconnected, instead of leaking one per session until connecting stopped working.
- Profile downloads give up on an unresponsive server instead of waiting indefinitely, and the screen now explains why it cannot be dismissed mid-operation.
- Rejecting a previewed profile ends the session with the server, so the next attempt is not refused as already in progress.
- Reader actions such as loading the current SIM to VoWiFi act on the profiles currently on the card rather than a stale list.

## [2.2.1+583] - 2026-08-11

### Fixed
- Fixed eUICC signing when a valid 15-digit IMEI is supplied as unsigned integer bytes.

## [2.1.5+575] - 2026-07-10

### Added
- Added Russian localization from Crowdin.

## [2.1.4+574] - 2026-07-10

### Fixed
- Show and edit the device TAC instead of the internal 16-digit stored IMEI encoding.
- Use TAC `35383741` by default while still accepting a full 15-digit IMEI.

## [2.1.0+569] - 2026-06-01

### Changed
- Prepared public store branding and standard platform icons.
- Restricted GitHub release publishing to the release branch.

## [2.0.10+568] - 2026-05-24

### Added
- Added distinct OMAPI and Telephony API reader icons.
- Added notification send, delete, and completion animations with a session-only pause control.

### Changed
- Improved eSIM switching stability across OMAPI and Telephony API readers.
- Notification processing now follows auto-trigger settings unless paused by the user.

### Fixed
- Fixed launch-time eSIM switching failures and reader deduplication for channels pointing at the same card.
- Fixed notification count taps showing stale sent notifications before fresh metadata finishes loading.

## [2.0.8+564] - 2026-04-03

### Added
- Android now detects rooted devices and shows that OTBridge can be used to enable Telephony support and bypass OMAPI ARA-M restrictions.

### Changed
- Android prefers the external OTBridge provider path when present.
- Android CI no longer builds the privileged NekokoLPA2 variant.

## [2.0.4+555] - 2026-02-15

### Added
- Improved eSTK.me Card support

## [2.0.2+543] - 2026-01-25

RemoCard v2.0 and minor UI fixes

## [2.0.2+542] - 2026-01-25

Added a browser with signing capabilities.

## [2.0.2+541] - 2026-01-25

Profile Size Predictions, Optimized Reset Flag

## [2.0.2+540] - 2026-01-24

### Added
- **IMEI**: Added IMEI to settings.

### Fixed
- **Wrong IMEI generation**: Fixed wrong IMEI generation. Previously it might contain non-numeric characters.

## [2.0.2+538] - 2026-01-22

### Changed
- **Version**: Bumped version to 2.0.2+538 to make Apple Happy.

### Fixed
- **TMAPI Handling**: Now it should work on Android 13- devices.
- **Remote Card Handling**: Now it should work again.

### Added
- **Download Size Prediction**: Allow predicting download size before downloading.

## [2.0.1+537] - 2026-01-22

### Changed
- **Version**: Bumped version to 2.0.1+537 to allow upgrading

### Added
- **Size Data Migration**: Now it's possible to read from v1 App's size stats and migrate them to v2 App with same package name.

## [2.0.1+35] - 2026-01-22

### Added
- **EUICC Signatures**: Added EUICC Signatures support.
- **Connection Stability**: Improved how the app manages smart card connections to prevent "channel busy" errors and ensure smoother profile loading.

## [2.0.1+34] - 2026-01-21

### Added
- **Deep Link Direct Download**: Added Deep Link Direct Download support. Now you can use urls to download profiles directly from the app, including webviews.

## [2.0.1+33] - 2026-01-20

### Added
- **Deep Linking Support**: Added Deep Linking support. Now you can use urls such as https://install.lpa.ee/LPA:1$smdp.example$MATCHING-ID to open the app.


## [2.0.0+32] - 2026-01-20

### Added
- **Linux Support**: Added Linux support.

## [2.0.0+31] - 2026-01-19

### Improved
- **Connection Stability**: Improved how the app manages smart card connections to prevent "channel busy" errors and ensure smoother profile loading.
- **Better User Feedback**: Fixed a bug where the app showed "Not Connected" while still trying to connect to a reader.
- **Connection Recovery**: Added easy "Cancel" and "Retry" buttons if a connection to a card reader takes too long.


## [2.0.0+30] - 2026-01-18

### Added
- **Variant-Specific Branding**: Added dynamic logos for app variants.
- **Improved Variant Detection**: Support for variants via package name and build environment.

### Fixed
- **Rooted Device Support**: Robustified Telephony/TMAPI plugin to prevent crashes on high-privileged builds on some devices.

## [2.0.0+29] - 2026-01-17

### Fixed
- **Multi-Language Support**: Improved translations.
- **Bluetooth Connection**: Improved Bluetooth connection handling.

## [2.0.0+28] - 2026-01-15

### Added
- **Multi-Language Support**: Added support for Spanish, French, Japanese, and Chinese.
- **Bluetooth-on-Windows Support**: Added support for Bluetooth on Windows.

## [2.0.0+27] - 2026-01-14

### Added
- **Phone Number Parsing**: Customizable E.164 / National Number Parsing

### Fixed
- **Card Switch Handling**: Better support for Android on OMAPI

## [2.0.0+26] - 2026-01-14

### Added
- **Custom Profile Icons**: Set custom icons for profiles from gallery, remote Nekoko icons, or eSIM card icons
- **Copy ICCID**: Quick copy profile ICCID to clipboard from context menu
- **Enhanced Tag Notifications**: Tag-based notification scheduling system

### Changed
- **Compact UI**: Improved space efficiency on small screens with scrollable dialogs and menus

### Fixed
- **Permission Handling**: Better support for Linux/macOS with clear unsupported platform messages
