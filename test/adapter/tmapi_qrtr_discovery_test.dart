import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/qrtr/qrtr_reader_adapter.dart';
import 'package:nlpa2/adapter/telephony/telephony_adapter.dart';
import 'package:nlpa2/settings/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('Telephony reader discovery', () {
    const channel = MethodChannel('ee.nekoko.telephony_plugin');
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    void mockSlots(List<Map<String, Object>> slots) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return switch (call.method) {
          'hasPrivilegedPermission' => true,
          'listSlots' => slots,
          _ => throw UnimplementedError(call.method),
        };
      });
    }

    Map<String, Object> slot({
      required int index,
      required bool isEuicc,
      required int simState,
    }) => {
      'slotIndex': index,
      'isEuicc': isEuicc,
      'simState': simState,
      'ports': [
        {'portIndex': 0, 'logicalSlotIndex': index},
      ],
    };

    test('hides an empty removable slot', () async {
      mockSlots([
        slot(index: 0, isEuicc: false, simState: 1), // SIM_STATE_ABSENT
        slot(index: 1, isEuicc: false, simState: 5), // SIM_STATE_READY
      ]);

      final readers = await TelephonyAdapter().listReaders();
      expect(readers.map((r) => r.name), ['TM Slot 2']);
    });

    test('keeps an eUICC whose slot reports no SIM', () async {
      mockSlots([slot(index: 1, isEuicc: true, simState: 1)]);

      final readers = await TelephonyAdapter().listReaders();
      expect(readers.map((r) => r.name), ['TM Slot 2|No SIM Card']);
    });
  });

  group('QRTR reader discovery', () {
    test('offers nothing when the modem cannot be reached', () async {
      final wasEnabled = AppSettings().enableQrtrConnector;
      await AppSettings().setEnableQrtrConnector(true);
      addTearDown(() => AppSettings().setEnableQrtrConnector(wasEnabled));

      // Off Android the bus cannot be opened at all, which stands in for a
      // modem that does not answer: no fallback reader may be offered.
      expect(await QrtrReaderAdapter().listReaders(), isEmpty);
    });
  });
}
