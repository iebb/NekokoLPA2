import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/signing_logic.dart';
import '../adapter/composite_adapter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart'; // To get navigatorKey

class DeepLinkService {
  static final Logger _log = Logger('DeepLinkService');
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<String>? _stringLinkSubscription;

  final _linkController = StreamController<String>.broadcast();
  Stream<String> get linkStream => _linkController.stream;

  final ValueNotifier<String?> pendingLpa = ValueNotifier<String?>(null);
  final ValueNotifier<Uri?> pendingSigningUri = ValueNotifier<Uri?>(null);
  final ValueNotifier<bool> triggerSelection = ValueNotifier<bool>(false);

  static const String _prefPendingLpa = 'pending_lpa_code';
  static const String _prefPendingSigning = 'pending_signing_uri';

  void init() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        handleUri(uri);
      },
      onError: (err) {
        _log.severe('Deep link URI error: $err');
      },
    );

    _stringLinkSubscription = _appLinks.stringLinkStream.listen(
      (link) {
        _handleString(link);
      },
      onError: (err) {
        _log.severe('Deep link String error: $err');
      },
    );

    if (!kIsWeb) {
      _checkCommandLineArgs();
    }

    // Initial check (especially for cold start)
    checkInitialLink();

    // Load persisted pending LPA
    SharedPreferences.getInstance().then((prefs) {
      final savedString = prefs.getString(_prefPendingLpa);
      if (savedString != null && savedString.isNotEmpty) {
        _log.info('Loaded persisted pending LPA: $savedString');
        pendingLpa.value = savedString;
      }
      final savedSigning = prefs.getString(_prefPendingSigning);
      if (savedSigning != null && savedSigning.isNotEmpty) {
        try {
          pendingSigningUri.value = Uri.parse(savedSigning);
        } catch (_) {}
      }
    });
  }

  Future<void> checkInitialLink() async {
    // Immediate check
    await _checkNow(label: 'Initial');
    // Minimal delay for late delivery
    await Future.delayed(const Duration(milliseconds: 200));
    await _checkNow(label: 'Retry');
  }

  Future<void> _checkNow({required String label}) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) handleUri(uri);

      final linkString = await _appLinks.getInitialLinkString();
      if (linkString != null) _handleString(linkString);
    } catch (e) {
      _log.severe('Failed to get initial link ($label): $e');
    }
  }

  void _handleString(String link) {
    _log.info('Handling link string: $link');
    try {
      final uri = Uri.parse(link);
      handleUri(uri);
    } catch (e) {
      _log.warning('Failed to parse link string as URI: $link, error: $e');
      // Even if parsing fails, we can try some heuristic
      if (link.startsWith('LPA:') || link.startsWith('lpa:')) {
        handleUri(Uri(scheme: 'lpa', path: link.substring(4)));
      } else if (link.contains('1\$')) {
        handleUri(Uri(scheme: 'lpa', path: link));
      }
    }
  }

  void handleUri(Uri uri) {
    String? code;

    // Check for signing endpoint first (works for both lpa:// and https://)
    if (uri.path == '/signing' ||
        uri.path == 'signing' ||
        uri.path == '/signing/') {
      _log.info('Detected signing URI, calling _handleSigningUri');
      _handleSigningUri(uri);
      return;
    }

    if (uri.scheme == 'lpa') {
      // Check if it's a signing request via lpa scheme
      if (uri.host == 'signing' || uri.path.startsWith('/signing')) {
        _log.info('Detected lpa:// signing URI');
        _handleSigningUri(uri);
        return;
      }
      // lpa:1$smdp$code
      code = uri.toString();
    } else if (uri.host.endsWith('install.lpa.ee') ||
        uri.host.endsWith('esimsetup.lpa.ee') ||
        uri.host.endsWith('esimsetup.apple.com') ||
        uri.host.endsWith('esimsetup.android.com')) {
      final path = uri.path;
      if (uri.queryParameters.containsKey('carddata')) {
        code = uri.queryParameters['carddata'];
      } else if (uri.queryParameters.containsKey('code')) {
        code = uri.queryParameters['code'];
      } else if (path.startsWith('/LPA:')) {
        code = path.substring(1); // Remove leading /
      } else if (path.startsWith('/1\$')) {
        code = path.substring(1);
      } else if (path.startsWith('/esim_qrcode_provisioning')) {
        code = uri.queryParameters['code'];
      } else if (path.startsWith('LPA:')) {
        code = path;
      }
    }

    if (code != null) {
      final index = code.indexOf('1\$');
      if (index != -1) {
        code = 'LPA:${code.substring(index)}';
      } else {
        // Fallback for codes that don't follow the 1$ pattern but are still valid
        if (!code.startsWith('LPA:')) {
          code = 'LPA:$code';
        }
      }

      _log.info('LPA code extracted: $code');
      _linkController.add(code);
      setPendingLpa(code);
    }
  }

  Future<void> setPendingLpa(String code) async {
    pendingLpa.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPendingLpa, code);
  }

  Future<void> clearPendingLpa() async {
    pendingLpa.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPendingLpa);
  }

  Future<void> clearPendingSigning() async {
    pendingSigningUri.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefPendingSigning);
  }

  void consumeCode() {
    // Deprecated in favor of clearPendingLpa
    clearPendingLpa();
  }

  Future<void> _handleSigningUri(Uri uri) async {
    final message = uri.queryParameters['message'];
    final callback = uri.queryParameters['callback'];
    if (message == null || callback == null) {
      _log.warning("Signing link missing message or callback: $uri");
      return;
    }

    String smdp = uri.queryParameters['smdp'] ?? "";
    String matchingId = message;

    if (smdp.isEmpty && message.contains('\$')) {
      final parts = message.split('\$');
      if (parts.length >= 3) {
        smdp = parts[1];
        matchingId = parts[2];
      }
    }

    if (smdp.isEmpty) {
      _log.warning("Signing link missing smdp address");
      return;
    }

    int? tac;
    int? imeiHigh;
    int? imeiLow;
    final imei = uri.queryParameters['imei'];

    final tacStr = uri.queryParameters['tac'];
    final imei1Str = uri.queryParameters['imei1'];
    final imei2Str = uri.queryParameters['imei2'];

    if (tacStr != null) tac = int.tryParse(tacStr);
    if (imei1Str != null && imei2Str != null) {
      imeiHigh = int.tryParse(imei1Str);
      imeiLow = int.tryParse(imei2Str);
    }

    // Check for available cards before attempting to sign
    final composite = CompositeAdapter();
    final readers = await composite.listReaders();
    if (readers.isEmpty) {
      _log.info("No readers found for signing, setting as pending.");
      pendingSigningUri.value = uri;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefPendingSigning, uri.toString());
      return;
    }

    // Ensure app is ready to show dialogs (important for cold-start deep links)
    if (navigatorKey.currentContext == null) {
      _log.info("Navigator context not available yet, waiting...");
      int attempts = 0;
      while (navigatorKey.currentContext == null && attempts < 50) {
        // 10s timeout
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }

    // Additional delay for stability
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final result = await SigningLogic.sign(
        smdpAddress: smdp,
        matchingId: matchingId,
        tac: tac,
        imeiHigh: imeiHigh,
        imeiLow: imeiLow,
        imei: imei,
      );

      if (result != null) {
        final callbackUri = Uri.parse(callback);
        final Map<String, String> newParams = Map.from(
          callbackUri.queryParameters,
        );
        newParams['response'] = result;

        final finalUri = callbackUri.replace(queryParameters: newParams);
        if (await canLaunchUrl(finalUri)) {
          await launchUrl(finalUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      _log.severe("Deep link signing failed: $e");
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text("Signing failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _checkCommandLineArgs() {
    // Only called when !kIsWeb
    try {
      for (final arg in Platform.executableArguments) {
        if (arg.startsWith('lpa:') || arg.contains('1\$')) {
          _log.info('Found potential link in args: $arg');
          _handleString(arg);
        }
      }
    } catch (e) {
      _log.warning('Failed to check command line args: $e');
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _stringLinkSubscription?.cancel();
    _linkController.close();
  }
}
