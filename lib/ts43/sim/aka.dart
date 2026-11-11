import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

/// EAP-AKA helpers ported from `github.com/damonto/ts43-go/sim/aka.go`.
///
/// Implements the EAP-AKA challenge/response used by the TS.43 EAP relay,
/// including the custom FIPS-186-2 PRF that derives the K_aut MAC key.

const int _eapCodeRequest = 0x01;
const int _eapCodeResponse = 0x02;
const int _eapTypeAka = 0x17;

const int _akaSubtypeChallenge = 0x01;
const int _akaSubtypeSyncFailure = 0x04;

const int _attributeRand = 0x01;
const int _attributeAutn = 0x02;
// AT_RES = 0x03, AT_AUTS = 0x04 are written directly where needed.
const int _attributeMac = 0x0b;

const int _securityContextSuccess = 0xdb;
const int _securityContextSyncFailure = 0xdc;

/// 3G AUTHENTICATE request (RAND + AUTN), as sent to the USIM.
class AkaRequest {
  final Uint8List rand;
  final Uint8List autn;
  const AkaRequest({required this.rand, required this.autn});

  /// Builds the data field for the AUTHENTICATE command:
  /// `len(RAND) || RAND || len(AUTN) || AUTN`.
  Uint8List marshal() {
    if (rand.length != 16) {
      throw FormatException('RAND length ${rand.length}, want 16');
    }
    if (autn.length != 16) {
      throw FormatException('AUTN length ${autn.length}, want 16');
    }
    final out = BytesBuilder();
    out.addByte(rand.length);
    out.add(rand);
    out.addByte(autn.length);
    out.add(autn);
    return out.toBytes();
  }
}

/// 3G AUTHENTICATE response parsed from the USIM security context.
class AkaResponse {
  final Uint8List? res;
  final Uint8List? ck;
  final Uint8List? ik;
  final Uint8List? auts;

  const AkaResponse({this.res, this.ck, this.ik, this.auts});

  bool get isSyncFailure => auts != null && auts!.isNotEmpty;

  factory AkaResponse.fromBytes(List<int> data) {
    if (data.isEmpty) {
      throw const FormatException('security context is empty');
    }
    switch (data[0]) {
      case _securityContextSuccess:
        var off = 1;
        final res = _valueLength(data, off, 'RES');
        off = res.next;
        final ck = _valueLength(data, off, 'CK');
        off = ck.next;
        final ik = _valueLength(data, off, 'IK');
        return AkaResponse(res: res.value, ck: ck.value, ik: ik.value);
      case _securityContextSyncFailure:
        final auts = _valueLength(data, 1, 'AUTS');
        return AkaResponse(auts: auts.value);
      default:
        throw FormatException(
          'unknown security context tag 0x${data[0].toRadixString(16)}',
        );
    }
  }
}

class _LenValue {
  final Uint8List value;
  final int next;
  const _LenValue(this.value, this.next);
}

_LenValue _valueLength(List<int> data, int off, String field) {
  if (off >= data.length) {
    throw FormatException('$field length is missing');
  }
  final n = data[off];
  off++;
  if (n > data.length - off) {
    throw FormatException(
      '$field length $n exceeds remaining data ${data.length - off}',
    );
  }
  return _LenValue(Uint8List.fromList(data.sublist(off, off + n)), off + n);
}

/// A parsed EAP-AKA challenge packet (AT_RAND + AT_AUTN).
class AkaChallenge {
  final int identifier;
  final Uint8List rand;
  final Uint8List autn;

  const AkaChallenge({
    required this.identifier,
    required this.rand,
    required this.autn,
  });

  AkaRequest authenticationRequest() => AkaRequest(
    rand: Uint8List.fromList(rand),
    autn: Uint8List.fromList(autn),
  );

  factory AkaChallenge.fromBase64(String text) {
    return AkaChallenge.fromBytes(base64.decode(text.trim()));
  }

