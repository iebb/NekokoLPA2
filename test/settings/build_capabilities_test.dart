import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/plugins/plugin_manager.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/settings/build_capabilities.dart';
import 'package:nlpa2/utils/platform_adapter.dart';

void main() {
  group('BuildCapabilities', () {
    test(
      'Community names are Android-only and accept legacy Open identities',
      () {
        for (final entry in {
          'open': 'community',
          'community': 'community',
          'open-rooted': 'community-rooted',
          'community-rooted': 'community-rooted',
        }.entries) {
          expect(
            BuildCapabilities.variantForPlatform(entry.key, isAndroid: true),
            entry.value,
          );
          expect(
            BuildCapabilities.variantForPlatform(entry.key, isAndroid: false),
            'std',
          );
        }
        for (final variant in ['esim9', 'std', 'sekiu']) {
          expect(
            BuildCapabilities.variantForPlatform(variant, isAndroid: false),
            variant,
          );
        }
      },
    );

    test('recognizes every supported 9eSIM identity signal', () {
      expect(BuildCapabilities.isEsim9Variant('esim9'), isTrue);
      expect(BuildCapabilities.isEsim9Variant('9eSIM'), isTrue);

      for (final identity
          in <
            ({bool flag, String environment, String flavor, String packageName})
          >[
            (
              flag: true,
              environment: 'sekiu',
              flavor: 'sekiu',
              packageName: 'ee.nekoko.nlpa2.sekiu',
            ),
            (
              flag: false,
              environment: 'esim9',
              flavor: 'sekiu',
              packageName: 'ee.nekoko.nlpa2.sekiu',
            ),
            (
              flag: false,
              environment: 'sekiu',
              flavor: 'esim9',
              packageName: 'ee.nekoko.nlpa2.sekiu',
            ),
            (
              flag: false,
              environment: 'sekiu',
              flavor: 'sekiu',
              packageName: '9esim',
            ),
            (
              flag: false,
              environment: 'sekiu',
              flavor: 'sekiu',
              packageName: 'com.9esim.nlpa',
            ),
            (
              flag: false,
              environment: 'sekiu',
              flavor: 'sekiu',
              packageName: 'ee.nekoko.nlpa.flavor1',
            ),
          ]) {
        expect(
          BuildCapabilities.isEsim9Build(
            compileTimeFlag: identity.flag,
            environmentVariant: identity.environment,
            flavorVariant: identity.flavor,
            packageName: identity.packageName,
          ),
          isTrue,
        );
      }
    });

    test('does not disable VoWiFi identities for other builds', () {
      expect(
        BuildCapabilities.isEsim9Build(
          compileTimeFlag: false,
          environmentVariant: 'std',
          flavorVariant: 'std',
          packageName: 'ee.nekoko.nlpa2',
        ),
        isFalse,
      );
      expect(BuildCapabilities.isEsim9Variant('sekiu'), isFalse);
      expect(BuildCapabilities.isEsim9Variant(''), isFalse);
    });

    test('VoWiFi availability excludes mobile and 9eSIM builds', () {
      expect(
        BuildCapabilities.isVowifiAvailable(
          isEsim9Build: false,
          isAndroid: false,
          isIOS: false,
        ),
        isTrue,
      );
      expect(
        BuildCapabilities.isVowifiAvailable(
          isEsim9Build: false,
          isAndroid: true,
          isIOS: false,
        ),
        isFalse,
      );
      expect(
        BuildCapabilities.isVowifiAvailable(
          isEsim9Build: true,
          isAndroid: false,
          isIOS: false,
        ),
        isFalse,
      );
      expect(
        BuildCapabilities.isVowifiAvailable(
          isEsim9Build: false,
          isAndroid: false,
          isIOS: true,
        ),
        isFalse,
      );
    });

    test('legacy state resets while current consent remains enabled', () {
      expect(
        BuildCapabilities.isVowifiEnabled(
          available: true,
          storedEnabled: true,
          consentVersion: null,
        ),
        isFalse,
      );
      expect(
        BuildCapabilities.isVowifiEnabled(
          available: true,
          storedEnabled: true,
          consentVersion: BuildCapabilities.vowifiConsentVersion,
        ),
        isTrue,
      );
      expect(
        BuildCapabilities.isVowifiEnabled(
          available: false,
          storedEnabled: true,
          consentVersion: BuildCapabilities.vowifiConsentVersion,
        ),
        isFalse,
      );
    });

    test('AppSettings masks VoWiFi for compile-time 9eSIM builds', () {
      const compileTimeFlag = bool.fromEnvironment('ESIM9_BUILD');
      const environmentVariant = String.fromEnvironment('APP_VARIANT');
      final expectedEsim9 = BuildCapabilities.isEsim9Build(
        compileTimeFlag: compileTimeFlag,
        environmentVariant: environmentVariant,
        flavorVariant: '',
        packageName: '',
      );

      expect(AppSettings().isEsim9Build, expectedEsim9);
      expect(
        AppSettings().vowifiAvailable,
        BuildCapabilities.isVowifiAvailable(
          isEsim9Build: expectedEsim9,
          isAndroid: PlatformX.isAndroid,
          isIOS: PlatformX.isIOS,
        ),
      );
      expect(AppSettings().vowifiEnabled, isFalse);
    });

    test('VoWiFi requires disclaimer acceptance on available builds', () async {
      final settings = AppSettings();

      await settings.setVowifiEnabled(true);
      expect(settings.vowifiEnabled, isFalse);

      await settings.setVowifiEnabled(true, disclaimerAccepted: true);
      expect(settings.vowifiEnabled, settings.vowifiAvailable);

      await settings.setVowifiEnabled(false);
    });
  });
}
