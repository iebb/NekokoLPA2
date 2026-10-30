import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/utils/atr_capabilities.dart';

void main() {
  test('reads the eUICC flag in TB3 following TD2 T=15', () {
    expect(AtrCapabilities.supportsEuicc('3B80802F82AD'), isTrue);
    expect(AtrCapabilities.supportsEuicc('3f 80 80 2f 82 ad'), isTrue);
  });
  test('requires both b8 and b2 in the global byte', () {
    expect(AtrCapabilities.supportsEuicc('3B80802F80AF'), isFalse);
    expect(AtrCapabilities.supportsEuicc('3B80802F022D'), isFalse);
  });
  test('does not scan historical bytes for a matching bit pattern', () {
    expect(AtrCapabilities.supportsEuicc('3B028282'), isFalse);
  });
  test('does not use protocol-specific TB bytes', () {
    expect(AtrCapabilities.supportsEuicc('3B2082'), isFalse);
    expect(AtrCapabilities.supportsEuicc('3B80218223'), isFalse);
  });
  test('the optional global TB can be absent on a real eUICC ATR', () {
    expect(
      AtrCapabilities.supportsEuicc(
        '3B9F96801FC78031E073FE211B57AA866016010001BA',
      ),
      isFalse,
    );
  });
  test('a later global byte cannot override the first global TB', () {
    expect(AtrCapabilities.supportsEuicc('3B8080AF802F8282'), isFalse);
  });
  test('checks interface layout, historical length and checksum', () {
    for (final atr in ['3B80802F82AA', '3B80812F82AD', '3B0282', '3B0082']) {
      expect(AtrCapabilities.supportsEuicc(atr), isNull, reason: atr);
    }
  });
  test('truncated interface chains are unknown', () {
    const atr = '3B80802F82AD';
    for (var end = 0; end < atr.length; end += 2) {
      expect(AtrCapabilities.supportsEuicc(atr.substring(0, end)), isNull);
    }
  });
  test('missing or malformed ATRs are unknown', () {
    for (final atr in [null, '', '3B0', '3B0X', '0000', '3B${'00' * 34}']) {
      expect(AtrCapabilities.supportsEuicc(atr), isNull);
    }
    expect(AtrCapabilities.supportsEuicc('3B00'), isFalse);
  });
}
