import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logging/logging.dart';
import '../services/database_service.dart';
import '../adapter/ble/ble_manager.dart';
import '../services/nbridge_service.dart';
import '../utils/platform_adapter.dart';
import '../utils/imei_codec.dart';
import '../version.dart';
import '../config.dart';
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

  String get variant {
    // 1. Check if explicitly defined in build environment
    const String envVariant = String.fromEnvironment(
      'APP_VARIANT',
      defaultValue: '',
    );
    if (envVariant.isNotEmpty) return envVariant;

    // 2. Check if flavor.json defines a variant
    if (_flavorFileVariant.isNotEmpty) return _flavorFileVariant;

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
    return 'assets/logo.png';
  }

  String get appName {
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
  bool get isDarkMode => _themeMode == ThemeMode.dark;

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
  bool _notifDeleteWithoutSendingInstall = false;
  bool get notifDeleteWithoutSendingInstall =>
      _notifDeleteWithoutSendingInstall;

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
  bool _notifDeleteWithoutSendingDelete = false;
  bool get notifDeleteWithoutSendingDelete => _notifDeleteWithoutSendingDelete;

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

  bool _enableUpdateCheck = true;
  bool get enableUpdateCheck => _enableUpdateCheck;

  bool get ensureSingleChannel => true;

  // Connection
  int _mss = 240;
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

  bool _showHardwareTab = true;
  bool get showHardwareTab => _showHardwareTab;

  Future<void> setShowHardwareTab(bool value) async {
    _showHardwareTab = value;
    await _prefs?.setBool('showHardwareTab', value);
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

  bool _redactEidFirst = true;
  bool get redactEidFirst => _redactEidFirst;

  bool _redactEidMiddle = false;
  bool get redactEidMiddle => _redactEidMiddle;

  bool _redactEidLast = true;
  bool get redactEidLast => _redactEidLast;

  bool _redactIccidFirst = true;
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

  Future<void> setRemoCardUrls(List<String> values) async {
    _remoCardUrls = values.where((v) => v.isNotEmpty).toList();
    // Sync to DB: For simplicity, we just save them all.
    // Ideally we should remove ones not in list, but we lack bulk delete currently without clearing all.
    // Assuming this is used for adding/reordering, saving all is safe for existence.
    // If used for deletion, we rely on removeRemoCardUrl logic.
    for (final url in _remoCardUrls) {
      await DatabaseService().saveRemoteServer(url);
    }
    notifyListeners();
  }

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
    _redactEidFirst = _prefs?.getBool('redactEidFirst') ?? true;
    _redactEidMiddle = _prefs?.getBool('redactEidMiddle') ?? false;
    _redactEidLast = _prefs?.getBool('redactEidLast') ?? true;
    _redactIccidFirst = _prefs?.getBool('redactIccidFirst') ?? true;
    _redactIccidMiddle = _prefs?.getBool('redactIccidMiddle') ?? true;
    _redactIccidLast = _prefs?.getBool('redactIccidLast') ?? true;

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

    _notifDeleteWithoutSendingInstall =
        _prefs?.getBool('notifDeleteWithoutSendingInstall') ?? false;
    _notifDeleteWithoutSendingEnable =
        _prefs?.getBool('notifDeleteWithoutSendingEnable') ?? false;
    _notifDeleteWithoutSendingDisable =
        _prefs?.getBool('notifDeleteWithoutSendingDisable') ?? false;
    _notifDeleteWithoutSendingDelete =
        _prefs?.getBool('notifDeleteWithoutSendingDelete') ?? false;
    _sizeUnit =
        _prefs?.getString('sizeUnit') ?? "settings_item_unit_adaptive_si";
    _mss = _prefs?.getInt('mss') ?? 233;
    _developerModeEnabled = _prefs?.getBool('developerModeEnabled') ?? false;
    _decodeAsn1 = _prefs?.getBool('decodeAsn1') ?? false;
    _enableApduLogging = _prefs?.getBool('enableApduLogging') ?? false;
    _lastSelectedReader = _prefs?.getString('lastSelectedReader');
    _remoCardPassword = _prefs?.getString('remoCardPassword');
    _forceDeviceDropdown = _prefs?.getBool('forceDeviceDropdown') ?? false;
    _enableNekokoStats = _prefs?.getBool('enableNekokoStats') ?? true;
    _estimateProfileSize = _prefs?.getBool('estimateProfileSize') ?? true;
    _enableProfileStatusEnhancer =
        _prefs?.getBool('enableProfileStatusEnhancer') ?? true;
    _enableProfileStatusEnhancer =
        _prefs?.getBool('enableProfileStatusEnhancer') ?? true;
    _enableScheduledNotifications =
        _prefs?.getBool('enableScheduledNotifications') ?? true;
    _enableBleConnector = _prefs?.getBool('enableBleConnector') ?? true;
    _enableCcidConnector = _prefs?.getBool('enableCcidConnector') ?? true;
    bool otbridgeHasOmapi = false;
    bool otbridgeHasTmapi = false;

    if (PlatformX.isAndroid) {
      _nbridgeProviderAvailable = await NBridgeService.isAvailable();
      _rootDetected = await NBridgeService.isRooted();

      if (_nbridgeProviderAvailable) {
        try {
          final slots = await NBridgeService.listSlots();
          otbridgeHasOmapi = slots.any(
            (s) => s['id']?.toString().startsWith('omapi:') == true,
          );
          otbridgeHasTmapi = slots.any(
            (s) => s['id']?.toString().startsWith('tmapi:') == true,
          );
        } catch (_) {
          otbridgeHasOmapi = true;
          otbridgeHasTmapi = true;
        }
      }
    }
    _enableOmapiConnector =
        _prefs?.getBool('enableOmapiConnector') ?? !otbridgeHasOmapi;
    _enableTmapiConnector =
        _prefs?.getBool('enableTmapiConnector') ?? !otbridgeHasTmapi;
    _enableRemoteConnector = _prefs?.getBool('enableRemoteConnector') ?? false;
    _enableUpdateCheck = _prefs?.getBool('enableUpdateCheck') ?? true;
    _locale = _prefs?.getString('locale');
    _estkMaxEids = (_prefs?.getStringList('estkMaxEids') ?? []).toSet();
    _aids = _prefs?.getStringList('aids') ?? _aids;

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
    _showHardwareTab = _prefs?.getBool('showHardwareTab') ?? true;
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
    return;
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

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
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

  Future<void> setNotifDeleteWithoutSendingInstall(bool value) async {
    _notifDeleteWithoutSendingInstall = value;
    await _prefs?.setBool('notifDeleteWithoutSendingInstall', value);
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

  Future<void> setNotifDeleteWithoutSendingDelete(bool value) async {
    _notifDeleteWithoutSendingDelete = value;
    await _prefs?.setBool('notifDeleteWithoutSendingDelete', value);
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

  Future<void> setRedactEidFirst(bool value) async {
    _redactEidFirst = value;
    await _prefs?.setBool('redactEidFirst', value);
    notifyListeners();
  }

  Future<void> setRedactEidMiddle(bool value) async {
    _redactEidMiddle = value;
    await _prefs?.setBool('redactEidMiddle', value);
    notifyListeners();
  }

  Future<void> setRedactEidLast(bool value) async {
    _redactEidLast = value;
    await _prefs?.setBool('redactEidLast', value);
    notifyListeners();
  }

  Future<void> setRedactIccidFirst(bool value) async {
    _redactIccidFirst = value;
    await _prefs?.setBool('redactIccidFirst', value);
    notifyListeners();
  }

  Future<void> setRedactIccidMiddle(bool value) async {
    _redactIccidMiddle = value;
    await _prefs?.setBool('redactIccidMiddle', value);
    notifyListeners();
  }

  Future<void> setRedactIccidLast(bool value) async {
    _redactIccidLast = value;
    await _prefs?.setBool('redactIccidLast', value);
    notifyListeners();
  }

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
      _redactEidFirst &&
      _redactEidMiddle &&
      _redactEidLast &&
      _redactIccidFirst &&
      _redactIccidMiddle &&
      _redactIccidLast &&
      _nicknameRedactionMode == NicknameRedactionMode.none &&
      _operatorRedactionMode == OperatorRedactionMode.none &&
      _tagsRedactionMode == TagsRedactionMode.none &&
      _iconRedactionMode == IconRedactionMode.none &&
      _flagRedactionMode == FlagRedactionMode.none;

  Future<void> applyQuickRedactionPreset() async {
    _revealSensitiveProfileData = false;
    _redactEidFirst = true;
    _redactEidMiddle = false;
    _redactEidLast = false;
    _redactIccidFirst = true;
    _redactIccidMiddle = false;
    _redactIccidLast = false;
    _nicknameRedactionMode = NicknameRedactionMode.hideNickname;
    _operatorRedactionMode = OperatorRedactionMode.countryName;

    await _prefs?.setBool('redactEidFirst', _redactEidFirst);
    await _prefs?.setBool('redactEidMiddle', _redactEidMiddle);
    await _prefs?.setBool('redactEidLast', _redactEidLast);
    await _prefs?.setBool('redactIccidFirst', _redactIccidFirst);
    await _prefs?.setBool('redactIccidMiddle', _redactIccidMiddle);
    await _prefs?.setBool('redactIccidLast', _redactIccidLast);
    await _prefs?.setInt('nicknameRedactionMode', _nicknameRedactionMode.index);
    await _prefs?.setInt('operatorRedactionMode', _operatorRedactionMode.index);
    notifyListeners();
  }

  Future<void> disableAllRedactions() async {
    _revealSensitiveProfileData = false;
    _redactEidFirst = true;
    _redactEidMiddle = true;
    _redactEidLast = true;
    _redactIccidFirst = true;
    _redactIccidMiddle = true;
    _redactIccidLast = true;
    _nicknameRedactionMode = NicknameRedactionMode.none;
    _operatorRedactionMode = OperatorRedactionMode.none;
    _tagsRedactionMode = TagsRedactionMode.none;
    _iconRedactionMode = IconRedactionMode.none;
    _flagRedactionMode = FlagRedactionMode.none;

    await _prefs?.setBool('redactEidFirst', _redactEidFirst);
    await _prefs?.setBool('redactEidMiddle', _redactEidMiddle);
    await _prefs?.setBool('redactEidLast', _redactEidLast);
    await _prefs?.setBool('redactIccidFirst', _redactIccidFirst);
    await _prefs?.setBool('redactIccidMiddle', _redactIccidMiddle);
    await _prefs?.setBool('redactIccidLast', _redactIccidLast);
    await _prefs?.setInt('nicknameRedactionMode', _nicknameRedactionMode.index);
    await _prefs?.setInt('operatorRedactionMode', _operatorRedactionMode.index);
    await _prefs?.setInt('tagsRedactionMode', _tagsRedactionMode.index);
    await _prefs?.setInt('iconRedactionMode', _iconRedactionMode.index);
    await _prefs?.setInt('flagRedactionMode', _flagRedactionMode.index);
    notifyListeners();
  }

  void setRevealSensitiveProfileData(bool value) {
    if (_revealSensitiveProfileData == value) return;
    _revealSensitiveProfileData = value;
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

  String get buyPageUrl {
    const envUrl = String.fromEnvironment('BUY_PAGE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    return 'https://n.lpa.ee/products';
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

  Future<void> setEnableCcidConnector(bool value) async {
    _enableCcidConnector = value;
    await _prefs?.setBool('enableCcidConnector', value);
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

  String? get imeiString {
    final hex = _prefs?.getString('deviceImei');
    return hex;
  }

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
