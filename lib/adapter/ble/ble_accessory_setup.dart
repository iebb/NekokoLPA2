import 'package:ble/ble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ble_adapter.dart';
import 'ble_manager.dart';

/// System authorization on iOS 18+, without starting a general Bluetooth scan.
class BleAccessorySetup {
  BleAccessorySetup({
    MethodChannel channel = const MethodChannel('ble/accessory_setup'),
    Future<String?> Function(String id)? resolveName,
  }) : _channel = channel,
       _resolveName = resolveName ?? _peripheralName;

  static final instance = BleAccessorySetup();
  final MethodChannel _channel;
  final Future<String?> Function(String id) _resolveName;

  Future<bool> get isSupported async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Each filter combines a service with a name. A name alone is insufficient
  /// for ASK. Plugin filters are checked against the host's Info.plist natively.
  static List<Map<String, String>> get filters => [
    _filter(BleAdapterType.redBle2, '4553', 'ESTKme RED'),
    _filter(BleAdapterType.redBle, '4553', 'ESTKme'),
    for (final type in [
      BleAdapterType.glocalMe,
      BleAdapterType.nineEsim,
      BleAdapterType.simLink,
    ])
      _filter(type, '6E400001-B5A3-F393-E0A9-E50E24DCCA9E', switch (type) {
        BleAdapterType.glocalMe => 'GlocalMe',
        BleAdapterType.nineEsim => '9eSIM',
        _ => 'eSIM_Writer',
      }),
    _filter(
      BleAdapterType.beeSim,
      '0000AE30-0000-1000-8000-00805F9B34FB',
      'BeeSIM',
    ),
    for (final kind in BleAdapterType.kinds)
      for (final service in kind.scanServiceUuids)
        for (final name in kind.accessorySetupNames ?? kind.scanKeywords)
          _filter(kind.type, service.toUpperCase(), name),
  ];

  static Map<String, String> _filter(
    BleAdapterType type,
    String service,
    String name,
  ) => {
    'type': type.id,
    'label': type.label,
    'serviceUuid': service,
    'nameSubstring': name,
  };

  Future<List<BleReaderInfo>> authorizedReaders() async {
    final values = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'getAccessories',
      filters,
    );
    final readers = <BleReaderInfo>[];
    for (final value in values ?? <Map<dynamic, dynamic>>[]) {
      readers.add(await _reader(value));
    }
    return readers;
  }

  /// null is cancellation, and must not trigger a legacy scan or permission UI.
  Future<BleReaderInfo?> pickReader() async {
    final value = await _channel.invokeMapMethod<dynamic, dynamic>(
      'pickAccessory',
      filters,
    );
    return value == null ? null : _reader(value);
  }

  Future<BleReaderInfo> _reader(Map<dynamic, dynamic> value) async {
    final id = value['id'];
    final type = BleAdapterType.tryFromId(value['type'] as String?);
    if (id is! String || id.isEmpty || type == null) {
      throw const FormatException('Invalid Bluetooth accessory identity');
    }
    // The product label (and a user-renamed ASK display name) is not the BLE
    // name. TYBLE derives its authentication PIN from the device's full name.
    final peripheralName = await _resolveName(id);
    if (peripheralName == null || peripheralName.trim().isEmpty) {
      throw const FormatException('Bluetooth reader name is unavailable');
    }
    final detectedType = BleAdapterType.fromDeviceNames(
      displayName: peripheralName,
      advertisedName: peripheralName,
    );
    final readerType = detectedType ?? type;
    final readerName = BleAdapterType.kindOf(readerType)?.readerName;
    return BleReaderInfo(
      id: id,
      name: readerName?.call(peripheralName, peripheralName) ?? peripheralName,
      type: readerType,
    );
  }

  static Future<String?> _peripheralName(String id) async {
    // Only initialize CoreBluetooth after the system has authorized a device.
    await Ble.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 10));
    return const MethodChannel(
      'flutter_blue_plus/methods',
    ).invokeMethod<String>('getPeripheralName', {'remote_id': id});
  }
}
