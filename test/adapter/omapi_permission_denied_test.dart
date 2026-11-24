import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/euicc_adapter.dart';
import 'package:nlpa2/adapter/omapi/omapi_adapter.dart';
import 'package:nlpa2/utils/error_codes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const native = MethodChannel('ee.nekoko.omapi_plugin');
  const aid = 'A0000005591010FFFFFFFF8900000100';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(native, null));

  test('a refused AID is reported as access denied, without a retry', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(native, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'connect' => {'success': true, 'atr': ''},
        'openChannel' => throw PlatformException(
          code: 'SECURITY_EXCEPTION',
          message:
              'Access denied: Restricted AID is not allowed in UICC terminal',
        ),
        _ => true,
      };
    });
    final adapter = OmapiAdapter();
    await adapter.connect(
      Reader(id: 'omapi:SIM1', name: 'SIM 1', source: adapter),
    );
    await expectLater(
      adapter.openChannel(aids: [aid]),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION,
        ),
      ),
    );
    // One attempt, and no cleanup or retry after the refusal.
    expect(calls.where((m) => m == 'openChannel'), hasLength(1));
    expect(calls.last, 'openChannel');
    await adapter.disconnect();
  });
}
