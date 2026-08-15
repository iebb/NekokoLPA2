import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/adapter/omapi/omapi_adapter.dart';
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

  test(
    'same-process handoff rejection stays temporary and does not latch',
    () async {
      final latch = OmapiSafetyLatch();
      var nativeCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            nativeCalls++;
            if (nativeCalls == 1) {
              throw PlatformException(
                code: omapiSessionCorruptedCode,
                message: omapiRebootRequiredMessage,
                details: const {
                  'rebootRequired': true,
                  'reason': omapiProcessHandoffPendingReason,
                },
              );
            }
            return 'ok';
          });

      await expectLater(
        latch.invoke<String>(channel, 'connect'),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'NOT_CONNECTED',
          ),
        ),
      );
      expect(latch.isPoisoned, isFalse);
      expect(await latch.invoke<String>(channel, 'connect'), 'ok');
      expect(nativeCalls, 2);
    },
  );

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

  test('eSTK reuse preserves the caller preferred AID', () {
    const estkPreferred = 'A06573746B6D65FFFF4953442D522030';
    const fallback = 'A0000005591010FFFFFFFF8900000100';

    expect(omapiPreferredAidReuseCandidates([estkPreferred, fallback]), [
      estkPreferred,
    ]);
    expect(omapiPreferredAidReuseCandidates([fallback, estkPreferred]), [
      fallback,
      estkPreferred,
    ]);
  });

  test('eSTK native open never duplicates an already tracked fallback', () {
    const estkPreferred = 'A06573746B6D65FFFF4953442D522030';
    const fallback = 'A0000005591010FFFFFFFF8900000100';

    expect(omapiNativeOpenCandidates([estkPreferred, fallback], [fallback]), [
      estkPreferred,
    ]);
    expect(omapiNativeOpenCandidates([estkPreferred, fallback], const []), [
      estkPreferred,
      fallback,
    ]);
    expect(
      omapiNativeOpenCandidates([fallback, estkPreferred], [estkPreferred]),
      [fallback, estkPreferred],
    );
  });

  test('stale handle cannot release a replacement channel with the same id', () {
    final ownership = OmapiChannelOwnershipTracker();
    final oldToken = ownership.claim(1);

    // Bulk cleanup invalidates every old Dart handle while the object may live on.
    ownership.clear();
    final replacementToken = ownership.claim(1);

    expect(ownership.owns(1, oldToken), isFalse);
    expect(ownership.owns(1, replacementToken), isTrue);
    expect(ownership.releaseIfOwned(1, oldToken), isFalse);
    expect(ownership.owns(1, replacementToken), isTrue);
    expect(ownership.releaseIfOwned(1, replacementToken), isTrue);
  });
}
