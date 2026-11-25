import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../adapter/qrtr/qrtr_host.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logging/logging.dart';
import '../services/database_service.dart';
import '../adapter/ble/ble_manager.dart';
import '../services/nbridge_service.dart';
import '../services/rsp_proxy_config.dart';
import '../utils/platform_adapter.dart';
import '../utils/imei_codec.dart';
import '../version.dart';
import '../config.dart';
import 'build_capabilities.dart';
import 'package:yaml/yaml.dart';

class BrowserTabConfig {
  final String title;
  final String url;
  final String icon;
  final String label;
  final bool toggleAllowed;
  final bool enabledByDefault;
  bool isEnabled;

  BrowserTabConfig({
    required this.title,
    required this.url,
    required this.icon,
    required this.label,
    required this.toggleAllowed,
    required this.enabledByDefault,
    this.isEnabled = true,
  });
}

enum PhoneFormatStrategy {
  internationalOnly, // E.164 Int'l Only
  internationalAndMobile, // Int'l & Mobile (National)
  internationalAndAll, // Int'l & All National
  off, // Off
}

enum ProfileSortType { none, iccid, country, nickname }

enum AppThemeType { custom, stock }

enum NicknameRedactionMode { none, redactPhoneNumbers, hideNickname }

enum OperatorRedactionMode { none, countryName }

enum TagsRedactionMode { none, hideTags }

enum IconRedactionMode { none, hideIcon, randomIcon }

enum FlagRedactionMode { none, hideFlag, shuffledFlags }

class AppSettings extends ChangeNotifier {
  static final Logger _log = Logger('AppSettings');
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  SharedPreferences? _prefs;
  final String _version = kAppVersion;
  final String _buildNumber = kAppBuildNumber;
  String _packageName = '';

  String get version => _version;
  String get buildNumber => _buildNumber;
  String get commitHash => kCommitHash;
  String get versionDisplay => 'v$_version b$_buildNumber';

  String _flavorFileVariant = '';

  bool get isEsim9Build {
    const environmentVariant = String.fromEnvironment(
      'APP_VARIANT',
      defaultValue: '',
    );
    return BuildCapabilities.isEsim9Build(
      compileTimeFlag: kIsEsim9,
      environmentVariant: environmentVariant,
      flavorVariant: _flavorFileVariant,
      packageName: _packageName,
    );
  }

  String get variant {
    // A positive 9eSIM signal always wins so a stale flavor asset cannot
    // accidentally enable build-specific features.
    if (isEsim9Build) return 'esim9';

    // 1. Check if explicitly defined in build environment
    const String envVariant = String.fromEnvironment(
      'APP_VARIANT',
      defaultValue: '',
    );
    if (envVariant.isNotEmpty) {
      return BuildCapabilities.variantForPlatform(
        envVariant,
        isAndroid: PlatformX.isAndroid,
      );
    }

    // Public Android identity wins over stale rebranding assets.
    if (PlatformX.isAndroid && _packageName.endsWith('.open')) {
      return 'community';
    }
    if (PlatformX.isAndroid &&
        kIsPrivileged &&
        (_flavorFileVariant == 'open' ||
            _flavorFileVariant == 'community' ||
            _flavorFileVariant == 'store')) {
      return 'community-rooted';
    }

    // 2. Check if flavor.json defines a variant
    if (_flavorFileVariant.isNotEmpty) {
      return BuildCapabilities.variantForPlatform(
        _flavorFileVariant,
        isAndroid: PlatformX.isAndroid,
      );
    }

    // 3. Check package name suffixes
    if (_packageName.endsWith('.multi') || _packageName.endsWith('.m')) {
      return 'multi';
    }
    if (_packageName.endsWith('.sekiu')) return 'sekiu';
    if (_packageName.endsWith('.yellow')) return 'yellow';
    if (_packageName.endsWith('.std')) return 'std';

    // 4. Check for privileged build flag
    if (kIsPrivileged) return 'privileged';

    return '';
  }

  String get logoAsset {
    if (variant == 'community' || variant == 'community-rooted') {
      return 'assets/logo-community.png';
    }
    return 'assets/logo.png';
  }

  String get appName {
    final v = variant;
    if (v == 'esim9') return '9eSIM';
    if (v == 'community') return 'NekokoLPA 2 Community';
    if (v == 'community-rooted') return 'NekokoLPA 2 Community Rooted';
    return 'NekokoLPA 2';
  }

  String get userAgent {
    final os = PlatformX.operatingSystem;
    final v = variant.isEmpty ? 'std' : variant;
    return 'NekokoLPA/$v/$os/$version/$buildNumber NekokoApp';
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      notifyListeners();
    }
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  AppThemeType _themeType = AppThemeType.custom;
  AppThemeType get themeType => _themeType;

  bool _autoLoadProfiles = true;
  bool get autoLoadProfiles => _autoLoadProfiles;

  bool _autoLoadRemoteDevices = false;
  bool get autoLoadRemoteDevices => _autoLoadRemoteDevices;

  bool _developerModeEnabled = false;
  bool get developerModeEnabled => _developerModeEnabled;

  bool _notifProcessInitialLoad = true;
  bool get notifProcessInitialLoad => _notifProcessInitialLoad;

  bool _notifProcessAfterSwitch = true;
  bool get notifProcessAfterSwitch => _notifProcessAfterSwitch;

  bool _notifProcessAfterDeletion = true;
  bool get notifProcessAfterDeletion =>
      _developerModeEnabled ? _notifProcessAfterDeletion : true;

  bool _notifProcessBeforeDownload = true;
  bool get notifProcessBeforeDownload =>
      _developerModeEnabled ? _notifProcessBeforeDownload : true;

  bool _notifProcessAfterInstall = true;
  bool get notifProcessAfterInstall =>
      _developerModeEnabled ? _notifProcessAfterInstall : true;

  // Notification Process Settings
  // Install
  bool _notifAutoSendInstall = true;
  bool get notifAutoSendInstall => _notifAutoSendInstall;
  bool _notifAutoRemoveInstall = true;
  bool get notifAutoRemoveInstall =>
      _notifAutoRemoveInstall && _notifAutoSendInstall;

  // Enable
  bool _notifAutoSendEnable = true;
  bool get notifAutoSendEnable => _notifAutoSendEnable;
  bool _notifAutoRemoveEnable = true;
  bool get notifAutoRemoveEnable =>
      _notifAutoRemoveEnable && _notifAutoSendEnable;
  bool _notifDeleteWithoutSendingEnable = false;
  bool get notifDeleteWithoutSendingEnable => _notifDeleteWithoutSendingEnable;

  // Disable
  bool _notifAutoSendDisable = true;
  bool get notifAutoSendDisable => _notifAutoSendDisable;
  bool _notifAutoRemoveDisable = true;
  bool get notifAutoRemoveDisable =>
      _notifAutoRemoveDisable && _notifAutoSendDisable;
  bool _notifDeleteWithoutSendingDisable = false;
  bool get notifDeleteWithoutSendingDisable =>
      _notifDeleteWithoutSendingDisable;

  // Deletion
  bool _notifAutoSendDelete = true;
  bool get notifAutoSendDelete => _notifAutoSendDelete;
  bool _notifAutoRemoveDelete = true;
  bool get notifAutoRemoveDelete =>
      _notifAutoRemoveDelete && _notifAutoSendDelete;

  // Size Unit
  String _sizeUnit = "settings_item_unit_adaptive_si";
  String get sizeUnit => _sizeUnit;

  String? _lastSelectedReader;
  String? get lastSelectedReader => _lastSelectedReader;

  bool _forceDeviceDropdown = false;
  bool get forceDeviceDropdown => _forceDeviceDropdown;

  bool _enableNekokoStats = true;
  bool get enableNekokoStats => _enableNekokoStats;

  bool _estimateProfileSize = true;
  bool get estimateProfileSize => _estimateProfileSize;

  bool _enableProfileStatusEnhancer = true;
  bool get enableProfileStatusEnhancer => _enableProfileStatusEnhancer;

  bool _revealSensitiveProfileData = false;
  bool get revealSensitiveProfileData => _revealSensitiveProfileData;

  /// Full-hide mode (eye icon third state): every identifier is masked.
  /// Memory-only, like [_revealSensitiveProfileData].
  bool _fullHideSensitiveData = false;
  bool get fullHideSensitiveData => _fullHideSensitiveData;

