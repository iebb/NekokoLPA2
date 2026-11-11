import 'dart:convert';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../adapter/euicc_adapter.dart';
import '../logic/profile_download_session.dart';
import '../logic/profile_manager.dart';
import 'es9plus_service.dart';

/// The GSMA root SM-DS, used when the eUICC has no configured discovery server.
const String kRootSmdsAddress = 'lpa.ds.gsma.com';

/// A profile-availability event discovered from an SM-DS (ES11), pointing at the
/// SM-DP+ that holds the pending profile.
class DiscoveredEvent {
  /// The matching ID to use when downloading from [address].
  final String eventId;

  /// The SM-DP+ FQDN that holds the profile.
  final String address;

  const DiscoveredEvent({required this.eventId, required this.address});

  /// LPA activation code form for this event.
  String get activationCode => 'LPA:1\$$address\$$eventId';
}

/// Performs SGP.22 ES11 SM-DS discovery: the same ES9+/ES10 mutual
/// authentication as a profile download, but against the SM-DS host, whose
/// `authenticateClient` response carries the list of pending profile events.
///
/// See SGP.22 §5.8.2 (ES11.AuthenticateClient). Mirrors euicc-go's
/// `lpa.Client.Discovery`.
class SmdsDiscoveryService {
  static final Logger _log = Logger('SmdsDiscoveryService');

  final ProfileManager manager;
  final Adapter adapter;
  final Reader reader;

  SmdsDiscoveryService({
    required this.manager,
    required this.adapter,
    required this.reader,
  });

  /// Discovers pending profile events from [smdsAddress] (host only, e.g.
  /// `lpa.ds.gsma.com`). [imei] is the target device IMEI (BCD bytes).
  Future<List<DiscoveredEvent>> discover({
    required String smdsAddress,
    Uint8List? imei,
  }) async {
    final host = _hostOf(smdsAddress);
    await adapter.connect(reader);
    final channel = await manager.openSession();
    try {
      final challengeBytes = await manager.getEuiccChallenge(
        useChannel: channel,
      );
      final info1Bytes = await manager.getEuiccInfo1(useChannel: channel);

      // SM-DS uses an empty matching ID; the flow is otherwise identical.
      final session = ProfileDownloadSession(smdpAddress: host, matchingId: '');
      session.processEuiccInfo1(info1Bytes);
      session.processEuiccChallenge(challengeBytes);

      final initAuthReq = session.getInitiateAuthenticationRequest();
      final initAuthResp = await Es9PlusService().initiateAuthentication(
        smdpAddress: host,
        euiccChallenge: base64Encode(initAuthReq.euiccChallenge!),
        euiccInfo1: base64Encode(initAuthReq.euiccInfo1!.encode()),
        clientTransactionId: '0',
      );
      for (final key in [
        'serverSigned1',
        'serverSignature1',
        'euiccCiPKIdToBeUsed',
        'serverCertificate',
        'transactionId',
      ]) {
        if (initAuthResp[key] == null) {
          throw Exception('SM-DS InitiateAuthentication missing $key');
        }
      }
      final serverCert = base64Decode(initAuthResp['serverCertificate']);
      final txnId = initAuthResp['transactionId'] as String;
      session.processInitiateAuthenticationResponse(
        'Executed-Success',
        txnId,
        serverCert,
      );

      final authServerResp = await manager.authenticateServer(
        serverSigned1: base64Decode(initAuthResp['serverSigned1']),
        serverSignature1: base64Decode(initAuthResp['serverSignature1']),
        euiccCiPKIdToBeUsed: base64Decode(initAuthResp['euiccCiPKIdToBeUsed']),
        serverCertificate: serverCert,
        matchingId: '',
        imei: imei,
        useChannel: channel,
      );
      session.processAuthenticateServerResponse(authServerResp);

      final authClientReq = session.getAuthenticateClientRequest();
      final clientResp = await Es9PlusService().authenticateClient(
        smdpAddress: host,
        transactionId: txnId,
        authenticateServerResponse: base64Encode(
          authClientReq.authenticateServerResponse!.encode(),
        ),
      );

      return _parseEventEntries(clientResp);
    } finally {
      try {
        await channel.close();
      } catch (_) {}
    }
  }

  List<DiscoveredEvent> _parseEventEntries(Map<String, dynamic> resp) {
    final entries = resp['eventEntries'];
    if (entries is! List) {
      _log.warning('SM-DS response has no eventEntries: ${resp.keys}');
      return const [];
    }
    final out = <DiscoveredEvent>[];
    for (final e in entries) {
      if (e is! Map) continue;
      final eventId = (e['eventId'] as String?) ?? '';
      final address = (e['rspServerAddress'] as String?) ?? '';
      if (eventId.isEmpty || address.isEmpty) continue;
      out.add(DiscoveredEvent(eventId: eventId, address: _hostOf(address)));
    }
    return out;
  }

  String _hostOf(String address) {
    var a = address.trim();
    if (!a.contains('://')) a = 'https://$a';
    final uri = Uri.tryParse(a);
    if (uri != null && uri.host.isNotEmpty) return uri.host;
    return address.trim();
  }
}
