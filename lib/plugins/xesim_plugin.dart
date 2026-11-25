import 'package:flutter/material.dart';

import '../adapter/ble/ble_adapter.dart';
import '../adapter/ble/nble_sim_adapter.dart';
import '../models/euicc_profile.dart';
import 'plugin_base.dart';

/// Adds Xesim's X7 Bluetooth eSIM card, advertised as `Xesim` and six digits.
///
/// The card speaks the 9eSIM writer protocol (Nordic UART, the E0 3DES
/// challenge, counter + APDU + sum16 frames), and hardware testing confirmed it
/// also accepts the 9eSIM device commands, so it uses [NBLESimAdapter] as-is.
/// The six-digit PIN is issued per card by Xesim; the adapter asks for it when
/// the default is rejected and keeps it with the other writer passwords.
class XesimPlugin extends ProfilePlugin {
  static final RegExp _deviceNamePattern = RegExp(
    r'^Xesim[0-9]{6}$',
    caseSensitive: false,
  );

  static bool isDeviceName(String name) =>
      _deviceNamePattern.hasMatch(name.trim());

  static final BleReaderKind kind = BleReaderKind(
    id: 'xesim',
    label: 'Xesim',
    matches: (displayName, advertisedName) =>
        isDeviceName(displayName) || isDeviceName(advertisedName),
    createAdapter: () => NBLESimAdapter(),
    icon: Icons.sd_card_outlined,
    // The authentication key is derived from the last two digits of the name,
    // so keep the advertised name when the platform caches a generic one.
    readerName: (displayName, advertisedName) =>
        isDeviceName(displayName) ? displayName.trim() : advertisedName.trim(),
    scanKeywords: const ['Xesim'],
    scanServiceUuids: const ['6e400001-b5a3-f393-e0a9-e50e24dcca9e'],
  );

  @override
  String get id => 'xesim';

  @override
  String get name => 'Xesim';

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  List<BleReaderKind> get bleReaderKinds => [kind];
}
