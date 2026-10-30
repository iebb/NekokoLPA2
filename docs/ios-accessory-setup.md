# Bluetooth reader setup on iOS

On iOS/iPadOS 18 or later the Bluetooth reader button uses AccessorySetupKit
to show Apple's accessory discovery and authorization sheet. Android, older
iOS versions, simulators, and other platforms keep their existing discovery
flow. Cancelling the system sheet does not start a general Bluetooth scan or
request Bluetooth/location permissions.

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

The host declares Bluetooth support, names and service UUIDs in Info.plist.
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

References: [AccessorySetupKit](https://developer.apple.com/documentation/accessorysetupkit),
[Discovering and configuring accessories](https://developer.apple.com/documentation/accessorysetupkit/discovering-and-configuring-accessories),
[ASDiscoveryDescriptor](https://developer.apple.com/documentation/accessorysetupkit/asdiscoverydescriptor).
