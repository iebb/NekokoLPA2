import 'dart:async';
import 'dart:convert';

import '../services/ts43_entitlement_http.dart';
import 'sim/aka.dart';
import 'sim/identity.dart';
import 'constants.dart';
import 'entitlement.dart';
import 'enums.dart';
import 'errors.dart';
import 'operation.dart';
import 'request.dart';
import 'response.dart';
import 'types.dart';

/// Configuration for [Ts43Client].
class Ts43Config {
  final Ts43Transport? transport;
  final List<EntitlementRecord>? entitlementRecords;
  final Entitlement entitlement;
  final Endpoint source;
  final Endpoint target;
  final Device companion;
  final void Function(Ts43Event)? onEvent;
  final String appVersion;
  final String clientTs43;
  final String realm;
  final DateTime Function()? now;
  final Future<void> Function(Duration)? sleep;

  Ts43Config({
    this.transport,
    this.entitlementRecords,
    required this.entitlement,
    required this.source,
    required this.target,
    Device? companion,
    this.onEvent,
    this.appVersion = '',
    this.clientTs43 = '',
    this.realm = '',
    this.now,
    this.sleep,
  }) : companion = companion ?? Device();
}

class _TransferCredential {
  final AuthToken auth;
  final TemporaryToken temporary;
  final bool temporaryToken;
  _TransferCredential({
    AuthToken? auth,
    TemporaryToken? temporary,
    this.temporaryToken = false,
  }) : auth = auth ?? AuthToken(),
       temporary = temporary ?? TemporaryToken();

  static _TransferCredential ofAuth(AuthToken token) =>
      _TransferCredential(auth: token);
  static _TransferCredential ofTemporary(TemporaryToken token) =>
      _TransferCredential(temporary: token, temporaryToken: true);
}

class _CallResult {
  final OdsaResponse resp;
  final List<String> cookies;
  _CallResult(this.resp, this.cookies);
}

const _sourceProfileDeletedEntitlementProtocol = 1;

/// TS.43 carrier-managed transfer client. Ported from `ts43-go/ts43`
/// (`client.go` + `service.go` + `websheet.go`).
class Ts43Client {
  Entitlement _entitlement;
  final Endpoint _source;
  final Endpoint _target;
  final Device _companion;
  final String _appVersion;
  final String _clientTs43Override;
  final String _realmOverride;
  final void Function(Ts43Event)? _onEvent;
  final DateTime Function()? _nowFn;
  final Future<void> Function(Duration)? _sleepFn;
  final List<EntitlementRecord>? _entitlementRecords;
  Ts43Transport _transport;
  bool _ownsTransport = false;

  Ts43Client._(
    this._entitlement,
    this._source,
    this._target,
    this._companion,
    this._appVersion,
    this._clientTs43Override,
    this._realmOverride,
    this._onEvent,
    this._nowFn,
    this._sleepFn,
    this._entitlementRecords,
    this._transport,
    this._ownsTransport,
  );

  factory Ts43Client(Ts43Config cfg) {
    final e = cfg.entitlement;
    e.transferType = _selectedTransferType(e);
    if (e.timeout == Duration.zero) e.timeout = defaultEntitlementTimeout;
    if (e.pollInterval == Duration.zero) {
      e.pollInterval = const Duration(minutes: 1);
    }
    if (e.pollTimeout == Duration.zero) {
      e.pollTimeout = const Duration(minutes: 10);
    }
    if (e.autoRetry511Limit == 0) e.autoRetry511Limit = 1;

    var transport = cfg.transport;
    var owns = false;
    if (transport == null) {
      transport = createTs43Transport(timeout: e.timeout);
      owns = true;
    }
    return Ts43Client._(
      e,
      cfg.source,
      cfg.target,
      cfg.companion,
      cfg.appVersion,
      cfg.clientTs43,
      cfg.realm,
      cfg.onEvent,
      cfg.now,
      cfg.sleep,
      cfg.entitlementRecords,
      transport,
      owns,
    );
  }

  void dispose() {
    if (_ownsTransport) _transport.close();
  }

  DateTime _now() => _nowFn != null ? _nowFn() : DateTime.now();

  Future<void> _sleep(Duration d) =>
      _sleepFn != null ? _sleepFn(d) : Future<void>.delayed(d);

  void _emit(Ts43Event event) => _onEvent?.call(event);

  bool _usesTemporaryToken() =>
      TransferType.usesTemporaryToken(_entitlement.transferType);

  // ---- Top-level flow (service.go) ----

  Future<Ts43Result> transfer() async {
    final channel = _source.channel;
    if (channel == null) {
      throw StateError('source channel is required');
    }
    final identity = await channel.identity();
    await _discoverEntitlement(identity);
    final source = _source.device.clone();
    source.iccid = firstNonEmpty([source.iccid, identity.iccid]);
    final target = _target.device.clone();
    final tokens = await _fetchTransferToken(identity, source, target);
    final offer = TransferOffer(
      sourceIdentity: identity,
      sourceDevice: source,
      targetDevice: target,
      authToken: tokens.auth,
      temporaryToken: tokens.temporary,
    );
    return _activate(
      offer,
      const UserInputResult(button: MessageButton.unknown),
    );
  }