  factory AkaChallenge.fromBytes(List<int> data) {
    if (data.length < 8) {
      throw const FormatException('EAP-AKA challenge too short');
    }
    if (data[0] != _eapCodeRequest) {
      throw FormatException(
        'unexpected EAP code 0x${data[0].toRadixString(16)}',
      );
    }
    final packetLen = (data[2] << 8) | data[3];
    if (packetLen != data.length) {
      throw FormatException(
        'EAP length $packetLen does not match packet length ${data.length}',
      );
    }
    if (data[4] != _eapTypeAka) {
      throw FormatException(
        'unexpected EAP type 0x${data[4].toRadixString(16)}',
      );
    }
    if (data[5] != _akaSubtypeChallenge) {
      throw FormatException(
        'unexpected EAP-AKA subtype 0x${data[5].toRadixString(16)}',
      );
    }
    Uint8List? rand;
    Uint8List? autn;
    for (var off = 8; off < data.length;) {
      if (data.length - off < 2) {
        throw const FormatException('truncated EAP-AKA attribute');
      }
      final typ = data[off];
      final attrLen = data[off + 1] * 4;
      if (attrLen < 4) {
        throw FormatException('invalid EAP-AKA attribute length $attrLen');
      }
      if (attrLen > data.length - off) {
        throw const FormatException('EAP-AKA attribute exceeds packet length');
      }
      final value = data.sublist(off + 4, off + attrLen);
      switch (typ) {
        case _attributeRand:
          if (value.length != 16) {
            throw FormatException('AT_RAND length ${value.length}, want 16');
          }
          rand = Uint8List.fromList(value);
          break;
        case _attributeAutn:
          if (value.length != 16) {
            throw FormatException('AT_AUTN length ${value.length}, want 16');
          }
          autn = Uint8List.fromList(value);
          break;
      }
      off += attrLen;
    }
    if (rand == null) throw const FormatException('AT_RAND is missing');
    if (autn == null) throw const FormatException('AT_AUTN is missing');
    return AkaChallenge(identifier: data[1], rand: rand, autn: autn);
  }
}

/// Builds the EAP identity `0<IMSI>@<realm>.mncXXX.mccYYY.3gppnetwork.org`.
String imsiEapIdentity(String mccMnc, String imsi, String realm) {
  if (mccMnc.length < 5) {
    throw FormatException('MCCMNC length ${mccMnc.length}, want at least 5');
  }
  if (imsi.isEmpty) throw const FormatException('IMSI is required');
  if (realm.isEmpty) throw const FormatException('realm is required');
  final mcc = mccMnc.substring(0, 3);
  var mnc = mccMnc.substring(3);
  if (mnc.length == 2) mnc = '0$mnc';
  return '0$imsi@$realm.mnc$mnc.mcc$mcc.3gppnetwork.org';
}

/// Builds the base64-encoded EAP-AKA response for [challenge]/[response].
String respondToChallengeBase64(
  AkaChallenge challenge,
  AkaResponse response,
  String identity,
) {
  return base64.encode(respondToChallenge(challenge, response, identity));
}

/// Builds the EAP-AKA response packet for the challenge.
Uint8List respondToChallenge(
  AkaChallenge challenge,
  AkaResponse response,
  String identity,
) {
  if (response.auts != null && response.auts!.isNotEmpty) {
    if (response.auts!.length != 14) {
      throw FormatException('AUTS length ${response.auts!.length}, want 14');
    }
    return _syncFailureResponse(challenge.identifier, response.auts!);
  }
  if (response.res == null || response.res!.isEmpty) {
    throw const FormatException('RES is required');
  }
  if (response.ck == null || response.ck!.isEmpty) {
    throw const FormatException('CK is required');
  }
  if (response.ik == null || response.ik!.isEmpty) {
    throw const FormatException('IK is required');
  }
  final kAut = _deriveKAut(identity, response.ik!, response.ck!);
  return _challengeResponse(challenge.identifier, response.res!, kAut);
}

int _paddedLen(int n) => n % 4 == 0 ? n : n + 4 - n % 4;

Uint8List _challengeResponse(int identifier, Uint8List res, Uint8List kAut) {
  final resLen = _paddedLen(res.length);
  final atResLen = 4 + resLen;
  final msg = Uint8List(8 + atResLen + 20);
  msg[0] = _eapCodeResponse;
  msg[1] = identifier;
  msg[2] = (msg.length >> 8) & 0xff;
  msg[3] = msg.length & 0xff;
  msg[4] = _eapTypeAka;
  msg[5] = _akaSubtypeChallenge;

  var off = 8;
  msg[off] = 0x03; // AT_RES
  msg[off + 1] = atResLen ~/ 4;
  final resBits = res.length * 8;
  msg[off + 2] = (resBits >> 8) & 0xff;
  msg[off + 3] = resBits & 0xff;
  msg.setRange(off + 4, off + 4 + res.length, res);
  off += atResLen;

  msg[off] = _attributeMac;
  msg[off + 1] = 0x05;
  final mac = crypto.Hmac(crypto.sha1, kAut).convert(msg).bytes;
  msg.setRange(off + 4, off + 20, mac.sublist(0, 16));
  return msg;
}

