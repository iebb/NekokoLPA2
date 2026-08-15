// ignore_for_file: constant_identifier_names
enum AppErrorCode {
  // Bluetooth related
  ERROR_BLUETOOTH_DISABLED,
  ERROR_BLUETOOTH_PERMISSION_DENIED,
  ERROR_BLUETOOTH_SCAN_FAILED,
  ERROR_BLUETOOTH_CONNECT_FAILED,
  ERROR_BLUETOOTH_TIMEOUT,
  ERROR_BLUETOOTH_SERVICE_NOT_FOUND,
  ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
  ERROR_BLUETOOTH_NOT_CONNECTED,

  // OMAPI related
  ERROR_OMAPI_NOT_SUPPORTED,
  ERROR_OMAPI_PERMISSION_DENIED,
  ERROR_OMAPI_SECURITYEXCEPTION,
  ERROR_OMAPI_READER_NOT_AVAILABLE,
  ERROR_OMAPI_CHANNEL_OPEN_FAILED,
  ERROR_OMAPI_TRANSMIT_FAILED,
  ERROR_OMAPI_SESSION_CORRUPTED,

  // Remote Reader related
  ERROR_REMOTE_CONNECTION_FAILED,
  ERROR_REMOTE_TIMEOUT,
  ERROR_REMOTE_AUTH_FAILED,
  ERROR_REMOTE_WRONG_PASSWORD,

  // Card related
  ERROR_CARD_NOT_PRESENT,
  ERROR_CARD_UNSUPPORTED,
  ERROR_CONDITION_OF_USE_NOT_SATISFIED,
  ERROR_APPLICATION_NOT_FOUND, // Generic AID failure (e.g. ISD-R)
  ERROR_ESTK_MAX_NOT_FOUND,

  // Generic
  ERROR_TRANSACTION_FAILED,
  ERROR_CHANNEL_OPEN_FAILED,
  ERROR_UNKNOWN,
}

class AppException implements Exception {
  final AppErrorCode code;
  final String? message;
  final dynamic originalError;

  AppException(this.code, {this.message, this.originalError});

  @override
  String toString() {
    String msg = "AppException: $code";
    if (message != null) msg += " ($message)";
    if (originalError != null) msg += "\nOriginal Error: $originalError";
    return msg;
  }
}
