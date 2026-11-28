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
    // Decimal names, plus hex names the Customize rename can produce (A-F,
    // either case).
    for (final name in [
      'Xesim123456',
      ' xesim000184 ',
      'Xesim12345A',
      'XesimABCDEF',
      'xesimdeadbe',
    ]) {
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
    // Too short, too long, and non-hex letters (G-L) stay unrecognized.
    for (final name in ['Xesim12345', 'Xesim1234567', 'XesimGHIJKL']) {
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

  test('prefers the advertised name over a stale cached platform name', () {
    // After a Customize rename the platform can still report the old name as
    // platformName while the scan advertises the new one. The auth key is built
    // from the name's last two characters, so the live advertised name wins.
    final info = BleReaderInfo.fromScanResult(
      ScanResult(
        device: _NamedBluetoothDevice('Xesim123456'),
        advertisementData: AdvertisementData(
          advName: 'Xesim654321',
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
    expect(info.readerName, 'xesim: Xesim654321|device');
  });
}

class _NamedBluetoothDevice extends Fake implements BluetoothDevice {
  _NamedBluetoothDevice(this.platformName);

  @override
  final DeviceIdentifier remoteId = DeviceIdentifier('device');

  @override
  final String platformName;
}
