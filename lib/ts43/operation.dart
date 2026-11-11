import 'enums.dart';
import 'google_request.dart';
import 'request.dart';
import 'samsung_request.dart';
import 'types.dart';

/// Channel-aware operation dispatch. Ported from `ts43-go/ts43/operation.go`.

OdsaOperation temporaryTokenOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungTemporaryTokenOperation(source);
  }
  return googleTemporaryTokenOperation(e, target);
}

OdsaOperation checkEligibilityOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungCheckEligibilityOperation(source, target);
  }
  return googleCheckEligibilityOperation(e, target);
}

Device manageSubscriptionRequestDevice(
  Entitlement e,
  Device source,
  Device target,
) {
  if (TransferType.isSourceCredential(e.transferType) ||
      e.transferType == TransferType.temporaryToken) {
    return source;
  }
  return target;
}

OdsaOperation manageSubscriptionOperation(
  Entitlement e,
  Device source,
  Device target,
  UserInputResult answer,
) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungManageSubscriptionOperation(e, source, target, answer);
  }
  return googleManageSubscriptionOperation(e, source, target, answer);
}

Device acquireConfigurationRequestDevice(
  Entitlement e,
  Device source,
  Device target,
) {
  if (TransferType.isSourceCredential(e.transferType)) {
    return source;
  }
  return target;
}

OdsaOperation acquireConfigurationOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungAcquireConfigurationOperation(e, source, target);
  }
  return googleAcquireConfigurationOperation(e, source, target);
}

OdsaOperation updateSubscriptionOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungUpdateSubscriptionOperation(source, target);
  }
  return googleUpdateSubscriptionOperation(e, source, target);
}

OdsaOperation activationConfigurationOperation(Entitlement e, Device target) {
  if (e.channel == EntitlementChannel.samsung) {
    return samsungActivationConfigurationOperation(target);
  }
  return googleActivationConfigurationOperation(e, target);
}
