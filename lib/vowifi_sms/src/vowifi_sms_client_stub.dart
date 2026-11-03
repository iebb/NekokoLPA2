import 'dart:async';

import 'models.dart';

class VowifiSmsClient {
  VowifiSmsClient({
    required this.config,
    this.authSecretProvider,
    this.digestAkaProvider,
    this.akaProvider,
    this.onLog,
  });

  final VowifiSmsConfig config;
  final Future<String?> Function(VowifiDigestChallenge challenge)?
  authSecretProvider;
  final Future<VowifiAkaResponse?> Function(VowifiDigestChallenge challenge)?
  digestAkaProvider;
  final Future<VowifiAkaResponse?> Function(VowifiAkaChallenge challenge)?
  akaProvider;
  final void Function(String line)? onLog;
  final StreamController<VowifiSmsEvent> _events =
      StreamController<VowifiSmsEvent>.broadcast();

  Stream<VowifiSmsEvent> get events => _events.stream;
  DateTime? get registeredUntil => null;
  Duration? get registeredDuration => null;
  String get publicIdentity => '';
  List<String> get associatedIdentities => const <String>[];
  String get preferredIdentity => '';

  void setPreferredIdentity(String identity) {}

  Future<void> connectAndRegister() async {
    throw UnsupportedError('VoWiFi SMS is not available on this platform.');
  }

  Future<void> refreshRegistration() async {
    throw UnsupportedError('VoWiFi SMS is not available on this platform.');
  }

  Future<void> disconnect() async {}

  Future<void> sendTextSms(String to, String text) async {
    throw UnsupportedError('VoWiFi SMS is not available on this platform.');
  }
}
