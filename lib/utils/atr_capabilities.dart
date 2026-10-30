/// Capabilities advertised by a structurally valid ISO/IEC 7816-3 ATR.
/// A missing optional eUICC flag does not establish that a card is not an eUICC.
class AtrCapabilities {
  /// ETSI TS 102 221 V17.1.0, 6.3.3/Table 6.7: b8 and b2 of the first
  /// global TB(i > 2) following a T=15 indication advertise eUICC functions.
  /// Returns null for unavailable, truncated, malformed or checksum-invalid ATRs.
  static bool? supportsEuicc(String? atr) {
    if (atr == null) return null;
    final hex = atr.replaceAll(RegExp(r'\s+'), '');
    if (hex.length < 4 ||
        hex.length > 66 ||
        hex.length.isOdd ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      return null;
    }
    final bytes = [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
    if (bytes[0] != 0x3B && bytes[0] != 0x3F) return null;
    final historicalCount = bytes[1] & 0x0F;
    var present = bytes[1] >> 4;
    var offset = 2;
    var group = 1;
    var protocol = 0;
    var needsChecksum = false;
    bool? globalEuicc;
    while (true) {
      if ((present & 1) != 0) {
        if (offset >= bytes.length) return null;
        offset++; // TA
      }
      if ((present & 2) != 0) {
        if (offset >= bytes.length) return null;
        final tb = bytes[offset++];
        if (protocol == 15 && group > 2 && globalEuicc == null) {
          globalEuicc = (tb & 0x82) == 0x82;
        }
      }
      if ((present & 4) != 0) {
        if (offset >= bytes.length) return null;
        offset++; // TC
      }
      if ((present & 8) == 0) break;
      if (offset >= bytes.length) return null;
      final td = bytes[offset++];
      protocol = td & 0x0F;
      needsChecksum |= protocol != 0;
      present = td >> 4;
      group++;
    }
    if (offset + historicalCount + (needsChecksum ? 1 : 0) != bytes.length) {
      return null;
    }
    if (needsChecksum && bytes.skip(1).fold<int>(0, (xor, b) => xor ^ b) != 0) {
      return null;
    }
    return globalEuicc ?? false;
  }
}
