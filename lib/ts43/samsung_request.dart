import 'enums.dart';
import 'google_request.dart';
import 'request.dart';
import 'types.dart';

/// Samsung-channel ODSA operation builders. Ported from
/// `ts43-go/ts43/samsung_request.go`.

OdsaOperation samsungTemporaryTokenOperation(Device source) {
  return OdsaOperation(
    operation: Operation.tempToken,
    operationType: OperationType.omit,
    operationTargets: const [Operation.manage, Operation.acquireConf],
    terminalIccid: source.iccid,
  );
}

OdsaOperation samsungCheckEligibilityOperation(Device source, Device target) {
  return OdsaOperation(
    operation: Operation.check,
    operationType: OperationType.omit,
    terminalIccid: source.iccid,
    targetTerminalId: target.imei,
  );
}

OdsaOperation samsungManageSubscriptionOperation(
  Entitlement e,
  Device source,
  Device target,
  UserInputResult answer,
) {
  final op = baseManageSubscriptionOperation(
    _samsungManageSubscriptionOperationType(e.transferType),
    answer,
  );
  if (TransferType.isSourceCredential(e.transferType)) {
    op.targetTerminalId = target.imei;
    op.targetTerminalEid = target.eid;
    op.terminalIccid = source.iccid;
    op.targetTerminalIccid = target.iccid;
  } else {
    op.terminalEid = target.eid;
    op.terminalIccid = target.iccid;
    op.targetTerminalId = target.imei;
    op.targetTerminalIccid = target.iccid;
    if (_samsungDigitalizedTempToken4ff(e)) {
      op.terminalIccid = '';
    }
  }
  _addSamsungOldTerminalFields(op, source);
  return op;
}

OdsaOperation samsungAcquireConfigurationOperation(
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
    op.terminalEid = firstNonEmpty([source.eid, target.eid]);
    op.terminalIccid = source.iccid;
    op.targetTerminalIccid = target.iccid;
    return op;
  }
  op.terminalIccid = target.iccid;
  _setSamsungAcquireConfigurationEid(op, e, target);
  op.targetTerminalId = target.imei;
  op.targetTerminalIccid = target.iccid;
  return op;
}

OdsaOperation samsungUpdateSubscriptionOperation(Device source, Device target) {
  return OdsaOperation(
    operation: Operation.manage,
    operationType: OperationType.updateSubscription,
    terminalEid: target.eid,
    terminalIccid: target.iccid,
    targetTerminalId: target.imei,
    targetTerminalIccid: target.iccid,
    oldTerminalId: source.imei,
    oldTerminalIccid: source.iccid,
  );
}

OdsaOperation samsungActivationConfigurationOperation(Device target) {
  return OdsaOperation(
    operation: Operation.acquireConf,
    operationType: OperationType.omit,
    terminalEid: target.eid,
    targetTerminalId: target.imei,
    targetTerminalIccid: target.iccid,
  );
}

OperationType _samsungManageSubscriptionOperationType(int transferType) {
  switch (transferType) {
    case TransferType.reusableActivationCode:
    case TransferType.ts43V8:
    case TransferType.oldTerminalIds:
    case TransferType.temporaryTokenOldTerminalIds:
    case TransferType.temporaryTokenVariant11:
      return OperationType.transferSubscription;
    default:
      return OperationType.samsungD2DTransfer;
  }
}

bool _samsungDigitalizedTempToken4ff(Entitlement e) =>
    e.channel == EntitlementChannel.samsung &&
    e.transferType == TransferType.temporaryTokenOldTerminalIds &&
    e.useTempTokenConversion;

void _setSamsungAcquireConfigurationEid(
  OdsaOperation op,
  Entitlement e,
  Device target,
) {
  switch (e.transferType) {
    case TransferType.oldTerminalIds:
      op.terminalEid = '';
      op.targetTerminalEid = target.eid;
      break;
    default:
      op.terminalEid = target.eid;
      op.targetTerminalEid = '';
  }
}

void _addSamsungOldTerminalFields(OdsaOperation op, Device source) {
  op.oldTerminalId = source.imei;
  op.oldTerminalIccid = source.iccid;
}
