class ActivationCode {
  /// What each part of an activation code may contain. Shared by the download
  /// form and the activation-code text field, which check on every build.
  static final RegExp smdpFqdnPattern = RegExp(
    r'^(?=^.{4,253}\.?$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}\.?$)$',
  );
  static final RegExp matchingIdPattern = RegExp(r'^[0-9A-Z\-]*$');
  static final RegExp oidPattern = RegExp(r'^\d+(\.\d+)+$');

  final String format;
  final String smdpAddress;
  final String matchingId;
  final String? confirmationCode;
  final String? smdpOid;

  ActivationCode({
    required this.format,
    required this.smdpAddress,
    required this.matchingId,
    this.confirmationCode,
    this.smdpOid,
  });

  static ActivationCode? parse(String code) {
    // Format: LPA:1$<SMDP>$<MatchingId>[$<SMDP_OID>][$<CC>]
    if (!code.startsWith('LPA:1\$')) return null;

    final parts = code.split('\$');
    if (parts.length < 2) return null;

    return ActivationCode(
      format: parts[0],
      smdpAddress: parts[1],
      matchingId: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : "",
      smdpOid: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
      confirmationCode: parts.length > 4 && parts[4].isNotEmpty
          ? parts[4]
          : null,
    );
  }

  @override
  String toString() {
    String base = 'LPA:1\$$smdpAddress\$$matchingId';
    if (smdpOid != null || confirmationCode != null) {
      base += '\$${smdpOid ?? ""}';
    }
    if (confirmationCode != null) {
      base += '\$$confirmationCode';
    }
    return base;
  }
}
