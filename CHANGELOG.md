# Changelog

All notable changes to NekokoLPA2 will be documented in this file.
## [2.0.2+546] - 2026-01-31

### Added
- Add BeeSIM support

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
- **G+D card Handling**: Better handling with 9eSIM v1 cards.

## [2.0.1+35] - 2026-01-22

### Added
- **EUICC Signatures**: Added EUICC Signatures support.
- **Connection Stability**: Improved how the app manages smart card connections to prevent "channel busy" errors and ensure smoother profile loading.

## [2.0.1+34] - 2026-01-21

### Added
- **Deep Link Direct Download**: Added Deep Link Direct Download support. Now you can use urls to download profiles directly from the app, including webviews.

## [2.0.1+33] - 2026-01-20

### Added
- **Deep Linking Support**: Added Deep Linking support. Now you can use urls such as https://install.lpa.ee/LPA:1$smdp.io$QR-G-5C-1LS-1W1Z9P7 to open the app.


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
