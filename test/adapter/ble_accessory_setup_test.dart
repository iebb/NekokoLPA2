import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/ble/ble_accessory_setup.dart';
import 'package:nlpa2/adapter/ble/ble_adapter.dart';
import 'package:nlpa2/plugins/ty_ble_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/accessory_setup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  dynamic response;
  var resolutions = 0;
  var deviceName = '9eSIM12345678';
  late BleAccessorySetup setup;

  setUp(() {
    calls.clear();
    response = null;
    resolutions = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    BleAdapterType.register(TyBlePlugin.kind);
    setup = BleAccessorySetup(
      channel: channel,
      resolveName: (_) async {
        resolutions++;
        return deviceName;
      },
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return response;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('does not call the native setup channel on other platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await setup.isSupported, isFalse);
    expect(calls, isEmpty);
  });

  test('an old native plugin falls back through availability only', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await setup.isSupported, isFalse);
  });

  test(
    'cancellation never initializes Bluetooth or resolves a device',
    () async {
      expect(await setup.pickReader(), isNull);
      expect(calls.map((call) => call.method), ['pickAccessory']);
      expect(resolutions, 0);
    },
  );

  test(
    'uses the full BLE name and plugin type for B0 Plus authentication',
    () async {
      response = {
        'id': 'device-uuid',
        'type': 'ty_ble',
        'name': 'Renamed reader',
      };
      final reader = await setup.pickReader();
      expect(reader!.name, '9eSIM12345678');
      expect(reader.type, TyBlePlugin.kind.type);
      expect(reader.id, 'device-uuid');
    },
  );

  test(
    'recognizes RED when the system matched the broader ESTKme filter',
    () async {
      deviceName = 'ESTKme RED 1234';
      response = [
        {'id': 'device-uuid', 'type': 'red_ble', 'name': 'ESTKme'},
      ];
      final readers = await setup.authorizedReaders();
      expect(readers.single.type, BleAdapterType.redBle2);
      expect(readers.single.name, deviceName);
    },
  );

  test('does not guess a protocol for an invalid system identity', () async {
    response = {'id': 'device-uuid', 'type': 'unknown', 'name': 'Reader'};
    await expectLater(setup.pickReader(), throwsFormatException);
    expect(resolutions, 0);
  });

  test(
    'never substitutes the product label for a missing authentication name',
    () async {
      deviceName = '';
      response = {'id': 'device-uuid', 'type': 'ty_ble', 'name': 'TYBLE'};
      await expectLater(setup.pickReader(), throwsFormatException);
    },
  );

  test(
    'plugin ASK filters include both a service and all device name families',
    () {
      final filters = BleAccessorySetup.filters.where(
        (filter) => filter['type'] == 'ty_ble',
      );
      expect(filters.map((filter) => filter['nameSubstring']), [
        'SCT-BT',
        'TES-BT',
        '9eSIM',
      ]);
      expect(
        filters.every(
          (filter) =>
              filter['serviceUuid'] == '49535343-FE7D-4AE5-8FA9-9FAFD205E455',
        ),
        isTrue,
      );
    },
  );
}
