// Decodes real eUICC responses with the generated models.
//
// Not a `_test.dart` file, so `flutter test` ignores it. Capture first, then
// run it against the capture:
//
//   python3 tools/euicc_probe.py /tmp/euicc_capture.json
//   dart run test/models/asn1/hardware_capture_check.dart /tmp/euicc_capture.json
//
// The point is to run bytes a real card produced through the decoders, rather
// than through hand-written fixtures.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:io' show exit, stderr, stdout;
import 'dart:typed_data';

import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:asn1_codegen/runtime.dart';

Uint8List fromHex(String hex) {
  final clean = hex.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16),
  ]);
}

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
  final path = args.isNotEmpty ? args.first : '/tmp/euicc_capture.json';
  final file = io.File(path);
  if (!file.existsSync()) {
    stderr.writeln('no capture at $path — run tools/euicc_probe.py first');
    exit(2);
  }
  final capture = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, String>();
  stdout.writeln('capture: $path (${capture.length} responses)\n');

  final eidHex = capture['GetEID'];
  if (eidHex != null) {
    stdout.writeln('GetEuiccDataResponse (BF3E)');
    final bytes = fromHex(eidHex);
    final response = GetEuiccDataResponse.decode(bytes);
    final eid = response.eidValue;
    check('outer tag is BF3E', toHex(bytes.sublist(0, 2)) == 'BF3E');
    check(
      'EID decoded',
      eid != null && eid.length == 16,
      eid == null ? null : toHex(eid),
    );
    check('re-encodes byte-for-byte', toHex(response.encode()) == toHex(bytes));
  }

  final infoHex = capture['GetEUICCInfo2'];
  if (infoHex != null) {
    stdout.writeln('\nEUICCInfo2 (BF22)');
    final bytes = fromHex(infoHex);
    final info = EUICCInfo2.decode(bytes);
    check('re-encodes byte-for-byte', toHex(info.encode()) == toHex(bytes));
    check(
      'profile version present',
      info.baseProfilePackageVersion != null,
      info.baseProfilePackageVersion == null
          ? null
          : toHex(info.baseProfilePackageVersion!),
    );
    check(
      'firmware version present',
      info.euiccFirmwareVersion != null,
      info.euiccFirmwareVersion == null
          ? null
          : toHex(info.euiccFirmwareVersion!),
    );
    // The type this change restored from Supplementary.asn1.
    final ext = info.extCardResource;
    check(
      'extCardResource is structured',
      ext != null,
      ext == null
          ? null
          : 'installed=${ext.installedApplication} '
                'freeNVM=${ext.freeNonVolatileMemory} '
                'freeVM=${ext.freeVolatileMemory}',
    );
    check(
      'free non-volatile memory looks sane',
      ext?.freeNonVolatileMemory != null && ext!.freeNonVolatileMemory! > 0,
    );
    check(
      'signing CI list non-empty',
      (info.euiccCiPKIdListForSigning?.length ?? 0) > 0,
      '${info.euiccCiPKIdListForSigning?.length ?? 0} entries',
    );
    check(
      'RSP capability decoded',
      info.euiccRspCapability != null,
      info.euiccRspCapability?.toString(),
    );
    check(
      'SAS accreditation number decoded',
      (info.sasAcreditationNumber ?? '').isNotEmpty,
      info.sasAcreditationNumber,
    );
  }

  final profilesHex = capture['GetProfilesInfo'];
  if (profilesHex != null) {
    stdout.writeln('\nProfileInfoListResponse (BF2D)');
    final bytes = fromHex(profilesHex);
    final response = ProfileInfoListResponse.decode(bytes);
    check('re-encodes byte-for-byte', toHex(response.encode()) == toHex(bytes));
    final profiles = response.profileInfoListOk;
    check(
      'profile list decoded',
      profiles != null,
      '${profiles?.length ?? 0} profiles',
    );
    for (final profile in profiles ?? const <ProfileInfo>[]) {
      final iccid = profile.iccid;
      stdout.writeln(
        '    - iccid=${iccid == null ? '?' : toHex(iccid)} '
        'state=${profile.profileState} class=${profile.profileClass} '
        'name=${profile.profileName} spn=${profile.serviceProviderName}',
      );
      check('  iccid is 10 bytes', iccid != null && iccid.length == 10);
      check('  profile state decoded', profile.profileState != null);
    }
  }

  final info1Hex = capture['GetEUICCInfo1'];
  if (info1Hex != null) {
    stdout.writeln('\nEUICCInfo1 (BF20)');
    final bytes = fromHex(info1Hex);
    final info1 = EUICCInfo1.decode(bytes);
    check('re-encodes byte-for-byte', toHex(info1.encode()) == toHex(bytes));
    check(
      'lowestSvn present',
      info1.lowestSvn != null,
      info1.lowestSvn == null ? null : toHex(info1.lowestSvn!),
    );
    check(
      'verification CI list non-empty',
      (info1.euiccCiPKIdListForVerification?.length ?? 0) > 0,
      '${info1.euiccCiPKIdListForVerification?.length ?? 0} entries',
    );
  }

  final challengeHex = capture['GetEUICCChallenge'];
  if (challengeHex != null) {
    stdout.writeln('\nGetEuiccChallengeResponse (BF2E)');
    final bytes = fromHex(challengeHex);
    final response = GetEuiccChallengeResponse.decode(bytes);
    check('re-encodes byte-for-byte', toHex(response.encode()) == toHex(bytes));
    check(
      'challenge is 16 bytes',
      response.euiccChallenge?.length == 16,
      response.euiccChallenge == null ? null : toHex(response.euiccChallenge!),
    );
  }

  final addressesHex = capture['GetEuiccConfiguredAddresses'];
  if (addressesHex != null) {
    stdout.writeln('\nEuiccConfiguredDataResponse (BF3C)');
    final bytes = fromHex(addressesHex);
    final response = EuiccConfiguredDataResponse.decode(bytes);
    check('re-encodes byte-for-byte', toHex(response.encode()) == toHex(bytes));
    // rootDsAddress is mandatory; defaultDpAddress is not set on every card.
    check(
      'root SM-DS address decoded',
      (response.rootDsAddress ?? '').isNotEmpty,
      response.rootDsAddress,
    );
    stdout.writeln('    defaultDpAddress: ${response.defaultDpAddress}');
  }

  final ratHex = capture['GetRat'];
  if (ratHex != null) {
    stdout.writeln('\nGetRatResponse (BF43)');
    final bytes = fromHex(ratHex);
    final response = GetRatResponse.decode(bytes);
    check('re-encodes byte-for-byte', toHex(response.encode()) == toHex(bytes));
    final rules = response.rat;
    check(
      'rules authorisation table decoded',
      rules != null,
      '${rules?.length ?? 0} rules',
    );
    for (final rule in rules ?? const <ProfilePolicyAuthorisationRule>[]) {
      stdout.writeln(
        '    - pprIds=${rule.pprIds} '
        'allowedOperators=${rule.allowedOperators?.length ?? 0} '
        'flags=${rule.pprFlags}',
      );
    }
  }

  // The nested SEQUENCE OF reading that used to be mistyped.
  final node = infoHex == null
      ? null
      : Asn1Reader(fromHex(infoHex)).readNext();
  if (node != null) {
    stdout.writeln('\nstructure');
    check(
      'EUICCInfo2 node has children',
      node.children.isNotEmpty,
      '${node.children.length} children',
    );
  }

  stdout.writeln(
    '\n${_failures == 0 ? 'all checks passed' : '$_failures check(s) FAILED'}',
  );
  exit(_failures == 0 ? 0 : 1);
}
