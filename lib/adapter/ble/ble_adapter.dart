import 'package:flutter/widgets.dart';

import '../euicc_adapter.dart';

/// Marker shared by every adapter that communicates over Bluetooth LE.
abstract interface class BleAdapter {}

/// A Bluetooth reader type: the stable ID used in reader IDs and serialized
/// reader metadata, and the label shown for it.
///
/// The built-in types are below. A plugin adds others by registering a
/// [BleReaderKind]; until then their IDs are unknown here.
final class BleAdapterType {
  const BleAdapterType._(this.id, this.label);

  final String id;
  final String label;

  static const redBle = BleAdapterType._('red_ble', 'ESTKme');
  static const redBle2 = BleAdapterType._('red_ble2', 'ESTKme RED');
  static const glocalMe = BleAdapterType._('glocalme', 'GlocalMe');
  static const nineEsim = BleAdapterType._('nine_esim', '9eSIM');
  static const beeSim = BleAdapterType._('bee_sim', 'BeeSIM');
  static const simLink = BleAdapterType._('simlink', 'SimLink');

  static const List<BleAdapterType> builtIn = [
    redBle,
    redBle2,
    glocalMe,
    nineEsim,
    beeSim,
    simLink,
  ];

  static final Map<String, BleReaderKind> _kinds = {};

  /// Every type this build knows: the built-in ones, then plugin kinds.
  static List<BleAdapterType> get values => [
    ...builtIn,
    for (final kind in _kinds.values) kind.type,
  ];

  /// The kinds plugins registered, in registration order.
  static Iterable<BleReaderKind> get kinds => _kinds.values;

  /// Adds a plugin's reader kind; registering an ID again replaces it.
  static void register(BleReaderKind kind) => _kinds[kind.type.id] = kind;

  /// The plugin kind behind [type], or null for a built-in type.
  static BleReaderKind? kindOf(BleAdapterType type) => _kinds[type.id];

  static final RegExp _nineEsimDeviceNamePattern = RegExp(
    r'^9eSIM[0-9a-f]{6}$',
    caseSensitive: false,
  );

  static BleAdapterType fromId(String? id) =>
      tryFromId(id) ?? BleAdapterType.redBle;

  static BleAdapterType? tryFromId(String? id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  static BleAdapterType? fromReaderId(String? readerId) {
    if (readerId == null) return null;
    final separator = readerId.indexOf(':');
    if (separator <= 0) return null;
    return tryFromId(readerId.substring(0, separator));
  }

  /// Identifies a supported reader from its platform and advertisement names.
  ///
  /// Plugin kinds are asked first: they recognize narrower name patterns than
  /// the built-in substring checks.
  static BleAdapterType? fromDeviceNames({
    required String displayName,
    required String advertisedName,
  }) {
    for (final kind in _kinds.values) {
      if (kind.matches(displayName, advertisedName)) return kind.type;
    }

    final lowerDisplayName = displayName.toLowerCase();
    final lowerAdvertisedName = advertisedName.toLowerCase();

    bool contains(String value) =>
        lowerDisplayName.contains(value) || lowerAdvertisedName.contains(value);

    if (contains('estkme red')) return BleAdapterType.redBle2;
    if (contains('glocal')) return BleAdapterType.glocalMe;
    if (_nineEsimDeviceNamePattern.hasMatch(displayName.trim()) ||
        _nineEsimDeviceNamePattern.hasMatch(advertisedName.trim())) {
      return BleAdapterType.nineEsim;
    }
    if (contains('beesim')) return BleAdapterType.beeSim;
    if (contains('esim_writer')) return BleAdapterType.simLink;
    if (contains('estkme')) return BleAdapterType.redBle;
    return null;
  }

  @override
  String toString() => 'BleAdapterType($id)';
}

/// A Bluetooth reader type a plugin adds: how to recognize, name, construct
/// and show it, and what a scan should look for to find it.
class BleReaderKind {
  BleReaderKind({
    required String id,
    required String label,
    required this.matches,
    required this.createAdapter,
    required this.icon,
    this.readerName,
    this.scanKeywords = const [],
    this.scanServiceUuids = const [],
    this.accessorySetupNames,
  }) : type = BleAdapterType._(id, label);

  final BleAdapterType type;

  /// Whether a reader advertising these names is of this kind.
  final bool Function(String displayName, String advertisedName) matches;

  final BaseAdapter Function() createAdapter;

  final IconData icon;

  /// The name a reader is listed, addressed and authenticated by, when that is
  /// not simply its display name.
  final String Function(String displayName, String advertisedName)? readerName;

  /// Advertised-name fragments the scan asks the platform to match.
  final List<String> scanKeywords;

  /// GATT service UUIDs, lower-case, that identify a reader in a scan.
  final List<String> scanServiceUuids;

  /// ASK name filters paired with [scanServiceUuids]. Defaults to scanKeywords.
  /// The iOS host must declare these names and services in its Info.plist.
  final List<String>? accessorySetupNames;
}
