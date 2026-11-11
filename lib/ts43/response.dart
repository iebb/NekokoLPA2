import 'dart:convert';

import 'package:xml/xml.dart';

import 'enums.dart';
import 'types.dart';

/// Parsed ODSA / service-entitlement response. Ported from
/// `ts43-go/ts43/response.go`, supporting both JSON and the WAP-provisioning
/// XML (`characteristic`/`parm`) form.
class OdsaResponse {
  int operationResult = OperationResult.unknown;
  int primaryAppEligibility = AppEligibility.unknown;
  int subscriptionResult = SubscriptionResult.unknown;
  int serviceStatus = ServiceStatus.unknown;
  int pollingInterval = 0;
  bool pollingIntervalSet = false;
  int pollingIntervalUnit = 0;
  String temporaryToken = '';
  String temporaryTokenExpiry = '';
  List<Operation> operationTargets = const [];
  int registerNotifStatus = 0;
  String generalErrorText = '';
  String authenticationToken = '';
  int authTokenValidity = 0;
  DownloadConfig download = DownloadConfig();
  Message message = const Message();
  Websheet websheet = const Websheet();
  List<int> raw = const [];

  static OdsaResponse decode(List<int> data) {
    final resp = OdsaResponse()..raw = List<int>.from(data);
    final text = utf8.decode(data, allowMalformed: true);
    final trimmed = text.trimLeft();
    if (_looksLikeJson(trimmed)) {
      resp._applyMap(_jsonToFieldMap(jsonDecode(text)));
    } else {
      resp._applyMap(_xmlToFieldMap(text));
    }
    return resp;
  }

