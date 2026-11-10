import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import '../settings/app_settings.dart';

class SmdpException implements Exception {
  final String subjectCode;
  final String reasonCode;
  final String subjectIdentifier;
  final String message;
  final int? statusCode;

  SmdpException({
    required this.subjectCode,
    required this.reasonCode,
    required this.subjectIdentifier,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    String detail = "SM-DP+ Error ($subjectCode, $reasonCode)";
    if (statusCode != null) detail += " [HTTP $statusCode]";
    return "$detail\n"
        "Identifier: $subjectIdentifier\n"
        "Message: $message";
  }
}

class SmdpClient {
  static final Logger _log = Logger('SmdpClient');

  static const bool _enableTestDnsOverride = bool.fromEnvironment(
    'NBLESIM_ENABLE_TEST_FAULTS',
    defaultValue: false,
  );
  static const String _testDnsOverrideHost = String.fromEnvironment(
    'SMDP_TEST_DNS_OVERRIDE_HOST',
  );
  static const String _testDnsOverrideIp = String.fromEnvironment(
    'SMDP_TEST_DNS_OVERRIDE_IP',
  );

  /// Bounds one ES9+ exchange end to end.
  ///
  /// Generous because building a bound profile package legitimately takes the
  /// SM-DP+ a while, but finite: a server that accepts the socket and never
  /// answers would otherwise hold the card session open indefinitely.
  static const Duration requestTimeout = Duration(seconds: 90);

  static const Duration _connectionTimeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> post({
    required String smdpAddress,
    required String endpoint,
    required Map<String, dynamic> bodyData,
    bool checkStatus = true,
  }) async {
    final smdpAddress0 = smdpAddress.trim();
    final proxyConfig = AppSettings().rspProxyConfig;
    final url = proxyConfig.buildRspUri(
      rspAddress: smdpAddress0,
      endpoint: endpoint,
      useDefaultWebProxy: kIsWeb,
    );
    final headers = kIsWeb
        ? {'Content-Type': 'application/json'}
        : {
            'User-Agent': 'gsma-rsp-lpad',
            'X-Admin-Protocol': 'gsma/rsp/v2.2.0',
            'Content-Type': 'application/json',
          };

    final body = jsonEncode(bodyData);
    final stopwatch = Stopwatch()..start();

    try {
      _log.info(
        "SM-DP+ POST $endpoint -> $url "
        "(proxy=${proxyConfig.displayLabel}, bodyBytes=${body.length})",
      );
      _log.fine("HEADERS: $headers");
      _log.fine("BODY: $body");

      final response = await _post(url, headers: headers, body: body);

      stopwatch.stop();
      _log.info(
        "SM-DP+ RESPONSE $endpoint <- ${response.statusCode} "
        "(${stopwatch.elapsedMilliseconds}ms, bodyBytes=${response.body.length})",
      );
      _log.fine("BODY: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _log.info("SM-DP+ RESPONSE $endpoint keys: ${data.keys.join(', ')}");
        }
        if (checkStatus) {
          _checkResponse(data, response.statusCode);
        }
        return data;
      } else {
        throw Exception(
          "SM-DP+ Network Error ${response.statusCode}: ${response.body}",
        );
      }
    } on SmdpException {
      rethrow;
    } on TimeoutException {
      stopwatch.stop();
      _log.severe(
        "SmdpClient timed out on $endpoint after "
        "${stopwatch.elapsedMilliseconds}ms",
      );
      throw Exception(
        "SM-DP+ at $smdpAddress0 did not respond within "
        "${requestTimeout.inSeconds}s",
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      if (e.toString().contains("SM-DP+")) rethrow;
      _log.severe(
        "SmdpClient connection error on $endpoint after "
        "${stopwatch.elapsedMilliseconds}ms: $e",
        e,
        stackTrace,
      );
      throw Exception("Failed to contact SM-DP+ at $smdpAddress: $e");
    }
  }

  static Future<http.Response> _post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
  }) async {
    if (kIsWeb) {
      return http
          .post(url, headers: headers, body: body)
          .timeout(requestTimeout);
    }

    // SM-DP+ and SM-DS servers present certificates from GSMA CIs and private
    // roots that no platform trust store carries, and the eUICC, not this
    // connection, authenticates the server. So any certificate is accepted
    // here, on a client used for this request alone: nothing else in the
    // process may inherit that.
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
    final proxyRule = AppSettings().rspProxyConfig.dartHttpProxyRule;
    if (proxyRule != null) {
      httpClient.findProxy = (_) => proxyRule;
    } else {
      _applyTestDnsOverride(httpClient, url);
    }

    final client = IOClient(httpClient);
    try {
      return await client
          .post(url, headers: headers, body: body)
          .timeout(requestTimeout);
    } finally {
      client.close();
    }
  }

  static void _applyTestDnsOverride(HttpClient client, Uri url) {
    if (!_enableTestDnsOverride ||
        _testDnsOverrideHost.isEmpty ||
        _testDnsOverrideIp.isEmpty ||
        url.host.toLowerCase() != _testDnsOverrideHost.toLowerCase()) {
      return;
    }

    final address = InternetAddress.tryParse(_testDnsOverrideIp);
    if (address == null) {
      throw ArgumentError.value(
        _testDnsOverrideIp,
        'SMDP_TEST_DNS_OVERRIDE_IP',
        'must be a numeric IPv4 or IPv6 address',
      );
    }

    _log.warning('Using compile-time test DNS override for ${url.host}');
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      if (proxyHost != null || proxyPort != null) {
        throw StateError('The test DNS override requires a direct connection');
      }
      if (uri.host.toLowerCase() != _testDnsOverrideHost.toLowerCase()) {
        throw StateError('Unexpected host while using the test DNS override');
      }

      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final connectionTask = await Socket.startConnect(address, port);
      if (uri.scheme != 'https') {
        return connectionTask;
      }

      final secureSocket = connectionTask.socket.then<Socket>(
        (socket) => SecureSocket.secure(
          socket,
          host: uri.host,
          onBadCertificate: (_) => true,
        ),
      );
      return ConnectionTask.fromSocket<Socket>(
        secureSocket,
        connectionTask.cancel,
      );
    };
  }

  static void _checkResponse(Map<String, dynamic> data, int httpStatus) {
    if (data.containsKey('header')) {
      final header = data['header'];
      if (header.containsKey('functionExecutionStatus')) {
        final status = header['functionExecutionStatus'];
        if (status['status'] == 'Failed') {
          final codeData = status['statusCodeData'] ?? {};
          throw SmdpException(
            subjectCode: codeData['subjectCode'] ?? 'N/A',
            reasonCode: codeData['reasonCode'] ?? 'N/A',
            subjectIdentifier: codeData['subjectIdentifier'] ?? 'N/A',
            message: codeData['message'] ?? 'Unknown SM-DP+ Error',
            statusCode: httpStatus,
          );
        }
      }
    }
  }
}
