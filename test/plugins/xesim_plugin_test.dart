import 'package:ble/ble.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/ble/ble_adapter.dart';
import 'package:nlpa2/adapter/ble/ble_manager.dart';
import 'package:nlpa2/plugins/plugin_manager.dart';
import 'package:nlpa2/plugins/xesim_plugin.dart';

void main() {
  setUpAll(() {
    expect(PluginManager().hasPlugin('xesim'), isTrue);
  });

  final xesim = XesimPlugin.kind.type;

  test('detects Xesim names and nothing near them', () {
    for (final name in ['Xesim123456', ' xesim000184 ']) {
      expect(
        BleAdapterType.fromDeviceNames(displayName: name, advertisedName: ''),
        xesim,
        reason: name,
      );
      expect(
        BleAdapterType.fromDeviceNames(
          displayName: 'Bluetooth Device',
          advertisedName: name,
        ),
        xesim,
        reason: name,
      );
    }
    for (final name in ['Xesim12345', 'Xesim1234567', 'Xesim12345A']) {
      expect(
        BleAdapterType.fromDeviceNames(displayName: name, advertisedName: ''),
        isNot(xesim),
        reason: name,
      );
    }
  });

  test('the native scan keeps Xesim names', () {
    expect(XesimPlugin.kind.scanKeywords.any('Xesim123456'.contains), isTrue);
  });

  test('keeps the advertised name, which the PIN key is derived from', () {
    final info = BleReaderInfo.fromScanResult(
      ScanResult(
        device: _NamedBluetoothDevice('Bluetooth Device'),
        advertisementData: AdvertisementData(
          advName: 'Xesim123456',
          txPowerLevel: null,
          appearance: null,
          connectable: true,
          manufacturerData: const {},
          serviceData: const {},
          serviceUuids: const [],
        ),
        rssi: -50,
        timeStamp: DateTime(2026, 11, 23),
      ),
    );
    expect(info.type, xesim);
    expect(info.readerName, 'xesim: Xesim123456|device');
  });
}

class _NamedBluetoothDevice extends Fake implements BluetoothDevice {
  _NamedBluetoothDevice(this.platformName);

  @override
  final DeviceIdentifier remoteId = DeviceIdentifier('device');

  @override
  final String platformName;
}
