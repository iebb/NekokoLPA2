import 'dart:convert';

import 'sim/aka.dart';
import 'sim/identity.dart';
import 'constants.dart';
import 'enums.dart';
import 'types.dart';

/// Service-entitlement request fields. Ported from `ts43-go/ts43/request.go`.
class ServiceEntitlementRequest {
  String entitlementVersion;
  String requestVersion;
  String authenticationToken;
  String temporaryToken;
  String app;
  String terminalId;
  String terminalVendor;
  String terminalModel;
  String terminalSoftware;
  String appName;
  String appVersion;
  String provisioningVersion;
  String accept;
  String gid1;
  String clientTs43;
  bool omitEapId;
  List<String> cookies;

  ServiceEntitlementRequest({
    this.entitlementVersion = '',
    this.requestVersion = '',
    this.authenticationToken = '',
    this.temporaryToken = '',
    this.app = '',
    this.terminalId = '',
    this.terminalVendor = '',
    this.terminalModel = '',
    this.terminalSoftware = '',
    this.appName = '',
    this.appVersion = '',
    this.provisioningVersion = '',
    this.accept = '',
    this.gid1 = '',
    this.clientTs43 = '',
    this.omitEapId = false,
    this.cookies = const [],
  });
}

/// ODSA operation parameters. Ported from `ODSAOperation`.
class OdsaOperation {
  Operation operation;
  OperationType operationType;
  List<Operation> operationTargets;
  String terminalIccid;
  String terminalEid;
  String targetTerminalId;
  String targetTerminalIccid;
  String targetTerminalEid;
  String targetTerminalModel;
  String targetTerminalSn;
  List<String> targetTerminalImeis;
  String targetTerminalEntitlementProto;
  String companionTerminalId;
  String companionTerminalVendor;
  String companionTerminalModel;
  String companionTerminalSoftware;
  String companionTerminalFriendlyName;
  String companionTerminalService;
  String companionTerminalIccid;
  String companionTerminalEid;
  String oldTerminalId;
  String oldTerminalIccid;
  String oldTerminalEntitlementProto;
  String messageResponse;
  int messageButton;
  bool messageButtonSet;

  OdsaOperation({
    this.operation = Operation.none,
    this.operationType = OperationType.omit,
    this.operationTargets = const [],
    this.terminalIccid = '',
    this.terminalEid = '',
    this.targetTerminalId = '',
    this.targetTerminalIccid = '',
    this.targetTerminalEid = '',
    this.targetTerminalModel = '',
    this.targetTerminalSn = '',
    this.targetTerminalImeis = const [],
    this.targetTerminalEntitlementProto = '',
    this.companionTerminalId = '',
    this.companionTerminalVendor = '',
    this.companionTerminalModel = '',
    this.companionTerminalSoftware = '',
    this.companionTerminalFriendlyName = '',
    this.companionTerminalService = '',
    this.companionTerminalIccid = '',
    this.companionTerminalEid = '',
    this.oldTerminalId = '',
    this.oldTerminalIccid = '',
    this.oldTerminalEntitlementProto = '',
    this.messageResponse = '',
    this.messageButton = MessageButton.unknown,
    this.messageButtonSet = false,
  });
}

/// HTTP-agnostic prepared request: parameters + headers + method, ready for the
/// transport layer to turn into a GET-with-query or POST-JSON request.
class PreparedRequest {
  final bool usePost;
  final Map<String, List<String>> params;
  final String accept;
  final String userAgent;
  final List<String> cookies;
  PreparedRequest({
    required this.usePost,
    required this.params,
    required this.accept,
    required this.userAgent,
    required this.cookies,
  });

  /// Query string for GET requests (form-urlencoded).
  String queryString() {
    final parts = <String>[];
    params.forEach((key, values) {
      for (final v in values) {
        parts.add(
          '${Uri.encodeQueryComponent(key)}='
          '${Uri.encodeQueryComponent(v)}',
        );
      }
    });
    return parts.join('&');
  }

  /// JSON body for POST requests. Repeated keys collapse (last wins), except
  /// `target_terminal_imeis` which keeps the last value too, per the Go port.
  String jsonBody() {
    final body = <String, String>{};
    params.forEach((key, values) {
      if (key == 'target_terminal_imeis') {
        for (final v in values) {
          body[key] = v;
        }
      } else {
        body[key] = values.join(',');
      }
    });
    return jsonEncode(body);
  }
}

