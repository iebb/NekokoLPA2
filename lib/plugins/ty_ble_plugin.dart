import 'package:flutter/material.dart';

import '../adapter/ble/ble_adapter.dart';
import '../adapter/ble/ty_ble_adapter.dart';
import '../adapter/ble/ty_ble_protocol.dart';
import '../models/euicc_profile.dart';
import 'plugin_base.dart';

/// Adds the TYBLE Bluetooth reader, including the eight-digit 9eSIM B0 Plus.
class TyBlePlugin extends ProfilePlugin {
  static final BleReaderKind kind = BleReaderKind(
    id: 'ty_ble',
    label: 'TYBLE',
    matches: (displayName, advertisedName) =>
        TYBLEProtocol.isDeviceName(displayName) ||
        TYBLEProtocol.isDeviceName(advertisedName),
    createAdapter: TYBLEAdapter.new,
    icon: Icons.key_rounded,
    // Authentication needs the UID even if the platform caches a generic name.
    readerName: (displayName, advertisedName) =>
        TYBLEProtocol.isDeviceName(displayName)
        ? displayName
        : advertisedName.trim(),
    scanKeywords: const ['SCT-BT', 'TES-BT'],
    accessorySetupNames: const ['SCT-BT', 'TES-BT', '9eSIM'],
    scanServiceUuids: const ['49535343-fe7d-4ae5-8fa9-9fafd205e455'],
  );

  @override
  String get id => 'ty_ble';

  @override
  String get name => 'TYBLE';

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  List<BleReaderKind> get bleReaderKinds => [kind];
}
