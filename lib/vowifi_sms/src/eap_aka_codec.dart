import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class VowifiEapAkaCodec {
  const VowifiEapAkaCodec._();

  static const int _atMac = 11;

  static Uint8List buildSynchronizationFailureResponse({
    required int identifier,
    required List<int> auts,
  }) {
    if (auts.length != 14) {
      throw ArgumentError.value(auts.length, 'auts.length', 'must be 14 bytes');
    }

    const eapResponse = 2;
    const eapAka = 23;
    const synchronizationFailure = 4;
    const atAuts = 4;
    const attributeLengthWords = 4;
    const packetLength = 24;

    return Uint8List.fromList(<int>[
      eapResponse,
      identifier & 0xff,
      0,
      packetLength,
      eapAka,
      synchronizationFailure,
      0,
      0,
      atAuts,
      attributeLengthWords,
      ...auts,
    ]);
  }

  /// Whether [packet] carries exactly one AT_MAC, and it is the HMAC-SHA1-128
  /// of the packet under [kAut] with the MAC field zeroed (RFC 4187 §10.15).
  ///
  /// This is how the peer knows an EAP-AKA request came from the server that
  /// holds the session keys, rather than from whoever relays it.
  static bool hasValidMac(Uint8List packet, Uint8List kAut) {
    if (packet.length < 8) return false;
    final length = (packet[2] << 8) | packet[3];
    if (length < 8 || length > packet.length) return false;

    int? macOffset;
    var offset = 8;
    while (offset + 2 <= length) {
      final attrLength = packet[offset + 1] * 4;
      if (attrLength == 0 || offset + attrLength > length) return false;
      if (packet[offset] == _atMac) {
        if (macOffset != null || attrLength != 20) return false;
        macOffset = offset + 4;
      }
      offset += attrLength;
    }
    if (macOffset == null || offset != length) return false;

    final zeroed = Uint8List.fromList(packet.sublist(0, length));
    zeroed.fillRange(macOffset, macOffset + 16, 0);
    final want = Hmac(sha1, kAut).convert(zeroed).bytes;
    var diff = 0;
    for (var i = 0; i < 16; i++) {
      diff |= want[i] ^ packet[macOffset + i];
    }
    return diff == 0;
  }
}
