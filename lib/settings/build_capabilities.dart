class BuildCapabilities {
  BuildCapabilities._();

  // Increment this when the warning changes enough to require a fresh opt-in.
  static const int vowifiConsentVersion = 1;

  static String variantForPlatform(String variant, {required bool isAndroid}) {
    final canonical = switch (variant) {
      'open' => 'community',
      'open-rooted' => 'community-rooted',
      _ => variant,
    };
    if (!isAndroid &&
        (canonical == 'community' || canonical == 'community-rooted')) {
      return 'std';
    }
    return canonical;
  }

  static bool isEsim9Variant(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'esim9' || normalized == '9esim';
  }

  static bool isEsim9Build({
    required bool compileTimeFlag,
    required String environmentVariant,
    required String flavorVariant,
    required String packageName,
  }) {
    return compileTimeFlag ||
        isEsim9Variant(environmentVariant) ||
        isEsim9Variant(flavorVariant) ||
        isEsim9Variant(packageName) ||
        packageName == 'com.9esim.nlpa' ||
        packageName.endsWith('.flavor1');
  }

  static bool isVowifiAvailable({
    required bool isEsim9Build,
    required bool isAndroid,
    required bool isIOS,
  }) {
    return !isEsim9Build && !isAndroid && !isIOS;
  }

  static bool isVowifiEnabled({
    required bool available,
    required bool storedEnabled,
    required int? consentVersion,
  }) {
    return available && storedEnabled && consentVersion == vowifiConsentVersion;
  }

  static bool isVowifiReaderAvailable({
    required bool isAndroid,
    required bool isOmapi,
    required bool supportsRawApdu,
  }) => !isAndroid && !isOmapi && supportsRawApdu;
}