class _Params {
  final Map<String, List<String>> data = {};
  void set(String name, String value) => data[name] = [value];
  void setOptional(String name, String value) {
    if (value.isNotEmpty) data[name] = [value];
  }

  void add(String name, String value) =>
      (data.putIfAbsent(name, () => [])).add(value);
  void remove(String name) => data.remove(name);
}

const _errAppRequired = 'app is required';

PreparedRequest buildPreparedRequest({
  required Entitlement entitlement,
  required Identity identity,
  required ServiceEntitlementRequest req,
  required OdsaOperation op,
  required String clientTs43,
  required String realm,
}) {
  req = _shapeSamsungRequest(entitlement, req);
  if (req.app.isEmpty) {
    throw const FormatException(_errAppRequired);
  }
  final params = _Params();
  _addAuthIdentity(params, identity, req, realm);
  _addCommon(params, req);
  if (op.operation != Operation.none) {
    _addOperation(params, op);
  }
  _addSamsungOperationFields(params, entitlement, identity, op, realm);

  final accept = _requestAccept(entitlement, req);
  final ua = userAgent(
    req,
    req.clientTs43.isNotEmpty ? req.clientTs43 : clientTs43,
  );
  return PreparedRequest(
    usePost: entitlement.usePost,
    params: params.data,
    accept: accept,
    userAgent: ua,
    cookies: req.cookies,
  );
}

String _requestAccept(Entitlement e, ServiceEntitlementRequest req) {
  final accept = responseAccept(e, req);
  if (_initialEapRequest(req)) {
    return eapRelayAccept(accept);
  }
  return accept;
}

String responseAccept(Entitlement e, ServiceEntitlementRequest req) {
  if (req.accept.isNotEmpty) return req.accept;
  if (e.channel == EntitlementChannel.samsung) {
    return Ts43Constants.samsungResponseAccept;
  }
  return Ts43Constants.defaultResponseAccept;
}

bool _initialEapRequest(ServiceEntitlementRequest req) =>
    req.authenticationToken.isEmpty &&
    req.temporaryToken.isEmpty &&
    !req.omitEapId;

String eapRelayAccept(String accept) {
  if (accept.isEmpty) accept = Ts43Constants.defaultResponseAccept;
  if (_acceptHasMediaType(accept, Ts43Constants.eapRelayContentType)) {
    return accept;
  }
  return '${Ts43Constants.eapRelayContentType}, $accept';
}

bool _acceptHasMediaType(String accept, String mediaType) {
  for (final part in accept.split(',')) {
    final value = part.trim().split(';').first.trim();
    if (value.toLowerCase() == mediaType.toLowerCase()) return true;
  }
  return false;
}

ServiceEntitlementRequest _shapeSamsungRequest(
  Entitlement e,
  ServiceEntitlementRequest req,
) {
  if (e.channel != EntitlementChannel.samsung) return req;
  req.app = Ts43Constants.appOdsaPrimary;
  return req;
}

void _addSamsungOperationFields(
  _Params params,
  Entitlement e,
  Identity identity,
  OdsaOperation op,
  String realm,
) {
  if (e.channel != EntitlementChannel.samsung ||
      op.operation == Operation.none) {
    return;
  }
  if (op.operation == Operation.manage && _samsungDigitalizedTempToken4ff(e)) {
    params.remove('IMSI');
    return;
  }
  if (!_samsungOperationUsesEapIdentity(op.operation)) {
    params.remove('IMSI');
    return;
  }
  params.remove('IMSI');
  final eapId = imsiEapIdentity(identity.mccMnc, identity.imsi, realm);
  params.set('IMSI', base64.encode(utf8.encode(eapId)));
}

bool _samsungOperationUsesEapIdentity(Operation operation) =>
    operation == Operation.check ||
    operation == Operation.manage ||
    operation == Operation.acquireConf;

bool _samsungDigitalizedTempToken4ff(Entitlement e) =>
    e.channel == EntitlementChannel.samsung &&
    e.transferType == TransferType.temporaryTokenOldTerminalIds &&
    e.useTempTokenConversion;