  /// Whether the redaction migration is truly complete. Tracked in memory
  /// because SharedPreferences caches writes optimistically: after a
  /// failed marker write the cache claims the marker is set while the
  /// store disagrees, so the marker must not be re-read from prefs.
  bool _migrationCompleted = false;

  /// Whether a migration snapshot is stored. Tracked in memory for the
  /// same reason: after a failed snapshot write the cache claims one
  /// exists, so the store must not be asked through prefs either — an
  /// edit recorded on that lie would let a later retry rebuild the
  /// source pair from already-edited flags.
  bool _migrationSnapshotStored = false;

  bool _enableUpdateCheck = true;
  bool get enableUpdateCheck => _enableUpdateCheck;

  RspProxyMode _rspProxyMode = RspProxyMode.direct;
  String _rspForwardProxyProtocol = 'http';
  String _rspForwardProxyHost = '';
  int? _rspForwardProxyPort;
  String _rspReverseProxyUrlPrefix = '';

  RspProxyMode get rspProxyMode => _rspProxyMode;
  String get rspForwardProxyProtocol => _rspForwardProxyProtocol;
  String get rspForwardProxyHost => _rspForwardProxyHost;
  int? get rspForwardProxyPort => _rspForwardProxyPort;
  String get rspReverseProxyUrlPrefix => _rspReverseProxyUrlPrefix;

  RspProxyConfig get rspProxyConfig => RspProxyConfig(
    mode: _rspProxyMode,
    forwardProtocol: _rspForwardProxyProtocol,
    forwardHost: _rspForwardProxyHost,
    forwardPort: _rspForwardProxyPort,
    reverseUrlPrefix: _rspReverseProxyUrlPrefix,
  );

  bool get ensureSingleChannel => true;

  // Connection
  // lpac's segment size; some modems fail STORE DATA with larger blocks.
  static const int defaultMss = 120;
  static const int minMss = 60;
  static const int maxMss = 240;
  int _mss = defaultMss;
  int get mss => _mss;

  String? _locale;
  String? get locale => _locale;

  List<String> _aids = [
    "A06573746B6D65FFFF4953442D522031", // eSTKme-specific AID
    "A06573746B6D65FFFF4953442D522030", // eSTKme-specific AID
    "A0000005591010FFFFFFFF8900000100",
    "A0000005591010FFFFFFFF8900050500",
    "A0000005591010000000008900000300",
    "A0000005591010FFFFFFFF8900000177",
  ];
  List<String> get aids => _aids;

  List<String> _remoCardUrls = [];
  bool _showProfileSearch = true; // Will be initialized based on platform
  bool get showProfileSearch => _showProfileSearch;

  Future<void> setShowProfileSearch(bool value) async {
    _showProfileSearch = value;
    await _prefs?.setBool('showProfileSearch', value);
    notifyListeners();
  }

  bool _enableBrowser = true;
  bool get enableBrowser => _enableBrowser;

  Future<void> setEnableBrowser(bool value) async {
    _enableBrowser = value;
    await _prefs?.setBool('enableBrowser', value);
    notifyListeners();
  }

  ProfileSortType _profileSortType = ProfileSortType.none;
  ProfileSortType get profileSortType => _profileSortType;

  bool _sortAscending = true;
  bool get sortAscending => _sortAscending;

  Future<void> setProfileSortType(ProfileSortType value) async {
    _profileSortType = value;
    await _prefs?.setInt('profileSortType', value.index);
    notifyListeners();
  }

  bool _useWaterfallLayout = true;
  bool get useWaterfallLayout => _useWaterfallLayout;

  Future<void> setUseWaterfallLayout(bool value) async {
    _useWaterfallLayout = value;
    await _prefs?.setBool('useWaterfallLayout', value);
    notifyListeners();
  }

  Future<void> setSortAscending(bool value) async {
    _sortAscending = value;
    await _prefs?.setBool('sortAscending', value);
    notifyListeners();
  }

  // Profile Icons
  bool _loadProfileIcons = false;
  bool get loadProfileIcons => _loadProfileIcons;

  bool _disableRefreshFlags = false;
  bool get disableRefreshFlags => _disableRefreshFlags;

  bool _useNekokoIcons = true;
  bool get useNekokoIcons => _useNekokoIcons;

  bool _redactEidFirst = false;
  bool get redactEidFirst => _redactEidFirst;

  bool _redactEidMiddle = true;
  bool get redactEidMiddle => _redactEidMiddle;

  bool _redactEidLast = false;
  bool get redactEidLast => _redactEidLast;

  bool _redactIccidFirst = false;
  bool get redactIccidFirst => _redactIccidFirst;

  bool _redactIccidMiddle = true;
  bool get redactIccidMiddle => _redactIccidMiddle;

  bool _redactIccidLast = true;
  bool get redactIccidLast => _redactIccidLast;

  NicknameRedactionMode _nicknameRedactionMode = NicknameRedactionMode.none;
  NicknameRedactionMode get nicknameRedactionMode => _nicknameRedactionMode;

  OperatorRedactionMode _operatorRedactionMode = OperatorRedactionMode.none;
  OperatorRedactionMode get operatorRedactionMode => _operatorRedactionMode;

  TagsRedactionMode _tagsRedactionMode = TagsRedactionMode.none;
  TagsRedactionMode get tagsRedactionMode => _tagsRedactionMode;

  IconRedactionMode _iconRedactionMode = IconRedactionMode.none;
  IconRedactionMode get iconRedactionMode => _iconRedactionMode;

  FlagRedactionMode _flagRedactionMode = FlagRedactionMode.none;
  FlagRedactionMode get flagRedactionMode => _flagRedactionMode;

  bool get isAnyNotificationProcessingEnabled =>
      _notifAutoSendInstall ||
      _notifAutoSendEnable ||
      _notifAutoSendDisable ||
      _notifAutoSendDelete;

  bool _enableBleConnector = true;
  bool get enableBleConnector => _enableBleConnector;

  bool _enableCcidConnector = true;
  bool get enableCcidConnector => _enableCcidConnector;

  /// Phoenix / Smartmouse style RS-232 readers. Off by default: they are
  /// desktop-only and enumerate every COM port.
  bool _enablePhoenixReader = false;
  bool get enablePhoenixReader => _enablePhoenixReader;

  /// The modem's own QRTR bus, which needs no USB at all.
  bool _enableQrtrConnector = false;
  bool get enableQrtrConnector => _enableQrtrConnector;

  bool _enableSeHalConnector = false;
  bool get enableSeHalConnector => _enableSeHalConnector;
  final _halBorrowedSlots = <int>{};
  bool halUseBorrowed(int slot) => _halBorrowedSlots.contains(slot);

  bool _enableOmapiConnector = true;
  bool get enableOmapiConnector => _enableOmapiConnector;

  bool _enableTmapiConnector = true;
  bool get enableTmapiConnector => _enableTmapiConnector;

  bool _nbridgeProviderAvailable = false;
  bool get nbridgeProviderAvailable => _nbridgeProviderAvailable;

  bool _rootDetected = false;
  bool get rootDetected => _rootDetected;

  String? _remoCardPassword;
  String? get remoCardPassword => _remoCardPassword;

  static const String _vowifiEnabledKey = 'vowifiEnabled';
  static const String _vowifiConsentVersionKey = 'vowifiConsentVersion';
  static const String _vowifiAutoRenewKey = 'vowifiAutoRenew';

  bool _vowifiEnabled = false;
  int? _vowifiConsentVersion;
  bool _vowifiAutoRenew = false;
  bool get vowifiAvailable => BuildCapabilities.isVowifiAvailable(
    isEsim9Build: isEsim9Build,
    isAndroid: PlatformX.isAndroid,
    isIOS: PlatformX.isIOS,
  );
  bool get vowifiEnabled => BuildCapabilities.isVowifiEnabled(
    available: vowifiAvailable,
    storedEnabled: _vowifiEnabled,
    consentVersion: _vowifiConsentVersion,
  );
  bool get vowifiAutoRenew => _vowifiAutoRenew && vowifiEnabled;

  Future<void> setVowifiAutoRenew(bool value) async {
    final was = vowifiAutoRenew;
    _vowifiAutoRenew = value;
    if (value) {
      await _prefs?.setBool(_vowifiAutoRenewKey, true);
    } else {
      await _prefs?.remove(_vowifiAutoRenewKey);
    }
    if (was != vowifiAutoRenew) notifyListeners();
  }