  Future<void> _discoverEntitlement(Identity identity) async {
    if (_entitlement.server.isNotEmpty) return;
    final requested = _entitlement;
    final records = _entitlementRecords ?? await Ts43EntitlementDb.load();
    final discovered = discoverEntitlementForChannel(
      records,
      identity,
      requested.sourceSimType,
      requested.channel,
    );
    discovered.sourceSimType = requested.sourceSimType;
    if (requested.timeout != defaultEntitlementTimeout ||
        discovered.timeout == Duration.zero) {
      discovered.timeout = requested.timeout;
    }
    discovered.autoRetry511Limit = requested.autoRetry511Limit;
    if (discovered.pollInterval == Duration.zero) {
      discovered.pollInterval = const Duration(minutes: 1);
    }
    if (discovered.pollTimeout == Duration.zero) {
      discovered.pollTimeout = const Duration(minutes: 10);
    }
    if (discovered.autoRetry511Limit == 0) discovered.autoRetry511Limit = 1;
    _entitlement = discovered;
  }

  Future<Ts43Result> continueFlow(
    Ts43Result result,
    ContinueRequest req,
  ) async {
    switch (result.state) {
      case Ts43State.pendingUserInput:
        final session = _requireSession(result);
        if (req.userInput == null) {
          throw StateError('user input is required');
        }
        if (req.userInput!.button == MessageButton.unknown) {
          throw StateError('user input button is required');
        }
        return _activate(session.offer, req.userInput!);
      case Ts43State.pendingWebsheet:
        _requireSession(result);
        if (req.websheet == null) {
          throw StateError('websheet result is required');
        }
        return _handleWebsheetResult(result, req.websheet!);
      case Ts43State.pendingSourceProfileDeletion:
        final session = _requireSession(result);
        if (!req.sourceProfileDeleted) {
          throw StateError('source profile deletion confirmation is required');
        }
        if (TransferType.isSourceCredential(_entitlement.transferType)) {
          if (session.offer.sourceDevice.entitlementProtocol == 0) {
            session.offer.sourceDevice.entitlementProtocol =
                _sourceProfileDeletedEntitlementProtocol;
          }
          return _pollAfterSourceProfileDeletion(result);
        }
        return _activate(
          session.offer,
          const UserInputResult(button: MessageButton.unknown),
        );
      default:
        throw StateError('state ${result.state} cannot continue');
    }
  }

  Future<Ts43Result> completeActivation(
    Ts43Result result,
    ActivationResult activation,
  ) async {
    final session = _requireSession(result);
    final offer = session.offer;
    final iccid = firstNonEmpty([
      activation.iccid,
      result.downloadConfig.profileIccid,
    ]);
    if (iccid.isNotEmpty) {
      offer.targetDevice.iccid = iccid;
      result.downloadConfig.profileIccid = iccid;
    }
    if (TransferType.isSourceCredential(_entitlement.transferType)) {
      result.state = Ts43State.done;
      result.event = const DoneEvent();
      _emit(result.event!);
      return result;
    }
    var credential = await _transferCredential(offer);
    OdsaResponse? update;
    for (var attempt = 0; ; attempt++) {
      try {
        update = await _updateSubscription(
          offer.sourceIdentity,
          offer.sourceDevice,
          offer.targetDevice,
          credential,
        );
        break;
      } catch (err) {
        if (isHttpStatus(err, 511) &&
            attempt < _entitlement.autoRetry511Limit) {
          credential = await _refreshTransferCredential(offer);
          continue;
        }
        result.updateSubscription = update;
        rethrow;
      }
    }
    result.updateSubscription = update;
    final sr = update.subscriptionResult;
    if (sr == SubscriptionResult.done) {
      result.state = Ts43State.done;
      result.event = const DoneEvent();
      _emit(result.event!);
      return result;
    }
    if (sr == SubscriptionResult.dismiss) {
      result.state = Ts43State.dismissed;
      result.event = DismissEvent(sr);
      _emit(result.event!);
      return result;
    }
    if (sr == SubscriptionResult.delayedDownload) {
      result.state = Ts43State.pendingActivation;
      result.event = ActivationPendingEvent(
        iccid: offer.targetDevice.iccid,
        subscriptionResult: sr,
      );
      _emit(result.event!);
      return result;
    }
    try {
      final configuration = await _pollActivationConfiguration(
        offer,
        credential,
      );
      result.updateConfiguration = configuration;
    } on _PollingNotTriggered {
      result.state = Ts43State.pendingActivation;
      result.event = ActivationPendingEvent(
        iccid: offer.targetDevice.iccid,
        subscriptionResult: sr,
      );
      _emit(result.event!);
      return result;
    }
    result.state = Ts43State.done;
    result.event = const DoneEvent();
    _emit(result.event!);
    return result;
  }

