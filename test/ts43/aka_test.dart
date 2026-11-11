import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/ts43/sim/aka.dart';

Uint8List _hex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String _toHex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

void main() {
  // Ported verbatim from ts43-go sim/aka_test.go (TestRespondToChallengeMatchesAndroidVector).
  test('RespondToChallenge matches the Android EAP-AKA vector', () {
    const challengeB64 =
        'AQIAfBcBAAABBQAAXOZSkCjxysgE43GWqHJvgQIFAABrikWGrekAALNU4TxmCDPoCwUAAJT0nqXeAYlqzT0UGXINENWBBQAA7z3fhImkg+vcCKWIZBdvuYIJAAAPRUFp7KWFo+Thr78Qj9hEkB2zA0i6KakODsufBC+BJQ==';
    const responseB64 =
        '2wjHnwKln8mjjxDzMKJvLBzMHtm0X9SNBsUWEAbEiAdD7xeqqZ7nsXzukRkIhd6SDZ4bj7s=';
    const identity = '0234107813240779@nai.epc.mnc010.mcc234.3gppnetwork.org';
    const want =
        '020200281701000003030040C79F02A59FC9A38F0B0500001C141BDDDE8BEF2E502FB6793808DE7C';

    final challenge = AkaChallenge.fromBase64(challengeB64);
    final response = AkaResponse.fromBytes(base64.decode(responseB64));
    final got = respondToChallenge(challenge, response, identity);

    expect(_toHex(got), equals(want));
  });

  test('AkaChallenge round-trips RAND/AUTN', () {
    const challengeB64 =
        'AQIAfBcBAAABBQAAXOZSkCjxysgE43GWqHJvgQIFAABrikWGrekAALNU4TxmCDPoCwUAAJT0nqXeAYlqzT0UGXINENWBBQAA7z3fhImkg+vcCKWIZBdvuYIJAAAPRUFp7KWFo+Thr78Qj9hEkB2zA0i6KakODsufBC+BJQ==';
    final challenge = AkaChallenge.fromBase64(challengeB64);
    expect(challenge.rand.length, 16);
    expect(challenge.autn.length, 16);
  });

  test('AkaResponse parses success security context', () {
    const responseB64 =
        '2wjHnwKln8mjjxDzMKJvLBzMHtm0X9SNBsUWEAbEiAdD7xeqqZ7nsXzukRkIhd6SDZ4bj7s=';
    final response = AkaResponse.fromBytes(base64.decode(responseB64));
    expect(response.isSyncFailure, isFalse);
    expect(response.res, isNotNull);
    expect(response.ck, isNotNull);
    expect(response.ik, isNotNull);
  });

  test('imsiEapIdentity builds the 3GPP NAI', () {
    final id = imsiEapIdentity('234010', '234107813240779', 'nai.epc');
    expect(id, '0234107813240779@nai.epc.mnc010.mcc234.3gppnetwork.org');
  });
}
