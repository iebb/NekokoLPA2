import 'package:flutter/material.dart';

import '../adapter/ble/ble_adapter.dart';
import '../adapter/ble/linklan_adapter.dart';
import '../models/euicc_profile.dart';
import 'plugin_base.dart';

/// Adds the Linksfield / Linklan Bluetooth reader (`BLE-eSIM-XXXXXXXX`).
///
/// The card speaks LPAd rather than raw APDUs: the adapter handles the PSK
/// handshake, the AES-CCM session and the SCARD bridge, so from the rest of the
/// app it behaves like any other reader.
class LinklanPlugin extends ProfilePlugin {
  static final BleReaderKind kind = BleReaderKind(
    id: 'linklan',
    label: 'Linklan',
    matches: (displayName, advertisedName) =>
        LinklanAdapter.isDeviceName(displayName) ||
        LinklanAdapter.isDeviceName(advertisedName),
    createAdapter: LinklanAdapter.new,
    icon: Icons.sim_card_outlined,
    // The password is stored per card, so use the advertised BLE-eSIM name when
    // the platform reports a generic one.
    readerName: (displayName, advertisedName) =>
        LinklanAdapter.isDeviceName(displayName)
        ? displayName
        : advertisedName.trim(),
    scanKeywords: const ['BLE-eSIM'],
    // The first command after connecting authenticates, so the card needs its
    // six-digit password; it defaults to the last six digits of the EID and the
    // adapter asks for it on first use.
    scanServiceUuids: const [LinklanProtocol.serviceUuid],
  );

  @override
  String get id => 'linklan';

  @override
  String get name => 'Linklan';

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  List<BleReaderKind> get bleReaderKinds => [kind];
}
