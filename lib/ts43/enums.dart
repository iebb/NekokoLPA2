// TS.43 enumerations, ported from `ts43-go/ts43/constants.go`.

/// ODSA operation names.
class Operation {
  final String value;
  const Operation(this.value);

  static const check = Operation('CheckEligibility');
  static const tempToken = Operation('AcquireTemporaryToken');
  static const manage = Operation('ManageSubscription');
  static const acquireConf = Operation('AcquireConfiguration');
  static const none = Operation('');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is Operation && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// operation_type query values.
class OperationType {
  final int value;
  const OperationType(this.value);

  static const omit = OperationType(-1);
  static const samsungD2DTransfer = OperationType(0);
  static const transferSubscription = OperationType(3);
  static const updateSubscription = OperationType(4);

  String get text => value.toString();
}

enum SimType { esim, psim }

class EntitlementChannel {
  final String value;
  const EntitlementChannel(this.value);
  static const google = EntitlementChannel('google');
  static const samsung = EntitlementChannel('samsung');
  static const none = EntitlementChannel('');

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is EntitlementChannel && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// TS.43 transfer types. Only values that affect the client are named; other
/// non-zero values fall back to the ordinary TS.43 auth-token flow.
class TransferType {
  static const int disabled = 0;
  static const int temporaryToken = 2;
  static const int reusableActivationCode = 3;
  static const int ts43V8 = 6;
  static const int oldTerminalIds = 7;
  static const int temporaryTokenOldTerminalIds = 9;
  static const int temporaryTokenVariant11 = 11;

  /// Whether [t] uses the source-side credential path.
  static bool isSourceCredential(int t) =>
      t == reusableActivationCode || t == ts43V8;

  /// String form ('' when disabled).
  static String text(int t) => t == disabled ? '' : t.toString();

  static bool usesTemporaryToken(int t) {
    switch (t) {
      case temporaryToken:
      case temporaryTokenOldTerminalIds:
      case temporaryTokenVariant11:
        return true;
      default:
        return false;
    }
  }
}

class OperationResult {
  static const int unknown = 0;
  static const int success = 1;
  static int parse(String? text) => _enumInt(text, unknown);
}

class AppEligibility {
  static const int unknown = -1;
  static const int enabled = 1;
  static int parse(String? text) => _enumInt(text, unknown);
}

class SubscriptionResult {
  static const int unknown = 0;
  static const int continueToWebsheet = 1;
  static const int downloadProfile = 2;
  static const int done = 3;
  static const int delayedDownload = 4;
  static const int dismiss = 5;
  static const int deleteProfileInUse = 6;
  static const int redownloadableProfileMandatory = 7;
  static const int requiresUserInput = 8;
  static int parse(String? text) => _enumInt(text, unknown);
}

class ServiceStatus {
  static const int unknown = 0;
  static const int activated = 1;
  static const int activating = 2;
  static const int deactivated = 3;
  static const int deactivatedNoReuse = 4;
  static int parse(String? text) => _enumInt(text, unknown);
}

class MessageButton {
  static const int unknown = -1;
  static const int rejected = 0;
  static const int accepted = 1;
  static String text(int b) => b == unknown ? '' : b.toString();
}

int _enumInt(String? text, int fallback) {
  if (text == null) return fallback;
  final s = text.trim();
  if (s.isEmpty) return fallback;
  return int.tryParse(s) ?? fallback;
}