void _addAuthIdentity(
  _Params params,
  Identity identity,
  ServiceEntitlementRequest req,
  String realm,
) {
  if (req.authenticationToken.isNotEmpty) {
    params.set('IMSI', identity.imsi);
    params.set('token', req.authenticationToken);
    return;
  }
  if (req.temporaryToken.isNotEmpty) {
    params.set('temporary_token', req.temporaryToken);
    return;
  }
  if (req.omitEapId) return;
  final eapId = imsiEapIdentity(identity.mccMnc, identity.imsi, realm);
  params.set('EAP_ID', eapId);
}

void _addCommon(_Params params, ServiceEntitlementRequest req) {
  var version = req.requestVersion;
  if (version.isEmpty) version = '0';
  params.set('terminal_id', req.terminalId);
  params.set('app', req.app);
  params.set('terminal_vendor', _truncate(req.terminalVendor, 4));
  params.set('terminal_model', _truncate(req.terminalModel, 10));
  params.set('terminal_sw_version', _truncate(req.terminalSoftware, 20));
  params.set('vers', version);
  params.set('entitlement_version', req.entitlementVersion);
  params.setOptional('GID1', req.gid1);
  params.setOptional('app_version', req.appVersion);
  params.setOptional('app_name', req.appName);
  params.setOptional('provisioning_version', req.provisioningVersion);
}

void _addOperation(_Params params, OdsaOperation op) {
  params.set('operation', op.operation.value);
  if (op.operationType != OperationType.omit) {
    params.set('operation_type', op.operationType.text);
  }
  params.setOptional(
    'operation_targets',
    _operationTargets(op.operationTargets),
  );
  params.setOptional('terminal_iccid', op.terminalIccid);
  params.setOptional('terminal_eid', op.terminalEid);
  params.setOptional('target_terminal_id', op.targetTerminalId);
  params.setOptional('target_terminal_iccid', op.targetTerminalIccid);
  params.setOptional('target_terminal_eid', op.targetTerminalEid);
  params.setOptional('target_terminal_model', op.targetTerminalModel);
  params.setOptional('target_terminal_sn', op.targetTerminalSn);
  params.setOptional(
    'target_terminal_entitlement_protocol',
    op.targetTerminalEntitlementProto,
  );
  params.setOptional('companion_terminal_id', op.companionTerminalId);
  params.setOptional('companion_terminal_vendor', op.companionTerminalVendor);
  params.setOptional('companion_terminal_model', op.companionTerminalModel);
  params.setOptional(
    'companion_terminal_sw_version',
    op.companionTerminalSoftware,
  );
  params.setOptional(
    'companion_terminal_friendly_name',
    op.companionTerminalFriendlyName,
  );
  params.setOptional('companion_terminal_service', op.companionTerminalService);
  params.setOptional('companion_terminal_iccid', op.companionTerminalIccid);
  params.setOptional('companion_terminal_eid', op.companionTerminalEid);
  params.setOptional('old_terminal_id', op.oldTerminalId);
  params.setOptional('old_terminal_iccid', op.oldTerminalIccid);
  params.setOptional(
    'old_terminal_entitlement_protocol',
    op.oldTerminalEntitlementProto,
  );
  params.setOptional('MSG_response', op.messageResponse);
  if (op.messageButtonSet) {
    params.set('MSG_btn', MessageButton.text(op.messageButton));
  }
  for (final v in op.targetTerminalImeis) {
    if (v.isNotEmpty) params.add('target_terminal_imeis', v);
  }
}

String _operationTargets(List<Operation> ops) {
  if (ops.isEmpty) return '';
  return ops.map((o) => o.value).join(',');
}

String userAgent(ServiceEntitlementRequest req, String clientTs43) {
  if (clientTs43.isEmpty) clientTs43 = Ts43Constants.defaultOdsaClientTs43;
  return 'PRD-TS43 term-${_truncate(req.terminalVendor, 4)}/'
      '${_truncate(req.terminalModel, 10)} $clientTs43/'
      '${req.appVersion} OS-Android/${_truncate(req.terminalSoftware, 20)}';
}

String _truncate(String s, int n) {
  if (n <= 0 || s.length <= n) return s;
  return s.substring(0, n);
}

String entitlementProtocol(int protocol) =>
    protocol == 0 ? '' : protocol.toString();

String oldTerminalEntitlementProtocol(Device source) {
  if (source.entitlementProtocol != 0) {
    return entitlementProtocol(source.entitlementProtocol);
  }
  return '';
}

List<String> terminalImeis(Device device) =>
    device.imeis.isEmpty ? const [] : List<String>.from(device.imeis);
