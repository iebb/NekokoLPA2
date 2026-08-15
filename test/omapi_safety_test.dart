import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/omapi/omapi_safety.dart';
import 'package:nlpa2/utils/error_codes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.omapi.safety');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('healthy invocation returns native result', () async {
    final latch = OmapiSafetyLatch();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'ok');

    expect(await latch.invoke<String>(channel, 'transmit'), 'ok');
    expect(latch.isPoisoned, isFalse);
  });

  test('native corruption latches and blocks every later OMAPI call', () async {
    final latch = OmapiSafetyLatch();
    var nativeCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          nativeCalls++;
          throw PlatformException(
            code: omapiSessionCorruptedCode,
            message: omapiRebootRequiredMessage,
          );
        });

    await expectLater(
      latch.invoke<void>(channel, 'closeChannel'),
      throwsA(isA<PlatformException>()),
    );
    await expectLater(
      latch.invoke<void>(channel, 'reset'),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppErrorCode.ERROR_OMAPI_SESSION_CORRUPTED,
        ),
      ),
    );
    expect(nativeCalls, 1, reason: 'poisoned reset/reconnect must stay local');
  });

  test('profile switch is never retried after submission or corruption', () {
    const ordinary = FormatException('temporary');
    final corrupted = PlatformException(code: omapiSessionCorruptedCode);

    expect(
      canAutomaticallyRetryProfileSwitch(ordinary, commandSubmitted: false),
      isTrue,
    );
    expect(
      canAutomaticallyRetryProfileSwitch(ordinary, commandSubmitted: true),
      isFalse,
    );
    expect(
      canAutomaticallyRetryProfileSwitch(corrupted, commandSubmitted: false),
      isFalse,
    );
  });

  test('wrapped native corruption remains recognizable', () {
    final wrapped = AppException(
      AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED,
      originalError: PlatformException(code: omapiSessionCorruptedCode),
    );

    expect(isOmapiSessionCorruptedError(wrapped), isTrue);
  });
}
