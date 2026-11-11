// Decodes the ASN.1 carried inside a captured ES9+ exchange.
//
//   dart run test/models/asn1/es9_capture_check.dart /tmp/es9_flow.json
//
// The input is the JSON that the ES9+ bodies were extracted into: a list of
// {endpoint, kind, body}. Every base64 field in those bodies is a DER
// structure from SGP.22, so this runs a real SM-DP+ exchange through the
// generated decoders.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:io' show exit, stderr, stdout;
import 'dart:typed_data';

import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:asn1_codegen/runtime.dart';

String toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

int _failures = 0;

void check(String what, bool ok, [String? detail]) {
  stdout.writeln(
    '  ${ok ? 'ok  ' : 'FAIL'}  $what${detail == null ? '' : ' — $detail'}',
  );
  if (!ok) _failures++;
}

void main(List<String> args) {
  final path = args.isNotEmpty ? args.first : '/tmp/es9_flow.json';
  final file = io.File(path);
  if (!file.existsSync()) {
    stderr.writeln('no capture at $path');
    exit(2);
  }
  final entries = (jsonDecode(file.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final bodies = <String, Map<String, dynamic>>{
    for (final e in entries)
      '${e['endpoint']}.${e['kind']}':
          jsonDecode(e['body'] as String) as Map<String, dynamic>,
  };

  Uint8List b64(String key, String field) =>
      Uint8Ust(bodies[key]![field] as String);

  stdout.writeln('ES10b.GetEUICCInfo1 (sent to the SM-DP+)');
  final info1 = Uint8Ust(
    bodies['initiateAuthentication.request']!['euiccInfo1'] as String,
  );
  check('outer tag is BF20', toHex(info1.sublist(0, 2)) == 'BF20');
  final euiccInfo1 = EUICCInfo1.decode(info1);
  check(
    'lowestSvn present',
    euiccInfo1.lowestSvn != null,
    euiccInfo1.lowestSvn == null ? null : toHex(euiccInfo1.lowestSvn!),
  );
  check(
    'verification CI list non-empty',
    (euiccInfo1.euiccCiPKIdListForVerification?.length ?? 0) > 0,
    '${euiccInfo1.euiccCiPKIdListForVerification?.length ?? 0} entries',
  );
  check('re-encodes byte-for-byte', toHex(euiccInfo1.encode()) == toHex(info1));

  stdout.writeln('\nES9+.InitiateAuthentication response');
  final signed1 = Uint8Ust(
    bodies['initiateAuthentication.response']!['serverSigned1'] as String,
  );
  final serverSigned1 = ServerSigned1.decode(signed1);
  check(
    'transactionId present',
    serverSigned1.transactionId != null,
    serverSigned1.transactionId == null
        ? null
        : toHex(serverSigned1.transactionId!),
  );
  check(
    'serverAddress decoded',
    (serverSigned1.serverAddress ?? '').isNotEmpty,
    serverSigned1.serverAddress,
  );
  check(
    'euiccChallenge is 16 bytes',
    serverSigned1.euiccChallenge?.length == 16,
  );
  check(
    're-encodes byte-for-byte',
    toHex(serverSigned1.encode()) == toHex(signed1),
  );

  final serverCert = Uint8Ust(
    bodies['initiateAuthentication.response']!['serverCertificate'] as String,
  );
  final certificate = Certificate.decode(serverCert);
  check('server certificate parses', certificate.tbsCertificate != null);
  check(
    'certificate re-encodes byte-for-byte',
    toHex(certificate.encode()) == toHex(serverCert),
  );

  stdout.writeln(
    '\nES10b.AuthenticateServer response (sent as authenticateServerResponse)',
  );
  final authResp = Uint8Ust(
    bodies['authenticateClient.request']!['authenticateServerResponse']
        as String,
  );
  check('outer tag is BF38', toHex(authResp.sublist(0, 2)) == 'BF38');
  final node = Asn1Reader(authResp).readNext();
  check('parses as a TLV', node != null, '${node?.children.length} children');

  stdout.writeln('\nES9+.AuthenticateClient response');
  final metadataBytes = b64('authenticateClient.response', 'profileMetadata');
  final metadata = StoreMetadataRequest.decode(metadataBytes);
  check('outer tag is BF25', toHex(metadataBytes.sublist(0, 2)) == 'BF25');
  check('ICCID is 10 bytes', metadata.iccid?.length == 10);
  check(
    'serviceProviderName decoded',
    (metadata.serviceProviderName ?? '').isNotEmpty,
    metadata.serviceProviderName,
  );
  check(
    'profileName decoded',
    (metadata.profileName ?? '').isNotEmpty,
    metadata.profileName,
  );
  check(
    'profileOwner decoded',
    metadata.profileOwner?.mccMnc != null,
    metadata.profileOwner == null
        ? null
        : toHex(metadata.profileOwner!.mccMnc!),
  );
  check(
    're-encodes byte-for-byte',
    toHex(metadata.encode()) == toHex(metadataBytes),
  );

  final signed2Bytes = b64('authenticateClient.response', 'smdpSigned2');
  final smdpSigned2 = SmdpSigned2.decode(signed2Bytes);
  check('smdpSigned2 transactionId present', smdpSigned2.transactionId != null);
  check(
    'ccRequiredFlag decoded',
    smdpSigned2.ccRequiredFlag != null,
    '${smdpSigned2.ccRequiredFlag}',
  );
  check(
    'smdpSigned2 re-encodes byte-for-byte',
    toHex(smdpSigned2.encode()) == toHex(signed2Bytes),
  );

  stdout.writeln(
    '\nES10b.PrepareDownload response (sent as prepareDownloadResponse)',
  );
  final prepare = b64(
    'getBoundProfilePackage.request',
    'prepareDownloadResponse',
  );
  check('outer tag is BF21', toHex(prepare.sublist(0, 2)) == 'BF21');
  final prepared = PrepareDownloadResponse.decode(prepare);
  check('re-encodes byte-for-byte', toHex(prepared.encode()) == toHex(prepare));

  stdout.writeln('\nES9+.GetBoundProfilePackage response');
  final bpp = b64('getBoundProfilePackage.response', 'boundProfilePackage');
  check('outer tag is BF36', toHex(bpp.sublist(0, 2)) == 'BF36');
  final bound = BoundProfilePackage.decode(bpp);
  check(
    'initialiseSecureChannelRequest present',
    bound.initialiseSecureChannelRequest != null,
  );
  check(
    're-encodes byte-for-byte (${bpp.length} bytes)',
    toHex(bound.encode()) == toHex(bpp),
  );

  stdout.writeln(
    '\n${_failures == 0 ? 'all checks passed' : '$_failures check(s) FAILED'}',
  );
  exit(_failures == 0 ? 0 : 1);
}

Uint8List Uint8Ust(String base64Text) =>
    Uint8List.fromList(base64.decode(base64Text));
