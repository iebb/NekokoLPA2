import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The IKEv2 shared-key AUTH payload, as both ends send it after EAP.
class VowifiIkeAuthCodec {
  const VowifiIkeAuthCodec._();

  /// AUTH method 2, "Shared Key Message Integrity Code".
  static const int sharedKeyMethod = 2;

  static final Uint8List _keyPad = Uint8List.fromList(
    'Key Pad for IKEv2'.codeUnits,
  );

  /// The AUTH data one end proves the EAP MSK with (RFC 7296 §2.15, §2.16):
  ///
  ///     prf(prf(MSK, "Key Pad for IKEv2"), message | nonce | prf(skP, id))
  ///
  /// For the initiator, [message] is its IKE_SA_INIT request, [nonce] the
  /// responder's nonce, [skP] SK_pi and [idPayload] the body of its IDi. For
  /// the responder, they are its IKE_SA_INIT response, the initiator's nonce,
  /// SK_pr and the body of the IDr it sent.
  static Uint8List sharedKeyAuthData({
    required String prf,
    required Uint8List msk,
    required Uint8List message,
    required Uint8List nonce,
    required Uint8List skP,
    required Uint8List idPayload,
  }) {
    final signedOctets = Uint8List.fromList(<int>[
      ...message,
      ...nonce,
      ..._prf(prf, skP, idPayload),
    ]);
    return _prf(prf, _prf(prf, msk, _keyPad), signedOctets);
  }

  /// Whether [authPayload], the body of a received AUTH payload, is the
  /// shared-key AUTH [sharedKeyAuthData] computes from the same inputs.
  static bool verifySharedKeyAuth({
    required Uint8List authPayload,
    required String prf,
    required Uint8List msk,
    required Uint8List message,
    required Uint8List nonce,
    required Uint8List skP,
    required Uint8List idPayload,
  }) {
    if (authPayload.length < 4 || authPayload[0] != sharedKeyMethod) {
      return false;
    }
    final want = sharedKeyAuthData(
      prf: prf,
      msk: msk,
      message: message,
      nonce: nonce,
      skP: skP,
      idPayload: idPayload,
    );
    final got = authPayload.sublist(4);
    if (got.length != want.length) return false;
    var diff = 0;
    for (var i = 0; i < want.length; i++) {
      diff |= want[i] ^ got[i];
    }
    return diff == 0;
  }

  static Uint8List _prf(String name, List<int> key, List<int> data) {
    final hash = switch (name) {
      'md5' => md5,
      'sha256' => sha256,
      _ => sha1,
    };
    return Uint8List.fromList(Hmac(hash, key).convert(data).bytes);
  }
}
