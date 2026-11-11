import 'package:http/http.dart' as http;

import '../ts43/errors.dart';
import 'ts43_entitlement_http.dart';

/// Web (package:http) TS.43 transport. Requests are routed through the same
/// reverse proxy the SM-DP+ client uses to work around browser CORS; cookies
/// are managed by the browser, so per-cookie tracking is best-effort.
class _WebTransport implements Ts43Transport {
  final http.Client _client = http.Client();

  String _proxied(String url) {
    final uri = Uri.parse(url);
    final hostPath =
        '${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}';
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return 'https://nlpa-data.nekoko.ee/ts43/$hostPath$query';
  }

  @override
  Future<Ts43HttpResponse> doRaw(Ts43HttpRequest request) async {
    final uri = Uri.parse(_proxied(request.url));
    final headers = Map<String, String>.from(request.headers);
    if (request.cookies.isNotEmpty) {
      headers['cookie'] = request.cookies.join('; ');
    }
    final resp = request.method == Ts43Method.post
        ? await _client.post(uri, headers: headers, body: request.body)
        : await _client.get(uri, headers: headers);

    final cookies = <String>[];
    final setCookie = resp.headers['set-cookie'];
    if (setCookie != null) {
      for (final part in setCookie.split(',')) {
        final pair = part.split(';').first.trim();
        if (pair.contains('=')) cookies.add(pair);
      }
    }
    if (resp.statusCode < 200 || resp.statusCode > 299) {
      throw Ts43HttpError(statusCode: resp.statusCode, body: resp.bodyBytes);
    }
    return Ts43HttpResponse(resp.bodyBytes, cookies);
  }

  @override
  void close() => _client.close();
}

Ts43Transport createTransport({Duration? timeout}) => _WebTransport();
