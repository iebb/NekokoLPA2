import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/utils/profile_redaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleEid = '8904903200000000000000001234567890';
  const sampleIccid = '89882810345678901234';
  const samplePhone = '+372 5123 4567';
  const sampleBalance = '12.34 €';

  final settings = AppSettings();

  Future<void> resetToDefaults() async {
    // Full-hide first: clearing reveal while full-hide is on is a no-op
    // for the reveal flag itself, so clear full-hide before reveal.
    settings.setFullHideSensitiveData(false);
    settings.setRevealSensitiveProfileData(false);
    await settings.setRedactEidFirst(false);
    await settings.setRedactEidMiddle(true);
    await settings.setRedactEidLast(false);
    await settings.setRedactIccidFirst(false);
    await settings.setRedactIccidMiddle(true);
    await settings.setRedactIccidLast(true);
    await settings.setNicknameRedactionMode(NicknameRedactionMode.none);
    await settings.setOperatorRedactionMode(OperatorRedactionMode.none);
    await settings.setTagsRedactionMode(TagsRedactionMode.none);
    await settings.setIconRedactionMode(IconRedactionMode.none);
    await settings.setFlagRedactionMode(FlagRedactionMode.none);
  }

  Future<void> setAllSegmentFlags(bool value) async {
    await settings.setRedactEidFirst(value);
    await settings.setRedactEidMiddle(value);
    await settings.setRedactEidLast(value);
    await settings.setRedactIccidFirst(value);
    await settings.setRedactIccidMiddle(value);
    await settings.setRedactIccidLast(value);
  }

  setUp(resetToDefaults);

  group('segment previews (true = mask)', () {
    test('defaults mask the EID middle and everything after the ICCID first segment', () {
      expect(
        ProfileRedaction.redactEidPreview(sampleEid),
        '89049032********90',
      );
      expect(
        ProfileRedaction.redactIccidPreview(sampleIccid),
        '89882810********',
      );
    });

    test('all flags off shows everything', () async {
      await setAllSegmentFlags(false);
      expect(ProfileRedaction.redactEidPreview(sampleEid), sampleEid);
      expect(ProfileRedaction.redactIccidPreview(sampleIccid), sampleIccid);
    });

    test('all flags on masks everything', () async {
      await setAllSegmentFlags(true);
      expect(ProfileRedaction.redactEidPreview(sampleEid), '********');
      expect(ProfileRedaction.redactIccidPreview(sampleIccid), '********');
    });

    test('reveal shows the full identifiers', () {
      settings.setRevealSensitiveProfileData(true);
      expect(ProfileRedaction.redactEid(sampleEid), sampleEid);
      expect(
        ProfileRedaction.redactEid(sampleEid, revealFull: true),
        sampleEid,
      );
      expect(ProfileRedaction.redactIccid(sampleIccid), sampleIccid);
    });
  });

  group('quick preset', () {
    test(
      'shows only the EID first segment and fully masks the ICCID',
      () async {
        await settings.applyQuickRedactionPreset();
        expect(settings.redactEidFirst, isFalse);
        expect(settings.redactEidMiddle, isTrue);
        expect(settings.redactEidLast, isTrue);
        expect(settings.redactIccidFirst, isTrue);
        expect(settings.redactIccidMiddle, isTrue);
        expect(settings.redactIccidLast, isTrue);
        expect(
          ProfileRedaction.redactEidPreview(sampleEid),
          '89049032********',
        );
        expect(ProfileRedaction.redactIccidPreview(sampleIccid), '********');
      },
    );
  });

  group('phone number and balance', () {
    test('masks only the last 6 digits, keeping the format', () {
      expect(ProfileRedaction.redactPhoneNumber(samplePhone), '+372 51** ****');
    });

    test('masks a short number completely', () {
      expect(ProfileRedaction.redactPhoneNumber('12345'), '*****');
      expect(ProfileRedaction.redactPhoneNumber(''), '');
      expect(ProfileRedaction.redactPhoneNumber(null), '');
    });

    test('masks the whole balance', () {
      expect(ProfileRedaction.redactBalance(sampleBalance), '********');
      expect(ProfileRedaction.redactBalance(''), '');
      expect(ProfileRedaction.redactBalance(null), '');
    });

    test('reveal shows the raw phone number and balance', () {
      settings.setRevealSensitiveProfileData(true);
      expect(ProfileRedaction.redactPhoneNumber(samplePhone), samplePhone);
      expect(ProfileRedaction.redactBalance(sampleBalance), sampleBalance);
    });
  });

  group('full-hide mode', () {
    test('masks every identifier with *', () {
      settings.setFullHideSensitiveData(true);
      expect(ProfileRedaction.redactEid(sampleEid), '********');
      expect(ProfileRedaction.redactIccid(sampleIccid), '********');
      expect(ProfileRedaction.redactPhoneNumber(samplePhone), '+*** **** ****');
      expect(ProfileRedaction.redactBalance(sampleBalance), '********');
    });

    test('full-hide wins over reveal', () {
      settings.setRevealSensitiveProfileData(true);
      settings.setFullHideSensitiveData(true);
      expect(settings.revealSensitiveProfileData, isFalse);
      expect(ProfileRedaction.redactEid(sampleEid), '********');
    });

    test('reveal and full-hide are mutually exclusive', () {
      settings.setFullHideSensitiveData(true);
      expect(settings.fullHideSensitiveData, isTrue);
      settings.setRevealSensitiveProfileData(true);
      expect(settings.revealSensitiveProfileData, isTrue);
      expect(settings.fullHideSensitiveData, isFalse);
      settings.setFullHideSensitiveData(true);
      expect(settings.fullHideSensitiveData, isTrue);
      expect(settings.revealSensitiveProfileData, isFalse);
    });
  });

  group('hasNoRedactionsConfigured', () {
    test('is true only when nothing is masked', () async {
      expect(settings.hasNoRedactionsConfigured, isFalse);
      await settings.setRedactEidMiddle(false);
      await settings.setRedactIccidMiddle(false);
      await settings.setRedactIccidLast(false);
      expect(settings.hasNoRedactionsConfigured, isTrue);
    });
  });

  group('redaction flags migration', () {
    test('flips stored old-semantics flags once', () async {
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': false,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactEidFirst'), isFalse);
      expect(prefs.getBool('redactEidMiddle'), isTrue);
      expect(prefs.getBool('redactEidLast'), isFalse);
      expect(prefs.getBool('redactIccidFirst'), isFalse);
      expect(prefs.getBool('redactIccidMiddle'), isFalse);
      expect(prefs.getBool('redactIccidLast'), isFalse);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);

      // A second run is a no-op.
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactEidFirst'), isFalse);
      expect(prefs.getBool('redactIccidFirst'), isFalse);
    });
  });
}