  static bool _looksLikeJson(String s) {
    if (s.isEmpty) return false;
    final c = s.codeUnitAt(0);
    if (c != 0x7b /* { */ && c != 0x5b /* [ */ ) return false;
    try {
      jsonDecode(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _applyMap(_Fields f) {
    operationResult = OperationResult.parse(f.app['OperationResult']);
    primaryAppEligibility = AppEligibility.parse(
      f.app['PrimaryAppEligibility'],
    );
    subscriptionResult = SubscriptionResult.parse(f.app['SubscriptionResult']);
    serviceStatus = ServiceStatus.parse(f.primary['ServiceStatus']);

    var pi = f.primary['PollingInterval'];
    var piUnit = f.primary['PollingIntervalUnit'];
    if (pi == null || pi.trim().isEmpty) {
      pi = f.app['PollingInterval'];
      piUnit = f.app['PollingIntervalUnit'];
    }
    pollingIntervalSet = pi != null && pi.trim().isNotEmpty;
    pollingInterval = _atoi(pi);
    pollingIntervalUnit = _atoi(piUnit);

    temporaryToken = f.app['TemporaryToken'] ?? '';
    temporaryTokenExpiry = f.app['TemporaryTokenExpiry'] ?? '';
    operationTargets = _splitOperations(f.app['OperationTargets'] ?? '');
    registerNotifStatus = _atoi(f.app['RegisterNotifStatus']);
    generalErrorText = f.app['GeneralErrorText'] ?? '';
    authenticationToken = f.token['token'] ?? '';
    authTokenValidity = _atoi(f.token['Validity']);

    message = Message(
      title: f.msg['Title'] ?? '',
      text: f.msg['Message'] ?? '',
      acceptButton: _one(f.msg['Accept_btn']),
      acceptButtonLabel: f.msg['Accept_btn_label'] ?? '',
      rejectButton: _one(f.msg['Reject_btn']),
      rejectButtonLabel: f.msg['Reject_btn_label'] ?? '',
      acceptFreeText: _one(f.msg['Accept_freetext']),
      acceptFreeTextHint: f.msg['Accept_freetext_hint'] ?? '',
      acceptFreeTextValidation: _encodedPrefixedField(
        f.msg['Accept_freetext_validation'] ?? '',
      ),
      acceptFreeTextValidationFailedErrorText:
          f.msg['Accept_freetext_validation_failed_error_text'] ?? '',
    );

    if (subscriptionResult == SubscriptionResult.continueToWebsheet) {
      websheet = Websheet(
        url: f.app['SubscriptionServiceURL'] ?? '',
        userData: _encodedPrefixedField(
          f.app['SubscriptionServiceUserData'] ?? '',
        ),
        contentsType: f.app['SubscriptionServiceContentsType'] ?? '',
      );
    }

    download = DownloadConfig(
      activationCode: _activationCodeField(
        f.download['ProfileActivationCode'] ?? '',
      ),
    );
    var smdp = f.download['ProfileSmdpAddress'] ?? '';
    if (smdp.isEmpty) smdp = f.download['SubscriptionServiceURL'] ?? '';
    download.smdpFqdn = _smdpFqdn(smdp);
    download.profileIccid = f.download['ProfileIccid'] ?? '';
    download.matchingId = f.download['MatchingID'] ?? '';
  }
}

/// Field buckets grouped by ODSA characteristic section.
class _Fields {
  final Map<String, String> token = {};
  final Map<String, String> app = {};
  final Map<String, String> primary = {};
  final Map<String, String> download = {};
  final Map<String, String> msg = {};
}

_Fields _jsonToFieldMap(dynamic root) {
  final f = _Fields();
  if (root is! Map) return f;

  Map? application = root['APPLICATION'] is Map ? root['APPLICATION'] : null;
  final app = application ?? root;
  final token = root['TOKEN'];

  void copy(Map src, Map<String, String> dst, List<String> keys) {
    for (final k in keys) {
      final v = src[k];
      if (v != null) dst[k] = '$v';
    }
  }

  if (token is Map) {
    copy(token, f.token, ['token', 'Validity']);
  }
  copy(app, f.app, [
    'OperationResult',
    'PrimaryAppEligibility',
    'SubscriptionResult',
    'PollingInterval',
    'PollingIntervalUnit',
    'TemporaryToken',
    'TemporaryTokenExpiry',
    'OperationTargets',
    'RegisterNotifStatus',
    'GeneralErrorText',
    'SubscriptionServiceURL',
    'SubscriptionServiceUserData',
    'SubscriptionServiceContentsType',
  ]);

  final primary = app['PrimaryConfiguration'];
  Map? download = app['DownloadInfo'] is Map ? app['DownloadInfo'] : null;
  Map? msg = app['MSG'] is Map ? app['MSG'] : null;
  if (primary is Map) {
    copy(primary, f.primary, [
      'ServiceStatus',
      'PollingInterval',
      'PollingIntervalUnit',
    ]);
    download ??= primary['DownloadInfo'] is Map
        ? primary['DownloadInfo']
        : null;
    msg ??= primary['MSG'] is Map ? primary['MSG'] : null;
  }
  if (download is Map) {
    copy(download, f.download, [
      'ProfileActivationCode',
      'ProfileSmdpAddress',
      'ProfileIccid',
      'SubscriptionServiceURL',
      'MatchingID',
    ]);
  }
  if (msg is Map) {
    copy(msg, f.msg, [
      'Title',
      'Message',
      'Accept_btn',
      'Accept_btn_label',
      'Reject_btn',
      'Reject_btn_label',
      'Accept_freetext',
      'Accept_freetext_hint',
      'Accept_freetext_validation',
      'Accept_freetext_validation_failed_error_text',
    ]);
  }
  return f;
}

_Fields _xmlToFieldMap(String text) {
  final f = _Fields();
  final doc = XmlDocument.parse(text);
  for (final ch in doc.findAllElements('characteristic')) {
    final type = ch.getAttribute('type');
    switch (type) {
      case 'TOKEN':
        _collectParams(ch, f.token);
        break;
      case 'APPLICATION':
        _collectParams(ch, f.app);
        for (final inner in ch.findElements('characteristic')) {
          switch (inner.getAttribute('type')) {
            case 'PrimaryConfiguration':
              _collectParams(inner, f.primary);
              for (final pc in inner.findElements('characteristic')) {
                if (pc.getAttribute('type') == 'DownloadInfo') {
                  _collectParams(pc, f.download);
                } else if (pc.getAttribute('type') == 'MSG') {
                  _collectParams(pc, f.msg);
                }
              }
              break;
            case 'DownloadInfo':
              _collectParams(inner, f.download);
              break;
            case 'MSG':
              _collectParams(inner, f.msg);
              break;
          }
        }
        break;
    }
  }
  return f;
}

void _collectParams(XmlElement element, Map<String, String> dst) {
  for (final p in element.children.whereType<XmlElement>()) {
    final name = p.name.local;
    if (name == 'parm' || name == 'param') {
      final key = p.getAttribute('name');
      final value = p.getAttribute('value');
      if (key != null && value != null) dst[key] = value;
    }
  }
}

int _atoi(String? s) => int.tryParse((s ?? '').trim()) ?? 0;

bool _one(String? s) => (s ?? '').trim() == '1';

List<String> _splitList(String s) {
  if (s.isEmpty) return const [];
  return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

List<Operation> _splitOperations(String s) =>
    _splitList(s).map((e) => Operation(e)).toList();

String _encodedPrefixedField(String value) {
  value = value.trim();
  if (value.startsWith('encodedValue=')) {
    value = value.substring('encodedValue='.length);
  }
  if (value.isEmpty) return '';
  try {
    return utf8.decode(base64.decode(value));
  } catch (_) {
    return value;
  }
}

String _activationCodeField(String value) {
  value = _encodedPrefixedField(value);
  if (value.isEmpty) return '';
  if (value.startsWith('LPA:')) return value;
  return 'LPA:$value';
}

String _smdpFqdn(String value) {
  final values = _splitList(_encodedPrefixedField(value));
  if (values.isEmpty) return '';
  final fqdn = values.first;
  final uri = Uri.tryParse(fqdn);
  if (uri != null && uri.host.isNotEmpty) return uri.host;
  return fqdn;
}
