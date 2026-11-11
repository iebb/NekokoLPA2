import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/models/asn1/rsp_definitions.g.dart';
import 'package:nlpa2/utils/hex_utils.dart';

/// The `resetOptions` value builder mirrored from ProfileManager, kept here so
/// the encoding it feeds [EuiccMemoryResetRequest] is pinned by a test.
int resetOptionsValue({
  required bool deleteOperationalProfiles,
  required bool deleteFieldLoadedTestProfiles,
  required bool resetDefaultSmdpAddress,
}) {
  var bits = 0;
  if (deleteOperationalProfiles) {
    bits |= EuiccMemoryResetRequest_resetOptions.deleteOperationalProfiles;
  }
  if (deleteFieldLoadedTestProfiles) {
    bits |= EuiccMemoryResetRequest_resetOptions.deleteFieldLoadedTestProfiles;
  }
  if (resetDefaultSmdpAddress) {
    bits |= EuiccMemoryResetRequest_resetOptions.resetDefaultSmdpAddress;
  }
  return bits;
}

void main() {
  group('EuiccMemoryResetRequest', () {
    test('purge encodes byte-for-byte as lpac chip purge', () {
      // lpac euicc/es10c.c: tag 0x82, length 2, value {0x05, 0xE0}.
      final options = resetOptionsValue(
        deleteOperationalProfiles: true,
        deleteFieldLoadedTestProfiles: true,
        resetDefaultSmdpAddress: true,
      );
      final encoded = EuiccMemoryResetRequest(resetOptions: options).encode();
      expect(HexUtils.bytesToHex(encoded).toUpperCase(), 'BF3404820205E0');
    });

    test('a single option carries its unused-bit count', () {
      final options = resetOptionsValue(
        deleteOperationalProfiles: true,
        deleteFieldLoadedTestProfiles: false,
        resetDefaultSmdpAddress: false,
      );
      final encoded = EuiccMemoryResetRequest(resetOptions: options).encode();
      expect(HexUtils.bytesToHex(encoded).toUpperCase(), 'BF340482020780');
    });
  });
}
