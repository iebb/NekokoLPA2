import 'dart:convert';

import 'enums.dart';
import 'types.dart';

/// Parses a websheet callback line into a [WebsheetResult]. Ported from
/// `ts43-go/ts43/websheet_result.go`.
///
/// Accepts the JSON, `ODSAServiceFlow.*(...)` JS, `VoWiFiWebServiceFlow.*` JS,
/// and `/_callback` URL callback forms, with optional `TS43_ODSA_CALLBACK` /
/// `TS43_VOWIFI_CALLBACK` log prefixes.
WebsheetResult parseWebsheetResult(String text) {
  var line = text.trim();
  if (line.isEmpty) {
    throw const FormatException('websheet callback is required');
  }
  final vowifiCallback = line.startsWith('TS43_VOWIFI_CALLBACK');
  line = _trimCallbackLogPrefix(line, 'TS43_ODSA_CALLBACK');
  line = _trimCallbackLogPrefix(line, 'TS43_VOWIFI_CALLBACK');

  if (line.startsWith('{')) {
    return _fromJson(line, vowifiCallback);
  }
  if (line.contains('ODSAServiceFlow.')) {
    return _fromJs(line);
  }
  if (line.contains('VoWiFiWebServiceFlow.')) {
    return _fromVoWiFiJs(line);
  }
  if (line.contains('/_callback')) {
    return _fromUrl(line);
  }
  throw FormatException('unknown websheet callback "$line"');
}

String _trimCallbackLogPrefix(String line, String prefix) {
  line = line.trim();
  if (!line.startsWith(prefix)) return line;
  return line.substring(prefix.length).trim();
}

WebsheetResult _fromJson(String line, bool vowifiCallback) {
  final payload = jsonDecode(line) as Map<String, dynamic>;
  String s(String k) => (payload[k] as String?) ?? '';
  if (vowifiCallback || s('source').toLowerCase() == 'vowifi') {
    return _fromVoWiFiName(s('event'));
  }
  final query = <String, String>{
    'activationCode': s('activationCode'),
    'defaultSmdpAddress': firstNonEmpty([
      s('defaultSmdpAddress'),
      s('smdpFqdn'),
    ]),
    'iccid': s('iccid'),
    'imei': s('imei'),
    'nextAction': s('nextAction'),
  };
  return _fromName(s('event'), const [], query);
}

WebsheetResult _fromJs(String line) {
  final idx = line.indexOf('ODSAServiceFlow.');
  if (idx < 0) {
    throw const FormatException('ODSAServiceFlow callback is required');
  }
  final after = line.substring(idx + 'ODSAServiceFlow.'.length);
  final paren = after.indexOf('(');
  if (paren < 0) {
    throw const FormatException('callback argument list is required');
  }
  final name = after.substring(0, paren);
  final rest = after.substring(paren + 1);
  final close = rest.indexOf(')');
  if (close < 0) {
    throw const FormatException('callback argument list is not closed');
  }
  return _fromName(name, _splitJsArgs(rest.substring(0, close)), const {});
}

WebsheetResult _fromVoWiFiJs(String line) {
  final idx = line.indexOf('VoWiFiWebServiceFlow.');
  if (idx < 0) {
    throw const FormatException('VoWiFiWebServiceFlow callback is required');
  }
  final after = line.substring(idx + 'VoWiFiWebServiceFlow.'.length);
  final paren = after.indexOf('(');
  if (paren < 0) {
    throw const FormatException('callback argument list is required');
  }
  return _fromVoWiFiName(after.substring(0, paren));
}

WebsheetResult _fromVoWiFiName(String name) {
  switch (_normalizeCallbackName(name)) {
    case 'entitlementchanged':
      return const WebsheetResult(
        event: WebsheetCallbackEvent.voWiFiEntitlementChanged,
      );
    case 'dismissflow':
      return const WebsheetResult(
        event: WebsheetCallbackEvent.voWiFiDismissFlow,
      );
    default:
      throw FormatException('unknown VoWiFi websheet callback "$name"');
  }
}

WebsheetResult _fromUrl(String raw) {
  final u = Uri.parse(raw);
  final query = u.queryParameters;
  var name = _firstValue(query, ['event', 'callback', 'action', 'method']);
  if (name.isEmpty) {
    final parts = u.path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) name = parts.last;
  }
  final normalized = _normalizeCallbackName(name);
  if (normalized == 'callback' || normalized == 'esim') {
    name = _callbackNameFromQuery(query);
  }
  return _fromName(name, const [], query);
}