  // ---- Token fetch ----

  Future<TransferTokenResult> _fetchTransferToken(
    Identity identity,
    Device source,
    Device target,
  ) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _fetchTransferTokenOnce(identity, source, target);
      } catch (err) {
        if (isHttpStatus(err, 511) &&
            attempt < _entitlement.autoRetry511Limit) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<TransferTokenResult> _fetchTransferTokenOnce(
    Identity identity,
    Device source,
    Device target,
  ) async {
    var auth = await _authenticate(identity, source);
    auth = await _checkEligibility(identity, source, auth, target);
    return _transferTokens(identity, source, target, auth);
  }

  Future<TransferTokenResult> _transferTokens(
    Identity identity,
    Device source,
    Device target,
    AuthToken auth,
  ) async {
    if (!_usesTemporaryToken()) {
      return TransferTokenResult(auth: auth);
    }
    return _acquireTemporaryToken(identity, source, target, auth);
  }

  Future<AuthToken> _authenticate(Identity identity, Device device) async {
    var req = _baseRequest(device, '', '');
    final op = OdsaOperation();
    _CallResult result;
    try {
      result = await _call(identity, req, op);
    } catch (err) {
      if (isHttpStatus(err, 511)) {
        req.omitEapId = true;
        result = await _call(identity, req, op);
      } else {
        rethrow;
      }
    }
    final resp = result.resp;
    if (resp.authenticationToken.isEmpty) {
      throw StateError('authentication token is missing');
    }
    DateTime? expires;
    if (resp.authTokenValidity > 0) {
      expires = _now().add(Duration(seconds: resp.authTokenValidity));
    }
    return AuthToken(
      value: resp.authenticationToken,
      expiresAt: expires,
      cookies: result.cookies,
    );
  }

  Future<TransferTokenResult> _acquireTemporaryToken(
    Identity identity,
    Device source,
    Device target,
    AuthToken auth,
  ) async {
    final req = _authRequest(source, auth);
    final op = temporaryTokenOperation(_entitlement, source, target);
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    final resp = result.resp;
    if (resp.operationResult != OperationResult.unknown &&
        resp.operationResult != OperationResult.success) {
      throw CarrierDeniedError(operation: Operation.tempToken, result: resp);
    }
    if (resp.temporaryToken.isEmpty) {
      throw StateError('temporary token is missing');
    }
    if (!resp.operationTargets.contains(Operation.manage) ||
        !resp.operationTargets.contains(Operation.acquireConf)) {
      throw StateError('temporary token does not allow transfer operations');
    }
    final expiresAt = _temporaryTokenExpiresAt(resp.temporaryTokenExpiry);
    final mergedCookies = mergeCookieHeaders(auth.cookies, result.cookies);
    return TransferTokenResult(
      auth: _authTokenFromResponse(auth, resp, mergedCookies),
      temporary: TemporaryToken(
        value: resp.temporaryToken,
        expiresAt: expiresAt,
        cookies: mergedCookies,
        targets: List<Operation>.from(resp.operationTargets),
      ),
    );
  }

  Future<AuthToken> _checkEligibility(
    Identity identity,
    Device source,
    AuthToken auth,
    Device target,
  ) async {
    final req = _authRequest(source, auth);
    final op = checkEligibilityOperation(_entitlement, source, target);
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    final resp = result.resp;
    if (resp.operationResult != OperationResult.success ||
        resp.primaryAppEligibility != AppEligibility.enabled) {
      throw CarrierDeniedError(operation: Operation.check, result: resp);
    }
    return _authTokenFromResponse(
      auth,
      resp,
      mergeCookieHeaders(auth.cookies, result.cookies),
    );
  }

  // ---- Subscription operations ----

  Future<OdsaResponse> _manageSubscription(
    Identity identity,
    Device source,
    Device target,
    _TransferCredential credential,
    UserInputResult answer,
  ) async {
    final reqDevice = manageSubscriptionRequestDevice(
      _entitlement,
      source,
      target,
    );
    final req = _transferRequest(reqDevice, credential);
    final op = manageSubscriptionOperation(
      _entitlement,
      source,
      target,
      answer,
    );
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    if (!_manageSubscriptionAccepted(result.resp)) {
      throw CarrierDeniedError(
        operation: Operation.manage,
        result: result.resp,
      );
    }
    return result.resp;
  }

  Future<OdsaResponse> _acquireConfiguration(
    Identity identity,
    Device source,
    Device target,
    _TransferCredential credential,
  ) async {
    final reqDevice = acquireConfigurationRequestDevice(
      _entitlement,
      source,
      target,
    );
    final req = _transferRequest(reqDevice, credential);
    final op = acquireConfigurationOperation(_entitlement, source, target);
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    return result.resp;
  }

  Future<OdsaResponse> _updateSubscription(
    Identity identity,
    Device source,
    Device target,
    _TransferCredential credential,
  ) async {
    final req = _transferRequest(target, credential);
    final op = updateSubscriptionOperation(_entitlement, source, target);
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    if (!_subscriptionUpdateAccepted(result.resp)) {
      throw CarrierDeniedError(
        operation: Operation.manage,
        result: result.resp,
      );
    }
    return result.resp;
  }

  Future<OdsaResponse> _acquireActivationConfiguration(
    Identity identity,
    Device target,
    _TransferCredential credential,
  ) async {
    final req = _transferRequest(target, credential);
    final op = activationConfigurationOperation(_entitlement, target);
    _addOptionalOperationFields(op);
    final result = await _call(identity, req, op);
    return result.resp;
  }

  // ---- activate / poll ----

  Future<Ts43Result> _activate(
    TransferOffer offer,
    UserInputResult answer,
  ) async {
    var credential = await _transferCredential(offer);
    OdsaResponse? manage;
    for (var attempt = 0; ; attempt++) {
      try {
        manage = await _manageSubscription(
          offer.sourceIdentity,
          offer.sourceDevice,
          offer.targetDevice,
          credential,
          answer,
        );
        break;
      } catch (err) {
        if (isHttpStatus(err, 511) &&
            attempt < _entitlement.autoRetry511Limit) {
          credential = await _refreshTransferCredential(offer);
          continue;
        }
        rethrow;
      }
    }
    final result = Ts43Result(
      manageSubscription: manage,
      session: TransferSession(offer: offer),
    );
    credential = _updateTransferCredential(offer, manage, credential);

    if (_sourceProfileDeletionRequired(manage)) {
      result.session!.sourceProfileIccid = firstNonEmpty([
        offer.sourceDevice.iccid,
        offer.sourceIdentity.iccid,
      ]);
      result.state = Ts43State.pendingSourceProfileDeletion;
      result.event = SourceProfileDeletionEvent(
        result.session!.sourceProfileIccid,
      );
      _emit(result.event!);
      return result;
    }
    if (_userInputRequired(manage)) {
      result.state = Ts43State.pendingUserInput;
      result.event = UserInputEvent(manage.message);
      _emit(result.event!);
      return result;
    }
    if (_websheetRequired(manage)) {
      result.state = Ts43State.pendingWebsheet;
      result.event = WebsheetEvent(manage.websheet);
      _emit(result.event!);
      return result;
    }
    if (_downloadProfileReady(manage)) {
      result.downloadConfig = _completeDownloadConfig(
        manage.download,
        offer.targetDevice,
      );
      result.state = Ts43State.pendingDownload;
      result.event = DownloadReadyEvent(result.downloadConfig);
      _emit(result.event!);
      return result;
    }
    if (_subscriptionDone(manage)) {
      result.state = Ts43State.done;
      result.event = const DoneEvent();
      _emit(result.event!);
      return result;
    }
    if (_subscriptionDismissed(manage)) {
      result.state = Ts43State.dismissed;
      result.event = DismissEvent(manage.subscriptionResult);
      _emit(result.event!);
      return result;
    }
    if (_delayedDownloadRequired(manage)) {
      _applyDelayedDownloadState(result, offer, manage.subscriptionResult);
      _emit(result.event!);
      return result;
    }
    try {
      final configuration = await _pollConfiguration(offer, credential);
      result.configuration = configuration;
      return _applyDownloadConfiguration(result, configuration.download);
    } on _PollingNotTriggered {
      result.state = Ts43State.pendingActivation;
      result.event = ActivationPendingEvent(
        iccid: offer.targetDevice.iccid,
        subscriptionResult: manage.subscriptionResult,
      );
      _emit(result.event!);
      return result;
    }
  }

  Future<Ts43Result> _pollAfterSourceProfileDeletion(Ts43Result result) async {
    final session = _requireSession(result);
    final offer = session.offer;
    final credential = await _transferCredential(offer);
    try {
      final configuration = await _pollConfiguration(offer, credential);
      result.configuration = configuration;
      return _applyDownloadConfiguration(result, configuration.download);
    } on _PollingNotTriggered {
      result.state = Ts43State.pendingActivation;
      result.event = ActivationPendingEvent(
        iccid: offer.targetDevice.iccid,
        subscriptionResult: 0,
      );
      _emit(result.event!);
      return result;
    }
  }

  Future<OdsaResponse> _pollConfiguration(
    TransferOffer offer,
    _TransferCredential credential,
  ) async {
    final deadline = _now().add(_entitlement.pollTimeout);
    var retries = 0;
    while (true) {
      if (!_now().isBefore(deadline)) {
        throw StateError('acquire configuration timeout');
      }
      OdsaResponse resp;
      try {
        resp = await _acquireConfiguration(
          offer.sourceIdentity,
          offer.sourceDevice,
          offer.targetDevice,
          credential,
        );
      } catch (err) {
        if (isHttpStatus(err, 511) &&
            retries < _entitlement.autoRetry511Limit) {
          retries++;
          credential = await _refreshTransferCredential(offer);
          continue;
        }
        rethrow;
      }
      switch (resp.serviceStatus) {
        case ServiceStatus.activated:
          return resp;
        case ServiceStatus.activating:
          final interval = _pollIntervalFor(resp);
          if (interval == null) throw const _PollingNotTriggered();
          await _sleep(interval);
          break;
        case ServiceStatus.deactivated:
          throw StateError('service is deactivated');
        case ServiceStatus.deactivatedNoReuse:
          throw StateError('service is deactivated with no ICCID reuse');
        default:
          throw StateError('unexpected service status ${resp.serviceStatus}');
      }
    }
  }

  Future<OdsaResponse> _pollActivationConfiguration(
    TransferOffer offer,
    _TransferCredential credential,
  ) async {
    final deadline = _now().add(_entitlement.pollTimeout);
    var retries = 0;
    while (true) {
      if (!_now().isBefore(deadline)) {
        throw StateError('activation configuration timeout');
      }
      OdsaResponse resp;
      try {
        resp = await _acquireActivationConfiguration(
          offer.sourceIdentity,
          offer.targetDevice,
          credential,
        );
      } catch (err) {
        if (isHttpStatus(err, 511) &&
            retries < _entitlement.autoRetry511Limit) {
          retries++;
          credential = await _refreshTransferCredential(offer);
          continue;
        }
        rethrow;
      }
      switch (resp.serviceStatus) {
        case ServiceStatus.activated:
          return resp;
        case ServiceStatus.activating:
          final interval = _pollIntervalFor(resp);
          if (interval == null) throw const _PollingNotTriggered();
          await _sleep(interval);
          break;
        case ServiceStatus.deactivated:
          throw StateError('activation service is deactivated');
        case ServiceStatus.deactivatedNoReuse:
          throw StateError(
            'activation service is deactivated with no ICCID reuse',
          );
        default:
          throw StateError(
            'unexpected activation service status ${resp.serviceStatus}',
          );
      }
    }
  }

  // ---- Credential management ----

  Future<_TransferCredential> _refreshTransferCredential(
    TransferOffer offer,
  ) async {
    final tokens = await _fetchTransferToken(
      offer.sourceIdentity,
      offer.sourceDevice,
      offer.targetDevice,
    );
    offer.authToken = tokens.auth;
    offer.temporaryToken = tokens.temporary;
    return _transferCredentialFromTokens(tokens);
  }

  Future<_TransferCredential> _transferCredential(TransferOffer offer) async {
    if (_usesTemporaryToken()) {
      if (offer.temporaryToken.value.isNotEmpty) {
        return _TransferCredential.ofTemporary(offer.temporaryToken);
      }
      return _refreshTransferCredential(offer);
    }
    if (offer.authToken.value.isNotEmpty) {
      return _TransferCredential.ofAuth(offer.authToken);
    }
    return _refreshTransferCredential(offer);
  }

  _TransferCredential _transferCredentialFromTokens(
    TransferTokenResult tokens,
  ) {
    if (_usesTemporaryToken()) {
      return _TransferCredential.ofTemporary(tokens.temporary);
    }
    return _TransferCredential.ofAuth(tokens.auth);
  }

  _TransferCredential _updateTransferCredential(
    TransferOffer offer,
    OdsaResponse resp,
    _TransferCredential credential,
  ) {
    if (resp.authenticationToken.isEmpty) return credential;
    offer.authToken = _authTokenFromResponse(
      offer.authToken,
      resp,
      offer.authToken.cookies,
    );
    if (_usesTemporaryToken()) return credential;
    final next = _authTokenFromResponse(
      credential.auth,
      resp,
      credential.auth.cookies,
    );
    offer.authToken = next;
    return _TransferCredential.ofAuth(next);
  }

  // ---- Websheet (websheet.go) ----

  Future<Ts43Result> _handleWebsheetResult(
    Ts43Result result,
    WebsheetResult callback,
  ) async {
    final session = _requireSession(result);
    final offer = session.offer;
    switch (callback.event) {
      case WebsheetCallbackEvent.profileReadyWithActivationCode:
        if (callback.activationCode.isEmpty) {
          throw StateError('activation code is required');
        }
        result.downloadConfig = _completeDownloadConfig(
          DownloadConfig(
            activationCode: callback.activationCode,
            profileIccid: callback.iccid,
            imei: firstNonEmpty([callback.imei, offer.targetDevice.imei]),
          ),
          offer.targetDevice,
        );
        result.state = Ts43State.pendingDownload;
        result.event = DownloadReadyEvent(result.downloadConfig);
        _emit(result.event!);
        return result;
      case WebsheetCallbackEvent.profileReadyWithDefaultSmdp:
        throw const WebsheetException(websheetDefaultSmdpUnsupported);
      case WebsheetCallbackEvent.selectionCompleted:
        if (callback.iccid.isEmpty && callback.imei.isEmpty) {
          throw StateError('selected ICCID or IMEI is required');
        }
        if (callback.iccid.isNotEmpty) {
          offer.sourceDevice.iccid = callback.iccid;
          offer.sourceIdentity = offer.sourceIdentity.copyWith(
            iccid: callback.iccid,
          );
        }
        if (callback.imei.isNotEmpty) offer.sourceDevice.imei = callback.imei;
        return _activate(
          offer,
          const UserInputResult(button: MessageButton.unknown),
        );
      case WebsheetCallbackEvent.dismissFlow:
        throw const WebsheetException(websheetDismissed);
      case WebsheetCallbackEvent.finishFlow:
        return _continueWebsheetNextAction(result, callback.nextAction);
      case WebsheetCallbackEvent.deleteToken:
        offer.authToken = AuthToken();
        offer.temporaryToken = TemporaryToken();
        return result;
      case WebsheetCallbackEvent.checkProfileServiceStatus:
        final credential = await _transferCredential(offer);
        final configuration = await _pollConfiguration(offer, credential);
        result.configuration = configuration;
        return _applyDownloadConfiguration(result, configuration.download);
      case WebsheetCallbackEvent.deleteProfileInUse:
        session.sourceProfileIccid = firstNonEmpty([
          callback.iccid,
          session.sourceProfileIccid,
          offer.sourceDevice.iccid,
          offer.sourceIdentity.iccid,
        ]);
        result.state = Ts43State.pendingSourceProfileDeletion;
        result.event = SourceProfileDeletionEvent(session.sourceProfileIccid);
        _emit(result.event!);
        return result;
      default:
        throw StateError('websheet callback event is required');
    }
  }

  Future<Ts43Result> _continueWebsheetNextAction(
    Ts43Result result,
    Operation next,
  ) async {
    final session = _requireSession(result);
    final offer = session.offer;
    if (next == Operation.none) next = Operation.acquireConf;
    if (next == Operation.acquireConf) {
      final credential = await _transferCredential(offer);
      final configuration = await _pollConfiguration(offer, credential);
      result.configuration = configuration;
      return _applyDownloadConfiguration(result, configuration.download);
    }
    if (next == Operation.manage) {
      return _activate(
        offer,
        const UserInputResult(button: MessageButton.unknown),
      );
    }
    throw StateError('unsupported websheet next action ${next.value}');
  }

  // ---- HTTP call + EAP relay (client.go) ----

  Future<_CallResult> _call(
    Identity identity,
    ServiceEntitlementRequest req,
    OdsaOperation op,
  ) async {
    final prepared = buildPreparedRequest(
      entitlement: _entitlement,
      identity: identity,
      req: req,
      op: op,
      clientTs43: _clientTs43(),
      realm: _realm(),
    );
    final httpReq = _toHttpRequest(prepared);
    final initial = await _transport.doRaw(httpReq);
    final relayed = await _eapRelay(identity, initial, req);
    final resp = OdsaResponse.decode(relayed.body);
    return _CallResult(resp, relayed.cookies);
  }

  Ts43HttpRequest _toHttpRequest(PreparedRequest prepared) {
    final base = Uri.parse(_entitlement.server);
    final headers = <String, String>{
      'Accept': prepared.accept,
      'User-Agent': prepared.userAgent,
    };
    if (prepared.usePost) {
      headers['Content-Type'] = 'application/json';
      return Ts43HttpRequest(
        method: Ts43Method.post,
        url: base.toString(),
        headers: headers,
        body: utf8.encode(prepared.jsonBody()),
        cookies: prepared.cookies,
      );
    }
    final existing = base.query;
    final query = prepared.queryString();
    final combined = existing.isEmpty ? query : '$existing&$query';
    final url = base.replace(query: combined).toString();
    return Ts43HttpRequest(
      method: Ts43Method.get,
      url: url,
      headers: headers,
      cookies: prepared.cookies,
    );
  }

  Future<Ts43HttpResponse> _eapRelay(
    Identity identity,
    Ts43HttpResponse initial,
    ServiceEntitlementRequest req,
  ) async {
    var body = initial.body;
    var requestCookies = initial.cookies;
    var responseCookies = initial.cookies;
    for (var i = 0; i < 3; i++) {
      final packet = _relayPacket(body);
      if (packet.isEmpty) {
        return Ts43HttpResponse(body, responseCookies);
      }
      final challenge = AkaChallenge.fromBase64(packet);
      final akaResp = await _source.channel!.authenticateAka(
        challenge.authenticationRequest(),
      );
      final eapId = imsiEapIdentity(identity.mccMnc, identity.imsi, _realm());
      final responseText = respondToChallengeBase64(challenge, akaResp, eapId);
      final next = await _postRelay(responseText, req, requestCookies);
      requestCookies = next.cookies;
      responseCookies = next.cookies;
      body = next.body;
    }
    throw StateError('EAP-AKA relay exhausted');
  }

  Future<Ts43HttpResponse> _postRelay(
    String packet,
    ServiceEntitlementRequest req,
    List<String> cookies,
  ) async {
    final data = jsonEncode({'eap-relay-packet': packet});
    final headers = <String, String>{
      'Content-Type': Ts43Constants.eapRelayContentType,
      'Accept': _relayResponseAccept(req),
      'User-Agent': userAgent(
        req,
        firstNonEmpty([req.clientTs43, _clientTs43()]),
      ),
    };
    final httpReq = Ts43HttpRequest(
      method: Ts43Method.post,
      url: _entitlement.server,
      headers: headers,
      body: utf8.encode(data),
      cookies: cookies,
    );
    return _transport.doRaw(httpReq);
  }

  String _relayResponseAccept(ServiceEntitlementRequest req) {
    if (req.app == Ts43Constants.appVoWiFi ||
        req.clientTs43 == Ts43Constants.defaultWfcClientTs43) {
      return firstNonEmpty([req.accept, Ts43Constants.wfcResponseAccept]);
    }
    return eapRelayAccept(req.accept);
  }

  String _relayPacket(List<int> data) {
    try {
      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is Map && decoded['eap-relay-packet'] is String) {
        return decoded['eap-relay-packet'] as String;
      }
    } catch (_) {}
    return '';
  }

  // ---- Request builders ----

  ServiceEntitlementRequest _baseRequest(
    Device device,
    String authToken,
    String tempToken,
  ) {
    return ServiceEntitlementRequest(
      entitlementVersion: _entitlementVersion(),
      requestVersion: _requestVersion(),
      authenticationToken: authToken,
      temporaryToken: tempToken,
      app: _app(),
      terminalId: device.imei,
      terminalVendor: device.vendor,
      terminalModel: device.model,
      terminalSoftware: device.softwareVersion,
      appName: _appName(),
      appVersion: _appVersion,
      provisioningVersion: _entitlement.provisioningVersion,
      accept: _accept(),
    );
  }

  ServiceEntitlementRequest _authRequest(Device device, AuthToken token) {
    final req = _baseRequest(device, token.value, '');
    req.cookies = token.cookies;
    return req;
  }

  ServiceEntitlementRequest _temporaryRequest(
    Device device,
    TemporaryToken token,
  ) {
    final req = _baseRequest(device, '', token.value);
    req.cookies = token.cookies;
    return req;
  }

  ServiceEntitlementRequest _transferRequest(
    Device device,
    _TransferCredential credential,
  ) {
    if (credential.temporaryToken) {
      return _temporaryRequest(device, credential.temporary);
    }
    return _authRequest(device, credential.auth);
  }

  void _addOptionalOperationFields(OdsaOperation op) {
    final c = _companion;
    op.companionTerminalId = c.imei;
    op.companionTerminalVendor = c.vendor;
    op.companionTerminalModel = c.model;
    op.companionTerminalSoftware = c.softwareVersion;
    op.companionTerminalFriendlyName = c.friendlyName;
    op.companionTerminalService = c.service;
    op.companionTerminalIccid = c.iccid;
    op.companionTerminalEid = c.eid;
  }

  String _clientTs43() {
    if (_clientTs43Override.isNotEmpty) return _clientTs43Override;
    if (_entitlement.channel == EntitlementChannel.samsung) {
      return Ts43Constants.samsungOdsaClientTs43;
    }
    return Ts43Constants.defaultOdsaClientTs43;
  }

  String _realm() => _realmOverride.isNotEmpty
      ? _realmOverride
      : Ts43Constants.defaultEapAkaRealm;

  String _appName() {
    if (_entitlement.appName.isNotEmpty) return _entitlement.appName;
    if (_entitlement.channel == EntitlementChannel.samsung) {
      return Ts43Constants.appOdsaPrimary;
    }
    return 'androidTransfer';
  }

  String _accept() {
    if (_entitlement.channel == EntitlementChannel.samsung) return '';
    return Ts43Constants.defaultResponseAccept;
  }

  String _app() {
    if (_entitlement.app.isNotEmpty) return _entitlement.app;
    return Ts43Constants.appOdsaPrimary;
  }

  String _requestVersion() {
    if (_entitlement.requestVersion.isNotEmpty) {
      return _entitlement.requestVersion;
    }
    if (_entitlement.channel == EntitlementChannel.samsung) return '1';
    return '0';
  }

  String _entitlementVersion() => firstNonEmpty([_entitlement.version, '9.0']);

  // ---- Response predicates ----

  bool _sourceProfileDeletionRequired(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.deleteProfileInUse;

  bool _userInputRequired(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.requiresUserInput;

  bool _websheetRequired(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.continueToWebsheet;

  bool _downloadProfileReady(OdsaResponse r) {
    if (r.operationResult != OperationResult.success ||
        r.subscriptionResult != SubscriptionResult.downloadProfile) {
      return false;
    }
    return r.download.activationCode.isNotEmpty ||
        r.download.smdpFqdn.isNotEmpty;
  }

  bool _subscriptionDone(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.done;

  bool _subscriptionDismissed(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.dismiss;

  bool _delayedDownloadRequired(OdsaResponse r) =>
      r.operationResult == OperationResult.success &&
      r.subscriptionResult == SubscriptionResult.delayedDownload;

  void _applyDelayedDownloadState(
    Ts43Result result,
    TransferOffer offer,
    int subscriptionResult,
  ) {
    final sourceIccid = firstNonEmpty([
      offer.sourceDevice.iccid,
      offer.sourceIdentity.iccid,
    ]);
    if (_entitlement.useSmdsDelayedDownload) {
      result.state = Ts43State.pendingSmdsDiscovery;
      result.event = SmdsDiscoveryEvent(
        sourceIccid: sourceIccid,
        targetEid: offer.targetDevice.eid,
        targetImei: offer.targetDevice.imei,
        subscriptionResult: subscriptionResult,
      );
    } else {
      result.state = Ts43State.pendingDelayedDownload;
      result.event = DelayedDownloadEvent(
        sourceIccid: sourceIccid,
        targetEid: offer.targetDevice.eid,
        targetImei: offer.targetDevice.imei,
        subscriptionResult: subscriptionResult,
      );
    }
  }

  Ts43Result _applyDownloadConfiguration(
    Ts43Result result,
    DownloadConfig cfg,
  ) {
    final session = _requireSession(result);
    cfg = _completeDownloadConfig(cfg, session.offer.targetDevice);
    if (cfg.activationCode.isEmpty && cfg.smdpFqdn.isEmpty) {
      throw StateError('download info is missing');
    }
    result.downloadConfig = cfg;
    result.state = Ts43State.pendingDownload;
    result.event = DownloadReadyEvent(result.downloadConfig);
    _emit(result.event!);
    return result;
  }

  DownloadConfig _completeDownloadConfig(DownloadConfig cfg, Device target) {
    if (cfg.imei.isEmpty) cfg.imei = target.imei;
    return cfg;
  }

  bool _manageSubscriptionAccepted(OdsaResponse r) {
    if (r.operationResult != OperationResult.success) return false;
    switch (r.subscriptionResult) {
      case SubscriptionResult.downloadProfile:
        return r.download.activationCode.isNotEmpty ||
            r.download.smdpFqdn.isNotEmpty;
      case SubscriptionResult.delayedDownload:
        return true;
      case SubscriptionResult.done:
      case SubscriptionResult.dismiss:
      case SubscriptionResult.deleteProfileInUse:
        return true;
      case SubscriptionResult.continueToWebsheet:
        return r.websheet.url.isNotEmpty;
      case SubscriptionResult.requiresUserInput:
        return r.message.text.isNotEmpty;
      default:
        return false;
    }
  }

  bool _subscriptionUpdateAccepted(OdsaResponse r) {
    if (r.operationResult != OperationResult.success) return false;
    switch (r.subscriptionResult) {
      case SubscriptionResult.done:
      case SubscriptionResult.delayedDownload:
      case SubscriptionResult.dismiss:
        return true;
      default:
        return false;
    }
  }

  Duration? _pollIntervalFor(OdsaResponse resp) {
    if (!resp.pollingIntervalSet) {
      return _entitlement.pollInterval > Duration.zero
          ? _entitlement.pollInterval
          : null;
    }
    if (resp.pollingInterval <= 0) return null;
    switch (resp.pollingIntervalUnit) {
      case 1:
        return Duration(seconds: resp.pollingInterval);
      case 2:
        return Duration(milliseconds: resp.pollingInterval * 100);
      default:
        return Duration(minutes: resp.pollingInterval);
    }
  }

  AuthToken _authTokenFromResponse(
    AuthToken current,
    OdsaResponse resp,
    List<String> cookies,
  ) {
    final next = AuthToken(
      value: current.value,
      expiresAt: current.expiresAt,
      cookies: cookies,
    );
    if (resp.authenticationToken.isEmpty) return next;
    next.value = resp.authenticationToken;
    next.expiresAt = null;
    if (resp.authTokenValidity > 0) {
      next.expiresAt = _now().add(Duration(seconds: resp.authTokenValidity));
    }
    return next;
  }

  DateTime _temporaryTokenExpiresAt(String value) {
    value = value.trim();
    if (value.isEmpty) {
      throw const FormatException('temporary token expiry is missing');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    throw FormatException('parse temporary token expiry "$value"');
  }

  TransferSession _requireSession(Ts43Result result) {
    final s = result.session;
    if (s == null) {
      throw StateError('transfer session is required');
    }
    return s;
  }
}

class _PollingNotTriggered implements Exception {
  const _PollingNotTriggered();
}

int _selectedTransferType(Entitlement e) {
  if (e.transferType != TransferType.disabled ||
      e.sourceSimType != SimType.psim) {
    return e.transferType;
  }
  if (e.useTempTokenConversion) {
    return TransferType.temporaryTokenOldTerminalIds;
  }
  return TransferType.oldTerminalIds;
}
