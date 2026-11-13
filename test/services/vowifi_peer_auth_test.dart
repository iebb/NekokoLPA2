import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/vowifi_sms/src/eap_aka_codec.dart';
import 'package:nlpa2/vowifi_sms/src/ike_auth_codec.dart';

// The expected values were computed with Python's hmac module, independently
// of the code under test.

Uint8List _hex(String value) => Uint8List.fromList(<int>[
  for (var i = 0; i < value.length; i += 2)
    int.parse(value.substring(i, i + 2), radix: 16),
]);

Uint8List _range(int start, int end) =>
    Uint8List.fromList(List<int>.generate(end - start, (i) => start + i));

final Uint8List _kAut = _range(0x10, 0x20);

/// EAP-Request/AKA-Challenge, identifier 0x2a, with AT_RAND, AT_AUTN and
/// AT_MAC, in that order. AT_MAC's value starts at byte 52.
Uint8List _challenge(List<int> mac) => Uint8List.fromList(<int>[
  1, 0x2a, 0, 68, 23, 1, 0, 0, //
  1, 5, 0, 0, ..._range(0xa0, 0xb0),
  2, 5, 0, 0, ..._range(0xb0, 0xc0),
  11, 5, 0, 0, ...mac,
]);

final Uint8List _goodMac = _hex('db201a5352c4e89af16a8f82cd60c7d8');

void main() {
  group('EAP-AKA AT_MAC', () {
    test('accepts the MAC computed under K_aut', () {
      expect(VowifiEapAkaCodec.hasValidMac(_challenge(_goodMac), _kAut), true);
    });

    test('rejects a wrong key, a changed MAC or a changed attribute', () {
      final packet = _challenge(_goodMac);
      expect(VowifiEapAkaCodec.hasValidMac(packet, _range(0x11, 0x21)), false);

      final badMac = Uint8List.fromList(packet)..[52] ^= 1;
      expect(VowifiEapAkaCodec.hasValidMac(badMac, _kAut), false);

      final badRand = Uint8List.fromList(packet)..[12] ^= 1;
      expect(VowifiEapAkaCodec.hasValidMac(badRand, _kAut), false);
    });

    test('rejects a packet with no AT_MAC or two of them', () {
      final noMac = Uint8List.fromList(<int>[
        1, 0x2a, 0, 48, 23, 1, 0, 0, //
        1, 5, 0, 0, ..._range(0xa0, 0xb0),
        2, 5, 0, 0, ..._range(0xb0, 0xc0),
      ]);
      expect(VowifiEapAkaCodec.hasValidMac(noMac, _kAut), false);

      final twoMacs = Uint8List.fromList(<int>[
        ..._challenge(_goodMac),
        11,
        5,
        0,
        0,
        ..._goodMac,
      ])..[3] = 88;
      expect(VowifiEapAkaCodec.hasValidMac(twoMacs, _kAut), false);
    });

    test('rejects truncated and malformed packets', () {
      final packet = _challenge(_goodMac);
      expect(
        VowifiEapAkaCodec.hasValidMac(packet.sublist(0, 60), _kAut),
        false,
      );
      final zeroLength = Uint8List.fromList(packet)..[9] = 0;
      expect(VowifiEapAkaCodec.hasValidMac(zeroLength, _kAut), false);
      final overrun = Uint8List.fromList(packet)..[49] = 6;
      expect(VowifiEapAkaCodec.hasValidMac(overrun, _kAut), false);
    });
  });

  group('IKEv2 shared-key AUTH', () {
    final msk = _range(0, 64);
    final message = Uint8List.fromList(
      List<int>.generate(32, (i) => i % 8 + 1),
    );
    final nonce = _range(0x40, 0x50);
    final skP = _range(0x60, 0x74);
    final idPayload = Uint8List.fromList(<int>[2, 0, 0, 0, ...'ims'.codeUnits]);

    Uint8List authData(String prf) => VowifiIkeAuthCodec.sharedKeyAuthData(
      prf: prf,
      msk: msk,
      message: message,
      nonce: nonce,
      skP: skP,
      idPayload: idPayload,
    );

    bool verify(Uint8List payload, {Uint8List? nonceOverride}) =>
        VowifiIkeAuthCodec.verifySharedKeyAuth(
          authPayload: payload,
          prf: 'sha256',
          msk: msk,
          message: message,
          nonce: nonceOverride ?? nonce,
          skP: skP,
          idPayload: idPayload,
        );

    test('matches RFC 7296 for HMAC-SHA1 and HMAC-SHA256', () {
      expect(
        authData('sha1'),
        _hex('dbe71d824ae02379ec44dfb65bfba21fe21d4847'),
      );
      expect(
        authData('sha256'),
        _hex(
          '0ed09979be66bc94b1835aad1834d92277abd92d'
          '68ff8b75e05d0c55608a1bb0',
        ),
      );
    });

    test('verifies a shared-key AUTH payload', () {
      final payload = Uint8List.fromList(<int>[
        2,
        0,
        0,
        0,
        ...authData('sha256'),
      ]);
      expect(verify(payload), true);
    });

    test('rejects another method, changed data or the other end\'s inputs', () {
      final data = authData('sha256');
      expect(verify(Uint8List.fromList(<int>[1, 0, 0, 0, ...data])), false);
      expect(
        verify(Uint8List.fromList(<int>[2, 0, 0, 0, ...data])..[10] ^= 1),
        false,
      );
      expect(
        verify(Uint8List.fromList(<int>[2, 0, 0, 0, ...data.sublist(1)])),
        false,
      );
      expect(
        verify(
          Uint8List.fromList(<int>[2, 0, 0, 0, ...data]),
          nonceOverride: _range(0x41, 0x51),
        ),
        false,
      );
      expect(verify(Uint8List.fromList(<int>[2, 0, 0])), false);
    });
  });
}
