import '../ts43/errors.dart';

import 'ts43_transport_stub.dart'
    if (dart.library.io) 'ts43_transport_io.dart'
    as impl;

/// HTTP method for a TS.43 request.
enum Ts43Method { get, post }

/// A fully-resolved TS.43 HTTP request to send.
class Ts43HttpRequest {
  final Ts43Method method;
  final String url;
  final Map<String, String> headers;
  final List<int>? body;

  /// Cookies as `name=value` header strings to attach.
  final List<String> cookies;

  Ts43HttpRequest({
    required this.method,
    required this.url,
    this.headers = const {},
    this.body,
    this.cookies = const [],
  });
}

/// A raw TS.43 HTTP response: body bytes plus parsed `name=value` cookies.
class Ts43HttpResponse {
  final List<int> body;
  final List<String> cookies;
  Ts43HttpResponse(this.body, this.cookies);
}

/// Transport abstraction; the concrete implementation is selected by platform.
abstract class Ts43Transport {
  /// Performs the request, returning the body and cookies. Throws
  /// [Ts43HttpError] for non-2xx responses (carrying the status for 511 retry).
  Future<Ts43HttpResponse> doRaw(Ts43HttpRequest request);
  void close();
}

/// Creates a platform-appropriate transport with the given [timeout].
Ts43Transport createTs43Transport({Duration? timeout}) =>
    impl.createTransport(timeout: timeout);

// --- Cookie helpers, ported from ts43-go request.go ---

/// Replaces/merges `next` cookies into `current`, keyed by cookie name.
List<String> mergeCookieHeaders(List<String> current, List<String> next) {
  if (next.isEmpty) return List<String>.from(current);
  final merged = List<String>.from(current);
  for (final cookie in next) {
    if (cookie.isEmpty) continue;
    final name = cookie.contains('=') ? cookie.split('=').first : cookie;
    var replaced = false;
    for (var i = 0; i < merged.length; i++) {
      final existing = merged[i];
      final existingName = existing.contains('=')
          ? existing.split('=').first
          : existing;
      if (existingName == name) {
        merged[i] = cookie;
        replaced = true;
        break;
      }
    }
    if (!replaced) merged.add(cookie);
  }
  return merged;
}
