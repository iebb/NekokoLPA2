import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/logic/profile_state_transition.dart';
import 'package:nlpa2/utils/apdu_exception.dart';
import 'package:nlpa2/utils/error_codes.dart';

void main() {
  group('ProfileStateTransition', () {
    test(
      'verifies an acknowledged command from a fresh profile list',
      () async {
        final order = <String>[];
        final transition = ProfileStateTransition(
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: true,
          submit: (attempt) async => order.add('submit:$attempt'),
          reconnect: () async => order.add('reconnect'),
          readActualState: () async {
            order.add('read');
            return true;
          },
          isTransient: _isTransientBluetoothError,
        );

        expect(order, ['submit:1', 'read']);
        expect(result.actualEnabled, isTrue);
        expect(result.commandAttempts, 1);
        expect(result.verificationAttempts, 1);
      },
    );

    test(
      'lost command response verifies applied state without replaying command',
      () async {
        final order = <String>[];
        final transition = ProfileStateTransition(
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: true,
          submit: (attempt) async {
            order.add('submit:$attempt');
            throw AppException(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT);
          },
          reconnect: () async => order.add('reconnect'),
          readActualState: () async {
            order.add('read');
            return true;
          },
          isTransient: _isTransientBluetoothError,
        );

        expect(order, ['submit:1', 'reconnect', 'read']);
        expect(result.actualEnabled, isTrue);
        expect(result.commandAttempts, 1);
        expect(result.verificationAttempts, 1);
      },
    );

    test(
      'replays only after bounded fresh lists prove command was not applied',
      () async {
        final order = <String>[];
        var reads = 0;
        final transition = ProfileStateTransition(
          maxCommandAttempts: 2,
          maxVerificationAttempts: 2,
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: true,
          submit: (attempt) async {
            order.add('submit:$attempt');
            if (attempt == 1) {
              throw AppException(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED);
            }
          },
          reconnect: () async => order.add('reconnect'),
          readActualState: () async {
            reads++;
            order.add('read:$reads');
            return reads >= 3;
          },
          isTransient: _isTransientBluetoothError,
        );

        expect(order, [
          'submit:1',
          'reconnect',
          'read:1',
          'read:2',
          'reconnect',
          'submit:2',
          'read:3',
        ]);
        expect(result.actualEnabled, isTrue);
        expect(result.commandAttempts, 2);
        expect(result.verificationAttempts, 3);
      },
    );

    test(
      'reconnects and relists after a transient verification failure',
      () async {
        final order = <String>[];
        var reads = 0;
        final transition = ProfileStateTransition(
          maxVerificationAttempts: 2,
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: false,
          submit: (attempt) async => order.add('submit:$attempt'),
          reconnect: () async => order.add('reconnect'),
          readActualState: () async {
            reads++;
            order.add('read:$reads');
            if (reads == 1) {
              throw AppException(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT);
            }
            return false;
          },
          isTransient: _isTransientBluetoothError,
        );

        expect(order, ['submit:1', 'read:1', 'reconnect', 'read:2']);
        expect(result.actualEnabled, isFalse);
        expect(result.commandAttempts, 1);
        expect(result.verificationAttempts, 2);
      },
    );

    test('an unknown command outcome is verified but never replayed', () async {
      var submits = 0;
      var reads = 0;
      var reconnects = 0;
      final transition = ProfileStateTransition(
        maxVerificationAttempts: 2,
        verificationDelay: Duration.zero,
      );

      await expectLater(
        transition.run(
          targetEnabled: true,
          submit: (_) async {
            submits++;
            throw const ProfileStateCommandOutcomeUnknown('response lost');
          },
          reconnect: () async => reconnects++,
          readActualState: () async {
            reads++;
            return false;
          },
          isTransient: _isTransientBluetoothError,
        ),
        throwsA(
          isA<ProfileStateVerificationException>()
              .having((error) => error.actualEnabled, 'actualEnabled', false)
              .having((error) => error.commandAttempts, 'commandAttempts', 1)
              .having(
                (error) => error.lastError,
                'lastError',
                isA<ProfileStateCommandOutcomeUnknown>(),
              ),
        ),
      );

      expect(submits, 1);
      expect(reads, 2);
      expect(reconnects, 0);
    });

    test(
      'an unknown command outcome rides out transient reads without reconnecting',
      () async {
        var submits = 0;
        var reads = 0;
        var reconnects = 0;
        final transition = ProfileStateTransition(
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: true,
          submit: (_) async {
            submits++;
            throw const ProfileStateCommandOutcomeUnknown('response lost');
          },
          reconnect: () async => reconnects++,
          readActualState: () async {
            if (++reads == 1) {
              throw AppException(AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED);
            }
            return true;
          },
          isTransient: _isTransientBluetoothError,
        );

        expect(result.actualEnabled, isTrue);
        expect(result.commandAttempts, 1);
        expect(submits, 1);
        expect(reads, 2);
        expect(reconnects, 0);
      },
    );

    test(
      'propagates transport error when no verification read succeeds',
      () async {
        final firstFailure = AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        );
        final lastFailure = AppException(AppErrorCode.ERROR_BLUETOOTH_TIMEOUT);
        var submissions = 0;
        var reads = 0;
        var reconnects = 0;
        final transition = ProfileStateTransition(
          maxCommandAttempts: 2,
          maxVerificationAttempts: 6,
          verificationDelay: Duration.zero,
        );

        await expectLater(
          transition.run(
            targetEnabled: true,
            submit: (_) async => submissions++,
            reconnect: () async => reconnects++,
            readActualState: () async {
              reads++;
              throw reads == 1 ? firstFailure : lastFailure;
            },
            isTransient: _isTransientBluetoothError,
          ),
          throwsA(same(lastFailure)),
        );

        expect(submissions, 1, reason: 'unknown state must not be replayed');
        expect(reads, 2);
        expect(reconnects, 1);
      },
    );

    test(
      'card busy is replayed only after fresh reads stay unchanged',
      () async {
        final order = <String>[];
        var reads = 0;
        final transition = ProfileStateTransition(
          maxCommandAttempts: 2,
          maxVerificationAttempts: 2,
          verificationDelay: Duration.zero,
        );

        final result = await transition.run(
          targetEnabled: true,
          submit: (attempt) async {
            order.add('submit:$attempt');
            if (attempt == 1) throw CardBusyException('busy');
          },
          reconnect: () async => order.add('reconnect'),
          readActualState: () async {
            reads++;
            order.add('read:$reads');
            return reads >= 3;
          },
          isTransient: (error) =>
              error is CardBusyException || _isTransientBluetoothError(error),
        );

        expect(order, [
          'submit:1',
          'reconnect',
          'read:1',
          'read:2',
          'reconnect',
          'submit:2',
          'read:3',
        ]);
        expect(result.commandAttempts, 2);
      },
    );

    test(
      'never substitutes the requested state for independently read state',
      () async {
        final delays = <Duration>[];
        var submissions = 0;
        var reads = 0;
        var reconnects = 0;
        final transition = ProfileStateTransition(
          maxCommandAttempts: 2,
          maxVerificationAttempts: 2,
          verificationDelay: const Duration(milliseconds: 25),
          delay: (duration) async => delays.add(duration),
        );

        Object? caught;
        try {
          await transition.run(
            targetEnabled: true,
            submit: (_) async => submissions++,
            reconnect: () async => reconnects++,
            readActualState: () async {
              reads++;
              return false;
            },
            isTransient: _isTransientBluetoothError,
          );
        } catch (error) {
          caught = error;
        }

        expect(caught, isA<ProfileStateVerificationException>());
        final failure = caught! as ProfileStateVerificationException;
        expect(failure.targetEnabled, isTrue);
        expect(failure.actualEnabled, isFalse);
        expect(failure.commandAttempts, 2);
        expect(failure.verificationAttempts, 4);
        expect(submissions, 2);
        expect(reads, 4);
        expect(
          reconnects,
          1,
          reason: 'only the command replay needs reconnect',
        );
        expect(delays, const [
          Duration(milliseconds: 25),
          Duration(milliseconds: 25),
        ]);
      },
    );

    test(
      'treats a missing profile as unverified and remains bounded',
      () async {
        final transition = ProfileStateTransition(
          maxCommandAttempts: 1,
          maxVerificationAttempts: 2,
          verificationDelay: Duration.zero,
        );
        var reads = 0;

        await expectLater(
          transition.run(
            targetEnabled: false,
            submit: (_) async {},
            reconnect: () async {},
            readActualState: () async {
              reads++;
              return null;
            },
            isTransient: _isTransientBluetoothError,
          ),
          throwsA(
            isA<ProfileStateVerificationException>()
                .having((error) => error.actualEnabled, 'actualEnabled', isNull)
                .having(
                  (error) => error.verificationAttempts,
                  'verificationAttempts',
                  2,
                ),
          ),
        );
        expect(reads, 2);
      },
    );

    test(
      'propagates permanent command failures without reconnect or replay',
      () async {
        final permanent = AppException(AppErrorCode.ERROR_TRANSACTION_FAILED);
        var reconnects = 0;
        var reads = 0;
        final transition = ProfileStateTransition(
          verificationDelay: Duration.zero,
        );

        await expectLater(
          transition.run(
            targetEnabled: true,
            submit: (_) async => throw permanent,
            reconnect: () async => reconnects++,
            readActualState: () async {
              reads++;
              return true;
            },
            isTransient: _isTransientBluetoothError,
          ),
          throwsA(same(permanent)),
        );

        expect(reconnects, 0);
        expect(reads, 0);
      },
    );

    test(
      'propagates permanent verification failures without command replay',
      () async {
        final permanent = AppException(AppErrorCode.ERROR_TRANSACTION_FAILED);
        var submissions = 0;
        var reconnects = 0;
        final transition = ProfileStateTransition(
          verificationDelay: Duration.zero,
        );

        await expectLater(
          transition.run(
            targetEnabled: true,
            submit: (_) async => submissions++,
            reconnect: () async => reconnects++,
            readActualState: () async => throw permanent,
            isTransient: _isTransientBluetoothError,
          ),
          throwsA(same(permanent)),
        );

        expect(submissions, 1);
        expect(reconnects, 0);
      },
    );
  });
}

bool _isTransientBluetoothError(Object error) {
  if (error is! AppException) return false;

  return switch (error.code) {
    AppErrorCode.ERROR_BLUETOOTH_TIMEOUT ||
    AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED ||
    AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED ||
    AppErrorCode.ERROR_BLUETOOTH_DISABLED => true,
    _ => false,
  };
}
