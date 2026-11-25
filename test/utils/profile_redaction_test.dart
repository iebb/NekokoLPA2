import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/models/euicc_profile.dart';
import 'package:nlpa2/services/profile_metadata_service.dart';
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
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map)['redactIccidFirst'],
        isTrue,
      );
      // The snapshot itself is untouched: the edit lives in the edits
      // record, not as an inverted snapshot value.
      expect(
        (jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationSourceV2')
              as String,
        ) as Map)['redactIccidFirst'],
        isTrue,
      );

      // The retry writes the recorded edit instead of recomputing it.
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

    test('turning off only the EID last switch keeps the middle masked',
        () async {
      // The conservative old combination: show middle, mask last 10.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': false,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': false,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      // The marker write failed, so the migration is still pending; the
      // conservative mapping masked everything from 8 on.
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactEidLast, isTrue);

      // The user turns off only the new Last 2 switch: show the final
      // two digits, keep the middle masked.
      await settings.setRedactEidLast(false);
      expect(
        (jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map)['redactEidLast'],
        isFalse,
      );

      // The retry applies the recorded edit instead of inverting the
      // snapshot pair (which would expose the middle too).
      store.failingKeys.clear();
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactEidMiddle'), isTrue);
      expect(prefs.getBool('redactEidLast'), isFalse);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a flag edit is dropped when its migration record cannot be stored',
        () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': false,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      store.failingKeys.add('flutter.redactionFlagsMigrationEditsV2');
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
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(settings.redactIccidFirst, isFalse);

      // The edits record cannot be stored, so the setter leaves the
      // flag untouched instead of persisting a value the next startup
      // would read as old-semantics and negate.
      await settings.setRedactIccidFirst(true);
      expect(settings.redactIccidFirst, isFalse);
      expect(await store.persisted('flutter.redactIccidFirst'), isFalse);
      expect(
        await store.persisted('flutter.redactionFlagsMigrationEditsV2'),
        isNull,
      );

      // The retry converts the flag from the snapshot: the edit never
      // landed, so nothing is lost.
      store.failingKeys.clear();
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactIccidFirst'), isFalse);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('the quick preset is recorded for a pending migration retry',
        () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );

      // The eye applies the preset while the migration is still pending.
      await settings.applyQuickRedactionPreset();
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // The retry writes the preset values instead of replaying the
      // all-visible snapshot (which would unmask everything again).
      store.failingKeys.clear();
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final prefs = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(prefs);
      expect(prefs.getBool('redactEidFirst'), isFalse);
      expect(prefs.getBool('redactEidMiddle'), isTrue);
      expect(prefs.getBool('redactEidLast'), isTrue);
      expect(prefs.getBool('redactIccidFirst'), isTrue);
      expect(prefs.getBool('redactIccidMiddle'), isTrue);
      expect(prefs.getBool('redactIccidLast'), isTrue);
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a rejected edits record is not resurrected by the next edit',
        () async {
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': false,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      store.failingKeys.add('flutter.redactionFlagsMigrationEditsV2');
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
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(settings.redactIccidFirst, isFalse);

      // The first edit cannot be recorded, so the setter drops it.
      await settings.setRedactIccidFirst(true);
      expect(settings.redactIccidFirst, isFalse);
      expect(await store.persisted('flutter.redactIccidFirst'), isFalse);
      // The failed write replaced the cache, but the record was rolled
      // back, so the cache no longer claims the rejected edit.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('redactionFlagsMigrationEditsV2'), isNull);

      // A later edit succeeds and must persist only itself.
      store.failingKeys.clear();
      await settings.setRedactIccidMiddle(true);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map,
        {'redactIccidMiddle': true},
      );

      // The retry applies only the recorded edit.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final relaunched = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(relaunched);
      expect(relaunched.getBool('redactIccidFirst'), isFalse);
      expect(relaunched.getBool('redactIccidMiddle'), isTrue);
      expect(relaunched.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('an edit refused for a missing snapshot does not corrupt the pair',
        () async {
      // The conservative old combination: show middle, mask last 10.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': false,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigrationSourceV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': false,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      // The snapshot write failed, so the migration is still pending and
      // this run shows the converted values.
      expect(
        await store.persisted('flutter.redactionFlagsMigratedV2'),
        isNull,
      );
      expect(
        await store.persisted('flutter.redactionFlagsMigrationSourceV2'),
        isNull,
      );
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactEidLast, isTrue);

      // The first edit is refused: the snapshot cannot be captured, so
      // the flag is left untouched instead of letting a later retry
      // rebuild the source pair from the edited value.
      await settings.setRedactEidLast(false);
      expect(settings.redactEidLast, isTrue);
      expect(await store.persisted('flutter.redactEidLast'), isFalse);
      expect(
        await store.persisted('flutter.redactionFlagsMigrationSourceV2'),
        isNull,
      );

      // Once the snapshot write succeeds, the edit is captured against
      // the pre-edit values: off, then back on.
      store.failingKeys.clear();
      await settings.setRedactEidLast(false);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationSourceV2')
              as String,
        ) as Map,
        {
          'redactEidFirst': true,
          'redactEidMiddle': true,
          'redactEidLast': false,
          'redactIccidFirst': true,
          'redactIccidMiddle': true,
          'redactIccidLast': true,
        },
      );
      await settings.setRedactEidLast(true);

      // The retry converts from the true old pair: the middle stays
      // masked instead of being exposed by a mixed source pair.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final relaunched = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(relaunched);
      expect(relaunched.getBool('redactEidFirst'), isFalse);
      expect(relaunched.getBool('redactEidMiddle'), isTrue);
      expect(relaunched.getBool('redactEidLast'), isTrue);
      expect(relaunched.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('concurrent edits both survive the snapshot capture', () async {
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
      expect(
        await store.persisted('flutter.redactionFlagsMigrationSourceV2'),
        isNull,
      );

      // Two quick taps on different switches: neither setter is awaited
      // before the other starts, so both capture the snapshot at once.
      store.failingKeys.clear();
      final first = settings.setRedactIccidFirst(true);
      final second = settings.setRedactIccidMiddle(true);
      await Future.wait([first, second]);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map,
        {'redactIccidFirst': true, 'redactIccidMiddle': true},
      );

      // The retry applies both edits.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final relaunched = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(relaunched);
      expect(relaunched.getBool('redactIccidFirst'), isTrue);
      expect(relaunched.getBool('redactIccidMiddle'), isTrue);
      expect(relaunched.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed same-key edit keeps the earlier persisted edit',
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
      expect(
        await store.persisted('flutter.redactionFlagsMigrationSourceV2'),
        isNull,
      );

      // The first edit persists; the snapshot is captured on the way.
      store.failingKeys.clear();
      await settings.setRedactIccidFirst(true);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map,
        {'redactIccidFirst': true},
      );
      expect(await store.persisted('flutter.redactIccidFirst'), isTrue);

      // A later edit to the same key fails to record, so the setter
      // drops it — but the earlier record must survive the rollback.
      store.failingKeys.add('flutter.redactionFlagsMigrationEditsV2');
      await settings.setRedactIccidFirst(false);
      expect(settings.redactIccidFirst, isTrue);
      expect(await store.persisted('flutter.redactIccidFirst'), isTrue);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map,
        {'redactIccidFirst': true},
      );

      // The retry applies the earlier edit.
      store.failingKeys.clear();
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      final relaunched = await SharedPreferences.getInstance();
      await AppSettings.migrateRedactionFlags(relaunched);
      expect(relaunched.getBool('redactIccidFirst'), isTrue);
      expect(relaunched.getBool('redactionFlagsMigratedV2'), isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed preset leaves the preset state unchanged', () async {
      // Old values that convert to nothing configured: every flag off,
      // nickname and operator modes none.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The preset cannot stage its batch, so it aborts before touching
      // the nickname/operator modes: the eye still reports nothing
      // configured instead of looking masked.
      store.failingKeys.add('flutter.redactionFlagsMigrationPresetBatchV2');
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.redactIccidFirst, isFalse);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.none,
      );
      expect(
        settings.operatorRedactionMode,
        OperatorRedactionMode.none,
      );

      // Once storage recovers, the same preset applies in full.
      store.failingKeys.clear();
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.redactEidFirst, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactEidLast, isTrue);
      expect(settings.redactIccidFirst, isTrue);
      expect(settings.redactIccidMiddle, isTrue);
      expect(settings.redactIccidLast, isTrue);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a transient record failure does not partially apply the preset',
        () async {
      // Old values that convert to nothing configured: every flag off.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The single staged batch write fails once. With per-setter
      // recording, the setters after the failed one would still land
      // and leave the preset half-applied; staging means the failed
      // attempt changes nothing at all.
      store.failCounts['flutter.redactionFlagsMigrationPresetBatchV2'] = 1;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.redactIccidFirst, isFalse);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.none,
      );
      expect(
        await store.persisted(
          'flutter.redactionFlagsMigrationPresetBatchV2',
        ),
        isNull,
      );

      // The next attempt records and applies in full.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.redactIccidFirst, isTrue);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed flag write rolls the preset back', () async {
      // Migration completes at init: every flag off, nothing configured.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // With the migration complete there is no staged record to replay
      // from, so a single failed flag write must roll the whole preset
      // back instead of reporting success half-applied.
      store.failCounts['flutter.redactEidMiddle'] = 1;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.redactEidLast, isFalse);
      expect(settings.redactIccidFirst, isFalse);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.none,
      );
      expect(
        await store.persisted('flutter.redactEidMiddle'),
        isFalse,
      );

      // The next attempt applies in full.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.redactEidMiddle, isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed preset with a pending migration restores its batch',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // One flag write fails; the rollback succeeds, so the staged
      // batch is restored to its pre-preset state instead of being
      // replayed at the next launch.
      store.failCounts['flutter.redactEidMiddle'] = 1;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(
        await store.persisted(
          'flutter.redactionFlagsMigrationPresetBatchV2',
        ),
        isNull,
      );

      // The next attempt applies in full, modes included.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.hideNickname,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed rollback keeps the preset batch for the next launch',
        () async {
      // Migration completes at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The flag write and its rollback write both fail, so the batch
      // stays staged instead of being restored.
      store.failCounts['flutter.redactEidMiddle'] = 2;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
          'modes': {'nicknameRedactionMode': 2, 'operatorRedactionMode': 1},
        },
      );

      // A restart replays the full preset and drops the batch.
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.hideNickname,
      );
      expect(
        settings.operatorRedactionMode,
        OperatorRedactionMode.countryName,
      );
      expect(
        await store.persisted(
          'flutter.redactionFlagsMigrationPresetBatchV2',
        ),
        isNull,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed rollback with a pending migration replays at restart',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The flag write and its rollback write both fail, so the batch
      // stays staged.
      store.failCounts['flutter.redactEidMiddle'] = 2;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // A restart is a fresh process: rebuild the mock store from the
      // backing store's contents, so the prefs cache starts empty and
      // the migration really runs again. Storage has recovered by now.
      final stored = await store.getAll();
      SharedPreferences.setMockInitialValues(
        Map<String, Object>.fromEntries(
          stored.entries.map(
            (entry) => MapEntry(
              entry.key.replaceFirst('flutter.', ''),
              entry.value,
            ),
          ),
        ),
      );
      await settings.init();
      final prefs = await SharedPreferences.getInstance();
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(settings.redactEidMiddle, isTrue);
      expect(
        settings.nicknameRedactionMode,
        NicknameRedactionMode.hideNickname,
      );
      expect(prefs.getBool('redactionFlagsMigratedV2'), isTrue);
      expect(prefs.getString('redactionFlagsMigrationEditsV2'), isNull);
      expect(
        prefs.getString('redactionFlagsMigrationPresetBatchV2'),
        isNull,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a later edit survives a restart after a successful preset',
        () async {
      // Migration completes at init: every flag off, nothing configured.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The preset succeeds, and its batch is dropped: nothing is left
      // to replay over a later choice.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(
        await store.persisted(
          'flutter.redactionFlagsMigrationPresetBatchV2',
        ),
        isNull,
      );

      // The user then enables the EID-first mask; a restart must keep
      // it instead of replaying the stale preset (which had it off).
      await settings.setRedactEidFirst(true);
      expect(settings.redactEidFirst, isTrue);
      await settings.init();
      expect(settings.redactEidFirst, isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test(
        'a successful preset keeps only its flags while migration is pending',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(await settings.applyQuickRedactionPreset(), isTrue);

      // The flags stay for the pending retry; the modes are dropped,
      // so a later mode change is not overwritten by the stale batch.
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a preset supersedes edits recorded before it', () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // From an all-visible state, toggling EID Middle on and back off
      // leaves `false` in the edits record.
      await settings.setRedactEidMiddle(true);
      await settings.setRedactEidMiddle(false);
      expect(settings.redactEidMiddle, isFalse);

      // The preset shows and stores `true` in the current run.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.redactEidMiddle, isTrue);

      // A restart replays the preset, not the older edit: the middle
      // digits stay masked.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      await settings.init();
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a staged batch supersedes without deleting the old edit',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The user toggles EID Middle on and back off before the preset.
      await settings.setRedactEidMiddle(true);
      await settings.setRedactEidMiddle(false);

      // The preset succeeds. The old edit stays in the record; the
      // batch records that it supersedes it.
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(
        jsonDecode(
          await store.persisted('flutter.redactionFlagsMigrationEditsV2')
              as String,
        ) as Map,
        {'redactEidMiddle': false},
      );
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
          'supersedes': {'redactEidMiddle': false},
        },
      );

      // A launch whose marker write fails again still shows the
      // preset, not the superseded edit. (A plain second init() in
      // the same process cannot test this: the optimistic cache holds
      // the failed marker write as landed, so migrate short-circuits
      // and replays the batch instead.)
      final persisted = await store.getAll();
      final failingRestart = _FailingWriteStore(persisted);
      failingRestart.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = failingRestart;
      await settings.init();
      expect(settings.redactEidMiddle, isTrue);

      // A restart replays the preset, not the older edit.
      final restarted = await failingRestart.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in restarted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      await settings.init();
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a post-preset edit to a superseded key survives a restart',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The user toggles EID Middle on and back off before the preset.
      await settings.setRedactEidMiddle(true);
      await settings.setRedactEidMiddle(false);

      // The preset succeeds and supersedes the old edit.
      expect(await settings.applyQuickRedactionPreset(), isTrue);

      // The user toggles EID Middle back off after the preset — the
      // same value as the old edit. The batch no longer supersedes it.
      await settings.setRedactEidMiddle(false);
      expect(settings.redactEidMiddle, isFalse);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // A restart replays the post-preset edit, not the batch value.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      await settings.init();
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.hasNoRedactionsConfigured, isFalse);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a newer edit survives when clearing the supersession fails',
        () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The user toggles EID Middle on and back off before the preset.
      await settings.setRedactEidMiddle(true);
      await settings.setRedactEidMiddle(false);

      // The preset succeeds and supersedes the old edit.
      expect(await settings.applyQuickRedactionPreset(), isTrue);

      // The next write to the batch key fails, so clearing the
      // supersession does not land — but the newer edit has a
      // different value from the superseded one, so the migration
      // keeps it anyway.
      store.failCounts['flutter.redactionFlagsMigrationPresetBatchV2'] = 1;
      await settings.setRedactEidMiddle(true);
      expect(settings.redactEidMiddle, isTrue);

      // A restart replays the post-preset edit, not the batch value.
      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      await settings.init();
      expect(settings.redactEidMiddle, isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed preset keeps the edits it superseded', () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The user toggles EID Middle on and back off before the preset.
      await settings.setRedactEidMiddle(true);
      await settings.setRedactEidMiddle(false);

      // One flag write fails; the rollback succeeds, so the superseded
      // edit is still there (it was never removed) and the restart
      // replays the pre-preset choice.
      store.failCounts['flutter.redactEidMiddle'] = 1;
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);

      final persisted = await store.getAll();
      SharedPreferences.setMockInitialValues({
        for (final entry in persisted.entries)
          entry.key.replaceFirst('flutter.', ''): entry.value,
      });
      await settings.init();
      expect(settings.redactEidMiddle, isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed batch cleanup rolls the preset back', () async {
      // Migration completes at init: every flag off, nothing configured.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The cleanup remove fails after the staging write, so the preset
      // is rolled back instead of reporting success with a stale batch.
      store.failAfterFirst.add(
        'flutter.redactionFlagsMigrationPresetBatchV2',
      );
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
          'modes': {'nicknameRedactionMode': 2, 'operatorRedactionMode': 1},
        },
      );

      // Once storage recovers, the same preset applies in full and the
      // batch is dropped.
      store.failAfterFirst.clear();
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(
        await store.persisted(
          'flutter.redactionFlagsMigrationPresetBatchV2',
        ),
        isNull,
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });

    test('a failed mode drop rolls the preset back', () async {
      // Migration pending: the marker fails at init.
      final store = _FailingWriteStore({
        'flutter.redactEidFirst': true,
        'flutter.redactEidMiddle': true,
        'flutter.redactEidLast': true,
        'flutter.redactIccidFirst': true,
        'flutter.redactIccidMiddle': true,
        'flutter.redactIccidLast': true,
      });
      store.failingKeys.add('flutter.redactionFlagsMigratedV2');
      SharedPreferences.setMockInitialValues({
        'redactEidFirst': true,
        'redactEidMiddle': true,
        'redactEidLast': true,
        'redactIccidFirst': true,
        'redactIccidMiddle': true,
        'redactIccidLast': true,
      });
      SharedPreferencesStorePlatform.instance = store;
      await settings.init();
      expect(settings.hasNoRedactionsConfigured, isTrue);

      // The mode drop fails after the staging write, so the preset is
      // rolled back instead of reporting success with stale modes.
      store.failAfterFirst.add(
        'flutter.redactionFlagsMigrationPresetBatchV2',
      );
      expect(await settings.applyQuickRedactionPreset(), isFalse);
      expect(settings.hasNoRedactionsConfigured, isTrue);
      expect(settings.redactEidMiddle, isFalse);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
          'modes': {'nicknameRedactionMode': 2, 'operatorRedactionMode': 1},
        },
      );

      // Once storage recovers, the same preset applies in full; only
      // the flags stay for the pending retry.
      store.failAfterFirst.clear();
      expect(await settings.applyQuickRedactionPreset(), isTrue);
      expect(settings.hasNoRedactionsConfigured, isFalse);
      expect(
        jsonDecode(
          await store.persisted(
                'flutter.redactionFlagsMigrationPresetBatchV2',
              )
              as String,
        ) as Map,
        {
          'flags': {
            'redactEidFirst': false,
            'redactEidMiddle': true,
            'redactEidLast': true,
            'redactIccidFirst': true,
            'redactIccidMiddle': true,
            'redactIccidLast': true,
          },
        },
      );

      // Restore the default mock store for the tests after this one.
      SharedPreferences.setMockInitialValues({});
    });
  });

  group('displayName', () {
    test('a phone-number nickname is masked in full-hide mode', () {
      final profile = EuiccProfile(
        iccid: sampleIccid,
        enabled: true,
        nickname: '+441212345678',
      );
      // Control: with nothing hidden, the number is the title.
      expect(
        ProfileRedaction.displayName(profile),
        '+44 121 234 5678',
      );
      settings.setFullHideSensitiveData(true);
      expect(
        ProfileRedaction.displayName(profile),
        isNot(contains(RegExp(r'\d'))),
      );
    });
  });

  group('metadataDisplayName', () {
    final meta = ProfileMetadata(
      iccid: sampleIccid,
      nickname: '+441212345678',
      lastSeen: DateTime(2026, 11, 25),
    );

    test('a phone-number nickname is masked in full-hide mode', () {
      // Control: with nothing hidden, the number is the title.
      expect(
        ProfileRedaction.metadataDisplayName(meta),
        '+44 121 234 5678',
      );
      settings.setFullHideSensitiveData(true);
      expect(
        ProfileRedaction.metadataDisplayName(meta),
        isNot(contains(RegExp(r'\d'))),
      );
    });

    test('a stored nickname is hidden entirely in hide-nickname mode',
        () async {
      await settings.setNicknameRedactionMode(
        NicknameRedactionMode.hideNickname,
      );
      expect(ProfileRedaction.metadataDisplayName(meta), isNull);
    });

    test('a phone-number nickname is masked in redact-phone-numbers mode',
        () async {
      await settings.setNicknameRedactionMode(
        NicknameRedactionMode.redactPhoneNumbers,
      );
      expect(
        ProfileRedaction.metadataDisplayName(meta),
        isNot(contains(RegExp(r'\d'))),
      );
    });

    test('an operator name is kept when the nickname is hidden', () async {
      final operatorMeta = ProfileMetadata(
        iccid: sampleIccid,
        providerName: 'Vodafone',
        lastSeen: DateTime(2026, 11, 25),
      );
      await settings.setNicknameRedactionMode(
        NicknameRedactionMode.hideNickname,
      );
      expect(
        ProfileRedaction.metadataDisplayName(operatorMeta),
        'Vodafone',
      );
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

  /// Fail the next [count] writes to each key, then let them through:
  /// a transient failure on one write only.
  final Map<String, int> failCounts = {};

  /// Fail writes to each key after the first one goes through: a
  /// failure that hits a later write to the same key (for example the
  /// preset's cleanup write, which follows the staging write).
  final Set<String> failAfterFirst = {};

  final Map<String, int> _writeCounts = {};

  bool _shouldFail(String key) {
    final count = (_writeCounts[key] ?? 0) + 1;
    _writeCounts[key] = count;
    final remaining = failCounts[key];
    if (remaining != null && remaining > 0) {
      failCounts[key] = remaining - 1;
      return true;
    }
    if (failingKeys.contains(key)) return true;
    if (failAfterFirst.contains(key) && count > 1) return true;
    return false;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (_shouldFail(key)) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (_shouldFail(key)) return false;
    return super.remove(key);
  }

  Future<Object?> persisted(String key) async => (await getAll())[key];
}