Uint8List _syncFailureResponse(int identifier, Uint8List auts) {
  final msg = Uint8List(10 + auts.length);
  msg[0] = _eapCodeResponse;
  msg[1] = identifier;
  msg[2] = (msg.length >> 8) & 0xff;
  msg[3] = msg.length & 0xff;
  msg[4] = _eapTypeAka;
  msg[5] = _akaSubtypeSyncFailure;
  msg[8] = 0x04; // AT_AUTS
  msg[9] = 0x04;
  msg.setRange(10, 10 + auts.length, auts);
  return msg;
}

Uint8List _deriveKAut(String identity, Uint8List ik, Uint8List ck) {
  if (identity.isEmpty) throw const FormatException('identity is required');
  final seedInput = BytesBuilder();
  seedInput.add(utf8.encode(identity));
  seedInput.add(ik);
  seedInput.add(ck);
  final seed = crypto.sha1.convert(seedInput.toBytes()).bytes;
  final key = _fips1862Prf(Uint8List.fromList(seed), 160);
  return Uint8List.fromList(key.sublist(16, 32));
}

// --- FIPS-186-2 PRF over a raw SHA-1 block compression function. ---

Uint8List _fips1862Prf(Uint8List seed, int length) {
  final xkey = Uint8List.fromList(seed);
  final out = BytesBuilder();
  final state = <int>[
    0x67452301,
    0xefcdab89,
    0x98badcfe,
    0x10325476,
    0xc3d2e1f0,
  ];
  while (out.length < length) {
    for (var i = 0; i < 2; i++) {
      final w = _sha1G(state, xkey);
      out.add(w);
      _addMod160(xkey, w);
    }
  }
  return out.toBytes().sublist(0, length);
}

void _addMod160(Uint8List xkey, Uint8List w) {
  var carry = 1;
  for (var i = 19; i >= 0; i--) {
    carry += xkey[i] + w[i];
    xkey[i] = carry & 0xff;
    carry >>= 8;
  }
}

Uint8List _sha1G(List<int> state, Uint8List xkey) {
  final block = Uint8List(64);
  block.setRange(0, 20, xkey);
  final w = _sha1Block(state, block);
  final out = Uint8List(20);
  for (var i = 0; i < 5; i++) {
    out[i * 4] = (w[i] >> 24) & 0xff;
    out[i * 4 + 1] = (w[i] >> 16) & 0xff;
    out[i * 4 + 2] = (w[i] >> 8) & 0xff;
    out[i * 4 + 3] = w[i] & 0xff;
  }
  return out;
}

int _rotl32(int v, int n) => ((v << n) | (v >> (32 - n))) & 0xFFFFFFFF;

List<int> _sha1Block(List<int> h, Uint8List block) {
  final w = List<int>.filled(80, 0);
  for (var i = 0; i < 16; i++) {
    w[i] =
        ((block[i * 4] << 24) |
            (block[i * 4 + 1] << 16) |
            (block[i * 4 + 2] << 8) |
            block[i * 4 + 3]) &
        0xFFFFFFFF;
  }
  for (var i = 16; i < 80; i++) {
    final v = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
    w[i] = _rotl32(v, 1);
  }
  var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4];
  for (var i = 0; i < 80; i++) {
    int f, k;
    if (i < 20) {
      f = (b & c) | ((~b & 0xFFFFFFFF) & d);
      k = 0x5a827999;
    } else if (i < 40) {
      f = b ^ c ^ d;
      k = 0x6ed9eba1;
    } else if (i < 60) {
      f = (b & c) | (b & d) | (c & d);
      k = 0x8f1bbcdc;
    } else {
      f = b ^ c ^ d;
      k = 0xca62c1d6;
    }
    final temp = (_rotl32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
    e = d;
    d = c;
    c = _rotl32(b, 30);
    b = a;
    a = temp;
  }
  return <int>[
    (h[0] + a) & 0xFFFFFFFF,
    (h[1] + b) & 0xFFFFFFFF,
    (h[2] + c) & 0xFFFFFFFF,
    (h[3] + d) & 0xFFFFFFFF,
    (h[4] + e) & 0xFFFFFFFF,
  ];
}
