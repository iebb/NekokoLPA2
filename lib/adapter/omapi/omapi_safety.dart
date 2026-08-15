import 'package:flutter/services.dart';

import '../../utils/error_codes.dart';

const String omapiSessionCorruptedCode = 'OMAPI_SESSION_CORRUPTED';
const String omapiProcessHandoffPendingReason =
    'OMAPI same-process engine handoff is still cleaning up';
const String omapiRebootRequiredMessage =
    'SIM/eSIM channel became invalid during the profile operation. The operation may already have taken effect. Restart the device, reopen the app, and refresh profile status before retrying.';

bool isOmapiProcessHandoffPendingError(Object error) {
  if (error is! PlatformException || error.code != omapiSessionCorruptedCode) {
    return false;
  }
  final details = error.details;
  return details is Map &&
      details['reason'] == omapiProcessHandoffPendingReason;
}

bool isOmapiSessionCorruptedError(Object error) {
  if (error is PlatformException) {
    return error.code == omapiSessionCorruptedCode &&
        !isOmapiProcessHandoffPendingError(error);
  }
  if (error is AppException) {
    return error.code == AppErrorCode.ERROR_OMAPI_SESSION_CORRUPTED ||
        (error.originalError is Object &&
            isOmapiSessionCorruptedError(error.originalError as Object));
  }
  return false;
}

bool canAutomaticallyRetryProfileSwitch(
  Object error, {
  required bool commandSubmitted,
}) => !commandSubmitted && !isOmapiSessionCorruptedError(error);

class OmapiChannelOwnershipTracker {
  int _nextToken = 0;
  final Map<int, int> _owners = {};

  int claim(int channelId) {
    final token = ++_nextToken;
    _owners[channelId] = token;
    return token;
  }

  int? currentToken(int channelId) => _owners[channelId];

  bool owns(int channelId, int? token) =>
      token != null && _owners[channelId] == token;

  bool releaseIfOwned(int channelId, int? token) {
    if (!owns(channelId, token)) return false;
    _owners.remove(channelId);
    return true;
  }

  void clear() => _owners.clear();
}

class OmapiSafetyLatch {
  PlatformException? _failure;

  bool get isPoisoned => _failure != null;

  void ensureAvailable() {
    final failure = _failure;
    if (failure != null) {
      throw AppException(
        AppErrorCode.ERROR_OMAPI_SESSION_CORRUPTED,
        message: failure.message ?? omapiRebootRequiredMessage,
        originalError: failure,
      );
    }
  }

  Future<T> invoke<T>(
    MethodChannel channel,
    String method, [
    dynamic arguments,
  ]) async {
    ensureAvailable();
    try {
      return await channel.invokeMethod<T>(method, arguments) as T;
    } on PlatformException catch (error) {
      if (isOmapiProcessHandoffPendingError(error)) {
        throw PlatformException(
          code: 'NOT_CONNECTED',
          message: 'OMAPI lifecycle handoff is still completing',
          details: error.details,
        );
      }
      if (error.code == omapiSessionCorruptedCode) {
        _failure ??= error;
      }
      rethrow;
    }
  }
}
