typedef ProfileStateTransitionSubmit = Future<void> Function(int attempt);
typedef ProfileStateTransitionReconnect = Future<void> Function();
typedef ProfileStateTransitionReadState = Future<bool?> Function();
typedef ProfileStateTransitionErrorClassifier = bool Function(Object error);
typedef ProfileStateTransitionDelay = Future<void> Function(Duration duration);

class ProfileStateTransitionResult {
  const ProfileStateTransitionResult({
    required this.commandAttempts,
    required this.verificationAttempts,
    required this.actualEnabled,
  });

  final int commandAttempts;
  final int verificationAttempts;
  final bool actualEnabled;
}

class ProfileStateVerificationException implements Exception {
  const ProfileStateVerificationException({
    required this.targetEnabled,
    required this.commandAttempts,
    required this.verificationAttempts,
    required this.actualEnabled,
    this.lastError,
  });

  final bool targetEnabled;
  final int commandAttempts;
  final int verificationAttempts;
  final bool? actualEnabled;
  final Object? lastError;

  @override
  String toString() {
    final observed = actualEnabled == null
        ? 'profile absent'
        : 'enabled=$actualEnabled';
    final cause = lastError == null ? '' : ', last error: $lastError';
    return 'Profile state did not converge to enabled=$targetEnabled '
        'after $commandAttempts command attempt(s) and '
        '$verificationAttempts verification attempt(s); '
        'last observed $observed$cause';
  }
}

/// Thrown by a submit callback when the command may already have taken effect
/// but its response was lost and the transport has discarded the stale
/// session. The transition then only verifies: no reconnect, no replay.
class ProfileStateCommandOutcomeUnknown implements Exception {
  const ProfileStateCommandOutcomeUnknown(this.cause);

  final Object cause;

  @override
  String toString() => 'Profile state command outcome unknown: $cause';
}

/// Coordinates an idempotent profile state command with independent reads.
///
/// A lost Bluetooth response makes the command outcome ambiguous. This helper
/// always reads the actual profile state before deciding whether the command
/// needs to be replayed. Each [submit] and [readActualState] callback must use
/// and close its own fresh logical channel.
class ProfileStateTransition {
  ProfileStateTransition({
    this.maxCommandAttempts = 2,
    this.maxVerificationAttempts = 6,
    this.maxTransientVerificationFailuresWithoutRead = 2,
    this.verificationDelay = const Duration(milliseconds: 750),
    ProfileStateTransitionDelay? delay,
  }) : assert(maxCommandAttempts > 0),
       assert(maxVerificationAttempts > 0),
       assert(maxTransientVerificationFailuresWithoutRead > 0),
       _delay = delay ?? Future<void>.delayed;

  final int maxCommandAttempts;
  final int maxVerificationAttempts;
  final int maxTransientVerificationFailuresWithoutRead;
  final Duration verificationDelay;
  final ProfileStateTransitionDelay _delay;

  Future<ProfileStateTransitionResult> run({
    required bool targetEnabled,
    required ProfileStateTransitionSubmit submit,
    required ProfileStateTransitionReconnect reconnect,
    required ProfileStateTransitionReadState readActualState,
    required ProfileStateTransitionErrorClassifier isTransient,
  }) async {
    var commandAttempts = 0;
    var verificationAttempts = 0;
    bool? lastObservedEnabled;
    Object? lastError;
    var verifyOnly = false;

    for (
      var commandAttempt = 1;
      commandAttempt <= maxCommandAttempts;
      commandAttempt++
    ) {
      commandAttempts = commandAttempt;
      var successfulVerificationReads = 0;
      var transientVerificationFailures = 0;
      Object? lastVerificationError;
      try {
        await submit(commandAttempt);
      } on ProfileStateCommandOutcomeUnknown catch (error) {
        lastError = error;
        verifyOnly = true;
      } catch (error) {
        if (!isTransient(error)) rethrow;
        lastError = error;
        await _reconnectIfPossible(reconnect, isTransient);
      }

      for (
        var verificationAttempt = 1;
        verificationAttempt <= maxVerificationAttempts;
        verificationAttempt++
      ) {
        if (verificationAttempt > 1) await _delay(verificationDelay);
        verificationAttempts++;

        try {
          final actualEnabled = await readActualState();
          successfulVerificationReads++;
          lastObservedEnabled = actualEnabled;
          if (actualEnabled == targetEnabled) {
            return ProfileStateTransitionResult(
              commandAttempts: commandAttempts,
              verificationAttempts: verificationAttempts,
              actualEnabled: actualEnabled!,
            );
          }
        } catch (error) {
          if (!isTransient(error)) rethrow;
          lastError = error;
          lastVerificationError = error;
          transientVerificationFailures++;
          if (successfulVerificationReads == 0 &&
              transientVerificationFailures >=
                  maxTransientVerificationFailuresWithoutRead) {
            rethrow;
          }
          if (!verifyOnly) await _reconnectIfPossible(reconnect, isTransient);
        }
      }

      // With no responsive fresh-session read, the card state is unknown. Do
      // not misreport this as an absent profile or replay an ambiguous command.
      if (successfulVerificationReads == 0 && lastVerificationError != null) {
        throw lastVerificationError;
      }

      if (verifyOnly) break;
      if (commandAttempt < maxCommandAttempts) {
        await _reconnectIfPossible(reconnect, isTransient);
      }
    }

    throw ProfileStateVerificationException(
      targetEnabled: targetEnabled,
      commandAttempts: commandAttempts,
      verificationAttempts: verificationAttempts,
      actualEnabled: lastObservedEnabled,
      lastError: lastError,
    );
  }

  Future<void> _reconnectIfPossible(
    ProfileStateTransitionReconnect reconnect,
    ProfileStateTransitionErrorClassifier isTransient,
  ) async {
    try {
      await reconnect();
    } catch (error) {
      if (!isTransient(error)) rethrow;
    }
  }
}
