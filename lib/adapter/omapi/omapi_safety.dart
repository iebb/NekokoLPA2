import 'package:flutter/services.dart';

import '../../utils/error_codes.dart';

const String omapiSessionCorruptedCode = 'OMAPI_SESSION_CORRUPTED';
const String omapiRebootRequiredMessage =
    'SIM/eSIM channel became invalid during the profile operation. The operation may already have taken effect. Restart the device, reopen the app, and refresh profile status before retrying.';

bool isOmapiSessionCorruptedError(Object error) {
  if (error is PlatformException) {
    return error.code == omapiSessionCorruptedCode;
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
      if (error.code == omapiSessionCorruptedCode) {
        _failure ??= error;
      }
      rethrow;
    }
  }
}
