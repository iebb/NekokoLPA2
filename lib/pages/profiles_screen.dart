import '../adapter/se_hal_adapter.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import '../utils/platform_adapter.dart';
import '../plugins/plugin_base.dart';
import '../plugins/plugin_manager.dart';
import '../plugins/build_plugin_registry.dart';

import '../adapter/euicc_adapter.dart';
import '../adapter/composite_adapter.dart';
import '../adapter/remote/remocard_adapter.dart';
import '../adapter/ble/ble_adapter.dart';
import '../adapter/ble/ble_manager.dart';
import '../utils/error_codes.dart';
import '../adapter/nbridge/nbridge_adapter.dart';
import '../adapter/omapi/omapi_adapter.dart';
import '../adapter/omapi/omapi_safety.dart';
import '../adapter/telephony/telephony_adapter.dart';
import '../logic/profile_manager.dart';
import '../logic/profile_state_transition.dart';
import '../utils/apdu_exception.dart';
import '../utils/atr_capabilities.dart';
import '../utils/profile_tag_utils.dart';
import '../utils/profile_redaction.dart';
import '../services/profile_metadata_service.dart';
import '../services/tag_notification_service.dart';
import '../models/activation_code.dart';
import '../theme/app_theme.dart';
import '../settings/app_settings.dart';
import 'notifications_screen.dart';

import '../pages/settings_page.dart';
import '../pages/settings/remote_settings_page.dart';
import 'profile_tag_manager_page.dart';
import '../widgets/profiles_screen/ble_scan_dialog.dart' as ble;
import '../widgets/euicc_info_dialog.dart';
import '../widgets/common/simple_dialog_container.dart';
import '../models/euicc_profile.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

import '../services/database_service.dart';
import '../services/profile_enhancer_service.dart';
import '../services/card_status_cache.dart';
import '../utils/iccid_formatter.dart';
import '../services/operator_icon_service.dart';
import '../services/smds_discovery_service.dart';
import 'package:logging/logging.dart';

import 'download_profile_page.dart';
import 'batch_download_page.dart';
import 'esim_transfer_page.dart';
import 'aram_info_page.dart';
import '../widgets/common/adaptive_context_menu.dart';
import '../widgets/common/loading_spinner.dart';
import '../widgets/profiles_screen/connect_step_message.dart';
import '../widgets/profiles_screen/profile_loading_overlay.dart';
import '../services/update_service.dart';
import '../utils/update_utils.dart';
import '../widgets/profiles_screen/profile_list_section.dart';
import '../widgets/profiles_screen/reader_helper.dart';
import '../widgets/profiles_screen/state_messages.dart' hide ColumnStateMessage;
import '../widgets/profiles_screen/error_state.dart';
import '../widgets/profiles_screen/profiles_header.dart';
import '../services/deep_link_service.dart';
import '../widgets/log_console.dart';
import '../vowifi/vowifi_page.dart';
import '../vowifi/vowifi_service.dart';
import '../vowifi/session_owner.dart';

enum ReaderStatus {
  idle,
  loading,
  ready,
  noCard,
  unsupported,
  araMFailed,
  bleError,
  remoteError,
  error,
}

class ReaderState {
  List<EuiccProfile>? profiles;
  String? eid;
  EUICCInfo2? info2;

  /// ES10a addresses. Null when the card did not answer, which is not an error.
  EuiccConfiguredDataResponse? configuredData;
  Object? lastError;
  ReaderStatus status = ReaderStatus.idle;

  bool isAraMFailed = false;
  String? unsupportedOperatorIcon;
  String? unsupportedFallbackDetails;
  bool loading = false; // still needed for overlay
  bool isConnecting = false;
  bool isListingProfiles = false;
  String? operationLoadingMessage;
  String? togglingIccid;
  bool hasBeenLoaded = false;

  // Helpers to match legacy logic
  bool get isNoCard => status == ReaderStatus.noCard;
  set isNoCard(bool val) {
    if (val) {
      status = ReaderStatus.noCard;
    } else if (status == ReaderStatus.noCard) {
      status = ReaderStatus.ready;
    }
  }

  bool get isUnsupported => status == ReaderStatus.unsupported;
  set isUnsupported(bool val) {
    if (val) {
      status = ReaderStatus.unsupported;
    } else if (status == ReaderStatus.unsupported) {
      status = ReaderStatus.ready;
    }
  }

  bool get isBleConnectionError => status == ReaderStatus.bleError;
  set isBleConnectionError(bool val) {
    if (val) {
      status = ReaderStatus.bleError;
    } else if (status == ReaderStatus.bleError) {
      status = ReaderStatus.ready;
    }
  }

  bool get isRemoteConnectionError => status == ReaderStatus.remoteError;
  set isRemoteConnectionError(bool val) {
    if (val) {
      status = ReaderStatus.remoteError;
    } else if (status == ReaderStatus.remoteError) {
      status = ReaderStatus.ready;
    }
  }

  Object? get error => lastError;
  set error(Object? e) => lastError = e;
}

class _UnsupportedCardProbe {
  const _UnsupportedCardProbe({
    required this.operatorIconBase64,
    required this.details,
  });

