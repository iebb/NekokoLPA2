# Android variants and desktop builds

Current source/build comparison, 2026-10-31. **Community** is the name of the public Android variant. Windows, macOS, Linux and web are **NekokoLPA 2**; their application code is maintained in this public repository. Kasutera supplies branding, signing and release configuration.

## Shared application features

All provider plugins are public: eSIM.cc rewards/portal actions, eSIM.gg number/balance/package status, and 3HK number/line-expiry/package status. Matching profiles query the relevant provider service and cache the returned information. BeeSIM, eSTK and GM are public as well. There is no private provider plugin or separate private LPA engine.

| Area | Public application | Branded builds |
| --- | --- | --- |
| Download, enable, disable, rename and delete profiles | Shared core | Same |
| Reader transports, including TYBLE/B0 Plus, CCID, OMAPI, bridges, SE HAL and remote readers | Public, subject to OS/hardware support | Same |
| Plain-SIM probing | Included on eligible raw-APDU readers | Same |
| Experimental desktop IMS/SMS | Opt-in on Windows/macOS/Linux | Disabled in the 9eSIM variant |
| Reader-backed iOS calling | Public source with its source-built framework | Same implementation where enabled |
| Android/OMAPI VoWiFi | Disabled, including rooted/bridge configurations | Same |
| OTBridge and full rooted app/module | Public source and builds | Vendor-signed full rooted build also retained |
| eSIM.cc, eSIM.gg and 3HK profile extras | Included in current source | Same plugins |
| Extra navigation and artwork | Public defaults | Optional brand/provider web tabs and flavor assets |

The 2.4.1+601 binaries include eSIM.cc/eSIM.gg and the OMAPI restart fix. They predate the 3HK promotion: the public 3HK plugin is included from the next build. Adding canonical desktop filenames to the 601 release does not change those binaries. The original 2.4.0+600 public binaries predate all three provider promotions and the OMAPI restart fix.

OS limits apply equally: the app has no Linux BLE transport. Desktop IMS provides experimental SMS; the separate iOS implementation provides reader-backed calling.

## Android identity, signing and packaging

| Build | Android package | Signing/distribution |
| --- | --- | --- |
| Community | `ee.nekoko.nlpa2.open` | Public community certificate; public GitHub APK is multi-ABI |
| Standard GitHub APK | `ee.nekoko.nlpa2.std` | 9eSIM certificate; current APK targets ARM64 |
| Standard Google Play | `ee.nekoko.nlpa` | Store app identity and Play distribution |
| Multi-signer | `ee.nekoko.nlpa2.multi` | Multiple vendor/community certificates; ARM64 and ARMv7 |
| Community/sekiu | `ee.nekoko.nlpa2.sekiu` | Community certificate and its flavor assets |
| 9eSIM | `ee.nekoko.nlpa.flavor1` | 9eSIM branding/certificate and build restrictions |
| Full rooted app | `ee.nekoko.nlpa2` | Public rooted build uses the community certificate; vendor build uses its vendor certificate |

Signing certificates can affect card access through OMAPI: the card and firmware must accept the certificate/permissions. Ordinary APK installation grants neither root nor system privileges. See [OTBridge and the rooted app](android-root.md).

The vendor Android scripts pass `ENABLE_ZXING=false`, while Community uses the default `true`. Community therefore retains the extra ZXing fallback when imported QR-image analysis throws an error. Both still use the normal mobile scanner. Desktop builds keep that decoder enabled.

## Desktop naming and app data

Desktop builds are named NekokoLPA 2, without a Community suffix. Canonical downloads use `ee.nekoko.nlpa2.windows-<version>-setup.exe`, `ee.nekoko.nlpa2.windows-<version>-x64.zip`, and `ee.nekoko.nlpa2.linux-<version>-x64.AppImage` / `.tar.gz`. Web archives use `ee.nekoko.nlpa2.web-<version>.zip`. Historical `.open-` download names are retained for existing links; they do not designate another desktop product.

Windows uses `%LOCALAPPDATA%/NekokoLPA2/databases/nekokolpa2.db`. Earlier installers use different installer IDs but the same default `%ProgramFiles%/NekokoLPA2` directory. These naming changes preserve the current installer ID and database location. Do not treat old and new download names as isolated installations. Database import/export is available in the shared app.

Normal Community and other Android variants have separate package IDs and local app data. Rooted builds share their legacy package ID; switching signing certificates can require reinstalling. Profiles themselves reside on the eUICC, independently of the app's notes/settings/database.

Community uses the existing dolphin/sekiu artwork. Its Android package remains `ee.nekoko.nlpa2.open` and its signing certificate is unchanged, so existing installations can update in place. New Android artifact filenames use `.community-`; earlier `.open-` artifacts remain valid historical downloads.

## Update delivery

Android Community and rooted Community use isolated `community` and `community-rooted` channels with verified APK signing certificates. Windows/Linux use the shared standard desktop feeds. Legacy Android `open` / `open-rooted` channels are kept as aliases for existing installations. Earlier desktop `open` and `store` channels remain compatibility aliases to those same public desktop artifacts; Community is not a desktop product name.

The first public 2.4.0+600 Android artifacts embedded `store`. Both normal and rooted APKs used that variant and the same certificate, so their compatibility feed opens the release chooser. Choose the matching Community Android APK or rooted module. New Android builds carry distinct identities. See [update delivery](update-feeds.md).

macOS/iOS use Store/TestFlight delivery. Kasutera retains signing material, platform/flavor assets and release infrastructure; all Dart application and provider code is public.