  Future<void> setRemoCardPassword(String? value) async {
    _remoCardPassword = value;
    if (value == null) {
      await _prefs?.remove('remoCardPassword');
    } else {
      await _prefs?.setString('remoCardPassword', value);
    }
    notifyListeners();
  }

  List<String> get remoCardUrls => _remoCardUrls;

  Future<void> addRemoCardUrl(String value) async {
    if (value.isEmpty || _remoCardUrls.contains(value)) return;
    _remoCardUrls.add(value);
    await DatabaseService().saveRemoteServer(value);
    notifyListeners();
  }

  Future<void> removeRemoCardUrl(String value) async {
    if (_remoCardUrls.remove(value)) {
      await DatabaseService().deleteRemoteServer(value);
      notifyListeners();
    }
  }

  /// `remove` is a platform round trip even for a key that is not stored.
  Future<void> _removePrefIfPresent(String key) async {
    if (_prefs?.containsKey(key) == true) await _prefs?.remove(key);
  }

  /// The six segment flags the redaction migration converts.
  static const _segmentFlagKeys = [
    'redactEidFirst',
    'redactEidMiddle',
    'redactEidLast',
    'redactIccidFirst',
    'redactIccidMiddle',
    'redactIccidLast',
  ];

  static const _migrationMarkerKey = 'redactionFlagsMigratedV2';
  static const _migrationSnapshotKey = 'redactionFlagsMigrationSourceV2';

  /// Edits made to the segment flags while the migration is still
  /// pending, recorded in new-semantics terms. A retry writes these
  /// values as-is instead of recomputing them from the snapshot, so an
  /// edit can never be undone by the frozen pre-migration values — and
  /// the coupled EID pair is recorded together, not inverted flag by
  /// flag into the snapshot (inverting only Last of the conservative
  /// old pair would flip the middle back to visible on retry).
  static const _migrationEditsKey = 'redactionFlagsMigrationEditsV2';

  /// Converts stored old-semantics flag values ("show this segment") to
  /// the new "mask this segment" values. The EID segment boundaries
  /// changed with the new defaults: the middle range now runs to
  /// length-2 and the last range is only the final 2 digits (was: middle
  /// [8,24), last 10). A stored "show middle, mask last 10" choice would
  /// expose 8 digits after a plain flip, so that combination maps
  /// conservatively to "mask everything from 8 on".
  static Map<String, bool> _convertedFlags(Map<String, bool> old) {
    final eidMaskFromEightOn =
        old['redactEidMiddle'] == true && old['redactEidLast'] == false;
    return {
      for (final entry in old.entries)
        entry.key:
            eidMaskFromEightOn &&
                    (entry.key == 'redactEidMiddle' ||
                        entry.key == 'redactEidLast')
                ? true
                : !entry.value,
    };
  }

  /// New-semantics flag values for the current run, given the stored
  /// values, the migration snapshot (if one exists), and edits made
  /// while the migration is pending. A key already at its converted
  /// value is taken as-is, a key still at its snapshot value takes the
  /// converted value, and a key that matches neither was edited after
  /// the snapshot, so the stored (new-semantics) value is trusted. With
  /// no snapshot every stored value is still old-semantics and is
  /// converted. Recorded edits win over anything recomputed: they are
  /// new-semantics values the user chose.
  static Map<String, bool> _displayValues(
    Map<String, bool> stored,
    Map<String, bool>? source,
    Map<String, bool> edits,
  ) {
    final Map<String, bool> base;
    if (source == null) {
      base = _convertedFlags(stored);
    } else {
      final targets = _convertedFlags(source);
      base = {
        for (final entry in stored.entries)
          entry.key: entry.value == targets[entry.key]
              ? entry.value
              : entry.value == source[entry.key]
                  ? targets[entry.key]!
                  : entry.value,
      };
    }
    return {...base, ...edits};
  }

