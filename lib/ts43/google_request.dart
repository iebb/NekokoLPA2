import 'enums.dart';
import 'request.dart';
import 'types.dart';

/// Google-channel ODSA operation builders. Ported from
/// `ts43-go/ts43/google_request.go`.

OdsaOperation googleTemporaryTokenOperation(Entitlement e, Device target) {
  final op = OdsaOperation(
    operation: Operation.tempToken,
    operationType: OperationType.omit,
    operationTargets: const [Operation.manage, Operation.acquireConf],
  );
  if (_googleIncludeTargetTerminalIdentity(e)) {
    _setGoogleTargetTerminalFields(op, target, true);
  }
  return op;
}

OdsaOperation googleCheckEligibilityOperation(Entitlement e, Device target) {
  final op = OdsaOperation(
    operation: Operation.check,
    operationType: OperationType.omit,
  );
  if (_googleIncludeTargetTerminalIdentity(e)) {
    _setGoogleTargetTerminalFields(op, target, true);
  }
  return op;
}

OdsaOperation googleManageSubscriptionOperation(
  Entitlement e,
  Device source,
  Device target,
  UserInputResult answer,
) {
  final op = baseManageSubscriptionOperation(
    OperationType.transferSubscription,
    answer,
  );
  if (TransferType.isSourceCredential(e.transferType)) {
    op.targetTerminalId = target.imei;
    op.targetTerminalEid = target.eid;
  } else {
    op.terminalEid = target.eid;
    op.terminalIccid = target.iccid;
    if (_googleIncludeTargetTerminalIdentity(e)) {
      _setGoogleTargetTerminalFields(op, target, true);
    }
  }
  _addGoogleOldTerminalFields(op, e, source);
  return op;
}

OdsaOperation googleAcquireConfigurationOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  final op = OdsaOperation(
    operation: Operation.acquireConf,
    operationType: OperationType.omit,
  );
  if (TransferType.isSourceCredential(e.transferType)) {
    op.targetTerminalId = target.imei;
    op.targetTerminalEid = target.eid;
    op.oldTerminalEntitlementProto = oldTerminalEntitlementProtocol(source);
    return op;
  }
  op.terminalEid = target.eid;
  op.terminalIccid = target.iccid;
  if (_googleIncludeTargetTerminalIdentity(e)) {
    _setGoogleTargetTerminalFields(op, target, true);
  }
  return op;
}

OdsaOperation googleUpdateSubscriptionOperation(
  Entitlement e,
  Device source,
  Device target,
) {
  final op = OdsaOperation(
    operation: Operation.manage,
    operationType: OperationType.updateSubscription,
    terminalEid: target.eid,
    terminalIccid: target.iccid,
  );
  if (_googleIncludeTargetTerminalIdentity(e)) {
    _setGoogleTargetTerminalFields(op, target, true);
  }
  _addGoogleOldTerminalFields(op, e, source);
  return op;
}

OdsaOperation googleActivationConfigurationOperation(
  Entitlement e,
  Device target,
) {
  final op = OdsaOperation(
    operation: Operation.acquireConf,
    operationType: OperationType.omit,
    terminalEid: target.eid,
  );
  if (_googleIncludeTargetTerminalIdentity(e)) {
    _setGoogleTargetTerminalFields(op, target, true);
  }
  return op;
}

void _setGoogleTargetTerminalFields(
  OdsaOperation op,
  Device target,
  bool includeIdentity,
) {
  if (includeIdentity) {
    op.targetTerminalId = target.imei;
    op.targetTerminalEid = target.eid;
  }
  op.targetTerminalIccid = target.iccid;
  op.targetTerminalModel = target.model;
  op.targetTerminalSn = target.serialNumber;
  op.targetTerminalImeis = terminalImeis(target);
  op.targetTerminalEntitlementProto = entitlementProtocol(
    target.entitlementProtocol,
  );
}

void _addGoogleOldTerminalFields(
  OdsaOperation op,
  Entitlement e,
  Device source,
) {
  if (!_googleIncludeOldTerminalIds(e)) return;
  op.oldTerminalId = source.imei;
  op.oldTerminalIccid = source.iccid;
  op.oldTerminalEntitlementProto = oldTerminalEntitlementProtocol(source);
}

bool _googleIncludeTargetTerminalIdentity(Entitlement e) {
  switch (e.transferType) {
    case TransferType.temporaryToken:
    case TransferType.temporaryTokenVariant11:
      return e.setTargetTerminalFields;
    default:
      return true;
  }
}

bool _googleIncludeOldTerminalIds(Entitlement e) {
  if (!e.restrictOldTerminalFields) return true;
  switch (e.transferType) {
    case TransferType.oldTerminalIds:
    case TransferType.temporaryTokenOldTerminalIds:
      return true;
    default:
      return false;
  }
}

OdsaOperation baseManageSubscriptionOperation(
  OperationType operationType,
  UserInputResult answer,
) {
  return OdsaOperation(
    operation: Operation.manage,
    operationType: operationType,
    messageResponse: answer.response,
    messageButton: answer.button,
    messageButtonSet: answer.button != MessageButton.unknown,
  );
}
