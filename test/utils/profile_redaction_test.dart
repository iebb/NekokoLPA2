import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/settings/app_settings.dart';
import 'package:nlpa2/utils/profile_redaction.dart';
import 'package:nlpa2/vowifi/privacy_redaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

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

    test('nothing configured shows the raw phone number and balance', () async {
      await setAllSegmentFlags(false);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(ProfileRedaction.redactPhoneNumber(samplePhone), samplePhone);
      expect(ProfileRedaction.redactBalance(sampleBalance), sampleBalance);
    });

    test('full-hide wins over nothing configured', () async {
      await setAllSegmentFlags(false);
      settings.setFullHideSensitiveData(true);
      expect(ProfileRedaction.redactPhoneNumber(samplePhone), '+*** **** ****');
      expect(ProfileRedaction.redactBalance(sampleBalance), '********');
    });
  });

  group('isSensitiveDataMasked', () {
    test('is true when something is masked', () {
      expect(settings.isSensitiveDataMasked, isTrue);
      expect(VoWifiPrivacy.isEnabled, isTrue);
    });

    test('is false when nothing is configured', () async {
      await setAllSegmentFlags(false);
      expect(settings.isSensitiveDataMasked, isFalse);
      expect(VoWifiPrivacy.isEnabled, isFalse);
    });

    test('full-hide counts as masked even with nothing configured', () async {
      await setAllSegmentFlags(false);
      settings.setFullHideSensitiveData(true);
      expect(settings.isSensitiveDataMasked, isTrue);
      expect(VoWifiPrivacy.isEnabled, isTrue);
    });

    test('reveal counts as unmasked', () {
      settings.setRevealSensitiveProfileData(true);
      expect(settings.isSensitiveDataMasked, isFalse);
      expect(VoWifiPrivacy.isEnabled, isFalse);
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

    test('full-hide wins over revealFull for display', () {
      settings.setFullHideSensitiveData(true);
      expect(
        ProfileRedaction.redactEid(sampleEid, revealFull: true),
        '********',
      );
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

  group('toggleSensitiveDataVisibility', () {
    test('masked as configured toggles to reveal', () async {
      await settings.toggleSensitiveDataVisibility();
      expect(settings.revealSensitiveProfileData, isTrue);
    });

    test('reveal toggles back to masked as configured', () async {
      settings.setRevealSensitiveProfileData(true);
      await settings.toggleSensitiveDataVisibility();
      expect(settings.revealSensitiveProfileData, isFalse);
      expect(settings.isSensitiveDataMasked, isTrue);
    });

    test('nothing configured applies the quick preset', () async {
      await setAllSegmentFlags(false);
      await settings.toggleSensitiveDataVisibility();
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactIccidFirst, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
    });

    test('full-hide with nothing configured reveals instead of preset',
        () async {
      await setAllSegmentFlags(false);
      settings.setFullHideSensitiveData(true);
      await settings.toggleSensitiveDataVisibility();
      expect(settings.fullHideSensitiveData, isFalse);
      expect(settings.revealSensitiveProfileData, isTrue);
      // The persisted no-redaction choices survive: flags stay off.
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.redactIccidMiddle, isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.isSensitiveDataMasked, isFalse);
    });

    test('leaving reveal with nothing configured applies the preset',
        () async {
      await setAllSegmentFlags(false);
      settings.setRevealSensitiveProfileData(true);
      await settings.toggleSensitiveDataVisibility();
      expect(settings.revealSensitiveProfileData, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactIccidFirst, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.isSensitiveDataMasked, isTrue);
    });

    test('full-hide with nothing configured cycles to preset in two taps',
        () async {
      await setAllSegmentFlags(false);
      settings.setFullHideSensitiveData(true);
      // Tap 1: full-hide -> reveal all.
      await settings.toggleSensitiveDataVisibility();
      expect(settings.revealSensitiveProfileData, isTrue);
      expect(settings.isSensitiveDataMasked, isFalse);
      // Tap 2: reveal -> preset (no inert step in between).
      await settings.toggleSensitiveDataVisibility();
      expect(settings.revealSensitiveProfileData, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactIccidFirst, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.isSensitiveDataMasked, isTrue);
    });

    test('full-hide with redactions configured reveals', () async {
      settings.setFullHideSensitiveData(true);
      await settings.toggleSensitiveDataVisibility();
      expect(settings.fullHideSensitiveData, isFalse);
      expect(settings.revealSensitiveProfileData, isTrue);
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

    test('masks the EID from 8 on when old middle was shown and old last masked',
        () async {
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': false,
        'redactIccidFirst': true,
        'redactIccidMiddle': false,
        'redactIccidLast': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      // The EID middle range widened to length-2, so a plain flip would
      // expose 8 digits that were masked; map it conservatively instead.
      expect(prefs.getBool('redactEidFirst'), isFalse);
      expect(prefs.getBool('redactEidMiddle'), isTrue);
      expect(prefs.getBool('redactEidLast'), isTrue);
      // The ICCID ranges did not change, so its keys flip plainly.
      expect(prefs.getBool('redactIccidFirst'), isFalse);
      expect(prefs.getBool('redactIccidMiddle'), isTrue);
      expect(prefs.getBool('redactIccidLast'), isFalse);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);
    });
    test('stores the pre-migration snapshot before flipping', () async {
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
      expect(
        jsonDecode(prefs.getString('redactionFlagsMigrationSourceV2')!),
        {
          'redactEidFirst': true,
          'redactEidMiddle': false,
          'redactEidLast': true,
          'redactIccidFirst': true,
          'redactIccidMiddle': true,
          'redactIccidLast': true,
        },
      );
    });

    test('retries an interrupted migration from the snapshot', () async {
      // A run that was killed after flipping the EID middle but before
      // the marker: the snapshot holds the original values, the middle
      // is already flipped, the marker is absent.
      SharedPreferences.setMockInitialValues({
        'redactionFlagsMigrationSourceV2': jsonEncode({
          'redactEidFirst': true,
          'redactEidMiddle': false,
          'redactEidLast': true,
          'redactIccidFirst': true,
          'redactIccidMiddle': true,
          'redactIccidLast': true,
        }),
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      // Same result as an uninterrupted run: the middle stays masked
      // instead of being flipped back to visible.
      expect(prefs.getBool('redactEidFirst'), isFalse);
      expect(prefs.getBool('redactEidMiddle'), isTrue);
      expect(prefs.getBool('redactEidLast'), isFalse);
      expect(prefs.getBool('redactIccidFirst'), isFalse);
      expect(prefs.getBool('redactIccidMiddle'), isFalse);
      expect(prefs.getBool('redactIccidLast'), isFalse);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);
    });

    test('does not mark complete when a flag write fails', () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': false,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactEidMiddle');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': false,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      // The middle write failed, so the migration must not be marked
      // complete; the stale value stays but a later retry can fix it.
      // (Read the store directly: SharedPreferences caches writes
      // optimistically, so prefs.getBool would show the new value.)
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(await store.persisted('flutter.redactEidMiddle'), isFalse);
      expect(await store.persisted('flutter.redactEidFirst'), isFalse);

      // The retry, with writes succeeding, finishes from the snapshot.
      store.failingKeys.clear();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(await store.persisted('flutter.redactEidMiddle'), isTrue);
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isTrue,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('init loads converted values when the snapshot write fails',
        () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': false,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigrationSourceV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': false,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      // The migration bailed out, but this run still shows the converted
      // values instead of reading old show-segment flags as new
      // mask-segment flags.
      expect(settings.redactEidFirst, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactEidLast, isFalse);
      expect(settings.redactIccidFirst, isFalse);
      expect(settings.redactIccidMiddle, isFalse);
      expect(settings.redactIccidLast, isFalse);
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('edits made before a migration retry are preserved', () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': false,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': false,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      // The marker write failed, so the migration is still pending; the
      // flags themselves landed.
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(settings.redactIccidFirst, isFalse);

      // The user enables masking for the ICCID first segment before the
      // next startup retries the migration.
      await settings.setRedactIccidFirst(true);
      expect(
        (jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationSourceV2')
              as String,
        ) as Map)['redactIccidFirst'],
        isFalse,
      );

      // The retry recomputes the edited value instead of overwriting it.
      // Simulate a relaunch with a fresh prefs instance reading only what
      // actually persisted: the old instance's optimistic cache would
      // claim the failed marker write succeeded and skip the retry.
      store.failingKeys.clear();
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactIccidFirst'), isTrue);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });
  });

  group('unsupported card details', () {
    const details =
        'ICCID: 89882810345678901234\nIMSI: 310150123456789\nPLMN: 310-150\nGID1: 01';

    test('masks the ICCID as configured and leaves the rest', () {
      expect(
        ProfileRedaction.redactUnsupportedCardDetails(details),
        'ICCID: 89882810********\nIMSI: 310150123456789\nPLMN: 310-150\nGID1: 01',
      );
    });

    test('hides both identifiers under full-hide', () async {
      settings.setFullHideSensitiveData(true);
      expect(
        ProfileRedaction.redactUnsupportedCardDetails(details),
        'ICCID: ********\nIMSI: ********\nPLMN: 310-150\nGID1: 01',
      );
    });

    test('shows everything when revealing', () async {
      settings.setRevealSensitiveProfileData(true);
      expect(
        ProfileRedaction.redactUnsupportedCardDetails(details),
        details,
      );
    });
  });
}

/// An in-memory prefs store that can fail chosen writes, to prove the
/// migration copes with partial failures.
class _FailingWriteStore extends InMemorySharedPreferencesStore {
  _FailingWriteStore(super.data) : super.withData();

  final Set<String> failingKeys = {};

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failingKeys.contains(key)) return false;
    return super.setValue(valueType, key, value);
  }

  Future<Object?> persisted(String key) async => (await getAll())[key];
}
