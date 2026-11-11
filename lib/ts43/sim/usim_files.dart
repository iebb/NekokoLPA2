import 'dart:typed_data';

/// USIM file identifiers and APDU constants, ported from `sim/usim.go`.
class UsimFiles {
  /// USIM ADF AID prefix (3GPP, Telecom).
  static final Uint8List usimAidPrefix = Uint8List.fromList([
    0xa0,
    0x00,
    0x00,
    0x00,
    0x87,
    0x10,
    0x02,
  ]);

  // File identifiers.
  static const int masterFile = 0x3f00;
  static const int efDir = 0x2f00;
  static const int efIccid = 0x2fe2;
  static const int efImsi = 0x6f07;
  static const int efAd = 0x6fad;
  static const int efGid1 = 0x6f3e;

  // EF read lengths used by the identity reads.
  static const int iccidLength = 10;
  static const int imsiLength = 9;
  static const int adLength = 4;

  // AUTHENTICATE (3G) command header: CLA=00 INS=88 P1=00 P2=81.
  static const int authenticateCla = 0x00;
  static const int authenticateIns = 0x88;
  static const int authenticateP1 = 0x00;
  static const int authenticateP2 = 0x81;

  // SELECT by FID: CLA=00 INS=A4 P1=00 P2=04 (return FCP template).
  static const int selectCla = 0x00;
  static const int selectIns = 0xa4;
  static const int selectByIdP1 = 0x00;
  static const int selectByNameP1 = 0x04;
  static const int selectP2 = 0x04;

  // READ BINARY: CLA=00 INS=B0. READ RECORD: CLA=00 INS=B2 (P2=04 absolute).
  static const int readBinaryCla = 0x00;
  static const int readBinaryIns = 0xb0;
  static const int readRecordCla = 0x00;
  static const int readRecordIns = 0xb2;
  static const int readRecordP2 = 0x04;

  /// Two-byte big-endian encoding of a file identifier (SELECT data field).
  static Uint8List fid(int id) =>
      Uint8List.fromList([(id >> 8) & 0xff, id & 0xff]);
}