  final String? operatorIconBase64;
  final String? details;
}

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  static bool isSwitchingGlobal = false;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static final Logger _log = Logger('ProfilesScreen');
  final CompositeAdapter _adapter = CompositeAdapter();
  late ProfileManager _manager;
  final Map<String, ReaderState> _readerStates = {};
  final Set<String> _omapiEuiccNoticesShown = {};
  bool _showingOmapiEuiccNotice = false;
  List<EuiccProfile>? _profiles;
  List<Reader> _readers = [];
  bool _reloadingHalModes = false;
  final Set<int> _pendingHalSettingSlots = {};
  bool _halConnectorEnabled = AppSettings().enableSeHalConnector;
  List<bool> _halBorrowedModes = [
    for (final slot in [1, 2]) AppSettings().halUseBorrowed(slot),
  ];
  Reader? _selectedReader;
  String? _eid;
  EUICCInfo2? _info2;
  EuiccConfiguredDataResponse? _configuredData;
  ReaderStatus _status = ReaderStatus.idle;
  String? _operationLoadingMessage;
  Object? _error;
  String? _unsupportedOperatorIcon;
  String? _unsupportedFallbackDetails;
  bool _isConnecting = false; // Specific flag for 'Connecting to reader' stage

  // Unified state getters
  bool get _loading => _status == ReaderStatus.loading;
  set _loading(bool val) {
    if (val) {
      _status = ReaderStatus.loading;
    } else if (_status == ReaderStatus.loading) {
      _status = ReaderStatus.ready;
    }
  }

  bool get _isNoCard => _status == ReaderStatus.noCard;
  set _isNoCard(bool val) {
    if (val) {
      _status = ReaderStatus.noCard;
    } else if (_status == ReaderStatus.noCard) {
      _status = ReaderStatus.ready;
    }
  }

  bool get _isUnsupported => _status == ReaderStatus.unsupported;
  set _isUnsupported(bool val) {
    if (val) {
      _status = ReaderStatus.unsupported;
    } else if (_status == ReaderStatus.unsupported) {
      _status = ReaderStatus.ready;
    }
  }

  bool get _isAraMFailed => _status == ReaderStatus.araMFailed;
  set _isAraMFailed(bool val) {
    if (val) {
      _status = ReaderStatus.araMFailed;
    } else if (_status == ReaderStatus.araMFailed) {
      _status = ReaderStatus.ready;
    }
  }

  // Search
  String _searchQuery = "";
  List<EuiccProfile>? _filteredProfiles;

  String? _togglingIccid;
  String? _deletingIccid;
  TabController? _tabController;
  bool _autoDiscoveryFinished = false;
  final Set<String> _autoSwitchTriedReaders = {};
  final GlobalKey _remoteReaderButtonKey = GlobalKey();
  bool _isSwitching = false;
  Timer? _switchingTimer;

  /// Height of the developer log console, adjustable by its drag handle.
  double _consoleHeight = 260;
  int _profileSwitchGeneration = 0;
  Future<void> _profileMetadataPersistence = Future<void>.value();
  final GlobalKey _downloadButtonKey = GlobalKey();
  final GlobalKey _downloadButtonKey2 = GlobalKey();

  final Set<String> _restoredReaders =
      {}; // Track restored devices (BLE & Remote)
  bool _hasLoadedRestoredReaders = false;
  bool _isListingProfiles = false; // Prevent infinite loops

  String? _pendingDeepLinkCode;
  Uri? _pendingSigningUri;
  Timer? _simChangeDebounce;
  StreamSubscription<String>? _deepLinkSub;
  StreamSubscription? _simChangeSub;

  bool _isBle(Reader? reader) {
    return reader?.source is BleAdapter;
  }

  bool _isRemote(Reader? reader) {
    if (reader == null) return false;
    return reader.source is RemoCardAdapter;
  }

  bool _isOmapi(Reader? reader) {
    if (reader == null) return false;
    return reader.source is OmapiAdapter ||
        (reader.source is NBridgeAdapter && reader.id.startsWith('omapi:'));
  }

  bool _isTmapi(Reader? reader) {
    if (reader == null) return false;
    return reader.source is TelephonyAdapter ||
        (reader.source is NBridgeAdapter && reader.id.startsWith('tmapi:'));
  }

  bool _isTelephony(Reader? reader) {
    if (reader == null) return false;
    return reader.source is TelephonyAdapter ||
        (reader.source is NBridgeAdapter && reader.id.startsWith('tmapi:'));
  }

  void _handleOperationError(
    Reader? reader,
    Object e, {
    Future<void> Function()? onRetry,
  }) {
    final errStr = e.toString();

    // A refused card command leaves the session perfectly usable, so it does
    // not warrant replacing the profile list with a full-page error. Report it
    // over the list and let the reader carry on.
    if (errStr.contains('DELETE_FAILED:') ||
        errStr.contains('MEMORY_RESET_FAILED:')) {
      if (reader != null) {
        _updateReaderSession(reader.id, (s) {
          s.loading = false;
          s.operationLoadingMessage = null;
          s.error = null;
        });
      }
      if (mounted) {
        final reason = errStr.substring(errStr.indexOf(':') + 1).trim();
        _showPremiumConfirmDialog(
          title: AppLocalizations.of(context)!.failed,
          message: reason,
          confirmLabel: AppLocalizations.of(context)!.retry,
        ).then((retry) {
          if (retry == true && onRetry != null) onRetry();
        });
      }
      return;
    }

    if (e is ConditionOfUseNotSatisfiedException) {
      _setErrorState(
        reader,
        AppException(
          AppErrorCode.ERROR_CONDITION_OF_USE_NOT_SATISFIED,
          // The card will not hand over the ISD-R and nothing here can change
          // that, so ask for the re-plug rather than suggesting a wait.
          message: AppLocalizations.of(context)!.cardNeedsReplugMessage,
          originalError: e,
        ),
        false,
        false,
      );
      return;
    }

    final bool isBleError =
        (e is AppException &&
        (e.code == AppErrorCode.ERROR_BLUETOOTH_DISABLED ||
            e.code == AppErrorCode.ERROR_BLUETOOTH_TIMEOUT));
    final bool isRemoteConnectionError =
        e is RemoCardConnectionException ||
        (e is AppException &&
            e.code == AppErrorCode.ERROR_REMOTE_CONNECTION_FAILED);
    final bool isRemoteTransportError =
        e is RemoCardException && !isRemoteConnectionError;

    if (e is AppException) {
      // Special handling for ERROR_CARD_NOT_PRESENT - use dedicated state
      if (e.code == AppErrorCode.ERROR_CARD_NOT_PRESENT) {
        if (reader != null) {
          _updateReaderSession(reader.id, (s) {
            s.isNoCard = true;
            s.error = null;
            s.loading = false;
            s.operationLoadingMessage = null;
          });
        }
        return;
      }
      if (e.code == AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD) {
        // NBLESimAdapter handles its own password loop now.
        // It prompts and retries, throwing only if user cancels.
        if (reader != null) {
          _updateReaderSession(reader.id, (s) {
            s.loading = false;
            s.operationLoadingMessage = null;
          });
        }
        return;
      }

      if (e.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED) {
        if (mounted) {
          _showPremiumConfirmDialog(
            title: AppLocalizations.of(context)!.bleDisconnectedTitle,
            message: AppLocalizations.of(context)!.bleDisconnectedMessage,
            confirmLabel: AppLocalizations.of(context)!.retry,
          ).then((retry) {
            if (retry == true && onRetry != null) {
              if (reader != null) {
                _updateReaderSession(reader.id, (s) {
                  s.loading = true;
                  s.error = null;
                });
              }
              onRetry();
            } else {
              _setErrorState(reader, e, true, false);
            }
          });
        }
        return;
      }

      final isBle = e.code.name.startsWith("ERROR_BLUETOOTH");
      final isRemote = e.code.name.startsWith("ERROR_REMOTE");

      // Pass the error object directly to be handled by ErrorState widget
      _setErrorState(reader, e, isBle, isRemote);
      return;
    }

    if (e is AppException &&
        (e.code == AppErrorCode.ERROR_TRANSACTION_FAILED ||
            e.message != null)) {
      final reason = e.message ?? "Unknown";
      _showPremiumConfirmDialog(
        title: AppLocalizations.of(context)!.failed,
        message: "Operation failed: $reason",
        details: e.toString(),
        confirmLabel: AppLocalizations.of(context)!.ok,
        showCancel: false,
      );
      if (reader != null) {
        _updateReaderSession(reader.id, (s) {
          s.loading = false;
          s.error = null; // Handled by dialog
        });
      }
      return;
    }

    if (isRemoteTransportError && onRetry != null && mounted) {
      _log.severe("Remote Transport Error: $e");
      _showPremiumConfirmDialog(
        title: AppLocalizations.of(context)!.transportFailed,
        message: AppLocalizations.of(context)!.remoteTransportFailedMessage,
        details: errStr,
        confirmLabel: AppLocalizations.of(context)!.retry,
      ).then((retry) {
        if (retry == true) {
          if (reader != null) {
            _updateReaderSession(reader.id, (s) {
              s.loading = true;
              s.error = null;
            });
          }
          onRetry();
        } else {
          _setErrorState(reader, e, isBleError, isRemoteConnectionError);
        }
      });
      return;
    }

    _setErrorState(reader, e, isBleError, isRemoteConnectionError);
    _log.severe("Operation failed: $e");
  }

  void _setErrorState(
    Reader? reader,
    Object error,
    bool isBleError,
    bool isRemoteError,
  ) {
    if (reader == null) return;

    ReaderStatus status = ReaderStatus.error;
    if (isBleError) {
      status = ReaderStatus.bleError;
    } else if (isRemoteError) {
      status = ReaderStatus.remoteError;
    }

    _updateReaderSession(reader.id, (s) {
      s.lastError = error;
      s.status = status;
      s.loading = false;
      s.isListingProfiles = false;
      s.operationLoadingMessage = null;
    });
  }

  void _setSwitching(bool value) {
    ProfilesScreen.isSwitchingGlobal = value;
    _switchingTimer?.cancel();
    if (mounted) {
      setState(() => _isSwitching = value);
    }
  }

  void _armProfileSwitchDeadline(int generation) {
    _switchingTimer?.cancel();
    // A profile switch on a card that lives in a handset waits for the modem to
    // reset it, which takes tens of seconds and drops the Bluetooth link on the
    // way. 45s cut that short and reported a working switch as a timeout.
    _switchingTimer = Timer(const Duration(seconds: 150), () {
      if (generation != _profileSwitchGeneration) return;
      _log.warning(
        'Profile switch exceeded its deadline; interrupting pending transport.',
      );
      _profileSwitchGeneration++;
      _adapter.interruptPendingOperation();
    });
  }

  void _onBleManagerChanged() {
    if (mounted && !_loading && !_isListingProfiles && !_isConnecting) {
      _loadReaders(skipLoading: true);
    }
  }

  bool get _voWifiOwnsReader =>
      VoWifiSessionOwner.instance.activeService != null;

  bool _rejectVoWifiConflict() {
    if (!_voWifiOwnsReader) return false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.voWifiReaderInUse),
        ),
      );
    }
    return true;
  }

  bool _voWifiWasActive = false;
  void _onVoWifiChanged() {
    final active = _voWifiOwnsReader;
    final released = _voWifiWasActive && !active;
    _voWifiWasActive = active;
    if (!mounted) return;
    setState(() {});
    if (released) {
      // Resume deferred eSIM notifications outside the SIM reservation zone.
      Zone.root.run(() {
        unawaited(
          _loadPendingNotificationCount().catchError((Object error) {
            _log.warning('Post-Wi-Fi-calling notification refresh failed');
          }),
        );
      });
    }
  }

  void _openVoWifi() {
    final active = VoWifiSessionOwner.instance.activeService;
    final reader = active?.reader ?? _selectedReader;
    if (!PlatformX.isIOS || reader == null || !VoWifiService.supports(reader)) {
      return;
    }
    String? iccid;
    for (final profile in _profiles ?? <EuiccProfile>[]) {
      if (profile.enabled) {
        iccid = profile.iccid;
        break;
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VoWifiPage(
          adapter: active?.adapter ?? _adapter,
          reader: reader,
          profileIccid: iccid,
          service: active,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _voWifiWasActive = _voWifiOwnsReader;
    VoWifiSessionOwner.instance.addListener(_onVoWifiChanged);
    WidgetsBinding.instance.addObserver(this);
    _manager = ProfileManager(_adapter);
    for (var plugin in BuildPluginRegistry.createSessionPlugins()) {
      _manager.addSessionPlugin(plugin);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReaders();
        _checkForUpdates();
        LocalNotificationService().checkPermission();
        ProfileRedaction.warmupOperatorPlaceholders();
      }
    });

    AppSettings().addListener(_onSettingsChanged);
    BleManager().addListener(_onBleManagerChanged);
    NotificationService().isProcessing.addListener(_onProcessingChanged);

    // _adapter.addListener(_onAdapterEvent);

    // Listen to pendingLpa changes
    DeepLinkService().pendingLpa.addListener(_onPendingLpaChanged);
    DeepLinkService().pendingSigningUri.addListener(
      _onPendingSigningUriChanged,
    );
    DeepLinkService().triggerSelection.addListener(_onTriggerSelectionChanged);

    _deepLinkSub = DeepLinkService().linkStream.listen((code) {
      _log.info("Deep link received via stream in ProfilesScreen: $code");
      if (mounted) {
        setState(() {
          _pendingDeepLinkCode = code;
        });
        // Optionally show a snackbar or scroll to the banner
      }
    });

    // Listen to SIM change events with debouncing
    _simChangeSub = _adapter.simChangeEventStream.listen((event) {
      if (mounted) {
        final state = event['state'] as String?;
        _log.info(
          'SIM change event detected in UI (state: $state), debouncing reset',
        );
        _simChangeDebounce?.cancel();
        final delay = _isSwitching || ProfilesScreen.isSwitchingGlobal
            ? const Duration(seconds: 2)
            : const Duration(milliseconds: 300);
        _simChangeDebounce = Timer(delay, () {
          if (!mounted) return;
          if (_isSwitching || ProfilesScreen.isSwitchingGlobal) {
            _log.info(
              'Ignoring transient SIM reset while profile switch recovery is active',
            );
            return;
          }
          _log.info('Executing debounced SIM reset');
          setState(() {
            if (state == 'ABSENT') {
              _log.info('SIM ABSENT detected, clearing all reader states');
              _readerStates.clear();
            }
          });
          _loadReaders(skipLoading: true, force: true);
        });
      }
    });

    // Check initial values
    _onPendingLpaChanged();
    _onPendingSigningUriChanged();
  }

  @override
  void dispose() {
    VoWifiSessionOwner.instance.removeListener(_onVoWifiChanged);
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    DeepLinkService().pendingLpa.removeListener(_onPendingLpaChanged);
    DeepLinkService().pendingSigningUri.removeListener(
      _onPendingSigningUriChanged,
    );
    DeepLinkService().triggerSelection.removeListener(
      _onTriggerSelectionChanged,
    );
    _tabController?.dispose();
    _profileSwitchGeneration++;
    if (_isSwitching) _adapter.interruptPendingOperation();
    _switchingTimer?.cancel();
    ProfilesScreen.isSwitchingGlobal = false;
    _simChangeDebounce?.cancel();
    _simChangeSub?.cancel();
    BleManager().removeListener(_onBleManagerChanged);
    AppSettings().removeListener(_onSettingsChanged);
    NotificationService().isProcessing.removeListener(_onProcessingChanged);
    super.dispose();
  }

  final ValueNotifier<Map<String, String>> _readerEids = ValueNotifier({});

  bool _lastIsProcessing = false;
  void _onProcessingChanged() {
    if (!mounted) return;
    final v = NotificationService().isProcessing.value;
    if (v == _lastIsProcessing) return;
    _lastIsProcessing = v;
    setState(() {});
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    setState(() {
      _filteredProfiles = null;
    });
    final modes = [
      for (final slot in [1, 2]) AppSettings().halUseBorrowed(slot),
    ];
    final enabled = AppSettings().enableSeHalConnector;
    for (final slot in [1, 2]) {
      if (enabled != _halConnectorEnabled ||
          modes[slot - 1] != _halBorrowedModes[slot - 1]) {
        _pendingHalSettingSlots.add(slot);
      }
    }
    _halBorrowedModes = modes;
    _halConnectorEnabled = enabled;
    if (_reloadingHalModes || _pendingHalSettingSlots.isEmpty) return;
    final changedSlots = _pendingHalSettingSlots.toList();
    _pendingHalSettingSlots.clear();
    _reloadingHalModes = true;
    unawaited(() async {
      try {
        await _adapter.runExclusive(() async {
          final connected = _adapter.connectedReader;
          if (connected != null &&
              connected.source is SeHalAdapter &&
              changedSlots.contains(SeHalAdapter.slotFor(connected))) {
            await _adapter.disconnect();
          }
          for (final slot in changedSlots) {
            final id = 'hal:SIM$slot';
            _readerStates.remove(id);
            _readerStates.remove('$id:owned');
          }
          final selected = _selectedReader;
          if (mounted &&
              selected != null &&
              selected.source is SeHalAdapter &&
              changedSlots.contains(SeHalAdapter.slotFor(selected))) {
            setState(() {
              _selectedReader = null;
              _profiles = null;
              _eid = null;
              _info2 = null;
              _error = null;
            });
          }
          if (mounted) await _loadReaders(skipLoading: true, force: true);
        });
      } catch (e) {
        _log.warning('Failed to reload SE HAL ownership settings: $e');
      } finally {
        _reloadingHalModes = false;
        _onSettingsChanged();
      }
    }());
  }

  void _onPendingLpaChanged() {
    if (mounted) {
      final newValue = DeepLinkService().pendingLpa.value;
      _log.info(
        "ProfilesScreen: _onPendingLpaChanged fired. New value: $newValue",
      );
      setState(() {
        _pendingDeepLinkCode = newValue;
      });
    }
  }

  void _onPendingSigningUriChanged() {
    if (mounted) {
      final newValue = DeepLinkService().pendingSigningUri.value;
      _log.info(
        "ProfilesScreen: _onPendingSigningUriChanged fired. New value: $newValue",
      );
      setState(() {
        _pendingSigningUri = newValue;
      });
    }
  }

  void _onTriggerSelectionChanged() {
    if (DeepLinkService().triggerSelection.value && mounted) {
      _log.info("ProfilesScreen: _onTriggerSelectionChanged fired.");
      DeepLinkService().triggerSelection.value = false;
      _handleDeepLinkDownload();
    }
  }

  Future<void> _fetchEidForReaderSilently(Reader reader) async {
    if (_voWifiOwnsReader) return;
    try {
      await _adapter.runExclusive(() async {
        // Connect specifically for fetching EID
        await _adapter.connect(reader);
        final channel = await _manager.openSession();
        try {
          final eid = await _manager.getEid(useChannel: channel);
          _adapter.currentEid = eid;
          if (mounted) {
            final newMap = Map<String, String>.from(_readerEids.value);
            newMap[reader.id] = eid;
            _readerEids.value = newMap;

            // Also update state if already initialized
            if (_readerStates.containsKey(reader.id)) {
              _readerStates[reader.id]!.eid = eid;
            }
          }
        } finally {
          await channel.close();
        }
      });
    } catch (e) {
      _log.warning("Silent EID fetch failed for ${reader.name}: $e");

      // Handle NO_CARD error specifically
      if (e is AppException && e.code == AppErrorCode.ERROR_CARD_NOT_PRESENT) {
        if (mounted) {
          setState(() {
            final state = _readerStates[reader.id];
            if (state != null) {
              state.isNoCard = true;
              state.error = null;
            }
            if (_selectedReader?.id == reader.id) {
              _isNoCard = true;
            }
          });
        }
      }
    }
  }

  Future<Reader?> _showReaderPickerDialog() async {
    if (_readers.isEmpty) {
      // If no readers, refresh
      await _loadReaders();
    }

    if (!mounted || _readers.isEmpty) return null;

    // If only one reader, just return it
    if (_readers.length == 1) return _readers.first;

    // Start background fetching EIDs
    for (var r in _readers) {
      if (!_readerEids.value.containsKey(r.id)) {
        _fetchEidForReaderSilently(r);
      }
    }

    return showDialog<Reader>(
      context: context,
      builder: (context) => ValueListenableBuilder<Map<String, String>>(
        valueListenable: _readerEids,
        builder: (context, eids, _) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.selectDevice),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _readers.length,
                itemBuilder: (context, index) {
                  final reader = _readers[index];
                  final eid = eids[reader.id];

                  return ListTile(
                    leading: Icon(
                      ReaderHelper.getIconData(reader.id),
                      color: ReaderHelper.getIconColor(
                        reader.id,
                        context,
                        overrideColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(reader.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reader.id, style: const TextStyle(fontSize: 10)),
                        if (eid != null)
                          Text(
                            "EID: $eid",
                            style: AppTheme.mono(
                              const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            "EID: Retrieving...",
                            style: const TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, reader),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    if (!AppSettings().enableUpdateCheck) return;
    // Only check if not already checking
    final update = await UpdateService().checkForUpdates();
    if (update != null && mounted) {
      showUpdateDialog(context, update);
    }
  }

  /// Refreshes the badge from the database alone, without touching the card.
  Future<void> _refreshPendingCountFromDb() async {
    final eid = _eid;
    if (eid == null) return;

    if (NotificationService().currentEid != eid) {
      NotificationService().currentEid = eid;
      NotificationService().currentNotifications.value = const [];
    }
    final unsent = await DatabaseService().getUnsentCount(eid);
    NotificationService().pendingCount.value = unsent;
  }

  Future<void> _loadPendingNotificationCount() async {
    final eid = _eid;
    if (eid == null) return;

    // Update local count from DB first for speed
    await _refreshPendingCountFromDb();

    if (_voWifiOwnsReader) return;

    // Trigger background sync if card available
    if (_selectedReader != null) {
      if (mounted) {
        NotificationService()
            .processPendingNotifications(
              _manager,
              null, // No channel
              readerName: _selectedReader!.id,
              eid: eid,
              autoSendInstall: false,
              autoRemoveInstall: false,
              autoSendEnable: false,
              autoRemoveEnable: false,
              deleteWithoutSendingEnable: false,
              autoSendDisable: false,
              autoRemoveDisable: false,
              deleteWithoutSendingDisable: false,
              autoSendDelete: false,
              autoRemoveDelete: false,
            )
            .catchError((e) {
              _log.warning("Background notification check failed: $e");
            });
      }
    }
  }

  final Map<String, GlobalKey> _keyMap = {};

  GlobalKey _getCardKey(String iccid) {
    final readerId = _selectedReader?.id ?? 'none';
    final key = '$readerId:$iccid';
    if (!_keyMap.containsKey(key)) {
      _keyMap[key] = GlobalKey();
    }
    return _keyMap[key]!;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      unawaited(
        _adapter.setAppInBackground(true).catchError((Object error) {
          _log.warning(
            'Unable to close released OMAPI channels on background: $error',
          );
        }),
      );
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_adapter.setAppInBackground(false));
      _log.info("App resumed, refreshing readers and checking for deep links");
      // Reload readers when app returns to foreground (e.g. after USB permission dialog)
      _loadReaders(skipLoading: true);
      // Manually check for a deep link in case the OS event was delivered during pause
      DeepLinkService().checkInitialLink();
    }
  }

  void _updateReaderState(
    Reader reader, {
    List<EuiccProfile>? profiles,
    String? eid,
    String? aid,
    bool? isEstkMax,
    EUICCInfo2? info2,
    Object? error,
    bool? isNoCard,
    bool? isUnsupported,
    bool? isAraMFailed,
    bool clearError = false,
  }) {
    _log.info(
      "Updating reader state for ${reader.id}: eid=$eid, aid=$aid, isEstkMax=$isEstkMax",
    );
    final state = _readerStates.putIfAbsent(reader.id, () => ReaderState());
    if (profiles != null) state.profiles = profiles;

    // Update the Reader object itself if new info available
    if (eid != null || aid != null || isEstkMax != null) {
      if (eid != null) reader.eid = eid;
      if (aid != null) reader.aid = aid;
      if (isEstkMax != null) reader.isEstkMax = isEstkMax;
      final updatedReader = reader;

      // Update in _readers list
      final idx = _readers.indexWhere((r) => r.id == reader.id);
      if (idx != -1) {
        _readers[idx] = updatedReader;
      }
      if (_selectedReader?.id == reader.id) {
        _selectedReader = updatedReader;
        if (eid != null) _eid = eid;
      }

      if (eid != null) {
        state.eid = eid;
        if (!_readerEids.value.containsKey(reader.id) ||
            _readerEids.value[reader.id] != eid) {
          final newMap = Map<String, String>.from(_readerEids.value);
          newMap[reader.id] = eid;
          _readerEids.value = newMap;
        }
      }
    }

    if (info2 != null) state.info2 = info2;

    if (clearError) {
      state.lastError = null;
      state.status = ReaderStatus.ready;
      state.isAraMFailed = false;
      state.unsupportedOperatorIcon = null;
      state.unsupportedFallbackDetails = null;
    } else if (error != null) {
      state.lastError = error;
      state.status = ReaderStatus.error;
    }

    if (isNoCard == true) state.status = ReaderStatus.noCard;
    if (isUnsupported == true) state.status = ReaderStatus.unsupported;
    if (isAraMFailed != null) {
      state.isAraMFailed = isAraMFailed;
      if (isAraMFailed) state.status = ReaderStatus.araMFailed;
    }

    if (reader.id == _selectedReader?.id && mounted) {
      setState(() {
        _profiles = state.profiles;
        _filteredProfiles =
            null; // Fix: Clear search/filter cache on data update
        _eid = state.eid;
        _info2 = state.info2;
        _configuredData = state.configuredData;
        _error = state.lastError;
        _status = state.status;
        _unsupportedOperatorIcon = state.unsupportedOperatorIcon;
        _unsupportedFallbackDetails = state.unsupportedFallbackDetails;
      });
    }
  }

  Future<_UnsupportedCardProbe?> _probeUnsupportedCardDetails(
    Reader reader,
  ) async {
    if (_isOmapi(reader) || _isTmapi(reader)) {
      return null;
    }
    try {
      // A plugin reads the SIM's own files; with none that can, an unsupported
      // card shows no operator details.
      final info = await PluginManager().probeSim(_adapter, reader);
      if (info == null) return null;
      final imsi = info.imsi.trim();
      final mncLength = info.mncLength == 3 ? 3 : 2;
      String? mcc;
      String? mnc;
      if (imsi.length >= 3 + mncLength) {
        mcc = imsi.substring(0, 3);
        mnc = imsi.substring(3, 3 + mncLength);
      }

      String? operatorIconBase64;
      if (mcc != null && mnc != null) {
        await OperatorIconService().fetchMissingIcons([
          <String, dynamic>{
            'mcc': mcc,
            'mnc': mnc,
            'gid1': info.gid1.isEmpty ? null : info.gid1,
            'gid2': info.gid2.isEmpty ? null : info.gid2,
            'profileName': info.iccid.isNotEmpty ? info.iccid : reader.name,
          },
        ]);
        await Future.delayed(const Duration(milliseconds: 800));
        operatorIconBase64 = await OperatorIconService().getIcon(
          mcc: mcc,
          mnc: mnc,
          gid1: info.gid1.isEmpty ? null : info.gid1,
          gid2: info.gid2.isEmpty ? null : info.gid2,
        );
      }

      final details = <String>[
        if (info.iccid.isNotEmpty) 'ICCID: ${info.iccid}',
        if (info.imsi.isNotEmpty) 'IMSI: ${info.imsi}',
        if (mcc != null && mnc != null) 'PLMN: $mcc-$mnc',
        if (info.gid1.isNotEmpty) 'GID1: ${info.gid1}',
        if (info.gid2.isNotEmpty) 'GID2: ${info.gid2}',
      ].join('\n');

      if (details.isEmpty && operatorIconBase64 == null) {
        return null;
      }
      return _UnsupportedCardProbe(
        operatorIconBase64: operatorIconBase64,
        details: details.isEmpty ? null : details,
      );
    } catch (error) {
      _log.info('Unsupported-card SIM probe failed for ${reader.name}: $error');
      return null;
    }
  }

  Future<void> _loadReaders({
    bool skipLoading = false,
    bool force = false,
  }) async {
    if (_voWifiOwnsReader) return;
    if (!skipLoading && mounted) {
      setState(() {
        _loading = true;
        _operationLoadingMessage = AppLocalizations.of(
          context,
        )!.scanningForReaders;
      });
    }
    try {
      final readers = (await _adapter.listReaders(force: force))
          .where(
            (r) =>
                r.source is! SeHalAdapter || AppSettings().enableSeHalConnector,
          )
          .map((r) {
            // The borrow setting may have changed while other readers were
            // listed, so HAL readers are rebuilt from the current one.
            if (r.source is SeHalAdapter) {
              final current = (r.source as SeHalAdapter).readerForSlot(
                SeHalAdapter.slotFor(r),
              );
              if (r.id != current.id) r = current;
            }
            final existingIdx = _readers.indexWhere((old) => old.id == r.id);
            if (existingIdx != -1) {
              final existing = _readers[existingIdx];
              existing.name = r.name;
              existing.source = r.source;
              existing.context = r.context;
              return existing;
            }

            final persistedEid = AppSettings().getPersistedEid(r.id);
            if (persistedEid != null) {
              r.eid = persistedEid;
              // Background check for capabilities if we don't have them yet
              if (!r.isEstkMax) {
                Future.wait(
                  BuildPluginRegistry.createSessionPlugins().map(
                    (p) => p.probeReaderCapabilities(persistedEid, null),
                  ),
                ).then((results) {
                  if (mounted) {
                    bool changed = false;
                    for (var result in results) {
                      if (result != null &&
                          result['isEstkMax'] == true &&
                          !r.isEstkMax) {
                        r.isEstkMax = true;
                        changed = true;
                      }
                    }
                    if (changed) {
                      setState(() {
                        // If this was the selected reader, update state too
                        if (_selectedReader?.id == r.id) {
                          _selectReader(r);
                        }
                      });
                    }
                  }
                });
              }
            }
            return r;
          })
          .toList();

      _log.info(
        "Loaded ${readers.length} readers. Current: ${_readers.length}",
      );
      if (!force && listEquals(_readers, readers)) {
        _log.info("Reader lists are equal, returning.");
        return;
      }
      _log.info("Reader list changed or force=true, updating state.");

      // Preserve states, but clear auto-switch flags
      _autoSwitchTriedReaders.clear();
      _autoDiscoveryFinished = false;

      if (mounted) {
        bool shouldAutoLoad = false;
        setState(() {
          _readers = readers;

          if (readers.isNotEmpty) {
            final lastSelectedId = AppSettings().lastSelectedReader;
            if (!_hasLoadedRestoredReaders) {
              if (lastSelectedId != null) _restoredReaders.add(lastSelectedId);
              _hasLoadedRestoredReaders = true;
            }
            Reader? newSelection;

            if (_selectedReader != null && readers.contains(_selectedReader)) {
              newSelection = _selectedReader;
            } else if (lastSelectedId != null) {
              try {
                newSelection = readers.firstWhere(
                  (r) => r.id == lastSelectedId,
                );
              } catch (_) {
                // Preserve the SIM slot when changing the HAL ownership mode.
                newSelection = readers.firstWhere(
                  (r) =>
                      r.source is SeHalAdapter &&
                      r.id.replaceFirst(':owned', '') ==
                          lastSelectedId.replaceFirst(':owned', ''),
                  orElse: () => readers.first,
                );
              }
            } else {
              newSelection = readers.first;
            }

            final bool selectionChanged =
                _selectedReader?.id != newSelection?.id;
            _selectedReader = newSelection;

            if (selectionChanged) {
              // Clear state or restore from cache
              final state = _readerStates[_selectedReader!.id];
              _profiles = state?.profiles;
              _filteredProfiles =
                  null; // Clear cache on selection change or update
              _eid = state?.eid;
              _info2 = state?.info2;
              _configuredData = state?.configuredData;
              _error = state?.error;
              _isNoCard = state?.isNoCard ?? false;
              _isUnsupported = state?.isUnsupported ?? false;
              _isAraMFailed = state?.isAraMFailed ?? false;
              _unsupportedOperatorIcon = state?.unsupportedOperatorIcon;
              _unsupportedFallbackDetails = state?.unsupportedFallbackDetails;
              if (_status == ReaderStatus.bleError) {
                _status = ReaderStatus.ready; // Reset by default
              }
            }

            if (readers.length != _tabController?.length) {
              _recreateTabController(readers);
            }

            if (_selectedReader != null) {
              AppSettings().setLastSelectedReader(_selectedReader!.id);
            }

            final bool isProfilesEmpty = _profiles?.isEmpty ?? true;
            // Apply restored logic to both BLE and Remote devices
            final bool isSpecialDevice =
                _isBle(_selectedReader) || _isRemote(_selectedReader);
            final bool isRestored =
                isSpecialDevice &&
                _restoredReaders.contains(_selectedReader!.id);

            // If it's a restored special device (BLE/Remote) and we haven't loaded profiles:
            // Force the "Not Connected" / specific error screen to wait for user action.
            if (isRestored && isProfilesEmpty) {
              if (_isBle(_selectedReader)) {
                _status = ReaderStatus.bleError;
              } else {
                _status = ReaderStatus.remoteError;
              }
              _error = null;
            } else if (AppSettings().autoLoadProfiles &&
                (isProfilesEmpty &&
                    !(_readerStates[_selectedReader!.id]?.hasBeenLoaded ??
                        false)) &&
                _error == null &&
                !_isNoCard &&
                !_isListingProfiles) {
              shouldAutoLoad = true;
            }
          } else {
            _selectedReader = null;
            _profiles = null;
            _eid = null;
            _info2 = null;
            _configuredData = null;
            _error = null;
            _isNoCard = false;
            _isUnsupported = false;
            _isAraMFailed = false;
            _unsupportedOperatorIcon = null;
            _unsupportedFallbackDetails = null;
          }
        });
        if (shouldAutoLoad) {
          await _listProfiles();
        }
      }
    } catch (e) {
      _log.severe("Failed to load readers: $e");
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted && !skipLoading) {
        setState(() {
          _loading = false;
          _operationLoadingMessage = null;
        });
      }
    }
  }

  Future<void> _switchEstkSlot() async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;

    final currentAid = (_manager.getWorkingAid(reader.id) ?? "").toUpperCase();
    final aid1 = "A06573746B6D65FFFF4953442D522031";
    final aid0 = "A06573746B6D65FFFF4953442D522030";

    String targetAid;
    if (currentAid == aid1) {
      targetAid = aid0;
    } else {
      targetAid = aid1;
    }

    setState(() {
      _loading = true;
      _operationLoadingMessage = AppLocalizations.of(context)!.switchedEstkSlot;
    });

    try {
      _manager.setWorkingAid(reader.id, targetAid);
      // Wait a bit or directly reload
      await Future.delayed(const Duration(milliseconds: 300));
      await _listProfiles();

      final activeAid = _adapter.connectedReader?.aid?.toUpperCase();
      final atr = _adapter.lastAtr;
      if (activeAid == targetAid && atr != null && atr.isNotEmpty) {
        await AppSettings().setPreferredEstkAid(reader.id, atr, targetAid);
        _log.info("Persisted eSTKme slot for ${reader.id}: $targetAid");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.switchedEstkSlot),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = "${AppLocalizations.of(context)!.switchFailed}: $e",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _operationLoadingMessage = null;
        });
      }
    }
  }

  void _recreateTabController(List<Reader> readers) {
    _tabController?.dispose();
    _tabController = TabController(length: readers.length, vsync: this);
    if (_selectedReader != null) {
      final idx = readers.indexOf(_selectedReader!);
      if (idx != -1) _tabController!.index = idx;
    }
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        final newReader = _readers[_tabController!.index];
        if (newReader != _selectedReader) {
          _selectReader(newReader);
        }
      }
    });
  }

  Future<void> _selectReader(Reader reader) async {
    if (_rejectVoWifiConflict()) return;
    _restoredReaders.remove(reader.id);
    if (_selectedReader?.id == reader.id) {
      // Picking the reader that is already selected is how a user retries one
      // that is showing as disconnected, so treat it as a connect request
      // rather than as a no-op.
      final state = _readerStates[reader.id];
      final needsConnect =
          (state?.profiles?.isEmpty ?? true) ||
          state?.lastError != null ||
          state?.status == ReaderStatus.bleError;
      if (needsConnect && !_loading && !_isConnecting) {
        _log.info(
          'Reader ${reader.id} reselected while not ready; connecting.',
        );
        await _listProfiles();
      }
      return;
    }

    if (!_readers.contains(reader)) {
      await _loadReaders(skipLoading: true);
      if (mounted && _readers.contains(reader)) {
        await _selectReader(reader);
      }
      return;
    }

    final state = _readerStates.putIfAbsent(reader.id, () => ReaderState());

    setState(() {
      _selectedReader = reader;
      _error = state.error;
      _profiles = state.profiles;
      _filteredProfiles = null; // Clear cache when switching reader
      _eid = state.eid;
      _info2 = state.info2;
      _configuredData = state.configuredData;
      _isNoCard = state.isNoCard;
      _isUnsupported = state.isUnsupported;
      _isAraMFailed = state.isAraMFailed;
      _loading = state.loading;
      _isConnecting = state.isConnecting;
      _isListingProfiles = state.isListingProfiles;
      if (state.status == ReaderStatus.bleError) {
        _status = ReaderStatus.bleError;
      }
      if (state.status == ReaderStatus.remoteError) {
        _status = ReaderStatus.remoteError;
      }
      _operationLoadingMessage = state.operationLoadingMessage;
    });

    AppSettings().setLastSelectedReader(reader.id);

    if (_tabController != null) {
      final idx = _readers.indexOf(reader);
      if (idx != -1 &&
          idx < _tabController!.length &&
          _tabController!.index != idx) {
        _tabController!.animateTo(idx);
      }
    }

    if (AppSettings().autoLoadProfiles &&
        (_profiles?.isEmpty ?? true) &&
        _error == null &&
        !_isNoCard) {
      await _listProfiles();
    } else {
      // Connect on an explicit selection, Bluetooth included. Skipping BLE here
      // left a deliberately chosen card sitting at "Bluetooth Not Connected"
      // until something else happened to connect it.
      {
        _adapter.connect(reader).catchError((e) {
          _log.warning("Silent connect failed: $e");

          // Handle NO_CARD error specifically
          if (e is AppException &&
              e.code == AppErrorCode.ERROR_CARD_NOT_PRESENT) {
            if (mounted) {
              setState(() {
                final state = _readerStates[reader.id];
                if (state != null) {
                  state.isNoCard = true;
                  state.error = null;
                }
                if (_selectedReader?.id == reader.id) {
                  _isNoCard = true;
                }
              });
            }
          }
        });
      }
      if (_eid != null) {
        _loadPendingNotificationCount();
      }
    }
  }

  Future<void> _handleDisconnectAndRemove() async {
    if (_rejectVoWifiConflict()) return;
    if (_selectedReader == null) return;
    final reader = _selectedReader!;

    _log.info("Disconnecting and removing reader: ${reader.id}");

    setState(() {
      _loading = true;
      _operationLoadingMessage = AppLocalizations.of(context)!.disconnecting;
    });

    try {
      await _adapter.disconnect();
      _adapter.removeReader(reader.id);

      // Clear local states
      if (mounted) {
        setState(() {
          _readerStates.remove(reader.id);
          _selectedReader = null;
          _profiles = null;
          _eid = null;
          _info2 = null;
          _error = null;
        });
      }

      // Reload the list
      await _loadReaders(skipLoading: true);
    } catch (e) {
      _log.warning("Disconnect failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _operationLoadingMessage = null;
        });
      }
    }
  }

  Future<void> _refreshDeviceList() async {
    if (_rejectVoWifiConflict()) return;
    _autoDiscoveryFinished = false;
    _autoSwitchTriedReaders.clear();

    setState(() {
      _loading = true;
      _operationLoadingMessage = AppLocalizations.of(
        context,
      )!.scanningForUnresponsiveDevices;
    });

    try {
      await _loadReaders();
      if (_selectedReader?.source is SeHalAdapter) {
        await _listProfiles(disableRetry: true);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              "${AppLocalizations.of(context)!.deviceRefreshFailed}: $e",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _operationLoadingMessage = null;
        });
      }
    }
  }

  void _updateReaderSession(
    String readerId,
    void Function(ReaderState) action,
  ) {
    if (!mounted) return;
    final state = _readerStates.putIfAbsent(readerId, () => ReaderState());
    action(state);

    if (_selectedReader?.id == readerId) {
      setState(() {
        _profiles = state.profiles;
        _filteredProfiles = null; // Clear filter cache when profiles update
        _eid = state.eid;
        _info2 = state.info2;
        _error = state.lastError;
        _status = state.status;
        _unsupportedOperatorIcon = state.unsupportedOperatorIcon;
        _unsupportedFallbackDetails = state.unsupportedFallbackDetails;
        _loading = state.loading;
        _isConnecting = state.isConnecting;
        _isListingProfiles = state.isListingProfiles;
        _operationLoadingMessage = state.operationLoadingMessage;
      });
    }
  }

  Future<void> _hardReconnect() async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;

    // Disconnect explicitly to clear any stuck state
    try {
      _updateReaderSession(
        reader.id,
        (s) => s.operationLoadingMessage = AppLocalizations.of(
          context,
        )!.resettingConnection,
      );
      await _adapter.reconnect();
    } catch (e) {
      _log.warning("Hard reconnect: Disconnect failed (ignoring): $e");
    }
    // Re-list profiles which will force a fresh connect()
    await _listProfiles();
  }

  void _maybeShowOmapiEuiccNotice(Reader reader, String? atr) {
    if (!PlatformX.isAndroid ||
        !reader.id.startsWith('omapi:') ||
        AtrCapabilities.supportsEuicc(atr) != true) {
      return;
    }
    final key = '${reader.id}:$atr';
    if (_omapiEuiccNoticesShown.contains(key)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _selectedReader?.id != reader.id ||
          _showingOmapiEuiccNotice ||
          !TickerMode.valuesOf(context).enabled ||
          _omapiEuiccNoticesShown.contains(key) ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _omapiEuiccNoticesShown.add(key);
      _showingOmapiEuiccNotice = true;
      final l10n = AppLocalizations.of(context)!;
      unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.omapiEuiccDetectedTitle),
            content: Text(l10n.omapiEuiccSystemDisableWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        ).whenComplete(() => _showingOmapiEuiccNotice = false),
      );
    });
  }

  // _handleReaderSelection removed

  Future<void> _listProfiles({
    int retryCount = 0,
    bool disableRetry = false,
  }) async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;
    final l10n = AppLocalizations.of(context)!;

    _updateReaderSession(reader.id, (s) {
      s.status = ReaderStatus.loading;
      s.loading = true;
      s.isListingProfiles = true;
      s.isConnecting = true;
      s.isAraMFailed = false;
      s.operationLoadingMessage = l10n.connectingToReader;
      s.lastError = null;
    });

    String? eid;
    EUICCInfo2? info2;
    String? connectedAtr;

    try {
      _updateReaderSession(reader.id, (s) => s.isConnecting = true);

      await _adapter.runExclusive(() async {
        // A Bluetooth reader can spend tens of seconds connecting, which one
        // static message makes look like a hang, so show each step it reports.
        void showConnectStep() {
          final progress = _adapter.connectProgress.value;
          if (progress == null) return;
          _updateReaderSession(
            reader.id,
            (s) =>
                s.operationLoadingMessage = connectStepMessage(l10n, progress),
          );
        }

        // A retained ISD-R session can be stale after modem REFRESH.
        final reopenHal =
            _adapter.connectedReader?.id == reader.id &&
            reader.source is SeHalAdapter;

        _adapter.connectProgress.addListener(showConnectStep);
        try {
          // Ensure reader is still the selected one or at least the one we started with
          await _adapter.connect(reader);
          connectedAtr = _adapter.lastAtr;
          if (reopenHal) await _adapter.reconnect();
        } finally {
          _adapter.connectProgress.removeListener(showConnectStep);
        }

        _updateReaderSession(
          reader.id,
          (s) => s.operationLoadingMessage = l10n.connectingToEuicc,
        );
        if (mounted && _selectedReader?.id == reader.id) {
          _updateReaderSession(reader.id, (s) => s.isConnecting = false);
        }

        final channel = await _manager.openSession();
        final updatedReader = _adapter.connectedReader;
        if (updatedReader != null) {
          _updateReaderState(updatedReader);
        }
        try {
          // Both fetches show their own step, but only on screen; the session
          // copy is what a mid-fetch session update puts back, so keep it in
          // step or the message jumps back to connecting.
          // 1. Fetch Basic Info
          _updateReaderSession(
            reader.id,
            (s) => s.operationLoadingMessage = l10n.retrievingEid,
          );
          final (fetchedEid, fetchedInfo2) = await _fetchEuiccData(
            channel,
            reader,
            force: true,
          );
          eid = fetchedEid;
          info2 = fetchedInfo2;

          // 2. Fetch Profiles
          _updateReaderSession(
            reader.id,
            (s) => s.operationLoadingMessage = l10n.retrievingProfiles,
          );
          final profiles = await _fetchProfiles(channel, reader);

          // 3. Save the card-reported state without substituting an expected
          // switch result. Profile toggles verify convergence separately.
          await _saveMetadataAndIcons(profiles, eid, info2, reader);
          if (eid != null && profiles.isNotEmpty) {
            unawaited(
              DatabaseService().preloadProfileSizes(
                eid!,
                profiles.map((profile) => profile.iccid),
              ),
            );
          }

          // 4. Update UI: Unfreeze immediately after profiles are ready
          _updateReaderSession(reader.id, (s) {
            s.profiles = profiles;
            s.eid = eid;
            s.info2 = info2;
            s.status = ReaderStatus.ready;
            s.loading = false;
            s.isListingProfiles = false;
            s.operationLoadingMessage = null;
            s.hasBeenLoaded = true;
          });

          // Notify plugins
          if (eid != null) {
            PluginManager().notifyProfilesLoaded(eid!, profiles);
          }
        } finally {
          await channel.close();
        }
      });
      _autoDiscoveryFinished = true;
      _setSwitching(false); // Success! Toggle is done.
      // Start a fresh notification session after releasing the list reservation.
      await _handleNotifications(null, eid, reader);
    } catch (e) {
      if (isOmapiSessionCorruptedError(e)) {
        _setSwitching(false);
        _handleOperationError(reader, e);
        return;
      }

      final bool isConnectivity =
          (e is ProactiveRefreshException) ||
          (e is CardBusyException) ||
          (e is AppException &&
              (e.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED ||
                  e.code == AppErrorCode.ERROR_REMOTE_CONNECTION_FAILED ||
                  e.code == AppErrorCode.ERROR_OMAPI_READER_NOT_AVAILABLE ||
                  e.code == AppErrorCode.ERROR_CHANNEL_OPEN_FAILED ||
                  e.code == AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED ||
                  e.code == AppErrorCode.ERROR_APPLICATION_NOT_FOUND)) ||
          (e is ApduException && e.sw1 == 0x69 && e.sw2 == 0x85);

      final bool isRemoteConnectionFailure =
          (e is RemoCardConnectionException) ||
          (e is AppException &&
              (e.code == AppErrorCode.ERROR_REMOTE_CONNECTION_FAILED ||
                  e.code == AppErrorCode.ERROR_REMOTE_TIMEOUT));

      final bool connectivityError =
          isConnectivity && !isRemoteConnectionFailure;
      final lowerError = e.toString().toLowerCase();
      final bool isNBridgeTransient =
          lowerError.contains('nbridge') &&
          (lowerError.contains('transient') ||
              lowerError.contains('invocationtargetexception'));

      if (e is ConditionOfUseNotSatisfiedException) {
        _log.info("Conditions of use not satisfied, stopping retry loop.");
        _handleOperationError(reader, e, onRetry: () => _listProfiles());
        return;
      }

      final bool canRetry = !disableRetry && connectivityError;
      final int maxRetries = (e is CardBusyException)
          ? 5
          : ((_isSwitching || isNBridgeTransient) ? 12 : 0);
      final bool shouldWaitAndRetry =
          canRetry &&
          (_isSwitching ||
              isNBridgeTransient ||
              (e is CardBusyException && retryCount < maxRetries)) &&
          retryCount < maxRetries;

      if (shouldWaitAndRetry) {
        final retryDelay = (_isSwitching || isNBridgeTransient)
            ? const Duration(milliseconds: 1500)
            : const Duration(seconds: 3);
        _log.info(
          "Connectivity error while switching, retrying in ${retryDelay.inMilliseconds}ms... (attempt ${retryCount + 1}): $e",
        );
        await Future.delayed(retryDelay);
        if (mounted) {
          await _listProfiles(retryCount: retryCount + 1);
        }
        return;
      }

      if (await _handleInvalidPassword(e)) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) await _listProfiles();
        return;
      }

      _handleOperationError(reader, e, onRetry: () => _listProfiles());

      // If it's a NO_CARD error, _handleOperationError already handled it, so return early
      if (e is AppException && e.code == AppErrorCode.ERROR_CARD_NOT_PRESENT) {
        return;
      }

      if (e is PlatformException &&
          (e.code == 'java.lang.NullPointerException' ||
              e.message == 'ArrayList.isEmpty')) {
        _log.warning(
          "Detected OMAPI NPE during list, performing hard reconnect and retry...",
        );
        await _hardReconnect();
        return;
      }

      if (mounted && _selectedReader != null) {
        bool isNoCard = false;
        bool isUnsupported = false;
        bool isAraMFailed = false;

        if (e is AppException) {
          isAraMFailed =
              (e.code == AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED ||
              e.code == AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION);
          isNoCard = (e.code == AppErrorCode.ERROR_CARD_NOT_PRESENT);
          isUnsupported =
              (e.code == AppErrorCode.ERROR_APPLICATION_NOT_FOUND ||
              e.code == AppErrorCode.ERROR_CHANNEL_OPEN_FAILED ||
              e.code == AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED);
        } else if (e is PlatformException) {
          isAraMFailed =
              (e.code == 'SecurityException' ||
              e.code == 'AccessControlException' ||
              e.message == 'no APDU access allowed');
          isNoCard =
              (e.code == 'NO_CARD' ||
              e.message == 'Secure Element is not present');
        } else if (e is ApduException) {
          isUnsupported =
              (e.sw1 == 0x6A && e.sw2 == 0x82) ||
              (e.sw1 == 0x6A && e.sw2 == 0x88);
        }
        if (isAraMFailed) {
          _selectedReader!.name =
              "${_selectedReader!.name.split('|')[0]}|${AppLocalizations.of(context)!.accessDenied}";
        } else if (isNoCard) {
          _selectedReader!.name =
              "${_selectedReader!.name.split('|')[0]}|${AppLocalizations.of(context)!.noCardDetected}";
        } else if (isUnsupported) {
          _selectedReader!.name =
              "${_selectedReader!.name.split('|')[0]}|${AppLocalizations.of(context)!.cardUnsupported}";
        }
        _UnsupportedCardProbe? unsupportedProbe;
        if (isUnsupported) {
          unsupportedProbe = await _probeUnsupportedCardDetails(reader);
        }

        if (((isNoCard || isUnsupported || isAraMFailed) &&
            AppSettings().autoLoadProfiles &&
            _readers.length > 1 &&
            !_autoDiscoveryFinished)) {
          final currentReader = reader;
          _autoSwitchTriedReaders.add(currentReader.id);

          int currentIndex = _readers.indexOf(currentReader);
          Reader? nextReader;

          for (int i = 1; i < _readers.length; i++) {
            int nextIdx = (currentIndex + i) % _readers.length;
            Reader potential = _readers[nextIdx];
            if (!_autoSwitchTriedReaders.contains(potential.id)) {
              nextReader = potential;
              break;
            }
          }

          if (nextReader != null) {
            _log.info(
              "Auto-switching from ${currentReader.name} to ${nextReader.name} due to error.",
            );
            _updateReaderState(
              currentReader,
              isNoCard: isNoCard,
              isUnsupported: isUnsupported,
              isAraMFailed: isAraMFailed,
              error: null,
              profiles: [],
            );
            if (isUnsupported) {
              final currentState = _readerStates[currentReader.id];
              if (currentState != null) {
                currentState.unsupportedOperatorIcon =
                    unsupportedProbe?.operatorIconBase64;
                currentState.unsupportedFallbackDetails =
                    unsupportedProbe?.details;
              }
            }

            _selectReader(nextReader);
            return;
          } else {
            _autoDiscoveryFinished = true;
          }
        } else {
          // We explicitly stopped auto-switching, or it found a device
          if (!isNoCard && !isUnsupported && !isAraMFailed) {
            _autoDiscoveryFinished = true;
          }
        }

        _updateReaderState(
          reader,
          isNoCard: isNoCard,
          isUnsupported: isUnsupported,
          isAraMFailed: isAraMFailed,
          error: (isNoCard || isUnsupported || isAraMFailed) ? null : e,
          profiles: [],
        );
        if (isUnsupported) {
          final state = _readerStates[reader.id];
          if (state != null) {
            state.unsupportedOperatorIcon =
                unsupportedProbe?.operatorIconBase64;
            state.unsupportedFallbackDetails = unsupportedProbe?.details;
          }
          if (reader.id == _selectedReader?.id && mounted) {
            setState(() {
              _unsupportedOperatorIcon = unsupportedProbe?.operatorIconBase64;
              _unsupportedFallbackDetails = unsupportedProbe?.details;
            });
          }
        }
      }
    } finally {
      _updateReaderSession(reader.id, (s) {
        s.loading = false;
        s.isListingProfiles = false;
        s.isConnecting = false;
        s.operationLoadingMessage = null;
      });
      _maybeShowOmapiEuiccNotice(reader, connectedAtr);
    }
  }

  Future<(String?, EUICCInfo2?)> _fetchEuiccData(
    Channel channel,
    Reader reader, {
    bool force = false,
  }) async {
    final session = _readerStates[reader.id];
    if (!force &&
        session != null &&
        session.eid != null &&
        session.info2 != null) {
      _log.info("Using cached EID/Info2 for ${reader.id}, skipping fetch.");
      return (session.eid, session.info2);
    }
    String? eid;
    EUICCInfo2? info2;
    try {
      if (mounted && _selectedReader?.id == reader.id) {
        setState(
          () => _operationLoadingMessage = AppLocalizations.of(
            context,
          )!.retrievingEid,
        );
      }
      eid = await _manager.getEid(useChannel: channel);
      _adapter.currentEid = eid;
      info2 = await _manager.getEuiccInfo2(useChannel: channel);

      // ES10a addresses, for the info dialog. Optional: a card that will not
      // answer must not fail the whole read, which is what the rest of this
      // method exists to do.
      try {
        final configured = await _manager.getEuiccConfiguredData(
          useChannel: channel,
        );
        _updateReaderSession(
          reader.id,
          (session) => session.configuredData = configured,
        );
        if (mounted && _selectedReader?.id == reader.id) {
          _configuredData = configured;
        }
      } catch (e) {
        _log.info('Configured addresses unavailable for ${reader.id}: $e');
      }

      final aid = channel.aid;

      bool pluginDetection = false;
      for (var plugin in BuildPluginRegistry.createSessionPlugins()) {
        final caps = await plugin.probeReaderCapabilities(eid, aid);
        if (caps != null && caps['isEstkMax'] == true) {
          pluginDetection = true;
          break;
        }
      }

      final isEstkMax = pluginDetection || (reader.isEstkMax == true);
      if (isEstkMax) {
        AppSettings().markAsEstkMax(eid);
      }

      _updateReaderState(reader, eid: eid, aid: aid, isEstkMax: isEstkMax);
      AppSettings().savePersistedEid(reader.id, eid);
    } catch (e) {
      _log.warning("Failed to get EID/Info2: $e");
      if (e is ConditionOfUseNotSatisfiedException) {
        rethrow;
      }
    }
    return (eid, info2);
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    double screenWidth,
    bool isExtremelySmall,
  ) {
    final settings = AppSettings();
    final revealIdentifiers =
        settings.revealSensitiveProfileData ||
        settings.hasNoRedactionsConfigured;
    // Unused theme removed

    // Calculate available space for actions
    // Leading takes: logo (48px) + padding (12-20px) + text width (~100-120px on normal, 0 on extremely small)
    final leadingWidth = isExtremelySmall ? 100.0 : 200.0;
    // Reserve space for trailing padding
    final trailingPadding = 8.0;
    // Each IconButton is ~48px wide
    final iconButtonWidth = 48.0;

    final availableWidth = screenWidth - leadingWidth - trailingPadding;
    final maxIconsBeforeFolding = (availableWidth / iconButtonWidth).floor();

    // Define all actions in order (right to left folding priority)
    final allActions = <Map<String, dynamic>>[
      if (PlatformX.isIOS &&
          (_voWifiOwnsReader || VoWifiService.supports(_selectedReader)))
        {
          'icon': Icons.wifi_calling_3,
          'tooltip': AppLocalizations.of(context)!.voWifiWiFiCalling,
          'onPressed': _openVoWifi,
          'key': 'wifi_calling',
        },
      if (_eid != null || _isUnsupported || _isAraMFailed)
        {
          'icon': revealIdentifiers
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          'tooltip': revealIdentifiers
              ? 'Disable redaction'
              : 'Enable redaction',
          'onPressed': _handleIdentifierVisibilityToggle,
          'key': 'toggle_identifier_visibility',
        },
      {
        'icon': Icons.refresh,
        'tooltip': AppLocalizations.of(context)!.refreshDevices,
        'onPressed': _refreshDeviceList,
        'key': 'refresh',
      },
      if (!PlatformX.isLinux && AppSettings().enableBleConnector)
        {
          'icon': Icons.bluetooth_searching,
          'tooltip': AppLocalizations.of(context)!.scanBluetooth,
          'onPressed': () async {
            if (_rejectVoWifiConflict()) return;
            if (kIsWeb) {
              final newReaderId = await BleManager().scanAndAddReaderForWeb();
              if (newReaderId != null && mounted) {
                await _loadReaders(skipLoading: true);
                try {
                  final reader = _readers.firstWhere(
                    (r) => r.id == newReaderId,
                  );
                  _selectReader(reader);
                } catch (_) {}
              }
            } else {
              final newReaderId = await ble.showBluetoothReaderPicker(context);
              if (newReaderId != null && mounted) {
                await _loadReaders(skipLoading: true);
                try {
                  final reader = _readers.firstWhere(
                    (r) => r.id == newReaderId,
                  );
                  _selectReader(reader);
                } catch (_) {}
              }
            }
          },
          'key': 'bluetooth',
        },
      if (AppSettings().enableRemoteConnector)
        {
          'icon': Icons.cloud_outlined,
          'tooltip': AppLocalizations.of(context)!.remoteReaders,
          'onPressed': () => _showRemoteReaderMenu(),
          'key': 'remote',
          'globalKey': _remoteReaderButtonKey,
        },
      {
        'icon': Icons.settings_outlined,
        'tooltip': AppLocalizations.of(context)!.settingsTitle,
        'onPressed': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        ),
        'key': 'settings',
      },
    ];

    // Determine how many to show vs fold
    // Always show at least 1 icon, fold the rest if needed
    // Don't fold if only 1 would be folded (not worth it)
    final numToShow = maxIconsBeforeFolding.clamp(1, allActions.length);
    final numToFold = allActions.length - numToShow;

    // Only create overflow menu if we need to fold 2 or more items
    final shouldFold = numToFold >= 2;

    final List<Widget> actions = [];

    if (shouldFold) {
      // Show first (numToShow - 1) as icons, rest in overflow
      final visibleActions = allActions.take(numToShow - 1).toList();
      final foldedActions = allActions.skip(numToShow - 1).toList();

      // Add visible icons
      for (final action in visibleActions) {
        actions.add(
          IconButton(
            key: action['globalKey'] as GlobalKey?,
            tooltip: action['tooltip'] as String,
            icon: Icon(
              action['icon'] as IconData,
              color: AppTheme.onSurfaceSubtle(context),
            ),
            onPressed: action['onPressed'] as VoidCallback,
          ),
        );
      }

      // Add overflow menu with folded actions
      actions.add(
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.onSurfaceSubtle(context)),
          tooltip: AppLocalizations.of(context)!.moreOptions,
          onSelected: (value) async {
            final action = foldedActions.firstWhere((a) => a['key'] == value);
            (action['onPressed'] as VoidCallback)();
          },
          itemBuilder: (BuildContext context) => foldedActions.map((action) {
            return PopupMenuItem<String>(
              value: action['key'] as String,
              child: ListTile(
                leading: Icon(action['icon'] as IconData),
                title: Text(action['tooltip'] as String),
                contentPadding: EdgeInsets.zero,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Show all icons
      for (final action in allActions) {
        actions.add(
          IconButton(
            key: action['globalKey'] as GlobalKey?,
            tooltip: action['tooltip'] as String,
            icon: Icon(
              action['icon'] as IconData,
              color: AppTheme.onSurfaceSubtle(context),
            ),
            onPressed: action['onPressed'] as VoidCallback,
          ),
        );
      }
    }

    actions.add(const SizedBox(width: 8));
    return actions;
  }

  void _handleIdentifierVisibilityToggle() async {
    final settings = AppSettings();
    if (settings.revealSensitiveProfileData) {
      settings.setRevealSensitiveProfileData(false);
      return;
    }
    if (settings.hasNoRedactionsConfigured) {
      await settings.applyQuickRedactionPreset();
    } else {
      settings.setRevealSensitiveProfileData(true);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<EuiccProfile>> _fetchProfiles(
    Channel channel,
    Reader reader,
  ) async {
    if (mounted && _selectedReader?.id == reader.id) {
      setState(
        () => _operationLoadingMessage = AppLocalizations.of(
          context,
        )!.retrievingProfiles,
      );
    }
    var allProfiles = await _manager.listProfiles(useChannel: channel);

    final existingProfiles = _readerStates[reader.id]?.profiles;
    if (allProfiles.isEmpty &&
        existingProfiles != null &&
        existingProfiles.isNotEmpty) {
      _log.warning(
        "Card returned zero profiles after previously having ${existingProfiles.length}. Possible transient state after refresh, retrying in 1.5s...",
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      allProfiles = await _manager.listProfiles(useChannel: channel);
      if (allProfiles.isNotEmpty) {
        _log.info("Successfully recovered profiles on retry.");
      } else {
        _log.warning("Card still returns zero profiles after retry.");
      }
    }

    // Deduplicate profiles by ICCID to prevent duplicate GlobalKey/ValueKey errors
    final seenIccids = <String>{};
    final profiles = allProfiles.where((p) => seenIccids.add(p.iccid)).toList();

    if (profiles.isEmpty && allProfiles.isNotEmpty) {
      _log.warning(
        "Filtered out all profiles due to duplicate ICCIDs? Original: ${allProfiles.length}",
      );
    }

    if (!reader.id.startsWith('omapi:')) {
      final enabledProfile = profiles.where((p) => p.enabled).firstOrNull;
      if (enabledProfile != null) {
        try {
          final msisdn = await _manager.readActiveMsisdn();
          if (msisdn != null) {
            unawaited(
              DatabaseService().saveMsisdn(enabledProfile.iccid, msisdn),
            );
          }
        } catch (e) {
          _log.warning("Tricky MSISDN query failed: $e");
        }
      }
    }
    return profiles;
  }

  Future<void> _saveMetadataAndIcons(
    List<EuiccProfile> profiles,
    String? eid,
    EUICCInfo2? info2,
    Reader reader, {
    bool showProgress = true,
    bool allowInteractivePrompts = true,
    bool refreshNotificationCount = true,
    bool allowAfterDispose = false,
  }) async {
    if (!mounted && !allowAfterDispose) return;

    // Fire and forget enhancement
    for (final p in profiles) {
      ProfileEnhancerService().enhanceProfile(p.iccid).catchError((e) {
        _log.warning("Enhancer failed for ${p.iccid}: $e");
        return null;
      });
    }

    // Preload card status cache to avoid UI freezing
    final iccids = profiles.map((p) => p.iccid).toList();
    CardStatusCache().preloadCardStatuses(iccids).catchError((e) {
      _log.warning("Failed to preload card statuses: $e");
      return null;
    });

    _updateReaderState(
      reader,
      profiles: profiles,
      eid: eid,
      info2: info2,
      clearError: true,
    );
    if (showProgress && mounted && _selectedReader?.id == reader.id) {
      setState(() {
        _operationLoadingMessage = AppLocalizations.of(
          context,
        )!.savingProfileMetadata;
      });
    }

    final metadataService = await ProfileMetadataService.getInstance();
    final operatorsMap = <String, Map<String, dynamic>>{};

    for (final profile in profiles) {
      final existing = await metadataService.getProfile(profile.iccid);

      // Sync custom icon from DB to in-memory profile
      if (existing?.customIcon != null) {
        profile.customIcon = existing!.customIcon;
      }

      if (existing != null &&
          allowInteractivePrompts &&
          AppSettings().enableScheduledNotifications &&
          mounted) {
        final cardTag = profile.tags
            .map((s) => ProfileTag.parse(s))
            .whereType<DateTag>()
            .firstOrNull;
        final dbTag = existing.tags
            .map((s) => ProfileTag.parse(s))
            .whereType<DateTag>()
            .firstOrNull;

        if (cardTag?.raw != dbTag?.raw) {
          if (cardTag != null) {
            await TagNotificationService().promptAndReschedule(
              context,
              profile.iccid,
              dbTag,
              cardTag,
              profileName: profile.name,
              profileNickname: profile.nickname,
            );
          } else if (dbTag != null) {
            await TagNotificationService().promptAndRemove(
              context,
              profile.iccid,
              dbTag,
              profileName: profile.name,
              profileNickname: profile.nickname,
            );
          }
        }
      }

      await metadataService.saveProfile(
        iccid: profile.iccid,
        nickname: profile.nickname,
        name: profile.name,
        providerName: profile.serviceProviderName,
        mcc: profile.mcc,
        mnc: profile.mnc,
        enabled: profile.enabled,
        profileClass: profile.profileClass,
        gid1: profile.gid1,
        gid2: profile.gid2,
        tags: profile.tags,
        eid: eid,
        customIcon: profile
            .customIcon, // Pass it back to ensure it persists if we overwrite everything
      );

      if (profile.mcc != null && profile.mnc != null) {
        final key =
            '${profile.mcc}-${profile.mnc}-${profile.gid1 ?? ""}-${profile.gid2 ?? ""}';
        operatorsMap[key] = {
          'mcc': profile.mcc!,
          'mnc': profile.mnc!,
          'gid1': profile.gid1,
          'gid2': profile.gid2,
          'profileName': profile.name,
          'serviceProviderName': profile.serviceProviderName,
        };
      }
    }

    if (operatorsMap.isNotEmpty) {
      OperatorIconService().fetchMissingIcons(operatorsMap.values.toList());
    }

    // Update notification count now that we have _eid, but only if still current
    if (refreshNotificationCount &&
        mounted &&
        _selectedReader?.id == reader.id) {
      await _refreshPendingCountFromDb();
    }
  }

  Future<void> _handleNotifications(
    Channel? channel,
    String? eid,
    Reader reader,
  ) async {
    if (_voWifiOwnsReader) return;
    final settings = AppSettings();
    final process =
        settings.notifProcessInitialLoad &&
        settings.isAnyNotificationProcessingEnabled;
    await NotificationService().processPendingNotifications(
      _manager,
      channel,
      readerName: reader.id,
      eid: eid,
      autoSendInstall: process && settings.notifAutoSendInstall,
      autoRemoveInstall: process && settings.notifAutoRemoveInstall,
      autoSendEnable: process && settings.notifAutoSendEnable,
      autoRemoveEnable: process && settings.notifAutoRemoveEnable,
      deleteWithoutSendingEnable:
          process && settings.notifDeleteWithoutSendingEnable,
      autoSendDisable: process && settings.notifAutoSendDisable,
      autoRemoveDisable: process && settings.notifAutoRemoveDisable,
      deleteWithoutSendingDisable:
          process && settings.notifDeleteWithoutSendingDisable,
      autoSendDelete: process && settings.notifAutoSendDelete,
      autoRemoveDelete: process && settings.notifAutoRemoveDelete,
    );
  }

  bool _isProfileSwitchTransientError(Object error) {
    if (error is CardBusyException) return true;
    // Straight after a switch the card is being reset by the host: it refuses
    // the ISD-R with 6985/6999 and raises proactive commands for tens of
    // seconds. Verification has to ride that out -- treating it as fatal
    // reports a switch that actually succeeded as a failure.
    if (error is ConditionOfUseNotSatisfiedException) return true;
    if (error is ProactiveRefreshException) return true;
    if (error is! AppException) return false;
    return error.code == AppErrorCode.ERROR_BLUETOOTH_TIMEOUT ||
        error.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED ||
        error.code == AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED ||
        error.code == AppErrorCode.ERROR_BLUETOOTH_DISABLED;
  }

  Future<void> _toggleProfile(EuiccProfile p, bool enable) async {
    if (_rejectVoWifiConflict()) return;
    final isProcessingNotifs = NotificationService().isProcessing.value;
    final isSwitching = _isSwitching || ProfilesScreen.isSwitchingGlobal;

    if (isProcessingNotifs || isSwitching || _loading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isProcessingNotifs
                  ? AppLocalizations.of(context)!.notificationProcessingError
                  : AppLocalizations.of(context)!.operationInProgressError,
            ),
          ),
        );
      }
      return;
    }

    final reader = _selectedReader;
    if (reader == null) return;

    if (reader.source is SeHalAdapter) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(
                enable ? l10n.seHalSwitchTitle : l10n.seHalDisableTitle,
              ),
              content: Text(
                '${p.displayName}\nICCID: ${p.iccid}\n\n${enable ? l10n.seHalEnableWarning : l10n.seHalDisableWarning}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    enable ? l10n.seHalAcceptSwitch : l10n.seHalAcceptDisable,
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed || !mounted) return;
      _setSwitching(true);
      setState(() {
        _loading = true;
        _togglingIccid = p.iccid;
        _error = null;
      });
      try {
        await _adapter.runExclusive(() async {
          await _adapter.connect(reader);
          final profiles = await _manager.switchHalProfileAndVerify(
            p.iccid,
            enable,
          );
          _updateReaderState(
            reader,
            profiles: profiles,
            eid: reader.eid,
            clearError: true,
          );
          try {
            final channel = await _manager.openSession();
            try {
              await NotificationService().processPendingNotifications(
                _manager,
                channel,
                autoSendInstall: true,
                autoRemoveInstall: false,
                autoSendEnable: true,
                autoRemoveEnable: false,
                deleteWithoutSendingEnable: false,
                autoSendDisable: true,
                autoRemoveDisable: false,
                deleteWithoutSendingDisable: false,
                autoSendDelete: false,
                autoRemoveDelete: false,
              );
            } finally {
              await channel.close();
            }
          } catch (e) {
            _log.warning(
              'HAL notification reporting failed; use the notification screen: $e',
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.seHalStateChanged)));
        }
      } catch (e) {
        final errorStr = e.toString();
        if (!mounted) return;
        if (errorStr.contains('ENABLE_FAILED:') ||
            errorStr.contains('DISABLE_FAILED:')) {
          // The card refused, so the profile list is still accurate.
          _showFailureModal(enable ? 'enable' : 'disable', errorStr);
        } else {
          _updateReaderState(
            reader,
            profiles: [],
            error: l10n.seHalStateUnknown(errorStr),
          );
        }
      } finally {
        _setSwitching(false);
        if (mounted) {
          setState(() {
            _loading = false;
            _togglingIccid = null;
          });
        }
      }
      return;
    }

    setState(() {
      _loading = true;
      _togglingIccid = p.iccid;
      _operationLoadingMessage = enable
          ? AppLocalizations.of(context)!.enablingProfile
          : AppLocalizations.of(context)!.disablingProfile;
      _error = null;
    });

    final switchGeneration = ++_profileSwitchGeneration;
    _setSwitching(true);
    _armProfileSwitchDeadline(switchGeneration);

    await Future.delayed(const Duration(milliseconds: 100));

    List<EuiccProfile>? verifiedProfiles;
    var retryAfterPassword = false;
    void ensureCurrentSwitch() {
      if (switchGeneration != _profileSwitchGeneration) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: 'Profile switch deadline exceeded',
        );
      }
    }

    try {
      final result =
          await ProfileStateTransition(
            maxCommandAttempts: 2,
            // The host's reset takes ~30s and the card is unreadable for most
            // of it, so verification needs to outlast that rather than give up
            // in the first few seconds.
            maxVerificationAttempts: 14,
            verificationDelay: const Duration(seconds: 4),
            maxTransientVerificationFailuresWithoutRead: 10,
          ).run(
            targetEnabled: enable,
            submit: (attempt) async {
              ensureCurrentSwitch();
              if (mounted && _selectedReader?.id == reader.id) {
                setState(() {
                  _operationLoadingMessage = enable
                      ? AppLocalizations.of(context)!.enablingProfile
                      : AppLocalizations.of(context)!.disablingProfile;
                });
              }

              var refreshRequested = false;
              await _adapter.runExclusive(() async {
                await _adapter.connect(reader);
                var switchMarkerSet = false;
                try {
                  await _adapter.setProfileSwitchInProgress(true);
                  switchMarkerSet = true;
                  final channel = await _manager.openSession();
                  var commandCompleted = false;
                  try {
                    final isRefresh = enable
                        ? await _manager.enableProfile(
                            p.rawIccid,
                            useChannel: channel,
                          )
                        : await _manager.disableProfile(
                            p.rawIccid,
                            useChannel: channel,
                          );
                    commandCompleted = true;
                    if (isRefresh) {
                      refreshRequested = true;
                      _log.info(
                        'Profile switch requested a refresh; going off the air '
                        'until the host has reset the card.',
                      );
                    }
                  } finally {
                    if (commandCompleted &&
                        switchGeneration == _profileSwitchGeneration) {
                      try {
                        await channel.close();
                      } catch (closeError) {
                        _log.warning(
                          'Failed to close profile switch channel: $closeError',
                        );
                        if (isOmapiSessionCorruptedError(closeError)) rethrow;
                      }
                    } else {
                      _log.info(
                        'Skipping stale profile switch channel close; the next '
                        'fresh session will clean it up.',
                      );
                    }
                  }
                } finally {
                  if (switchMarkerSet) {
                    await _adapter.setProfileSwitchInProgress(false);
                  }
                }
              });

              if (refreshRequested) {
                // The enable succeeded and the card is now holding a REFRESH
                // for the handset's modem, which owns it. Anything sent from
                // here -- even just opening a channel to verify the switch --
                // is answered 6985, and from that point the eUICC refuses its
                // ISD-R until the SIM is physically re-seated.
                //
                // Measured from an APDU trace of both clients switching the
                // same card: the command-line tool closes its channel and
                // sends nothing at all, and the card is back in ~30s. The app
                // used to re-open a session 60ms later (channel cleanup,
                // TERMINAL CAPABILITY, MANAGE CHANNEL, SELECT AID) and the
                // SELECT came back 6985 every time.
                ensureCurrentSwitch();
                await _adapter.proactiveRefresh();
              }
            },
            reconnect: () async {
              ensureCurrentSwitch();
              _log.info(
                'Reconnecting Bluetooth transport before profile verification.',
              );
              await _adapter.reconnect();
            },
            readActualState: () async {
              ensureCurrentSwitch();
              if (mounted && _selectedReader?.id == reader.id) {
                setState(() {
                  _operationLoadingMessage = AppLocalizations.of(
                    context,
                  )!.refreshingProfiles;
                });
              }

              final listedProfiles = await _adapter.runExclusive(() async {
                await _adapter.connect(reader);
                final channel = await _manager.openSession();
                var readCompleted = false;
                try {
                  final profiles = await _fetchProfiles(channel, reader);
                  readCompleted = true;
                  return profiles;
                } finally {
                  if (readCompleted &&
                      switchGeneration == _profileSwitchGeneration) {
                    try {
                      await channel.close();
                    } catch (closeError) {
                      _log.warning(
                        'Failed to close profile verification channel: $closeError',
                      );
                      if (isOmapiSessionCorruptedError(closeError)) rethrow;
                    }
                  } else {
                    _log.info(
                      'Skipping stale profile verification channel close; '
                      'the next fresh session will clean it up.',
                    );
                  }
                }
              });
              ensureCurrentSwitch();

              final seenIccids = <String>{};
              verifiedProfiles = listedProfiles
                  .where((profile) => seenIccids.add(profile.iccid))
                  .toList();
              return verifiedProfiles
                  ?.where((profile) => profile.iccid == p.iccid)
                  .firstOrNull
                  ?.enabled;
            },
            isTransient: (error) =>
                switchGeneration == _profileSwitchGeneration &&
                !isOmapiSessionCorruptedError(error) &&
                _isProfileSwitchTransientError(error),
          );
      ensureCurrentSwitch();

      final profiles = verifiedProfiles;
      if (profiles == null) {
        throw StateError('Verified profile list was not retained');
      }

      _log.info(
        'Profile state verified after ${result.commandAttempts} command '
        'attempt(s) and ${result.verificationAttempts} fresh list attempt(s).',
      );

      _updateReaderSession(reader.id, (state) {
        state.profiles = profiles;
        state.status = ReaderStatus.ready;
        state.loading = false;
        state.isListingProfiles = false;
        state.isConnecting = false;
        state.operationLoadingMessage = null;
        state.lastError = null;
        state.hasBeenLoaded = true;
      });
      final verifiedEid = _eid;
      final verifiedInfo2 = _info2;
      if (verifiedEid != null) {
        PluginManager().notifyProfilesLoaded(verifiedEid, profiles);
      }
      _queueVerifiedProfilePersistence(
        profiles,
        verifiedEid,
        verifiedInfo2,
        reader,
      );
      unawaited(_processNotificationsAfterVerifiedSwitch(reader));
    } catch (e) {
      if (isOmapiSessionCorruptedError(e)) {
        // OMAPI is unusable until the device reboots, so offer no retry.
        _handleOperationError(reader, e);
      } else if (await _handleInvalidPassword(e)) {
        retryAfterPassword = true;
      } else {
        final errorStr = e.toString();
        if (errorStr.contains('ENABLE_FAILED:') ||
            errorStr.contains('DISABLE_FAILED:') ||
            e is ProfileStateVerificationException) {
          _showFailureModal(enable ? 'enable' : 'disable', errorStr);
        } else {
          _handleOperationError(
            reader,
            e,
            onRetry: () => _toggleProfile(p, enable),
          );
        }
      }
    } finally {
      _setSwitching(false);
      if (switchGeneration == _profileSwitchGeneration) {
        _profileSwitchGeneration++;
      }
      if (mounted) {
        _updateReaderSession(reader.id, (state) {
          state.loading = false;
          state.isListingProfiles = false;
          state.isConnecting = false;
          state.operationLoadingMessage = null;
          state.togglingIccid = null;
        });
        setState(() {
          _loading = false;
          _togglingIccid = null;
          _operationLoadingMessage = null;
        });
      }
    }

    if (retryAfterPassword && mounted) {
      await _toggleProfile(p, enable);
    }
  }

  Future<void> _persistVerifiedProfileState(
    List<EuiccProfile> profiles,
    String? eid,
    EUICCInfo2? info2,
    Reader reader,
  ) async {
    try {
      await _saveMetadataAndIcons(
        profiles,
        eid,
        info2,
        reader,
        showProgress: false,
        allowInteractivePrompts: false,
        refreshNotificationCount: false,
        allowAfterDispose: true,
      );
    } catch (metadataError) {
      _log.warning(
        'Profile state was verified, but metadata persistence failed: '
        '$metadataError',
      );
    }
  }

  void _queueVerifiedProfilePersistence(
    List<EuiccProfile> profiles,
    String? eid,
    EUICCInfo2? info2,
    Reader reader,
  ) {
    final previous = _profileMetadataPersistence;
    _profileMetadataPersistence = () async {
      try {
        await previous;
      } catch (error) {
        _log.warning('Earlier profile metadata persistence failed: $error');
      }
      await _persistVerifiedProfileState(profiles, eid, info2, reader);
    }();
  }

  Future<void> _processNotificationsAfterVerifiedSwitch(Reader reader) async {
    if (_voWifiOwnsReader) return;
    try {
      final settings = AppSettings();
      if (!settings.notifProcessAfterSwitch ||
          !settings.isAnyNotificationProcessingEnabled) {
        return;
      }
      if (!mounted || _selectedReader?.id != reader.id) return;

      await _adapter.runExclusive(() async {
        if (!mounted || _selectedReader?.id != reader.id) return;
        await _adapter.connect(reader);
        final channel = await _manager.openSession();
        try {
          await NotificationService().processPendingNotifications(
            _manager,
            channel,
            readerName: reader.id,
            autoSendInstall: settings.notifAutoSendInstall,
            autoRemoveInstall: settings.notifAutoRemoveInstall,
            autoSendEnable: settings.notifAutoSendEnable,
            autoRemoveEnable: settings.notifAutoRemoveEnable,
            deleteWithoutSendingEnable:
                settings.notifDeleteWithoutSendingEnable,
            autoSendDisable: settings.notifAutoSendDisable,
            autoRemoveDisable: settings.notifAutoRemoveDisable,
            deleteWithoutSendingDisable:
                settings.notifDeleteWithoutSendingDisable,
            autoSendDelete: settings.notifAutoSendDelete,
            autoRemoveDelete: settings.notifAutoRemoveDelete,
          );
        } finally {
          await channel.close();
        }
      });
    } catch (error) {
      _log.warning(
        'Notification processing after verified switch failed: $error',
      );
    }
  }

  /// The reset bits offered by the purge dialog.
  ///
  /// Defaults mirror what a purge is normally expected to do: take everything
  /// the card is willing to give up. lpac's fixed set leaves the provisioning
  /// and pre-loaded test profiles behind, which on some cards is every profile
  /// they have, so those are on by default here too.
  static const List<({String key, String label, String detail})>
  _purgeOptionRows = [
    (
      key: 'operational',
      label: 'Operational profiles',
      detail: 'Downloaded carrier profiles',
    ),
    (
      key: 'fieldLoadedTest',
      label: 'Field-loaded test profiles',
      detail: 'Test profiles downloaded after issue',
    ),
    (
      key: 'preLoadedTest',
      label: 'Pre-loaded test profiles',
      detail: 'Test profiles shipped on the card',
    ),
    (
      key: 'provisioning',
      label: 'Provisioning profiles',
      detail: 'Bootstrap profiles shipped on the card',
    ),
    (
      key: 'resetDefaultSmdp',
      label: 'Reset default SM-DP+',
      detail: 'Clears the configured default server',
    ),
  ];

  /// Lets the operator choose which reset bits the purge asks for.
  ///
  /// Returns null when cancelled. Continue stays disabled while nothing is
  /// ticked, because an empty BIT STRING is not a request the card can act on.
  Future<Map<String, bool>?> _showPurgeOptionsDialog() {
    final selected = {for (final o in _purgeOptionRows) o.key: true};
    return showDialog<Map<String, bool>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final anySelected = selected.values.any((v) => v);
          return AlertDialog(
            title: const Text('Purge eUICC'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Choose what the card should erase.'),
                  ),
                  for (final option in _purgeOptionRows)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: selected[option.key],
                      title: Text(option.label),
                      subtitle: Text(
                        option.detail,
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      onChanged: (v) =>
                          setLocal(() => selected[option.key] = v ?? false),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(ctx)!.cancel),
              ),
              TextButton(
                onPressed: anySelected
                    ? () => Navigator.of(ctx).pop(Map.of(selected))
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error,
                ),
                child: const Text('Purge'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Developer-mode only: ES10c EuiccMemoryReset.
  ///
  /// Two confirmations, the second with its buttons swapped so the destructive
  /// choice is not under the finger that just tapped confirm. Every profile on
  /// the card goes, so the second dialog spells out the count and the EID.
  Future<void> _purgeEuicc() async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;
    final profileCount = _profiles?.length ?? 0;

    final options = await _showPurgeOptionsDialog();
    if (options == null) return;
    if (!mounted) return;

    final chosen = _purgeOptionRows
        .where((o) => options[o.key] ?? false)
        .map((o) => o.label.toLowerCase())
        .join('\n• ');
    final secondConfirmed = await _showPremiumConfirmDialog(
      title: "Purge eUICC — are you sure?",
      message:
          "Last chance. On ${_eid ?? reader.name} this erases "
          "permanently:\n\n• $chosen\n\n"
          "$profileCount profile(s) are currently installed. There is no way "
          "to recover them.",
      confirmLabel: "Erase everything",
      isDestructive: true,
      swapButtons: true,
    );
    if (secondConfirmed != true) return;
    if (!mounted) return;

    setState(() {
      _operationLoadingMessage = "Purging eUICC...";
      _error = null;
    });

    try {
      await _adapter.runExclusive(() async {
        await _adapter.connect(reader);
        final channel = await _manager.openSession();
        try {
          final result = await _manager.resetEuiccMemory(
            deleteOperationalProfiles: options['operational'] ?? false,
            deleteFieldLoadedTestProfiles: options['fieldLoadedTest'] ?? false,
            resetDefaultSmdpAddress: options['resetDefaultSmdp'] ?? false,
            deletePreLoadedTestProfiles: options['preLoadedTest'] ?? false,
            deleteProvisioningProfiles: options['provisioning'] ?? false,
            useChannel: channel,
          );
          _log.warning("eUICC memory reset returned ${result.name}");

          final profiles = await _fetchProfiles(channel, reader);
          final (eid, info2) = await _fetchEuiccData(
            channel,
            reader,
            force: true,
          );
          if (mounted && _selectedReader?.id == reader.id) {
            await _saveMetadataAndIcons(profiles, eid, info2, reader);
            _updateReaderState(
              reader,
              profiles: profiles,
              eid: eid,
              info2: info2,
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result == EuiccMemoryResetResponse_resetResult.nothingToDelete
                      ? "eUICC was already empty"
                      : "eUICC purged",
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } finally {
          await channel.close();
        }
      });
    } catch (e) {
      _handleOperationError(reader, e, onRetry: _purgeEuicc);
    } finally {
      if (mounted) {
        setState(() => _operationLoadingMessage = null);
      }
    }
  }

  Future<void> _deleteProfile(EuiccProfile p) async {
    if (_rejectVoWifiConflict()) return;
    final confirmed = await _showPremiumConfirmDialog(
      title: AppLocalizations.of(context)!.deleteProfile,
      message: AppLocalizations.of(
        context,
      )!.deleteProfileConfirmation(p.displayName),
      confirmLabel: AppLocalizations.of(context)!.delete,
      isDestructive: true,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final secondConfirmed = await _showPremiumConfirmDialog(
      title: AppLocalizations.of(context)!.deleteProfile,
      message: AppLocalizations.of(
        context,
      )!.deleteProfileConfirmation(p.displayName),
      confirmLabel: AppLocalizations.of(context)!.delete,
      isDestructive: true,
      swapButtons: true,
    );

    if (secondConfirmed != true) return;

    final reader = _selectedReader;
    if (reader == null) return;

    setState(() {
      _deletingIccid = p.iccid;
      _operationLoadingMessage = AppLocalizations.of(context)!.deletingProfile;
      _error = null;
    });

    try {
      await _adapter.runExclusive(() async {
        await _adapter.connect(reader);
        final channel = await _manager.openSession();
        try {
          await _manager.deleteProfile(p.rawIccid, useChannel: channel);

          if (mounted && _selectedReader?.id == reader.id) {
            setState(() {
              _operationLoadingMessage = AppLocalizations.of(
                context,
              )!.refreshingProfiles;
            });
          }

          final profiles = await _fetchProfiles(channel, reader);
          final (eid, info2) = await _fetchEuiccData(
            channel,
            reader,
            force: true,
          );
          if (mounted && _selectedReader?.id == reader.id) {
            await _saveMetadataAndIcons(profiles, eid, info2, reader);
            _updateReaderState(
              reader,
              profiles: profiles,
              eid: eid,
              info2: info2,
            );
          }
        } finally {
          await channel.close();
        }
      });
      final settings = AppSettings();
      if (reader.source is SeHalAdapter) {
        await NotificationService().processPendingNotifications(
          _manager,
          null,
          autoSendInstall: true,
          autoRemoveInstall: false,
          autoSendEnable: true,
          autoRemoveEnable: false,
          deleteWithoutSendingEnable: false,
          autoSendDisable: true,
          autoRemoveDisable: false,
          deleteWithoutSendingDisable: false,
          autoSendDelete: true,
          autoRemoveDelete: false,
        );
      } else if (settings.notifProcessAfterDeletion &&
          settings.isAnyNotificationProcessingEnabled) {
        await NotificationService().processPendingNotifications(
          _manager,
          null, // Use fresh session
          readerName: reader.id,
          autoSendInstall: settings.notifAutoSendInstall,
          autoRemoveInstall: settings.notifAutoRemoveInstall,
          autoSendEnable: settings.notifAutoSendEnable,
          autoRemoveEnable: settings.notifAutoRemoveEnable,
          deleteWithoutSendingEnable: settings.notifDeleteWithoutSendingEnable,
          autoSendDisable: settings.notifAutoSendDisable,
          autoRemoveDisable: settings.notifAutoRemoveDisable,
          deleteWithoutSendingDisable:
              settings.notifDeleteWithoutSendingDisable,
          autoSendDelete: settings.notifAutoSendDelete,
          autoRemoveDelete: settings.notifAutoRemoveDelete,
        );
      }
    } catch (e) {
      if (reader.source is SeHalAdapter) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          )!.seHalDeleteUnknown(e.toString()),
        );
      } else {
        _handleOperationError(reader, e, onRetry: () => _deleteProfile(p));
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingIccid = null;
          _operationLoadingMessage = null;
        });
      }
    }
  }

  Future<void> _showProfileContextMenu(
    EuiccProfile profile, {
    GlobalKey? anchorKey,
  }) async {
    if (NotificationService().isProcessing.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.notificationProcessingError,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool hasUsage = false;
    try {
      final status = await DatabaseService().getCardStatus(profile.iccid);
      if (status != null && status['data'] != null) {
        final data = jsonDecode(status['data'] as String);
        if (data is Map && data.containsKey('packages')) {
          final pkgs = data['packages'];
          if (pkgs is List && pkgs.isNotEmpty) {
            hasUsage = true;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;

    final pluginActions = PluginManager().getProfileActions(
      context,
      profile,
      actionContext: ReaderActionContext(
        adapter: _adapter,
        reader: _selectedReader,
        profiles: _profiles,
        manager: _manager,
      ),
    );

    final result = await AdaptiveContextMenu.show<String>(
      context: context,
      anchorKey: anchorKey,
      title: profile.displayName,
      items: [
        if (hasUsage)
          AdaptiveContextMenuItem(
            label: AppLocalizations.of(context)!.dataUsage,
            icon: Icons.data_usage_rounded,
            value: 'usage',
          ),
        ...pluginActions.asMap().entries.map(
          (e) => AdaptiveContextMenuItem(
            label: e.value.label,
            icon: e.value.icon,
            value: 'plugin_${e.key}',
          ),
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.details,
          icon: Icons.info_outline_rounded,
          value: 'details',
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.rename,
          icon: Icons.edit_outlined,
          value: 'rename',
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.changeIcon,
          icon: Icons.image_outlined,
          value: 'change_icon',
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.manageTags,
          icon: Icons.label_outline_rounded,
          value: 'tags',
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.copyIccid,
          icon: Icons.copy_outlined,
          value: 'copy_iccid',
        ),
        if (profile.profileClass == 2)
          AdaptiveContextMenuItem(
            label: AppLocalizations.of(context)!.transferTitle,
            icon: Icons.swap_horiz_rounded,
            value: 'transfer',
          ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.delete,
          icon: Icons.delete_outline_rounded,
          value: 'delete',
          enabled: !profile.enabled,
          isDestructive: true,
        ),
      ],
    );

    if (result == 'usage') _showDataUsageDialog(profile);
    if (result?.startsWith('plugin_') ?? false) {
      final index = int.tryParse(result!.substring(7));
      if (index != null && index < pluginActions.length) {
        pluginActions[index].onTap();
      }
    }
    if (result == 'details') _showProfileDetails(profile);
    if (result == 'rename') _renameProfile(profile);
    if (result == 'change_icon') _changeProfileIcon(profile);
    if (result == 'tags') _openTagManager(profile);
    if (result == 'copy_iccid') _copyIccid(profile);
    if (result == 'transfer') await _handleTransfer(profile);
    if (result == 'delete') _deleteProfile(profile);
  }

  /// Launches the TS.43 carrier-managed transfer wizard for [profile] and
  /// refreshes the profile list afterwards.
  Future<void> _handleTransfer(EuiccProfile profile) async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;
    if (NotificationService().isProcessing.value) {
      _showPremiumInfoDialog(
        title: AppLocalizations.of(context)!.operationRestricted,
        message: AppLocalizations.of(
          context,
        )!.notificationProcessingDownloadError,
        isError: true,
      );
      return;
    }
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EsimTransferPage(
          manager: _manager,
          adapter: _adapter,
          reader: reader,
          profile: profile,
        ),
      ),
    );
    if (mounted) await _listProfiles();
  }

  void _copyIccid(EuiccProfile profile) {
    Clipboard.setData(ClipboardData(text: profile.iccid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.iccidCopied(profile.iccid)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openTagManager(EuiccProfile profile) async {
    if (_selectedReader == null) return;

    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    bool? changed;
    if (isDesktop) {
      changed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: AppLocalizations.of(context)!.close,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return Center(
            child: Container(
              width: 500,
              height: 600,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ProfileTagManagerPage(
                profile: profile,
                manager: _manager,
                reader: _selectedReader!,
              ),
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
              child: child,
            ),
          );
        },
      );
    } else {
      changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileTagManagerPage(
            profile: profile,
            manager: _manager,
            reader: _selectedReader!,
          ),
        ),
      );
    }

    if (changed == true) {
      await _listProfiles();
    }
  }

  Widget _buildDeepLinkBanner() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final hasLpa = _pendingDeepLinkCode != null;
    final hasSigning = _pendingSigningUri != null;

    if (!hasLpa && !hasSigning) return const SizedBox.shrink();

    final String title = hasLpa
        ? l10n.readyToInstallProfile
        : l10n.authorizeSigning;
    final IconData icon = hasLpa
        ? Icons.sim_card_download_rounded
        : Icons.security_rounded;

    // Show where the request came from rather than the raw link. The SM-DP+
    // address is what the user is being asked to trust; the matching ID is
    // noise, and the full code only ever rendered as truncated mono text.
    final String source = hasLpa
        ? (ActivationCode.parse(_pendingDeepLinkCode!)?.smdpAddress ??
              _pendingDeepLinkCode!)
        : (_pendingSigningUri!.queryParameters['smdp'] ??
              _pendingSigningUri!.host);

    void dismiss() {
      setState(() {
        if (hasLpa) {
          _pendingDeepLinkCode = null;
          DeepLinkService().consumeCode();
        }
        if (hasSigning) {
          _pendingSigningUri = null;
          DeepLinkService().clearPendingSigning();
        }
      });
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: AppTheme.bannerDecoration(context),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  source,
                  style: AppTheme.mono(
                    TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_readers.isEmpty)
            TextButton(
              onPressed: _refreshDeviceList,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                l10n.refreshDevices,
                style: const TextStyle(fontSize: 12),
              ),
            )
          else
            FilledButton(
              onPressed: hasLpa
                  ? _handleDeepLinkDownload
                  : _handlePendingSigning,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                hasLpa ? l10n.downloadHere : l10n.sign,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            icon: const Icon(Icons.close_rounded),
            onPressed: dismiss,
          ),
        ],
      ),
    );
  }

  void _handleDeepLinkDownload() async {
    if (_rejectVoWifiConflict()) return;
    final code = _pendingDeepLinkCode;
    if (code == null) return;

    Reader? targetReader = _selectedReader;

    // Prompt user to select a device if there are multiple, or if none selected.
    if (_readers.length > 1) {
      targetReader = await _showReaderPickerDialog();
    } else if (_readers.length == 1) {
      targetReader = _readers.first;
    } else {
      // No readers found, try refreshing once
      await _loadReaders();
      if (_readers.length > 1) {
        targetReader = await _showReaderPickerDialog();
      } else if (_readers.length == 1) {
        targetReader = _readers.first;
      }
    }

    if (targetReader == null) return;
    final Reader reader = targetReader;

    // Ensure it's selected
    if (_selectedReader?.id != reader.id) {
      await _selectReader(reader);
    }

    if (mounted) {
      setState(() {
        _pendingDeepLinkCode = null;
        DeepLinkService().consumeCode();
      });
    }

    if (!mounted) return;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProfilePage(
          profileManager: _manager,
          adapter: _adapter,
          reader: reader,
          initialCode: code,
          autoStart: true,
        ),
      ),
    );

    if (success == true) {
      await _listProfiles();
    }
  }

  void _handlePendingSigning() async {
    if (_rejectVoWifiConflict()) return;
    final uri = _pendingSigningUri;
    if (uri == null) return;

    // Reset banner first
    setState(() {
      _pendingSigningUri = null;
    });
    // Clear in service too
    await DeepLinkService().clearPendingSigning();

    // Re-trigger the logic in DeepLinkService but now it will find readers
    DeepLinkService().handleUri(uri);
  }

  List<EuiccProfile> _getFilteredSortedProfiles() {
    if (_profiles == null) return [];
    if (_filteredProfiles != null) return _filteredProfiles!;

    var result = List<EuiccProfile>.from(_profiles!);

    // Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) {
        final iccid = p.iccid.toLowerCase();
        final name = (p.name ?? "").toLowerCase();
        final nickname = (p.nickname ?? "").toLowerCase();
        final spName = (p.serviceProviderName ?? "").toLowerCase();
        final mcc = (p.mcc ?? "").toLowerCase();
        final mnc = (p.mnc ?? "").toLowerCase();
        final isdpAid = (p.isdpAid ?? "").toLowerCase();

        return iccid.contains(query) ||
            name.contains(query) ||
            nickname.contains(query) ||
            spName.contains(query) ||
            mcc.contains(query) ||
            mnc.contains(query) ||
            isdpAid.contains(query);
      }).toList();
    }

    // Sort
    final sortType = AppSettings().profileSortType;
    final ascending = AppSettings().sortAscending;

    if (sortType != ProfileSortType.none) {
      result.sort((a, b) {
        int cmp = 0;
        switch (sortType) {
          case ProfileSortType.iccid:
            cmp = a.iccid.compareTo(b.iccid);
            break;
          case ProfileSortType.country:
            final cA = a.mcc ?? "ZZZ";
            final cB = b.mcc ?? "ZZZ";
            cmp = cA.compareTo(cB);
            break;
          case ProfileSortType.nickname:
            final nA = (a.nickname ?? "").toLowerCase();
            final nB = (b.nickname ?? "").toLowerCase();
            if (nA.isEmpty && nB.isNotEmpty) {
              cmp = 1;
            } else if (nA.isNotEmpty && nB.isEmpty) {
              cmp = -1;
            } else {
              cmp = nA.compareTo(nB);
            }
            break;
          default:
            return 0;
        }
        return ascending ? cmp : -cmp;
      });
    }

    _filteredProfiles = result;
    return result;
  }

  void _handleDownload() async {
    if (_rejectVoWifiConflict()) return;
    if (_selectedReader == null) return;
    if (NotificationService().isProcessing.value) {
      _showPremiumInfoDialog(
        title: AppLocalizations.of(context)!.operationRestricted,
        message: AppLocalizations.of(
          context,
        )!.notificationProcessingDownloadError,
        isError: true,
      );
      return;
    }
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProfilePage(
          profileManager: _manager,
          adapter: _adapter,
          reader: _selectedReader!,
        ),
      ),
    );

    if (success == true) {
      await _listProfiles();
    }
  }

  void _handleBatchDownload(GlobalKey anchorKey) async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;
    if (NotificationService().isProcessing.value) {
      _showPremiumInfoDialog(
        title: AppLocalizations.of(context)!.operationRestricted,
        message: AppLocalizations.of(
          context,
        )!.notificationProcessingDownloadError,
        isError: true,
      );
      return;
    }

    final result = await AdaptiveContextMenu.show<String>(
      context: context,
      anchorKey: anchorKey,
      items: [
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.batchDownloadTitle,
          icon: Icons.layers_outlined,
          value: 'batch',
        ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.discoverProfiles,
          icon: Icons.travel_explore_rounded,
          value: 'discovery',
        ),
      ],
    );

    if (result == 'batch') {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BatchDownloadPage(
            profileManager: _manager,
            adapter: _adapter,
            reader: _selectedReader!,
          ),
        ),
      );

      await _listProfiles();
    } else if (result == 'discovery') {
      await _handleDiscovery();
    }
  }

  /// Runs SM-DS (ES11) discovery on the selected reader, lets the user pick a
  /// pending profile, then downloads it through the normal download flow.
  Future<void> _handleDiscovery() async {
    if (_rejectVoWifiConflict()) return;
    final reader = _selectedReader;
    if (reader == null) return;

    final l10n = AppLocalizations.of(context)!;
    // Progress dialog while we talk to the card + SM-DS.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(l10n.discoveringProfiles)),
          ],
        ),
      ),
    );

    List<DiscoveredEvent> events;
    try {
      final imei = await AppSettings().getImei();
      final service = SmdsDiscoveryService(
        manager: _manager,
        adapter: _adapter,
        reader: reader,
      );
      events = await service.discover(
        smdsAddress: kRootSmdsAddress,
        imei: imei,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss progress
      if (mounted) {
        _showPremiumInfoDialog(
          title: l10n.transferTitle,
          message: l10n.transferFailed(e.toString()),
          isError: true,
        );
      }
      return;
    }
    if (mounted) Navigator.pop(context); // dismiss progress
    if (!mounted) return;

    if (events.isEmpty) {
      _showPremiumInfoDialog(
        title: l10n.discoverProfiles,
        message: l10n.discoveryNoProfiles,
        isError: false,
      );
      return;
    }

    final chosen = events.length == 1
        ? events.first
        : await _selectDiscoveredEvent(events);
    if (chosen == null || !mounted) return;

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadProfilePage(
          profileManager: _manager,
          adapter: _adapter,
          reader: reader,
          initialCode: chosen.activationCode,
          autoStart: true,
        ),
      ),
    );
    if (success == true) {
      await _listProfiles();
    }
  }

  Future<DiscoveredEvent?> _selectDiscoveredEvent(
    List<DiscoveredEvent> events,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<DiscoveredEvent>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.transferSelectProfile),
        children: [
          for (final e in events)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, e),
              child: Text(l10n.transferProfileOnServer(e.eventId, e.address)),
            ),
        ],
      ),
    );
  }

  void _showProfileDetails(EuiccProfile profile) {
    String classStr = AppLocalizations.of(context)!.operational;
    if (profile.profileClass == 0) {
      classStr = AppLocalizations.of(context)!.test;
    }
    if (profile.profileClass == 1) {
      classStr = AppLocalizations.of(context)!.provisioning;
    }
    final displayIccid = IccidFormatter.forDisplay(profile.iccid);

    final l10n = AppLocalizations.of(context)!;
    _showPremiumInfoDialog(
      title: l10n.profileDetails,
      message: l10n.profileDetailsSubtitle,
      details:
          "${l10n.iccid}: $displayIccid\n"
          "${l10n.provider}: ${profile.serviceProviderName ?? l10n.unavailable}\n"
          "${l10n.state}: ${profile.enabled ? l10n.enabled : l10n.disabled}\n"
          "${l10n.profileClass}: $classStr\n"
          "${l10n.aid}: ${profile.isdpAid ?? l10n.unavailable}",
    );
  }

  Future<void> _renameProfile(EuiccProfile profile) async {
    if (_rejectVoWifiConflict()) return;
    final parsed = ProfileTagUtils.parse(profile.nickname);
    final TextEditingController nameController = TextEditingController(
      text: parsed.name,
    );

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.dismiss,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return RepaintBoundary(
          child: SimpleDialogContainer(
            title: AppLocalizations.of(context)!.renameProfile,
            primaryActionLabel: AppLocalizations.of(context)!.save,
            secondaryActionLabel: AppLocalizations.of(context)!.cancel,
            onPrimaryAction: () =>
                Navigator.pop(context, nameController.text.trim()),
            onSecondaryAction: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.nickname,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceSubtle(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      )!.enterProfileNickname,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.tagsManagedSeparately,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVerySubtle(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null || result == parsed.name) return;

    final fullNickname = ProfileTagUtils.format(result, parsed.tags);

    final reader = _selectedReader;
    if (reader == null) return;

    setState(() {
      _loading = true;
      _operationLoadingMessage = AppLocalizations.of(context)!.updatingProfile;
    });

    try {
      await _adapter.runExclusive(() async {
        await _adapter.connect(reader);
        final channel = await _manager.openSession();
        try {
          await _manager.renameProfile(
            profile.iccid,
            fullNickname,
            useChannel: channel,
          );

          // Also update metadata in DB
          final metaService = await ProfileMetadataService.getInstance();
          final existing = await metaService.getProfile(profile.iccid);
          if (existing != null) {
            await metaService.saveProfile(
              iccid: profile.iccid,
              nickname: fullNickname,
              name: existing.name,
              providerName: existing.providerName,
              mcc: existing.mcc,
              mnc: existing.mnc,
              enabled: existing.enabled,
              profileClass: existing.profileClass,
              profileSize: existing.profileSize,
              gid1: existing.gid1,
              gid2: existing.gid2,
              tags: parsed.tags.map((t) => t.raw).toList(),
              eid: _eid,
            );
          }

          // Refresh list and sync metadata (ensures custom icon is preserved)
          final profiles = await _fetchProfiles(channel, reader);
          final (eid, info2) = await _fetchEuiccData(
            channel,
            reader,
            force: true,
          );
          if (mounted && _selectedReader?.id == reader.id) {
            await _saveMetadataAndIcons(profiles, eid, info2, reader);
          }
        } finally {
          await channel.close();
        }
      });
    } catch (e) {
      _handleOperationError(
        _selectedReader,
        e,
        onRetry: () => _renameProfile(profile),
      );
    } finally {
      final readerId = _selectedReader?.id;
      if (readerId != null) {
        _updateReaderSession(readerId, (s) => s.loading = false);
      }
    }
  }

  Future<void> _changeProfileIcon(EuiccProfile profile) async {
    final settings = AppSettings();
    final hasProfileIcon = profile.icon != null && profile.icon!.isNotEmpty;
    final hasNekokoIcon =
        settings.useNekokoIcons && profile.mcc != null && profile.mnc != null;
    final hasCustomIcon =
        profile.customIcon != null && profile.customIcon!.isNotEmpty;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.changeProfileIcon),
        contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
            maxWidth: 400,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(AppLocalizations.of(context)!.selectFromGallery),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                if (hasNekokoIcon)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.cloud_outlined),
                    title: Text(AppLocalizations.of(context)!.useRemoteIcon),
                    subtitle: Text(
                      AppLocalizations.of(context)!.nekokoOperatorIcon,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, 'remote'),
                  ),
                if (hasProfileIcon)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.sim_card_outlined),
                    title: Text(AppLocalizations.of(context)!.useProfileIcon),
                    subtitle: Text(
                      AppLocalizations.of(context)!.iconFromEsim,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, 'profile'),
                  ),
                if (hasCustomIcon)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: const Icon(Icons.delete_outline),
                    title: Text(AppLocalizations.of(context)!.removeCustomIcon),
                    onTap: () => Navigator.pop(context, 'remove'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final metaService = await ProfileMetadataService.getInstance();
      final existing = await metaService.getProfile(profile.iccid);

      switch (result) {
        case 'gallery':
          await _selectIconFromGallery(profile, metaService, existing);
          break;
        case 'remote':
          await _useRemoteIcon(profile, metaService, existing);
          break;
        case 'profile':
          await _useProfileIcon(profile, metaService, existing);
          break;
        case 'remove':
          await _removeCustomIcon(profile, metaService, existing);
          break;
      }
    } catch (e) {
      _log.severe("Failed to update icon: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.updateIconFailed(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectIconFromGallery(
    EuiccProfile profile,
    ProfileMetadataService metaService,
    ProfileMetadata? existing,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? imageBytes;

      if (kIsWeb) {
        imageBytes = file.bytes;
      } else if (file.path != null) {
        imageBytes = await io.File(file.path!).readAsBytes();
      }

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToReadImage),
            ),
          );
        }
        return;
      }

      // Decode and resize image to 256x256
      final codec = await instantiateImageCodec(
        imageBytes,
        targetWidth: 256,
        targetHeight: 256,
      );
      final frame = await codec.getNextFrame();
      final resizedData = await frame.image.toByteData(
        format: ImageByteFormat.png,
      );

      if (resizedData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.failedToProcessImage),
            ),
          );
        }
        return;
      }

      final resizedBytes = resizedData.buffer.asUint8List();
      final base64Image = base64Encode(resizedBytes);

      // Update in memory and database
      profile.customIcon = base64Image;
      await _saveProfileMetadata(
        profile,
        metaService,
        existing,
        customIcon: base64Image,
      );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.customIconSet)),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _useRemoteIcon(
    EuiccProfile profile,
    ProfileMetadataService metaService,
    ProfileMetadata? existing,
  ) async {
    if (profile.mcc == null || profile.mnc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noMccMnc)),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.fetchingRemoteIcon),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Try to get from cache/DB first
      String? base64Icon = await OperatorIconService().getIcon(
        mcc: profile.mcc!,
        mnc: profile.mnc!,
        gid1: profile.gid1,
        gid2: profile.gid2,
      );

      // If not in cache, fetch from server
      if (base64Icon == null) {
        await OperatorIconService().fetchMissingIcons([
          {
            'mcc': profile.mcc!,
            'mnc': profile.mnc!,
            'gid1': profile.gid1,
            'gid2': profile.gid2,
            'profileName': profile.name,
          },
        ]);

        // Wait a bit for the download to complete
        await Future.delayed(const Duration(seconds: 2));

        // Try to get again
        base64Icon = await OperatorIconService().getIcon(
          mcc: profile.mcc!,
          mnc: profile.mnc!,
          gid1: profile.gid1,
          gid2: profile.gid2,
        );
      }

      if (base64Icon == null || base64Icon.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noRemoteIcon)),
          );
        }
        return;
      }

      // Save as custom icon
      profile.customIcon = base64Icon;
      await _saveProfileMetadata(
        profile,
        metaService,
        existing,
        customIcon: base64Icon,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.remoteIconSaved),
          ),
        );
      }
    } catch (e) {
      _log.severe("Failed to fetch remote icon: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.fetchRemoteIconFailed(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _useProfileIcon(
    EuiccProfile profile,
    ProfileMetadataService metaService,
    ProfileMetadata? existing,
  ) async {
    if (profile.icon == null || profile.icon!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noProfileIcon)),
        );
      }
      return;
    }

    // Convert profile icon to base64 and save as custom icon
    final base64Icon = base64Encode(profile.icon!);
    profile.customIcon = base64Icon;
    await _saveProfileMetadata(
      profile,
      metaService,
      existing,
      customIcon: base64Icon,
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileIconSaved)),
      );
    }
  }

  Future<void> _removeCustomIcon(
    EuiccProfile profile,
    ProfileMetadataService metaService,
    ProfileMetadata? existing,
  ) async {
    // Clear custom icon - pass empty string to explicitly clear it in database
    profile.customIcon = null;
    await _saveProfileMetadata(profile, metaService, existing, customIcon: '');

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.customIconRemoved),
        ),
      );
    }
  }

  Future<void> _saveProfileMetadata(
    EuiccProfile profile,
    ProfileMetadataService metaService,
    ProfileMetadata? existing, {
    String? customIcon,
  }) async {
    await metaService.saveProfile(
      iccid: profile.iccid,
      nickname: existing?.nickname ?? profile.nickname,
      name: existing?.name ?? profile.name,
      providerName: existing?.providerName ?? profile.serviceProviderName,
      mcc: existing?.mcc ?? profile.mcc,
      mnc: existing?.mnc ?? profile.mnc,
      enabled: existing?.enabled ?? profile.enabled,
      profileClass: existing?.profileClass ?? profile.profileClass,
      gid1: existing?.gid1 ?? profile.gid1,
      gid2: existing?.gid2 ?? profile.gid2,
      tags: existing?.tags ?? profile.tags,
      eid: _eid,
      customIcon: customIcon,
    );
  }

  void _showFailureModal(String action, String reason) {
    // Clean up reason
    String cleanReason = reason;
    if (cleanReason.startsWith("Exception: ")) {
      cleanReason = cleanReason.substring("Exception: ".length);
    }
    if (cleanReason.contains(':')) {
      final parts = cleanReason.split(':');
      if (parts.length > 1) {
        cleanReason = parts[1];
      }
    }

    _showPremiumInfoDialog(
      title: AppLocalizations.of(context)!.failed,
      message: AppLocalizations.of(context)!.euiccError(action),
      details: cleanReason,
      isError: true,
    );
  }

  Future<bool?> _showPremiumConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    String? details,
    bool isDestructive = false,
    bool showCancel = true,
    bool swapButtons = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.dismiss,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        final theme = Theme.of(context);
        return SimpleDialogContainer(
          title: title,
          secondaryActionLabel: showCancel
              ? (swapButtons
                    ? confirmLabel
                    : AppLocalizations.of(context)!.cancel)
              : null,
          onSecondaryAction: showCancel
              ? (swapButtons
                    ? () => Navigator.pop(context, true)
                    : () => Navigator.pop(context, false))
              : null,
          primaryActionLabel: swapButtons
              ? AppLocalizations.of(context)!.cancel
              : confirmLabel,
          onPrimaryAction: swapButtons
              ? () => Navigator.pop(context, false)
              : () => Navigator.pop(context, true),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceSubtle(context),
                    height: 1.4,
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      details,
                      style: AppTheme.mono(
                        TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDataUsageDialog(EuiccProfile profile) async {
    final theme = Theme.of(context);

    // Fetch fresh data
    Map<String, dynamic>? data;
    try {
      final status = await DatabaseService().getCardStatus(profile.iccid);
      if (status != null && status['data'] != null) {
        data = jsonDecode(status['data'] as String);
      }
    } catch (_) {}

    if (data == null || !data.containsKey('packages')) return;

    if (!mounted) return;

    final packages = data['packages'] as List;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.data_usage_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.dataUsage),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: packages.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final pkg = packages[index] as Map;
              final double total = (pkg['totalGB'] as num?)?.toDouble() ?? 0.0;
              final double used = (pkg['usedGB'] as num?)?.toDouble() ?? 0.0;
              final String label =
                  pkg['label'] ?? AppLocalizations.of(context)!.dataPlan;
              final String? validity = pkg['validity'];

              final double percentage = total > 0
                  ? (used / total).clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 0.9 ? Colors.red : theme.colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$used GB ${AppLocalizations.of(context)!.used}",
                        style: TextStyle(
                          color: AppTheme.onSurfaceSubtle(context),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "$total GB ${AppLocalizations.of(context)!.total}",
                        style: TextStyle(
                          color: AppTheme.onSurfaceSubtle(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (validity != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.expires(validity),
                      style: TextStyle(
                        color: AppTheme.onSurfaceSubtle(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _showPremiumInfoDialog({
    required String title,
    required String message,
    String? details,
    bool isError = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.dismiss,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        final theme = Theme.of(context);
        return SimpleDialogContainer(
          title: title,
          headerAction: isError
              ? Icon(Icons.error_outline, color: Colors.red, size: 24)
              : Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
          primaryActionLabel: AppLocalizations.of(context)!.ok,
          onPrimaryAction: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceSubtle(context),
                    height: 1.4,
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isError ? Colors.red : theme.colorScheme.primary)
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      details,
                      style: AppTheme.mono(
                        TextStyle(
                          fontSize: 12,
                          color: isError
                              ? Colors.red[300]
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEidContextMenu(GlobalKey anchorKey) async {
    final extraActions = _selectedReader?.source.extraActions ?? [];
    _log.info(
      "Opening EID context menu for ${_selectedReader?.name}. Source: ${_selectedReader?.source.runtimeType}. Extra actions: ${extraActions.length}",
    );
    final items = [
      ...extraActions.map(
        (action) => AdaptiveContextMenuItem(
          label: action.label,
          icon: action.icon,
          value: 'extra_${action.key}',
        ),
      ),
      AdaptiveContextMenuItem(
        label: AppLocalizations.of(context)!.euiccInfo,
        icon: Icons.info_outline,
        value: 'info',
      ),
      if (_eid != null &&
          _eid!.startsWith('89043051') &&
          _manager.nxpInfos.containsKey(_eid))
        AdaptiveContextMenuItem(
          label: "NXP memory Info",
          icon: Icons.memory,
          value: 'nxp_info',
        ),
      AdaptiveContextMenuItem(
        label: AppLocalizations.of(context)!.copyEid,
        icon: Icons.copy,
        value: 'copy',
      ),
      // Developer-mode only: this erases every profile on the card. Kept out
      // of the localised strings for the same reason as "NXP memory Info" --
      // it is a debugging affordance, not a shipped feature.
      if (AppSettings().developerModeEnabled)
        AdaptiveContextMenuItem(
          label: "Purge eUICC",
          icon: Icons.delete_forever,
          value: 'purge',
          isDestructive: true,
        ),
      ...PluginManager()
          .getEidActions(context, _eid, aid: _selectedReader?.aid)
          .map(
            (action) => AdaptiveContextMenuItem(
              label: action.label,
              icon: action.icon,
              value: 'plugin_${action.label}',
            ),
          ),
    ];
    _log.info("Menu items: ${items.map((i) => i.label).join(', ')}");

    final result = await AdaptiveContextMenu.show<String>(
      context: context,
      anchorKey: anchorKey,
      title: AppLocalizations.of(context)!.euiccOptions,
      items: items,
    );

    if (!mounted) return;

    if (result == 'info') _showEuiccInfoDialog();
    if (result == 'nxp_info') _showNxpInfoDialog();
    if (result == 'copy' && _eid != null) {
      Clipboard.setData(ClipboardData(text: _eid!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.eidCopied),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    // Exclusive with the plugin/extra dispatch below, and returning here keeps
    // the awaited purge from putting an async gap in front of their context use.
    if (result == 'purge') {
      await _purgeEuicc();
      return;
    }

    if (result?.startsWith('plugin_') ?? false) {
      final label = result!.substring(7);
      final actions = PluginManager().getEidActions(
        context,
        _eid,
        aid: _selectedReader?.aid,
      );
      final action = actions.firstWhere((a) => a.label == label);
      action.onTap();
    }

    if (result?.startsWith('extra_') ?? false) {
      final key = result!.substring(6);
      final actions = _selectedReader?.source.extraActions ?? [];
      final action = actions.firstWhere((a) => a.key == key);
      await action.onPressed(context);
    }
  }

  void _showEuiccInfoDialog() {
    if (_rejectVoWifiConflict()) return;
    if (_info2 == null) return;
    EuiccInfoDialog.show(context, _info2!, configured: _configuredData);
  }

  void _showNxpInfoDialog() {
    if (_rejectVoWifiConflict()) return;
    if (_eid == null || !_manager.nxpInfos.containsKey(_eid)) return;
    final nxpInfo = _manager.nxpInfos[_eid]!;

    String osInfoStr = nxpInfo.osInformation != null
        ? "\n\nOS Information:\n${nxpInfo.osInformation}"
        : "";

    _showPremiumInfoDialog(
      title: "NXP Memory Info",
      message:
          "Detected model: ${nxpInfo.modelName}\n"
          "Firmware version: ${nxpInfo.firmwareVersion}",
      details:
          "Available: ${nxpInfo.availableBytes} bytes\n"
          "Total memory: ${nxpInfo.totalOrUnknownBytes} bytes\n"
          "Volatile: ${nxpInfo.volatileBytes} bytes\n"
          "Reserved blocks: ${nxpInfo.reservedBlocks}"
          "$osInfoStr",
      isError: false,
    );
  }

  Future<void> _showRemoteReaderMenu() async {
    _log.info("_showRemoteReaderMenu called");
    final hasRemotes = AppSettings().remoCardUrls.isNotEmpty;
    _log.info("hasRemotes: $hasRemotes, URLs: ${AppSettings().remoCardUrls}");

    final result = await AdaptiveContextMenu.show<String>(
      context: context,
      anchorKey: _remoteReaderButtonKey,
      title: AppLocalizations.of(context)!.remoteReaders,
      items: [
        if (hasRemotes)
          AdaptiveContextMenuItem(
            label: AppLocalizations.of(context)!.connectRemotes,
            icon: Icons.link,
            value: 'connect',
          ),
        AdaptiveContextMenuItem(
          label: AppLocalizations.of(context)!.configureRemotes,
          icon: Icons.settings_outlined,
          value: 'manage',
        ),
      ],
    );

    if (result == 'connect') {
      await _connectRemoteReaders();
    } else if (result == 'manage') {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RemoteSettingsPage()),
        );
      }
    }
  }

  Future<void> _connectRemoteReaders({bool silent = false}) async {
    if (_rejectVoWifiConflict()) return;
    // Non-blocking background loading
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.connectingToRemoteReaders,
          ),
        ),
      );
    }

    try {
      final remoteReaders = await _adapter.loadRemoteReaders();

      if (remoteReaders.isEmpty) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noRemoteReadersFound),
            ),
          );
        }
      } else {
        // Add remote readers to the current list safely
        if (mounted) {
          setState(() {
            final updatedReaders = List<Reader>.from(_readers);
            bool changed = false;
            for (final remote in remoteReaders) {
              if (!updatedReaders.any((r) => r.id == remote.id)) {
                updatedReaders.add(remote);
                changed = true;
              }
            }

            if (changed) {
              _readers = updatedReaders;
              // Recreate tab controller if using tabs
              if (_readers.length < 3) {
                _recreateTabController(_readers);
              }
            }
          });

          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.connectedRemoteReaders(remoteReaders.length),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (await _handleInvalidPassword(e)) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _connectRemoteReaders(silent: silent);
        return;
      }
      if (!silent && mounted) {
        if (mounted) {
          setState(
            () => _error = AppLocalizations.of(
              context,
            )!.failedToConnectRemoteReaders(e.toString()),
          );
        }
      }
    }
  }

  Future<String?> _promptForRemotePassword({String? url}) async {
    if (!mounted) return null;

    // Ensure we are in a stable state
    await Future.delayed(Duration.zero);
    if (!mounted) return null;

    String password = "";

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.remoteReaderPassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (url != null)
                Text(
                  "${AppLocalizations.of(context)!.server}: $url",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (url != null) const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.remoteReaderPasswordSubtitle),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                autofocus: true,
                onChanged: (val) => password = val,
                onSubmitted: (val) => Navigator.pop(context, val),
              ),
            ],
          ),
        ),
        actions: [
          if (url != null)
            TextButton(
              onPressed: () => Navigator.pop(context, "DELETE_CONNECTION"),
              child: Text(
                AppLocalizations.of(context)!.deleteConnection,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            child: Text(AppLocalizations.of(context)!.connect),
          ),
        ],
      ),
    );
  }

  bool _isPrompting = false;

  Future<bool> _handleInvalidPassword(Object e) async {
    final errorStr = e.toString();

    if (e is RemoCardInvalidPasswordException ||
        errorStr.contains('RemoCardInvalidPasswordException') ||
        errorStr.contains('401')) {
      if (mounted && !_isPrompting) {
        _isPrompting = true;

        // Hide loading so it doesn't overlap with dialog
        if (mounted) {
          setState(() {
            _loading = false;
            _operationLoadingMessage = null;
          });
        }

        final baseUrl = (e is RemoCardInvalidPasswordException) ? e.url : null;
        String? targetUrl = baseUrl;
        if (targetUrl == null) {
          try {
            if (errorStr.contains('at ')) {
              final parts = errorStr.split('at ');
              if (parts.length > 1) {
                targetUrl = parts[1].split(' ').first.split(': ').first;
              }
            }
          } catch (_) {}
        }

        try {
          String? result;
          result = await _promptForRemotePassword(url: targetUrl);

          if (result == "DELETE_CONNECTION") {
            if (targetUrl != null) {
              await AppSettings().removeRemoCardUrl(targetUrl);
              await _loadReaders(skipLoading: true);
            }
            return false;
          }

          final password = result;
          if (password != null && password.isNotEmpty) {
            if (targetUrl != null) {
              try {
                final uri = Uri.parse(targetUrl);
                final newUri = uri.replace(userInfo: ':$password');
                final newUrl = newUri.toString();

                await AppSettings().removeRemoCardUrl(targetUrl);
                await AppSettings().addRemoCardUrl(newUrl);

                if (_selectedReader != null &&
                    (_selectedReader!.id.contains(targetUrl))) {
                  final newId = _selectedReader!.id.replaceFirst(
                    targetUrl,
                    newUrl,
                  );
                  _selectedReader = Reader(
                    id: newId,
                    name: _selectedReader!.name,
                    source: _selectedReader!.source,
                    context: _selectedReader!.context,
                    eid: _selectedReader!.eid,
                    aid: _selectedReader!.aid,
                    isEstkMax: _selectedReader!.isEstkMax,
                  );
                }
                await _loadReaders(skipLoading: true);
                return true;
              } catch (e) {
                _log.warning("Failed to update remote URL: $e");
              }
            }
          }
        } finally {
          _isPrompting = false;
        }
      }
    }
    return false;
  }

  Widget _buildReaderContent(
    BuildContext context,
    bool isWide,
    double padding,
    double paddingV,
    bool isLocked,
  ) {
    final theme = Theme.of(context);
    final reader = _selectedReader;

    if (_status == ReaderStatus.loading &&
        _profiles == null &&
        _error == null) {
      // The ProfileLoadingOverlay in the main Stack will handle this.
      // Return empty to avoid "double loading" message.
      return const SizedBox.shrink();
    }

    switch (_status) {
      case ReaderStatus.unsupported:
        return UnsupportedCardState(
          isTelephony: reader != null && _isTelephony(reader),
          isOmapi: reader != null && _isOmapi(reader),
          operatorIconBase64: _unsupportedOperatorIcon,
          fallbackDetails: _unsupportedFallbackDetails,
          onRetry: _listProfiles,
          onAboutAram: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AramInfoPage()),
          ),
        );
      case ReaderStatus.araMFailed:
        return AramFailedState(
          onRetry: _listProfiles,
          onAboutAram: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AramInfoPage()),
          ),
        );
      case ReaderStatus.noCard:
        return NoCardDetectedState(onRefresh: _listProfiles);
      case ReaderStatus.bleError:
        return BluetoothConnectionErrorState(
          error: _error?.toString(),
          onRetry: _listProfiles,
          onRemove: () {
            if (_rejectVoWifiConflict()) return;
            if (reader != null) {
              _adapter.removeReader(reader.id);
              _loadReaders(skipLoading: true);
              _updateReaderSession(reader.id, (s) {
                s.status = ReaderStatus.idle;
                s.lastError = null;
              });
            }
          },
        );
      case ReaderStatus.remoteError:
        return RemoteConnectionErrorState(
          error: _error?.toString(),
          onRetry: _listProfiles,
          onChangeSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RemoteSettingsPage()),
          ).then((_) => _loadReaders(skipLoading: true)),
        );
      case ReaderStatus.error:
        if (_error != null) {
          return _buildErrorState(
            context,
            _error!,
            onRetry: _listProfiles,
            onClear: () => setState(() => _error = null),
          );
        }
        break;
      default:
        break;
    }

    if (!_isSwitching && (_profiles == null && !_loading || _eid == null)) {
      return NotLoadedState(onLoad: _listProfiles);
    }

    if (_profiles!.isEmpty) {
      return NoProfilesState(onRefresh: _listProfiles);
    }

    final filteredProfiles = _getFilteredSortedProfiles();
    if (filteredProfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noProfilesMatch,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ProfileListSection(
      key: const PageStorageKey('profile_list'),
      profiles: filteredProfiles,
      eid: _eid,
      togglingIccid: _togglingIccid,
      deletingIccid: _deletingIccid,
      isWide: isWide,
      padding: padding,
      paddingV: paddingV,
      getCardKey: _getCardKey,
      isLocked: isLocked,
      onToggle: _toggleProfile,
      onMenu: (p, key) => _showProfileContextMenu(p, anchorKey: key),
      onTagTap: _openTagManager,
      onRefresh: _listProfiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettings();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final isMobileNarrow = PlatformX.isMobile && constraints.maxWidth < 600;
        bool useTabs =
            isMobileNarrow &&
            _readers.isNotEmpty &&
            _readers.length <= 2 &&
            !settings.forceDeviceDropdown &&
            !PlatformX.isMacOS &&
            _readers.every((r) => _isOmapi(r) || _isTmapi(r));

        final isExtremelySmall = constraints.maxWidth < 300;
        final padding = isWide
            ? 24.0
            : isExtremelySmall
            ? 8.0
            : 16.0;
        final paddingV = isExtremelySmall ? 2.0 : 6.0;

        final isLocked =
            _voWifiOwnsReader ||
            _isSwitching ||
            ProfilesScreen.isSwitchingGlobal ||
            _loading ||
            NotificationService().isProcessing.value;

        final reader = _selectedReader;
        String? currentModeText;
        String? alternativeModeText;
        VoidCallback? onSwitchMode;

        if (reader != null) {
          if (reader.isEstkMax) {
            final workingAid = (_manager.getWorkingAid(reader.id) ?? "")
                .toUpperCase();
            if (workingAid.endsWith("31")) {
              currentModeText = "SE1";
              alternativeModeText = "SE0";
            } else {
              currentModeText = "SE0";
              alternativeModeText = "SE1";
            }
            onSwitchMode = _switchEstkSlot;
          }
        }

        final actionContext = ReaderActionContext(
          adapter: _adapter,
          reader: _selectedReader,
          profiles: _profiles,
        );

        return Stack(
          children: [
            Scaffold(
              appBar: PreferredSize(
                preferredSize: isExtremelySmall
                    ? Size.fromHeight(40)
                    : Size.fromHeight(56),
                child: AppBar(
                  leadingWidth: isExtremelySmall ? 100 : 200,
                  leading: Padding(
                    padding: EdgeInsets.only(
                      left: isWide ? 20 : 12,
                      top: isExtremelySmall ? 4 : 8,
                      right: 0,
                      bottom: 0,
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppSettings().logoAsset, height: 24),
                        if (!AppSettings().isOnline)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.cloud_off_rounded,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                          ),
                        if (!isExtremelySmall) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8,
                              top: 0,
                              right: 0,
                              bottom: 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppSettings().appName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                    height: 0.9,
                                  ),
                                ),
                                Text(
                                  AppSettings().versionDisplay,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  actions: _buildAppBarActions(
                    context,
                    constraints.maxWidth,
                    isExtremelySmall,
                  ),
                  bottom: null,
                ),
              ),
              body: Column(
                children: [
                  ProfilesHeader(
                    isWide: isWide,
                    useTabs: useTabs,
                    isExtremelySmall: isExtremelySmall,
                    padding: padding,
                    paddingV: paddingV,
                    readers: _readers,
                    selectedReader: _selectedReader,
                    tabController: _tabController,
                    eid: _eid,
                    status: _isUnsupported
                        ? AppLocalizations.of(context)!.cardUnsupported
                        : (_isAraMFailed
                              ? AppLocalizations.of(context)!.accessDenied
                              : null),
                    info2: _info2,
                    showFullEid:
                        AppSettings().revealSensitiveProfileData ||
                        AppSettings().hasNoRedactionsConfigured,
                    downloadButtonKey1: _downloadButtonKey,
                    downloadButtonKey2: _downloadButtonKey2,
                    onReaderChanged: _selectReader,
                    onReaderRemove: (r) {
                      if (_rejectVoWifiConflict()) return;
                      _adapter.removeReader(r.id);
                      _loadReaders(skipLoading: true);
                    },
                    onReaderOpen: () => _loadReaders(skipLoading: true),
                    onDisconnect: _handleDisconnectAndRemove,
                    onToggleEidVisibility: _handleIdentifierVisibilityToggle,
                    onEidContextMenu: _showEidContextMenu,
                    onSwitchMode: onSwitchMode,
                    isLocked: isLocked,
                    currentMode: currentModeText,
                    alternativeMode: alternativeModeText,
                    onDownload: _eid != null ? _handleDownload : null,
                    onBatchDownload:
                        _eid != null && _selectedReader?.source is! SeHalAdapter
                        ? (key) => _handleBatchDownload(key)
                        : null,
                    onNotifications: _eid != null
                        ? () async {
                            if (_rejectVoWifiConflict()) return;
                            if (_selectedReader != null) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotificationsScreen(
                                    reader: _selectedReader!,
                                    initialEid: _eid,
                                  ),
                                ),
                              );
                              _loadPendingNotificationCount();
                            }
                          }
                        : null,
                    extraActions: _selectedReader == null || _voWifiOwnsReader
                        ? []
                        : PluginManager().buildReaderActions(
                            context,
                            actionContext,
                          ),
                    onRefreshNotifications: _loadPendingNotificationCount,
                  ),

                  // Search and Sort Row
                  if (_profiles != null &&
                      _profiles!.isNotEmpty &&
                      AppSettings().showProfileSearch)
                    RepaintBoundary(
                      child: ProfileSearchSortRow(
                        padding: padding,
                        onSearchChanged: (v) {
                          setState(() {
                            _searchQuery = v;
                            _filteredProfiles = null;
                          });
                        },
                      ),
                    ),

                  if (_pendingDeepLinkCode != null) _buildDeepLinkBanner(),

                  // Unified Messaging / Content Area
                  if (_selectedReader == null)
                    Expanded(
                      child: (_error != null && !_loading)
                          ? _buildErrorState(
                              context,
                              _error!,
                              onRetry: _loadReaders,
                              onClear: () => setState(() => _error = null),
                            )
                          : NoReadersState(
                              isLoading: _loading,
                              operationLoadingMessage: _operationLoadingMessage,
                              onConnectRemote: _connectRemoteReaders,
                              onReaderSelected: (id) async {
                                _log.info("onReaderSelected called for $id");
                                // Retry selection a few times as reader list might take a moment to propagate
                                for (int i = 0; i < 3; i++) {
                                  final reader = _readers
                                      .where((r) => r.id == id)
                                      .firstOrNull;
                                  if (reader != null) {
                                    _log.info("Found reader $id, selecting...");
                                    await _selectReader(reader);
                                    return;
                                  }
                                  _log.info(
                                    "Reader $id not found, reloading (attempt $i)...",
                                  );
                                  await _loadReaders(
                                    skipLoading: true,
                                    force: true,
                                  );
                                  await Future.delayed(
                                    Duration(milliseconds: 300 * (i + 1)),
                                  );
                                }
                                _log.warning(
                                  "Could not find reader $id after retries",
                                );
                              },
                              onReadersLoaded: () =>
                                  _loadReaders(skipLoading: true, force: true),
                              onScanStarted: () {
                                setState(() {
                                  _loading = true;
                                  _operationLoadingMessage =
                                      AppLocalizations.of(
                                        context,
                                      )!.initializing;
                                });
                              },
                            ),
                    )
                  else
                    Expanded(
                      child: ClipRect(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: _buildReaderContent(
                                context,
                                isWide,
                                padding,
                                paddingV,
                                isLocked,
                              ),
                            ),
                            Positioned.fill(
                              child: ValueListenableBuilder<bool>(
                                valueListenable:
                                    NotificationService().isFetching,
                                builder: (context, isFetching, _) {
                                  return ValueListenableBuilder<bool>(
                                    valueListenable:
                                        NotificationService().isProcessing,
                                    builder: (context, isProcessing, _) {
                                      return ProfileLoadingOverlay(
                                        isVisible:
                                            (_loading || _isListingProfiles) &&
                                            _readers.isNotEmpty &&
                                            !_isSwitching &&
                                            !ProfilesScreen.isSwitchingGlobal,
                                        message: _operationLoadingMessage,
                                        isFetchingNotifications: isFetching,
                                        isProcessingNotifications: isProcessing,
                                        onCancel: _isConnecting
                                            ? () {
                                                setState(() {
                                                  _loading = false;
                                                  _isListingProfiles = false;
                                                  _isConnecting = false;
                                                  _operationLoadingMessage =
                                                      null;
                                                });
                                                // Try to break stuck operation by disconnecting
                                                _adapter
                                                    .disconnect()
                                                    .catchError((_) {});
                                              }
                                            : null,
                                        onRetry: _listProfiles,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Developer-only: leaving developer mode hides the console
                  // again even if it was switched on while in it.
                  if (AppSettings().developerModeEnabled &&
                      AppSettings().showLogConsole)
                    Builder(
                      builder: (context) {
                        final maxConsole = (constraints.maxHeight - 140).clamp(
                          120.0,
                          double.infinity,
                        );
                        final height = _consoleHeight.clamp(120.0, maxConsole);
                        return SizedBox(
                          height: height,
                          child: LogConsole(
                            onClose: () async {
                              await AppSettings().setShowLogConsole(false);
                              if (mounted) setState(() {});
                            },
                            onResize: (dy) => setState(() {
                              // Dragging the handle up grows the console.
                              _consoleHeight = (height - dy).clamp(
                                120.0,
                                maxConsole,
                              );
                            }),
                          ),
                        );
                      },
                    ),
                ],
              ),
              floatingActionButton:
                  (_profiles?.isNotEmpty ?? false) && !PlatformX.isMobile
                  ? FloatingActionButton.extended(
                      onPressed: _listProfiles,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      icon: _loading
                          ? const LoadingSpinner(
                              size: 18,
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        AppLocalizations.of(context)!.refresh,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    VoidCallback? onClear,
  }) {
    // Use the new ErrorState widget
    return ErrorState(error: error, onRetry: onRetry ?? () {});
  }
}

class ProfileSearchSortRow extends StatelessWidget {
  final double padding;
  final ValueChanged<String> onSearchChanged;

  const ProfileSearchSortRow({
    super.key,
    required this.padding,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                onChanged: onSearchChanged,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: l10n.searchProfiles,
                  prefixIcon: const Icon(Icons.search, size: 16),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 38,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: AppSettings(),
            builder: (context, _) {
              final currentSort = AppSettings().profileSortType;
              final isAscending = AppSettings().sortAscending;

              String sortLabel;
              switch (currentSort) {
                case ProfileSortType.none:
                  sortLabel = l10n.sortDefault;
                  break;
                case ProfileSortType.nickname:
                  sortLabel = l10n.sortNickname;
                  break;
                case ProfileSortType.country:
                  sortLabel = l10n.sortCountry;
                  break;
                case ProfileSortType.iccid:
                  sortLabel = l10n.sortIccid;
                  break;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentSort != ProfileSortType.none) ...[
                    Material(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            AppSettings().setSortAscending(!isAscending),
                        child: Container(
                          height: 38,
                          width: 38,
                          alignment: Alignment.center,
                          child: Icon(
                            isAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PopupMenuButton<ProfileSortType>(
                    initialValue: currentSort,
                    tooltip: l10n.sortBy,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) => AppSettings().setProfileSortType(v),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              sortLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildSortItem(
                        ProfileSortType.none,
                        l10n.sortDefault,
                        currentSort,
                        theme,
                      ),
                      _buildSortItem(
                        ProfileSortType.nickname,
                        l10n.sortNickname,
                        currentSort,
                        theme,
                      ),
                      _buildSortItem(
                        ProfileSortType.country,
                        l10n.sortCountry,
                        currentSort,
                        theme,
                      ),
                      _buildSortItem(
                        ProfileSortType.iccid,
                        l10n.sortIccid,
                        currentSort,
                        theme,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  PopupMenuItem<ProfileSortType> _buildSortItem(
    ProfileSortType value,
    String label,
    ProfileSortType currentSort,
    ThemeData theme,
  ) {
    final isSelected = value == currentSort;
    return PopupMenuItem<ProfileSortType>(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
