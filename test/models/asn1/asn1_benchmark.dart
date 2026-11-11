// Times the ASN.1 decode/encode paths against real captured data.
//
//   dart run test/models/asn1/asn1_benchmark.dart [fixtures dir]
//
// Not a test: it prints timings rather than asserting them, so it stays out of
// `flutter test`. Run it before and after touching the reader or the emitted
// decoders.

import 'dart:convert';
import 'dart:io' as io;
import 'dart:io' show stdout;
import 'dart:typed_data';

import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:asn1_codegen/runtime.dart';
import 'package:nlpa2/utils/hex_utils.dart';

Uint8List fromHex(String hex) {
  final clean = hex.replaceAll(RegExp(r'\s'), '');
  return Uint8List.fromList([
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16),
  ]);
}

void bench(String name, int reps, void Function() body) {
  for (var i = 0; i < reps ~/ 10 + 1; i++) {
    body(); // warm up
  }
  final watch = Stopwatch()..start();
  for (var i = 0; i < reps; i++) {
    body();
  }
  watch.stop();
  final perOp = watch.elapsedMicroseconds / reps;
  stdout.writeln(
    '  ${name.padRight(44)} '
    '${perOp.toStringAsFixed(1).padLeft(9)} us/op   '
    '${(reps / (watch.elapsedMicroseconds / 1e6)).round().toString().padLeft(8)} ops/s',
  );
}

void main(List<String> args) {
  final dir = args.isNotEmpty ? args.first : 'test/models/asn1/fixtures';

  final capture =
      (jsonDecode(io.File('$dir/live_capture.json').readAsStringSync()) as Map)
          .cast<String, String>();
  final info2 = fromHex(capture['GetEUICCInfo2']!);
  final profiles = fromHex(capture['GetProfilesInfo']!);

  final flow =
      (jsonDecode(io.File('$dir/es9_flow.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final bodies = {
    for (final e in flow)
      '${e['endpoint']}.${e['kind']}':
          jsonDecode(e['body'] as String) as Map<String, dynamic>,
  };
  final bpp = Uint8List.fromList(
    base64.decode(
      bodies['getBoundProfilePackage.response']!['boundProfilePackage']
          as String,
    ),
  );
  final certificate = Uint8List.fromList(
    base64.decode(
      bodies['initiateAuthentication.response']!['serverCertificate'] as String,
    ),
  );

  stdout.writeln('reader');
  bench(
    'Asn1Reader.readNext EUICCInfo2 ${info2.length}B',
    20000,
    () => Asn1Reader(info2).readNext(),
  );
  bench(
    'Asn1Reader.readNext BPP ${bpp.length}B',
    2000,
    () => Asn1Reader(bpp).readNext(),
  );

  final info2Node = Asn1Reader(info2).readNext()!;
  final bppNode = Asn1Reader(bpp).readNext()!;
  bench(
    'Asn1Node.children EUICCInfo2 (13 children)',
    20000,
    () => info2Node.children.length,
  );
  bench('Asn1Node.children BPP', 2000, () => bppNode.children.length);

  stdout.writeln('\ndecode');
  bench('EUICCInfo2.decode', 5000, () => EUICCInfo2.decode(info2));
  bench(
    'ProfileInfoListResponse.decode (2 profiles)',
    5000,
    () => ProfileInfoListResponse.decode(profiles),
  );
  bench(
    'Certificate.decode ${certificate.length}B',
    2000,
    () => Certificate.decode(certificate),
  );
  bench(
    'BoundProfilePackage.decode ${bpp.length}B',
    500,
    () => BoundProfilePackage.decode(bpp),
  );

  stdout.writeln('\nencode (decoded values re-encode from the retained node)');
  final decodedInfo2 = EUICCInfo2.decode(info2);
  bench('EUICCInfo2.encode (retained)', 20000, () => decodedInfo2.encode());

  stdout.writeln('\nencode (hand-built, so the encoder actually runs)');
  final built = EnableProfileRequest(
    profileIdentifier: EnableProfileRequest_profileIdentifier(
      iccid: fromHex('98000000000000000081'),
    ),
    refreshFlag: true,
  );
  bench('EnableProfileRequest.encode', 50000, () => built.encode());

  final manyVersions = EUICCInfo2(
    additionalProfilePackageVersions: List.generate(
      200,
      (_) => fromHex('020000'),
    ),
  );
  bench(
    'EUICCInfo2.encode 200-element SEQUENCE OF',
    500,
    () => manyVersions.encode(),
  );

  stdout.writeln('\nhex, which every APDU goes through in both directions');
  final oneApdu = Uint8List.fromList(List.generate(261, (i) => i & 0xFF));
  final segment = Uint8List.fromList(List.generate(1020, (i) => i & 0xFF));
  bench(
    'bytesToHex 261B (one APDU)',
    20000,
    () => HexUtils.bytesToHex(oneApdu),
  );
  bench(
    'bytesToHex 1020B (BPP segment)',
    5000,
    () => HexUtils.bytesToHex(segment),
  );
  bench('bytesToHex ${bpp.length}B', 500, () => HexUtils.bytesToHex(bpp));
  final segmentHex = HexUtils.bytesToHex(segment);
  bench('hexToBytes 1020B', 5000, () => HexUtils.hexToBytes(segmentHex));
}
