class IccidFormatter {
  static final RegExp _trailingFiller = RegExp(r'[Ff]+$');

  /// Strips the BCD filler from the end of an ICCID for display.
  ///
  /// Only trailing filler is removed. An 'F' in the middle of an ICCID is real
  /// and occurs in the wild, so it must survive.
  ///
  /// The input has to be in printed order. ICCIDs are stored nibble-swapped, so
  /// an odd-length one carries its filler in the high nibble of the last byte —
  /// '980000000000000030F4', second from last as characters — and it only
  /// reaches the end of the string once the nibbles are swapped. Strip first
  /// and there is no trailing F to match, so the filler survives into the
  /// output.
  static String forDisplay(String iccid) {
    return iccid.replaceAll(_trailingFiller, '');
  }
}
