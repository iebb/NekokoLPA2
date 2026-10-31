# Bluetooth reader setup on iOS

Shipping iOS/iPadOS builds use the standard CoreBluetooth permission and the
in-app Bluetooth scanner, including on iOS 18 or later. This supports readers
that are discoverable by their advertised name without advertising a service
UUID, such as BeeSIM's name-based reference discovery flow.

## Why AccessorySetupKit is disabled

The initial integration enabled AccessorySetupKit for every iOS 18+ device.
Its BeeSIM filter required both the `BeeSIM` name and the `AE30` service UUID.
The BeeSIM reference client instead filters only by name and lists `AE30` as
an optional GATT service. A service accessible after connecting is not proof
that the reader advertises it. The AccessorySetupKit filter therefore added
an unverified discovery requirement, and BeeSIM stopped working for users.

Declaring `Bluetooth` in `NSAccessorySetupKitSupports` also changes the app's
Bluetooth authorization model: CoreBluetooth scans only return accessories
already authorized through the system picker. Adding an in-app scan fallback
cannot restore discovery of a reader the picker cannot authorize. The opt-in
has consequently been removed from both the public and branded Info.plist.
The Bluetooth usage descriptions remain so the ordinary permission flow works.

## Retained experimental integration

The native plugin and Dart picker remain available for development. They are
inactive unless a test host explicitly adds `Bluetooth` to the
`NSAccessorySetupKitSupports` array. The plugin reports unsupported without
that declaration, selecting the existing in-app scanner.

Before enabling the system picker again, capture and verify the advertisements
of every supported reader and firmware family, including BeeSIM. Test both
fresh installs and upgrades from the AccessorySetupKit build on physical iOS
devices. A runtime switch alone cannot change the bundle's authorization model.

When explicitly enabled on iOS/iPadOS 18 or later, AccessorySetupKit shows
Apple's discovery and authorization sheet. Cancelling it does not start a
general Bluetooth scan or request Bluetooth/location permissions.

Previously authorized readers are listed on subsequent uses of the reader
button. Select one to reconnect or choose **Add Bluetooth reader** for the
system sheet. Removing authorization in iOS Settings removes it from this list.
System authorization does not persist an active reader in the app: it still
joins the current session only when selected.

The native setup channel is separate from the CoreBluetooth transport channel.
It never initializes CoreBluetooth before authorization. After selection the
app retrieves the approved peripheral by UUID and obtains its actual Bluetooth
name. This preserves reader identification and the UID-derived TYBLE PIN,
even if someone renamed its system display label. GATT communication and
reader-specific authentication continue through the existing adapters.

## Discovery filters

AccessorySetupKit needs an advertised service UUID or Bluetooth company ID;
it cannot discover a reader by name alone. This app combines each known reader
name with its service UUID. No custom pairing protocol, MFi authentication,
firmware extension or mandatory BLE bonding is added by this integration.
Devices must actually advertise the configured identifiers while discoverable.

An opted-in test host declares Bluetooth support, names and service UUIDs in Info.plist.
The plugin filters every request against these declarations before calling the
framework, because undeclared filters can terminate the app.
Plugin-provided readers use `scanServiceUuids` with `accessorySetupNames`
(falling back to `scanKeywords`). Add the corresponding declarations in the
host Info.plist when adding another reader family.

The iOS pod weak-links AccessorySetupKit so the minimum app target remains
iOS 15.6. Building it requires Xcode 16 or later. Name matching uses the
case-insensitive option where available (iOS 18.2+).

## Verification

Automated tests cover platform availability, cancellation, authorized-reader
mapping, full device-name preservation, plugin filters and invalid identities.
Real-device verification is still needed for each reader's advertisements,
authorization sheet, cancellation, Settings revocation and reconnect behavior.
Simulators do not provide this system Bluetooth onboarding experience.

References: [Meet AccessorySetupKit (discovery and CoreBluetooth authorization)](https://developer.apple.com/videos/play/wwdc2024/10203/),
[AccessorySetupKit](https://developer.apple.com/documentation/accessorysetupkit),
[Discovering and configuring accessories](https://developer.apple.com/documentation/accessorysetupkit/discovering-and-configuring-accessories),
[ASDiscoveryDescriptor](https://developer.apple.com/documentation/accessorysetupkit/asdiscoverydescriptor).