  /// Reads the pending migration edits, or an empty map when there are
  /// none or the record is corrupt.
  static Map<String, bool> _readMigrationEdits(SharedPreferences prefs) {
    final raw = prefs.getString(_migrationEditsKey);
    if (raw == null) return <String, bool>{};
    try {
      return Map<String, bool>.from(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return <String, bool>{};
    }
  }

  /// Reads the migration snapshot, or null when there is none or it is
  /// corrupt (the caller re-captures from the current flags then).
  static Map<String, bool>? _readMigrationSnapshot(SharedPreferences prefs) {
    final snapshot = prefs.getString(_migrationSnapshotKey);
    if (snapshot == null) return null;
    try {
      return Map<String, bool>.from(
        jsonDecode(snapshot) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// One-time migration for the redaction segment flags: they used to mean
  /// "show this segment" and now mean "mask this segment". Flip any stored
  /// values once so existing installs keep their on-screen display.
  ///
  /// Restart-safe: the pre-migration values are snapshotted into a single
  /// key before any flag is flipped, and a retry recomputes from that
  /// snapshot. Without it, an app killed mid-migration would flip the
  /// already-flipped flags a second time on the next startup and could
  /// unmask a segment the user had masked. If the snapshot itself cannot
  /// be stored, nothing is flipped and the next startup retries cleanly.
  /// The snapshot is left in place afterwards as the migration's record.
  /// Edits made while the migration is pending are recorded separately
  /// (see [_migrationEditsKey]) and win over the snapshot on retry, so
  /// they are never undone by the frozen pre-migration values.
  /// `init()` loads the in-memory flags through [_displayValues], so a run
  /// whose migration did not complete still shows the converted values.
  ///
  /// Returns the migration outcome: whether the marker is truly set
  /// (already set on entry, or every flag write and the marker write
  /// succeeded), and whether a snapshot is stored (already present, or
  /// written by this run).
  @visibleForTesting
  static Future<({bool completed, bool snapshotStored})>
  migrateRedactionFlags(SharedPreferences prefs) async {
    if (prefs.getBool(_migrationMarkerKey) == true) {
      return (completed: true, snapshotStored: true);
    }
    var source = _readMigrationSnapshot(prefs);
    if (source == null) {
      source = <String, bool>{};
      // Skip flags already recorded as edited: their stored values are
      // new-semantics, not pre-migration values (reached only when a
      // snapshot was lost after edits were recorded).
      final pendingEdits = _readMigrationEdits(prefs);
      for (final key in _segmentFlagKeys) {
        if (pendingEdits.containsKey(key)) continue;
        final stored = prefs.getBool(key);
        if (stored != null) source[key] = stored;
      }
      if (!await prefs.setString(
        _migrationSnapshotKey,
        jsonEncode(source),
      )) {
        return (completed: false, snapshotStored: false);
      }
    }
    final targets = _convertedFlags(source);
    // Edits made while the migration was pending win over the snapshot:
    // they are the values the user chose, in new-semantics terms.
    targets.addAll(_readMigrationEdits(prefs));
    var allWritesSucceeded = true;
    for (final entry in targets.entries) {
      if (!await prefs.setBool(entry.key, entry.value)) {
        allWritesSucceeded = false;
      }
    }
    // Only mark the migration complete when every flag actually landed;
    // otherwise the next startup retries from the snapshot instead of
    // reinterpreting a stale value under the new semantics.
    if (!allWritesSucceeded) {
      return (completed: false, snapshotStored: true);
    }
    final markerOk = await prefs.setBool(_migrationMarkerKey, true);
    if (markerOk) {
      // The edits are now the stored values; drop the pending record.
      await prefs.remove(_migrationEditsKey);
    }
    return (completed: markerOk, snapshotStored: true);
  }

  Future<void> init() async {
    // Attempt to read flavor from asset first (injected by rebrand script)
    try {
      final String flavorJson = await rootBundle.loadString(
        'assets/flavor.json',
      );
      final Map<String, dynamic> data = jsonDecode(flavorJson);
      if (data.containsKey('flavor')) {
        _flavorFileVariant = data['flavor'];
      }
    } catch (_) {
      // Asset might not exist or be invalid, fallback to other detection methods
      _flavorFileVariant = '';
    }
    _log.info('Detected variant from flavor.json: $_flavorFileVariant');

    _prefs = await SharedPreferences.getInstance();
    final themeStr = _prefs?.getString('themeMode') ?? 'system';
    _themeMode = themeStr == 'dark'
        ? ThemeMode.dark
        : (themeStr == 'light' ? ThemeMode.light : ThemeMode.system);

    final themeTypeStr = _prefs?.getString('themeType') ?? 'custom';
    _themeType = themeTypeStr == 'stock'
        ? AppThemeType.stock
        : AppThemeType.custom;
    _autoLoadProfiles = _prefs?.getBool('autoLoadProfiles') ?? true;
    _autoLoadRemoteDevices = _prefs?.getBool('autoLoadRemoteDevices') ?? false;
    _loadProfileIcons = _prefs?.getBool('loadProfileIcons_v2') ?? false;
    _useNekokoIcons = _prefs?.getBool('useNekokoIcons') ?? true;
    _disableRefreshFlags = _prefs?.getBool('disableRefreshFlags') ?? false;
    final prefs = _prefs;
    // migrateRedactionFlags reports whether the marker is truly set and
    // whether a snapshot is stored: the prefs cache is optimistic, so a
    // failed write would otherwise read back as done.
    final outcome = prefs == null
        ? (completed: true, snapshotStored: true)
        : await migrateRedactionFlags(prefs);
    _migrationCompleted = outcome.completed;
    _migrationSnapshotStored = outcome.snapshotStored;
    // Load through _displayValues so a run whose migration did not
    // complete still shows the converted values instead of reading old
    // show-segment flags as new mask-segment flags. Once migrated, the
    // stored values are already new-semantics and load as-is.
    final storedFlags = <String, bool>{};
    Map<String, bool>? snapshot;
    var edits = <String, bool>{};
    if (prefs != null) {
      for (final key in _segmentFlagKeys) {
        final value = prefs.getBool(key);
        if (value != null) storedFlags[key] = value;
      }
      snapshot = _readMigrationSnapshot(prefs);
      edits = _readMigrationEdits(prefs);
    }
    final displayFlags = _migrationCompleted
        ? storedFlags
        : _displayValues(storedFlags, snapshot, edits);
    _redactEidFirst = displayFlags['redactEidFirst'] ?? false;
    _redactEidMiddle = displayFlags['redactEidMiddle'] ?? true;
    _redactEidLast = displayFlags['redactEidLast'] ?? false;
    _redactIccidFirst = displayFlags['redactIccidFirst'] ?? false;
    _redactIccidMiddle = displayFlags['redactIccidMiddle'] ?? true;
    _redactIccidLast = displayFlags['redactIccidLast'] ?? true;

    final nicknameRedactionIdx = _prefs?.getInt('nicknameRedactionMode');
    if (nicknameRedactionIdx != null &&
        nicknameRedactionIdx >= 0 &&
        nicknameRedactionIdx < NicknameRedactionMode.values.length) {
      _nicknameRedactionMode =
          NicknameRedactionMode.values[nicknameRedactionIdx];
    }

    final operatorRedactionIdx = _prefs?.getInt('operatorRedactionMode');
    if (operatorRedactionIdx != null &&
        operatorRedactionIdx >= 0 &&
        operatorRedactionIdx < OperatorRedactionMode.values.length) {
      _operatorRedactionMode =
          OperatorRedactionMode.values[operatorRedactionIdx];
    }

    final tagsRedactionIdx = _prefs?.getInt('tagsRedactionMode');
    if (tagsRedactionIdx != null &&
        tagsRedactionIdx >= 0 &&
        tagsRedactionIdx < TagsRedactionMode.values.length) {
      _tagsRedactionMode = TagsRedactionMode.values[tagsRedactionIdx];
    }

    final iconRedactionIdx = _prefs?.getInt('iconRedactionMode');
    if (iconRedactionIdx != null &&
        iconRedactionIdx >= 0 &&
        iconRedactionIdx < IconRedactionMode.values.length) {
      _iconRedactionMode = IconRedactionMode.values[iconRedactionIdx];
    }

    final flagRedactionIdx = _prefs?.getInt('flagRedactionMode');
    if (flagRedactionIdx != null &&
        flagRedactionIdx >= 0 &&
        flagRedactionIdx < FlagRedactionMode.values.length) {
      _flagRedactionMode = FlagRedactionMode.values[flagRedactionIdx];
    }

    // Notification preferences
    _notifAutoSendInstall = _prefs?.getBool('notifAutoSendInstall') ?? true;
    _notifAutoRemoveInstall = _prefs?.getBool('notifAutoRemoveInstall') ?? true;
    _notifAutoSendEnable = _prefs?.getBool('notifAutoSendEnable') ?? true;
    _notifAutoRemoveEnable = _prefs?.getBool('notifAutoRemoveEnable') ?? true;
    _notifAutoSendDisable = _prefs?.getBool('notifAutoSendDisable') ?? true;
    _notifAutoRemoveDisable = _prefs?.getBool('notifAutoRemoveDisable') ?? true;
    _notifAutoSendDelete = _prefs?.getBool('notifAutoSendDelete') ?? true;
    _notifAutoRemoveDelete = _prefs?.getBool('notifAutoRemoveDelete') ?? false;
    _notifProcessInitialLoad =
        _prefs?.getBool('notifProcessInitialLoad') ?? true;
    _notifProcessAfterSwitch =
        _prefs?.getBool('notifProcessAfterSwitch') ?? true;
    _notifProcessAfterDeletion =
        _prefs?.getBool('notifProcessAfterDeletion') ?? true;
    _notifProcessBeforeDownload =
        _prefs?.getBool('notifProcessBeforeDownload') ?? true;
    _notifProcessAfterInstall =
        _prefs?.getBool('notifProcessAfterInstall') ?? true;

    _notifDeleteWithoutSendingEnable =
        _prefs?.getBool('notifDeleteWithoutSendingEnable') ?? false;
    _notifDeleteWithoutSendingDisable =
        _prefs?.getBool('notifDeleteWithoutSendingDisable') ?? false;
    _sizeUnit =
        _prefs?.getString('sizeUnit') ?? "settings_item_unit_adaptive_si";
    _mss = (_prefs?.getInt('mss') ?? defaultMss).clamp(minMss, maxMss);
    _developerModeEnabled = _prefs?.getBool('developerModeEnabled') ?? false;
    _showLogConsole = _prefs?.getBool('showLogConsole') ?? false;
    _decodeAsn1 = _prefs?.getBool('decodeAsn1') ?? false;
    _enableApduLogging = _prefs?.getBool('enableApduLogging') ?? false;
    _lastSelectedReader = _prefs?.getString('lastSelectedReader');
    _remoCardPassword = _prefs?.getString('remoCardPassword');
    _forceDeviceDropdown = _prefs?.getBool('forceDeviceDropdown') ?? false;
    _enableNekokoStats = _prefs?.getBool('enableNekokoStats') ?? true;
    _estimateProfileSize = _prefs?.getBool('estimateProfileSize') ?? true;
    _enableProfileStatusEnhancer =
        _prefs?.getBool('enableProfileStatusEnhancer') ?? true;
    _enableScheduledNotifications =
        _prefs?.getBool('enableScheduledNotifications') ?? true;
    _enableBleConnector = _prefs?.getBool('enableBleConnector') ?? true;
    _enableCcidConnector = _prefs?.getBool('enableCcidConnector') ?? true;
    _enablePhoenixReader = _prefs?.getBool('enablePhoenixReader') ?? false;
    // On a Qualcomm device the bus is there whether or not anything is
    // plugged in, so it starts on there and off everywhere else.
    _enableQrtrConnector =
        _prefs?.getBool('enableQrtrConnector') ?? await QrtrHost.isSupported();
    _enableSeHalConnector = _prefs?.getBool('enableSeHalConnector') ?? false;
    _halBorrowedSlots
      ..clear()
      ..addAll(
        (_prefs?.getStringList('halBorrowedSlots') ?? [])
            .where((s) => s == '1' || s == '2')
            .map(int.parse),
      );
    bool otbridgeHasOmapi = false;
    bool otbridgeHasTmapi = false;

    if (PlatformX.isAndroid) {
      _nbridgeProviderAvailable = await NBridgeService.isAvailable();
      _rootDetected = await NBridgeService.isRooted();

      // Only the connector defaults need the helper's slot list, and this runs
      // before the first frame: skip it once both are stored, and do not wait
      // on a helper that does not answer.
      final needsConnectorDefaults =
          _prefs?.containsKey('enableOmapiConnector') != true ||
          _prefs?.containsKey('enableTmapiConnector') != true;
      if (_nbridgeProviderAvailable && needsConnectorDefaults) {
        try {
          final slots = await NBridgeService.listSlots().timeout(
            const Duration(seconds: 5),
          );
          otbridgeHasOmapi = slots.any(
            (s) => s['id']?.toString().startsWith('omapi:') == true,
          );
          otbridgeHasTmapi = slots.any(
            (s) => s['id']?.toString().startsWith('tmapi:') == true,
          );
        } catch (error) {
          // An installed but unavailable helper is not evidence that it can replace built-in readers.
          _log.warning(
            'OTBridge discovery failed; keeping built-in reader defaults: $error',
          );
        }
      }
    }
    _enableOmapiConnector =
        _prefs?.getBool('enableOmapiConnector') ?? !otbridgeHasOmapi;
    _enableTmapiConnector =
        _prefs?.getBool('enableTmapiConnector') ?? !otbridgeHasTmapi;
    _enableRemoteConnector = _prefs?.getBool('enableRemoteConnector') ?? false;
    _enableUpdateCheck = _prefs?.getBool('enableUpdateCheck') ?? true;
    _rspProxyMode = RspProxyConfig.modeFromString(
      _prefs?.getString('rspProxyMode'),
    );
    _rspForwardProxyProtocol = RspProxyConfig.normalizeForwardProtocol(
      _prefs?.getString('rspForwardProxyProtocol'),
    );
    _rspForwardProxyHost = _prefs?.getString('rspForwardProxyHost') ?? '';
    _rspForwardProxyPort = _prefs?.getInt('rspForwardProxyPort');
    _rspReverseProxyUrlPrefix =
        _prefs?.getString('rspReverseProxyUrlPrefix') ?? '';
    _locale = _prefs?.getString('locale');
    _estkMaxEids = (_prefs?.getStringList('estkMaxEids') ?? []).toSet();
    _aids = _prefs?.getStringList('aids') ?? _aids;
    _vowifiEnabled = _prefs?.getBool(_vowifiEnabledKey) ?? false;
    _vowifiConsentVersion = _prefs?.getInt(_vowifiConsentVersionKey);
    _vowifiAutoRenew = _prefs?.getBool(_vowifiAutoRenewKey) ?? false;

    final phoneFormatIdx = _prefs?.getInt('phoneFormatStrategy');
    if (phoneFormatIdx != null &&
        phoneFormatIdx >= 0 &&
        phoneFormatIdx < PhoneFormatStrategy.values.length) {
      _phoneFormatStrategy = PhoneFormatStrategy.values[phoneFormatIdx];
    }

    final sortIdx = _prefs?.getInt('profileSortType');
    if (sortIdx != null &&
        sortIdx >= 0 &&
        sortIdx < ProfileSortType.values.length) {
      _profileSortType = ProfileSortType.values[sortIdx];
    }
    _sortAscending = _prefs?.getBool('sortAscending') ?? true;
    _useWaterfallLayout = _prefs?.getBool('useWaterfallLayout') ?? true;

    // Default showProfileSearch based on platform
    final isDesktop = PlatformX.isDesktop;
    _showProfileSearch = _prefs?.getBool('showProfileSearch') ?? isDesktop;
    _enableBrowser =
        _prefs?.getBool('enableBrowser') ??
        _prefs?.getBool('showVariantTabs') ??
        true;

    // Always load configured remote servers
    _remoCardUrls = await DatabaseService().getRemoteServers();

    await BleManager().init();

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      _packageName = packageInfo.packageName;
    } catch (e) {
      // Fallback to defaults already set
    }

    if (!vowifiEnabled) {
      _vowifiEnabled = false;
      _vowifiAutoRenew = false;
      await _removePrefIfPresent(_vowifiEnabledKey);
      await _removePrefIfPresent(_vowifiAutoRenewKey);
      if (!vowifiAvailable ||
          _vowifiConsentVersion != BuildCapabilities.vowifiConsentVersion) {
        _vowifiConsentVersion = null;
        await _removePrefIfPresent(_vowifiConsentVersionKey);
      }
    }

    // Load variant tabs configuration
    if (!PlatformX.isWindows && !PlatformX.isLinux) {
      try {
        final String yamlString = await rootBundle.loadString(
          'assets/variant_tabs.yaml',
        );
        final YamlMap doc = loadYaml(yamlString);
        if (doc['variants'] != null) {
          final v = variant.isEmpty ? 'std' : variant;
          final variantConfig = doc['variants'][v];
          if (variantConfig != null && variantConfig['tabs'] != null) {
            final YamlList tabs = variantConfig['tabs'];
            _variantTabs = [];
            for (var t in tabs) {
              final String url = t['url'];
              final bool defaultEnabled = t['enabledByDefault'] ?? true;
              final bool toggleAllowed = t['toggleAllowed'] ?? false;

              // Determine if enabled
              bool isEnabled = defaultEnabled;
              if (toggleAllowed) {
                isEnabled =
                    _prefs?.getBool('tab_enabled_$url') ?? defaultEnabled;
              }

              _variantTabs.add(
                BrowserTabConfig(
                  title: t['title'],
                  url: url,
                  icon: t['icon'],
                  label: t['label'],
                  toggleAllowed: toggleAllowed,
                  enabledByDefault: defaultEnabled,
                  isEnabled: isEnabled,
                ),
              );
            }
          }
        }
      } catch (e) {
        _log.warning('Failed to load variant tabs: $e');
      }
    } else {
      _log.info('Variant tabs disabled for this platform');
      _variantTabs = [];
    }

    notifyListeners();
  }

  String? getPreferredEstkAid(String readerId, String atr) {
    final key =
        'preferredEstkAid_v1_${readerId.toLowerCase()}|${atr.toUpperCase()}';
    return _prefs?.getString(key);
  }

  Future<void> setPreferredEstkAid(
    String readerId,
    String atr,
    String aid,
  ) async {
    final key =
        'preferredEstkAid_v1_${readerId.toLowerCase()}|${atr.toUpperCase()}';
    await _prefs?.setString(key, aid);
    notifyListeners();
  }

  String? getPersistedEid(String readerId) {
    final key = readerId.toLowerCase();
    final jsonStr = _prefs?.getString('persisted_reader_eids_v2');
    if (jsonStr == null) return null;
    try {
      final Map<String, dynamic> persisted = jsonDecode(jsonStr);
      return persisted[key]?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> savePersistedEid(String readerId, String eid) async {
    final key = readerId.toLowerCase();
    if (!key.startsWith('glocalme:')) return;

    final jsonStr = _prefs?.getString('persisted_reader_eids_v2');
    Map<String, dynamic> persisted = {};
    if (jsonStr != null) {
      try {
        persisted = jsonDecode(jsonStr);
      } catch (_) {}
    }
    persisted[key] = eid;
    await _prefs?.setString('persisted_reader_eids_v2', jsonEncode(persisted));
  }

  Future<void> setMss(int value) async {
    _mss = value;
    await _prefs?.setInt('mss', value);
    notifyListeners();
  }

  Future<void> setAids(List<String> value) async {
    _aids = value;
    await _prefs?.setStringList('aids', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _prefs?.setString('themeMode', value.name);
    notifyListeners();
  }

  Future<void> setThemeType(AppThemeType value) async {
    _themeType = value;
    await _prefs?.setString('themeType', value.name);
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    if (_themeMode == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  Future<void> setAutoLoadProfiles(bool value) async {
    _autoLoadProfiles = value;
    await _prefs?.setBool('autoLoadProfiles', value);
    notifyListeners();
  }

  Future<void> setAutoLoadRemoteDevices(bool value) async {
    _autoLoadRemoteDevices = value;
    await _prefs?.setBool('autoLoadRemoteDevices', value);
    notifyListeners();
  }

  // Notification Process Setters
  Future<void> setNotifAutoSendInstall(bool value) async {
    _notifAutoSendInstall = value;
    await _prefs?.setBool('notifAutoSendInstall', value);
    notifyListeners();
  }

  Future<void> setNotifAutoRemoveInstall(bool value) async {
    _notifAutoRemoveInstall = value;
    await _prefs?.setBool('notifAutoRemoveInstall', value);
    notifyListeners();
  }

  Future<void> setNotifAutoSendEnable(bool value) async {
    _notifAutoSendEnable = value;
    await _prefs?.setBool('notifAutoSendEnable', value);
    notifyListeners();
  }

  Future<void> setNotifAutoRemoveEnable(bool value) async {
    _notifAutoRemoveEnable = value;
    await _prefs?.setBool('notifAutoRemoveEnable', value);
    notifyListeners();
  }

  Future<void> setNotifDeleteWithoutSendingEnable(bool value) async {
    _notifDeleteWithoutSendingEnable = value;
    await _prefs?.setBool('notifDeleteWithoutSendingEnable', value);
    notifyListeners();
  }

  Future<void> setNotifAutoSendDisable(bool value) async {
    _notifAutoSendDisable = value;
    await _prefs?.setBool('notifAutoSendDisable', value);
    notifyListeners();
  }

  Future<void> setNotifAutoRemoveDisable(bool value) async {
    _notifAutoRemoveDisable = value;
    await _prefs?.setBool('notifAutoRemoveDisable', value);
    notifyListeners();
  }

  Future<void> setNotifDeleteWithoutSendingDisable(bool value) async {
    _notifDeleteWithoutSendingDisable = value;
    await _prefs?.setBool('notifDeleteWithoutSendingDisable', value);
    notifyListeners();
  }

  Future<void> setNotifAutoSendDelete(bool value) async {
    _notifAutoSendDelete = value;
    await _prefs?.setBool('notifAutoSendDelete', value);
    notifyListeners();
  }

  Future<void> setNotifAutoRemoveDelete(bool value) async {
    _notifAutoRemoveDelete = value;
    await _prefs?.setBool('notifAutoRemoveDelete', value);
    notifyListeners();
  }

  Future<void> setNotifProcessInitialLoad(bool value) async {
    _notifProcessInitialLoad = value;
    await _prefs?.setBool('notifProcessInitialLoad', value);
    notifyListeners();
  }

  Future<void> setNotifProcessAfterSwitch(bool value) async {
    _notifProcessAfterSwitch = value;
    await _prefs?.setBool('notifProcessAfterSwitch', value);
    notifyListeners();
  }

  Future<void> setNotifProcessAfterDeletion(bool value) async {
    _notifProcessAfterDeletion = value;
    await _prefs?.setBool('notifProcessAfterDeletion', value);
    notifyListeners();
  }

  Future<void> setNotifProcessBeforeDownload(bool value) async {
    _notifProcessBeforeDownload = value;
    await _prefs?.setBool('notifProcessBeforeDownload', value);
    notifyListeners();
  }

  Future<void> setNotifProcessAfterInstall(bool value) async {
    _notifProcessAfterInstall = value;
    await _prefs?.setBool('notifProcessAfterInstall', value);
    notifyListeners();
  }

  Future<void> setEnableUpdateCheck(bool value) async {
    _enableUpdateCheck = value;
    await _prefs?.setBool('enableUpdateCheck', value);
    notifyListeners();
  }

  Future<void> setRspProxyConfig(RspProxyConfig value) async {
    _rspProxyMode = value.mode;
    _rspForwardProxyProtocol = RspProxyConfig.normalizeForwardProtocol(
      value.forwardProtocol,
    );
    _rspForwardProxyHost = value.forwardHost.trim();
    _rspForwardProxyPort = value.forwardPort;
    _rspReverseProxyUrlPrefix = value.reverseUrlPrefix.trim();

    await _prefs?.setString('rspProxyMode', _rspProxyMode.name);
    await _prefs?.setString(
      'rspForwardProxyProtocol',
      _rspForwardProxyProtocol,
    );
    await _prefs?.setString('rspForwardProxyHost', _rspForwardProxyHost);
    if (_rspForwardProxyPort == null) {
      await _prefs?.remove('rspForwardProxyPort');
    } else {
      await _prefs?.setInt('rspForwardProxyPort', _rspForwardProxyPort!);
    }
    await _prefs?.setString(
      'rspReverseProxyUrlPrefix',
      _rspReverseProxyUrlPrefix,
    );
    notifyListeners();
  }

  Future<void> setSizeUnit(String value) async {
    _sizeUnit = value;
    await _prefs?.setString('sizeUnit', value);
    notifyListeners();
  }

  Future<void> setLoadProfileIcons(bool value) async {
    _loadProfileIcons = value;
    await _prefs?.setBool('loadProfileIcons_v2', value);
    notifyListeners();
  }

  Future<void> setDisableRefreshFlags(bool value) async {
    _disableRefreshFlags = value;
    await _prefs?.setBool('disableRefreshFlags', value);
    notifyListeners();
  }

  Future<void> setDeveloperModeEnabled(bool value) async {
    _developerModeEnabled = value;
    await _prefs?.setBool('developerModeEnabled', value);
    notifyListeners();
  }

  bool _showLogConsole = false;
  bool get showLogConsole => _developerModeEnabled && _showLogConsole;

  Future<void> setShowLogConsole(bool value) async {
    _showLogConsole = value;
    await _prefs?.setBool('showLogConsole', value);
    notifyListeners();
  }

  bool _decodeAsn1 = false;
  bool get decodeAsn1 => _decodeAsn1; // kDebugMode ||
  Future<void> setDecodeAsn1(bool value) async {
    _decodeAsn1 = value;
    await _prefs?.setBool('decodeAsn1', value);
    notifyListeners();
  }

  bool _enableApduLogging = false;
  bool get enableApduLogging => kDebugMode || _enableApduLogging;
  Future<void> setEnableApduLogging(bool value) async {
    _enableApduLogging = value;
    await _prefs?.setBool('enableApduLogging', value);
    notifyListeners();
  }

  Future<void> setLastSelectedReader(String? value) async {
    _lastSelectedReader = value;
    if (value == null) {
      await _prefs?.remove('lastSelectedReader');
    } else {
      await _prefs?.setString('lastSelectedReader', value);
    }
    notifyListeners();
  }

  Future<void> setForceDeviceDropdown(bool value) async {
    _forceDeviceDropdown = value;
    await _prefs?.setBool('forceDeviceDropdown', value);
    notifyListeners();
  }

  Future<void> setEnableNekokoStats(bool value) async {
    _enableNekokoStats = value;
    await _prefs?.setBool('enableNekokoStats', value);
    notifyListeners();
  }

  Future<void> setEstimateProfileSize(bool value) async {
    _estimateProfileSize = value;
    await _prefs?.setBool('estimateProfileSize', value);
    notifyListeners();
  }

  Future<void> setUseNekokoIcons(bool value) async {
    _useNekokoIcons = value;
    await _prefs?.setBool('useNekokoIcons', value);
    notifyListeners();
  }

  /// Serializes pending-migration edit transactions: the settings page
  /// fires the setters without awaiting them, so two quick taps would
  /// otherwise interleave their snapshot captures and edits-record
  /// writes and drop each other's edits.
  Future<void> _pendingMigrationEdit = Future.value();

  /// Runs [run] after any in-flight pending-migration edit transaction,
  /// so two quick taps cannot interleave their snapshot captures and
  /// edits-record writes.
  Future<T> _runPendingMigrationEdit<T>(Future<T> Function() run) {
    final result = _pendingMigrationEdit.then((_) => run());
    // Keep the chain alive even if this run fails.
    _pendingMigrationEdit = result.then((_) {}).catchError((_) {});
    return result;
  }

  /// Records segment-flag edits made while the migration is still
  /// pending, in new-semantics terms, so a later retry writes the edited
  /// values instead of recomputing them from the frozen snapshot. Returns
  /// false when the record itself cannot be stored.
  Future<bool> _syncPendingMigrationEdit(String key, bool newValue) =>
      _runPendingMigrationEdit(
        () => _recordPendingMigrationEdits({key: newValue}),
      );

  /// Captures the pre-migration flag values into the snapshot when none
  /// is stored yet. Without one, a later retry would rebuild the source
  /// pair from the current flags — but an edited flag already holds its
  /// new value, which would corrupt the coupled EID pair. Returns false
  /// when the snapshot cannot be stored, in which case the caller must
  /// refuse the edit.
  Future<bool> _ensureMigrationSnapshot(SharedPreferences prefs) async {
    if (_migrationSnapshotStored) return true;
    final edits = _readMigrationEdits(prefs);
    final source = <String, bool>{};
    for (final flagKey in _segmentFlagKeys) {
      if (edits.containsKey(flagKey)) continue;
      final stored = prefs.getBool(flagKey);
      if (stored != null) source[flagKey] = stored;
    }
    if (!await prefs.setString(_migrationSnapshotKey, jsonEncode(source))) {
      return false;
    }
    _migrationSnapshotStored = true;
    return true;
  }

  /// Records [values] in the pending-migration edits record with a single
  /// write. Staging a whole batch at once makes the write the atomic gate:
  /// if it fails, nothing is recorded at all, so a caller applying the
  /// values afterwards can never land half-applied. Returns false when
  /// the record cannot be stored.
  Future<bool> _recordPendingMigrationEdits(Map<String, bool> values) async {
    final prefs = _prefs;
    if (prefs == null) return true;
    if (_migrationCompleted) return true;
    if (!await _ensureMigrationSnapshot(prefs)) return false;
    final edits = _readMigrationEdits(prefs);
    final previousValues = <String, bool?>{};
    for (final entry in values.entries) {
      previousValues[entry.key] = edits[entry.key];
      edits[entry.key] = entry.value;
    }
    if (await prefs.setString(_migrationEditsKey, jsonEncode(edits))) {
      return true;
    }
    // The failed write still replaced the in-memory cache, so restore
    // the record to what it was before this transaction: an earlier
    // persisted edit to the same key must survive. The restore is itself
    // an optimistic write, so the cache is fixed even if the store write
    // fails again (the store never received the new values).
    for (final entry in previousValues.entries) {
      final previous = entry.value;
      if (previous == null) {
        edits.remove(entry.key);
      } else {
        edits[entry.key] = previous;
      }
    }
    if (edits.isEmpty) {
      await prefs.remove(_migrationEditsKey);
    } else {
      await prefs.setString(_migrationEditsKey, jsonEncode(edits));
    }
    return false;
  }

  /// Sets one segment flag, recording the edit first when the migration
  /// is still pending. If the record cannot be stored, the flag is left
  /// untouched: persisting it would let the next startup read it as an
  /// old-semantics value and negate it.
  Future<bool> _setSegmentFlag(
    String key,
    bool value,
    void Function(bool value) setField,
  ) async {
    if (!await _syncPendingMigrationEdit(key, value)) return false;
    setField(value);
    await _prefs?.setBool(key, value);
    notifyListeners();
    return true;
  }

  Future<bool> setRedactEidFirst(bool value) =>
      _setSegmentFlag('redactEidFirst', value, (v) => _redactEidFirst = v);

  Future<bool> setRedactEidMiddle(bool value) =>
      _setSegmentFlag('redactEidMiddle', value, (v) => _redactEidMiddle = v);

  Future<bool> setRedactEidLast(bool value) =>
      _setSegmentFlag('redactEidLast', value, (v) => _redactEidLast = v);

  Future<bool> setRedactIccidFirst(bool value) => _setSegmentFlag(
    'redactIccidFirst',
    value,
    (v) => _redactIccidFirst = v,
  );

  Future<bool> setRedactIccidMiddle(bool value) => _setSegmentFlag(
    'redactIccidMiddle',
    value,
    (v) => _redactIccidMiddle = v,
  );

  Future<bool> setRedactIccidLast(bool value) =>
      _setSegmentFlag('redactIccidLast', value, (v) => _redactIccidLast = v);

  Future<void> setNicknameRedactionMode(NicknameRedactionMode value) async {
    _nicknameRedactionMode = value;
    await _prefs?.setInt('nicknameRedactionMode', value.index);
    notifyListeners();
  }

  Future<void> setOperatorRedactionMode(OperatorRedactionMode value) async {
    _operatorRedactionMode = value;
    await _prefs?.setInt('operatorRedactionMode', value.index);
    notifyListeners();
  }

  Future<void> setTagsRedactionMode(TagsRedactionMode value) async {
    _tagsRedactionMode = value;
    await _prefs?.setInt('tagsRedactionMode', value.index);
    notifyListeners();
  }

  Future<void> setIconRedactionMode(IconRedactionMode value) async {
    _iconRedactionMode = value;
    await _prefs?.setInt('iconRedactionMode', value.index);
    notifyListeners();
  }

  Future<void> setFlagRedactionMode(FlagRedactionMode value) async {
    _flagRedactionMode = value;
    await _prefs?.setInt('flagRedactionMode', value.index);
    notifyListeners();
  }

  bool get hasNoRedactionsConfigured =>
      !_redactEidFirst &&
      !_redactEidMiddle &&
      !_redactEidLast &&
      !_redactIccidFirst &&
      !_redactIccidMiddle &&
      !_redactIccidLast &&
      _nicknameRedactionMode == NicknameRedactionMode.none &&
      _operatorRedactionMode == OperatorRedactionMode.none &&
      _tagsRedactionMode == TagsRedactionMode.none &&
      _iconRedactionMode == IconRedactionMode.none &&
      _flagRedactionMode == FlagRedactionMode.none;

  /// Shared display-only privacy state for profile and Wi-Fi calling pages.
  /// Full-hide counts as masked even when no redaction is configured.
  bool get isSensitiveDataMasked =>
      _fullHideSensitiveData ||
      (!_revealSensitiveProfileData && !hasNoRedactionsConfigured);

  Future<void> toggleSensitiveDataVisibility() async {
    if (_fullHideSensitiveData) {
      // Full-hide -> reveal all, like the Profiles eye.
      setFullHideSensitiveData(false);
      setRevealSensitiveProfileData(true);
    } else if (_revealSensitiveProfileData) {
      setRevealSensitiveProfileData(false);
      if (hasNoRedactionsConfigured) {
        await applyQuickRedactionPreset();
      }
    } else if (hasNoRedactionsConfigured) {
      await applyQuickRedactionPreset();
    } else {
      setRevealSensitiveProfileData(true);
    }
  }

  /// Applies the quick preset (mask every segment, hide nicknames, show
  /// country names). Returns false and changes nothing when a segment
  /// edit cannot be recorded while the migration is pending: a
  /// half-applied preset would look configured while the identifiers
  /// stay raw.
  Future<bool> applyQuickRedactionPreset() async {
    // Stage all six edits in the pending-migration record with a single
    // write first: if the record cannot be stored, nothing is applied at
    // all, so the preset can never land half-applied. Once staged, the
    // flags are applied directly instead of through the setters, since
    // each setter would record its own write and re-open the partial
    // window. The record also keeps the retry honest: a restart replays
    // the staged values instead of recomputing them from the snapshot.
    const preset = {
      'redactEidFirst': false,
      'redactEidMiddle': true,
      'redactEidLast': true,
      'redactIccidFirst': true,
      'redactIccidMiddle': true,
      'redactIccidLast': true,
    };
    final recorded = await _runPendingMigrationEdit(
      () => _recordPendingMigrationEdits(preset),
    );
    if (!recorded) return false;
    _redactEidFirst = false;
    _redactEidMiddle = true;
    _redactEidLast = true;
    _redactIccidFirst = true;
    _redactIccidMiddle = true;
    _redactIccidLast = true;
    _revealSensitiveProfileData = false;
    _fullHideSensitiveData = false;
    _nicknameRedactionMode = NicknameRedactionMode.hideNickname;
    _operatorRedactionMode = OperatorRedactionMode.countryName;

    final prefs = _prefs;
    if (prefs != null) {
      for (final entry in preset.entries) {
        await prefs.setBool(entry.key, entry.value);
      }
    }
    await _prefs?.setInt('nicknameRedactionMode', _nicknameRedactionMode.index);
    await _prefs?.setInt('operatorRedactionMode', _operatorRedactionMode.index);
    notifyListeners();
    return true;
  }

  void setRevealSensitiveProfileData(bool value) {
    // Reveal and full-hide are mutually exclusive.
    final changed =
        _revealSensitiveProfileData != value ||
        (value && _fullHideSensitiveData);
    if (!changed) return;
    _revealSensitiveProfileData = value;
    if (value) _fullHideSensitiveData = false;
    notifyListeners();
  }

  void setFullHideSensitiveData(bool value) {
    // Full-hide and reveal are mutually exclusive.
    final changed =
        _fullHideSensitiveData != value ||
        (value && _revealSensitiveProfileData);
    if (!changed) return;
    _fullHideSensitiveData = value;
    if (value) _revealSensitiveProfileData = false;
    notifyListeners();
  }

  void refreshUi() {
    notifyListeners();
  }

  Future<void> setEnableProfileStatusEnhancer(bool value) async {
    _enableProfileStatusEnhancer = value;
    await _prefs?.setBool('enableProfileStatusEnhancer', value);
    notifyListeners();
  }

  bool _enableScheduledNotifications = true;
  bool get enableScheduledNotifications => _enableScheduledNotifications;

  Future<void> setEnableScheduledNotifications(bool value) async {
    _enableScheduledNotifications = value;
    await _prefs?.setBool('enableScheduledNotifications', value);
    notifyListeners();
  }

  // Phone Format Strategy
  PhoneFormatStrategy _phoneFormatStrategy =
      PhoneFormatStrategy.internationalAndMobile;
  PhoneFormatStrategy get phoneFormatStrategy => _phoneFormatStrategy;

  Future<void> setPhoneFormatStrategy(PhoneFormatStrategy value) async {
    _phoneFormatStrategy = value;
    await _prefs?.setInt('phoneFormatStrategy', value.index);
    notifyListeners();
  }

  List<BrowserTabConfig> _variantTabs = [];
  List<BrowserTabConfig> get variantTabs => _variantTabs;

  Future<void> setTabEnabled(String url, bool value) async {
    final index = _variantTabs.indexWhere((t) => t.url == url);
    if (index != -1) {
      if (!_variantTabs[index].toggleAllowed) return; // Not allowed
      _variantTabs[index].isEnabled = value;
      await _prefs?.setBool('tab_enabled_$url', value);
      notifyListeners();
    }
  }

  Future<void> setLocale(String? value) async {
    _locale = value;
    if (value == null) {
      await _prefs?.remove('locale');
    } else {
      await _prefs?.setString('locale', value);
    }
    notifyListeners();
  }

  Future<void> setEnableBleConnector(bool value) async {
    _enableBleConnector = value;
    await _prefs?.setBool('enableBleConnector', value);
    notifyListeners();
  }

  Future<void> setVowifiEnabled(
    bool value, {
    bool disclaimerAccepted = false,
  }) async {
    final wasEnabled = vowifiEnabled;

    if (!value || !vowifiAvailable || !disclaimerAccepted) {
      _vowifiEnabled = false;
      _vowifiAutoRenew = false;
      await _prefs?.remove(_vowifiEnabledKey);
      await _prefs?.remove(_vowifiAutoRenewKey);
      if (!vowifiAvailable) {
        _vowifiConsentVersion = null;
        await _prefs?.remove(_vowifiConsentVersionKey);
      }
    } else {
      _vowifiConsentVersion = BuildCapabilities.vowifiConsentVersion;
      _vowifiEnabled = true;
      await _prefs?.setInt(
        _vowifiConsentVersionKey,
        BuildCapabilities.vowifiConsentVersion,
      );
      await _prefs?.setBool(_vowifiEnabledKey, true);
    }

    if (wasEnabled != vowifiEnabled) notifyListeners();
  }

  Future<void> setEnableCcidConnector(bool value) async {
    _enableCcidConnector = value;
    await _prefs?.setBool('enableCcidConnector', value);
    notifyListeners();
  }

  Future<void> setEnablePhoenixReader(bool value) async {
    _enablePhoenixReader = value;
    await _prefs?.setBool('enablePhoenixReader', value);
    notifyListeners();
  }

  Future<void> setEnableQrtrConnector(bool value) async {
    _enableQrtrConnector = value;
    await _prefs?.setBool('enableQrtrConnector', value);
    notifyListeners();
  }

  Future<void> setEnableSeHalConnector(bool value) async {
    _enableSeHalConnector = value;
    await _prefs?.setBool('enableSeHalConnector', value);
    notifyListeners();
  }

  Future<void> setHalUseBorrowed(int slot, bool value) async {
    if (slot < 1 || slot > 2) throw ArgumentError('Invalid SIM slot');
    if (value) {
      _halBorrowedSlots.add(slot);
    } else {
      _halBorrowedSlots.remove(slot);
    }
    await _prefs?.setStringList(
      'halBorrowedSlots',
      _halBorrowedSlots.map((s) => '$s').toList(),
    );
    notifyListeners();
  }

  Future<void> setEnableOmapiConnector(bool value) async {
    _enableOmapiConnector = value;
    await _prefs?.setBool('enableOmapiConnector', value);
    notifyListeners();
  }

  Future<void> setEnableTmapiConnector(bool value) async {
    _enableTmapiConnector = value;
    await _prefs?.setBool('enableTmapiConnector', value);
    notifyListeners();
  }

  bool _enableRemoteConnector = false;
  bool get enableRemoteConnector => _enableRemoteConnector;

  Future<void> setEnableRemoteConnector(bool value) async {
    _enableRemoteConnector = value;
    await _prefs?.setBool('enableRemoteConnector', value);
    notifyListeners();
  }

  // IMEI/TAC for profile downloads
  Uint8List? _cachedImei;
  Uint8List? _cachedTac;

  bool get sendFullImei => _prefs?.getBool('deviceImeiSendFull') ?? false;

  Future<void> setImeiString(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _prefs?.remove('deviceImei');
      await _prefs?.remove('deviceImeiSendFull');
      _cachedImei = null;
      _cachedTac = null;
    } else {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final imei = storedImeiBytesFromDigits(value);
      final stored = imei
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await _prefs?.setString('deviceImei', stored);
      await _prefs?.setBool('deviceImeiSendFull', digits.length == 15);
      _cachedImei = null;
      _cachedTac = null;
    }
    notifyListeners();
  }

  /// Gets or generates a persistent IMEI (8 bytes / 16 digits) for profile downloads.
  /// The default generated TAC is 35383741.
  Future<Uint8List> getImei() async {
    if (_cachedImei != null) return _cachedImei!;

    final stored = _prefs?.getString('deviceImei');
    bool isValid = false;
    if (stored != null && stored.length == 16) {
      // BCD validation: exactly 16 digits [0-9]
      if (RegExp(r'^[0-9]{16}$').hasMatch(stored)) {
        isValid = true;
        try {
          _cachedImei = Uint8List.fromList(
            List.generate(
              8,
              (i) => int.parse(stored.substring(i * 2, i * 2 + 2), radix: 16),
            ),
          );
          _cachedTac = _cachedImei!.sublist(0, 4);
          return _cachedImei!;
        } catch (e) {
          _log.warning('Failed to parse stored IMEI: $e');
          isValid = false;
        }
      }
    }

    if (stored != null && !isValid) {
      _log.warning(
        'Stored IMEI "$stored" is invalid (not exactly 16 digits). Regenerating...',
      );
    }

    // Generate new IMEI
    _cachedImei = await _generateImei();
    _cachedTac = _cachedImei!.sublist(0, 4);

    // Save to preferences
    final hex = _cachedImei!
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await _prefs?.setString('deviceImei', hex);

    _log.info('Generated new IMEI: $hex');
    return _cachedImei!;
  }

  /// Gets the TAC (first 4 bytes of IMEI)
  Future<Uint8List> getTac() async {
    if (_cachedTac != null) return _cachedTac!;
    await getImei(); // This will populate _cachedTac
    return _cachedTac!;
  }

  Future<String> getDisplayedImeiDigits() async {
    final digits = imeiDigitsFromStoredBytes(await getImei());
    return sendFullImei ? digits : digits.substring(0, 8);
  }

  Future<Uint8List?> getDeviceInfoImei() async {
    if (!sendFullImei) return null;
    return encodeDeviceInfoImei(await getImei());
  }

  Future<Uint8List> _generateImei() async {
    // Generate a truly random seed if we don't have a device ID yet
    int seed = DateTime.now().microsecondsSinceEpoch;

    try {
      final deviceId = _prefs?.getString('deviceId');
      if (deviceId != null) {
        seed = deviceId.hashCode;
      } else {
        final newDeviceId = DateTime.now().microsecondsSinceEpoch.toString();
        await _prefs?.setString('deviceId', newDeviceId);
        seed = newDeviceId.hashCode;
      }
    } catch (_) {}

    final random = Random(seed);

    return storedImeiBytesFromDigits(defaultDeviceTac, random: random);
  }

  Set<String> _estkMaxEids = {};
  bool isEstkMax(String? eid) {
    if (eid == null) return false;
    return _estkMaxEids.contains(eid.toUpperCase());
  }

  Future<void> markAsEstkMax(String eid) async {
    final upper = eid.toUpperCase();
    if (_estkMaxEids.add(upper)) {
      await _prefs?.setStringList('estkMaxEids', _estkMaxEids.toList());
      notifyListeners();
    }
  }
}