WebsheetResult _fromName(
  String name,
  List<String> args,
  Map<String, String> query,
) {
  switch (_normalizeCallbackName(name)) {
    case 'profilereadywithactivationcode':
    case 'activation':
      final ac = _argOrQuery(args, query, 0, [
        'activationCode',
        'activation_code',
      ]);
      if (ac.isEmpty) {
        throw const FormatException('activation code is required');
      }
      return WebsheetResult(
        event: WebsheetCallbackEvent.profileReadyWithActivationCode,
        activationCode: ac,
        iccid: _argOrQuery(args, query, 1, ['iccid', 'ICCID']),
        imei: _argOrQuery(args, query, 2, ['imei', 'IMEI']),
      );
    case 'profilereadywithdefaultsmdp':
    case 'defaultsmdp':
      final smdp = _argOrQuery(args, query, 0, [
        'defaultSmdpAddress',
        'smdp',
        'smdpFqdn',
      ]);
      final iccid = _argOrQuery(args, query, 1, ['iccid', 'ICCID']);
      if (smdp.isEmpty || iccid.isEmpty) {
        throw const FormatException('default SM-DP+ and ICCID are required');
      }
      return WebsheetResult(
        event: WebsheetCallbackEvent.profileReadyWithDefaultSmdp,
        smdpFqdn: smdp,
        iccid: iccid,
        imei: _argOrQuery(args, query, 2, ['imei', 'IMEI']),
      );
    case 'selectioncompleted':
    case 'select':
      final iccid = _argOrQuery(args, query, 0, ['iccid', 'ICCID']);
      final imei = _argOrQuery(args, query, 1, ['imei', 'IMEI']);
      if (iccid.isEmpty && imei.isEmpty) {
        throw const FormatException('selected ICCID or IMEI is required');
      }
      return WebsheetResult(
        event: WebsheetCallbackEvent.selectionCompleted,
        iccid: iccid,
        imei: imei,
      );
    case 'finishflow':
    case 'done':
      return WebsheetResult(
        event: WebsheetCallbackEvent.finishFlow,
        nextAction: _operationFromCallbackText(
          _argOrQuery(args, query, 0, ['next_action', 'nextAction']),
        ),
      );
    case 'dismissflow':
    case 'dismiss':
      return const WebsheetResult(event: WebsheetCallbackEvent.dismissFlow);
    case 'deletetoken':
      return const WebsheetResult(event: WebsheetCallbackEvent.deleteToken);
    case 'checkprofileservicestatus':
    case 'status':
      return const WebsheetResult(
        event: WebsheetCallbackEvent.checkProfileServiceStatus,
      );
    case 'deleteprofileinuse':
    case 'deleteprofile':
      return WebsheetResult(
        event: WebsheetCallbackEvent.deleteProfileInUse,
        iccid: _argOrQuery(args, query, 0, ['iccid', 'ICCID']),
      );
    case 'entitlementchanged':
      return const WebsheetResult(
        event: WebsheetCallbackEvent.voWiFiEntitlementChanged,
      );
    default:
      throw FormatException('unknown websheet callback "$name"');
  }
}

String _callbackNameFromQuery(Map<String, String> query) {
  if (_firstValue(query, ['activationCode', 'activation_code']).isNotEmpty) {
    return 'profileReadyWithActivationCode';
  }
  if (_firstValue(query, [
    'defaultSmdpAddress',
    'smdp',
    'smdpFqdn',
  ]).isNotEmpty) {
    return 'profileReadyWithDefaultSmdp';
  }
  if (_firstValue(query, ['next_action', 'nextAction']).isNotEmpty) {
    return 'finishFlow';
  }
  return '';
}

Operation _operationFromCallbackText(String s) {
  switch (_normalizeCallbackName(s)) {
    case '':
      return Operation.none;
    case 'acquireconfiguration':
    case 'acquireconf':
    case 'configuration':
      return Operation.acquireConf;
    case 'managesubscription':
    case 'manage':
      return Operation.manage;
    default:
      return Operation(s);
  }
}

List<String> _splitJsArgs(String text) {
  final args = <String>[];
  final b = StringBuffer();
  String? quote;
  var escaped = false;
  for (final r in text.split('')) {
    if (escaped) {
      b.write(r);
      escaped = false;
    } else if (r == '\\') {
      escaped = true;
    } else if (quote != null) {
      if (r == quote) {
        quote = null;
      } else {
        b.write(r);
      }
    } else if (r == "'" || r == '"') {
      quote = r;
    } else if (r == ',') {
      args.add(b.toString().trim());
      b.clear();
    } else {
      b.write(r);
    }
  }
  final last = b.toString().trim();
  if (last.isNotEmpty || text.isNotEmpty) {
    args.add(last);
  }
  return args;
}

String _normalizeCallbackName(String name) {
  name = name.trim();
  if (name.endsWith('()')) name = name.substring(0, name.length - 2);
  final b = StringBuffer();
  for (final code in name.codeUnits) {
    var c = code;
    if (c >= 0x41 && c <= 0x5a) c += 0x20; // to lower
    final isLower = c >= 0x61 && c <= 0x7a;
    final isDigit = c >= 0x30 && c <= 0x39;
    if (isLower || isDigit) b.writeCharCode(c);
  }
  return b.toString();
}

String _argOrQuery(
  List<String> args,
  Map<String, String> query,
  int index,
  List<String> keys,
) {
  if (index < args.length && args[index].isNotEmpty) {
    return args[index];
  }
  return _firstValue(query, keys);
}

String _firstValue(Map<String, String> values, List<String> keys) {
  for (final key in keys) {
    final v = values[key];
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}
