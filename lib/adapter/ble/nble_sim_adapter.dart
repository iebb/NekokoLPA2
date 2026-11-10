import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ble/ble.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../euicc_adapter.dart';
import '../../utils/cat_proactive.dart';
import '../../utils/hex_utils.dart';
import '../../utils/error_codes.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart'; // To get navigatorKey
import 'ble_adapter.dart';
import 'ble_transport_utils.dart';

class NBLESimAdapter extends BaseAdapter implements BleAdapter {
  static final Logger _log = Logger('NBLESimAdapter');
  static const int _nativeFrameWriteSize = 101;
  static const int _webFrameWriteSize = 20;

  /// Bare `>> apdu` / `<< response` lines, in the same shape the Python CLI
  /// emits, so a run of either client can be diffed against the other.
  static final Logger _apduTrace = Logger('ApduTrace');
  static const String storedPasswordKeyPrefix = 'nble_sim_password_';

  NBLESimAdapter() : super(_log);

  static String storedPasswordKey(String deviceName) =>
      '$storedPasswordKeyPrefix${deviceName.trim()}';

  static String defaultPasswordForDeviceName(String deviceName) {
    final cleanName = deviceName.trim().toUpperCase();
    final suffix = cleanName.length <= 6
        ? cleanName
        : cleanName.substring(cleanName.length - 6);
    return suffix.split('').reversed.join();
  }

  /// Whether [password] is the password this device name derives by default.
  ///
  /// Both sides have to be reduced to what the writer actually authenticates
  /// with. A device name whose final six characters are not all hex digits
  /// derives a default that is itself hashed, so comparing a reduced password
  /// against the raw default would never match and would wrongly report a
  /// customized password as default.
  static bool isDefaultPasswordFor(String deviceName, String password) =>
      calculatePasswordHex(password) ==
      calculatePasswordHex(defaultPasswordForDeviceName(deviceName));

  static Future<List<NBLESimStoredPassword>> loadStoredPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = <NBLESimStoredPassword>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(storedPasswordKeyPrefix)) continue;

      final deviceName = key.substring(storedPasswordKeyPrefix.length).trim();
      final password = prefs.getString(key);
      if (deviceName.isEmpty || password == null || password.isEmpty) continue;

      records.add(
        NBLESimStoredPassword(deviceName: deviceName, password: password),
      );
    }
    records.sort(
      (a, b) =>
          a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase()),
    );
    return records;
  }

  static Future<void> savePasswordForDevice({
    required String previousDeviceName,
    required String deviceName,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final previousKey = storedPasswordKey(previousDeviceName);
    final newKey = storedPasswordKey(deviceName);
    if (previousDeviceName.trim().isNotEmpty && previousKey != newKey) {
      await prefs.remove(previousKey);
    }

    await prefs.setString(newKey, password.trim());
  }

  @visibleForTesting
  static bool allowsReconnectForApdu(Uint8List apdu) =>
      !(apdu.length >= 4 && apdu[1] == 0x70 && apdu[2] == 0x80);

  // UART service/characteristics
  final Guid uartService = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid uartNotify = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid uartWrite = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription? _rxSub;
  StreamSubscription? _connSub;
  final List<Uint8List> _rxQueue = [];
  Completer<void>? _rxSignal;
  AppException? _rxFailure;
  Timer? _idleTimer;
  int _transportGeneration = 0;
  bool _deviceConnected = false;
  bool _disconnectRequested = false;

  static const Duration _apduResponseTimeout = Duration(seconds: 30);
  static const String _testDisconnectAtApdusRaw = String.fromEnvironment(
    'NBLESIM_TEST_DISCONNECT_AT_APDUS',
  );
  static const String _testDisconnectAtBppBlocksRaw = String.fromEnvironment(
    'NBLESIM_TEST_DISCONNECT_AT_BPP_BLOCKS',
  );
  static const bool _testFaultsEnabled = bool.fromEnvironment(
    'NBLESIM_ENABLE_TEST_FAULTS',
  );
  final Set<int> _testDisconnectAtApdus = _testFaultsEnabled
      ? _parseTestDisconnectPoints(_testDisconnectAtApdusRaw)
      : const <int>{};
  final Set<int> _testDisconnectAtBppBlocks = _testFaultsEnabled
      ? _parseTestDisconnectPoints(_testDisconnectAtBppBlocksRaw)
      : const <int>{};
  final Set<int> _testDisconnectsTriggered = <int>{};
  final Set<int> _testBppDisconnectsTriggered = <int>{};
  int _testApduCount = 0;
  int _testBppBlockCount = 0;
  bool _testBppTransferArmed = false;

  bool _initialized = false;
  Uint8List? _authKey;
  int _nextCounter = 0;
  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  String? _devicePrefix;
  String? _deviceName;
  String? _password;
  bool _usingDefaultPassword = false;

  String? get devicePrefix => _devicePrefix;
  String? get deviceName => _deviceName;
  String? get password => _password;
  bool get usingDefaultPassword => _usingDefaultPassword;

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  // This card lives in a handset's SIM tray, so the modem -- not this app -- is
  // the terminal driving its toolkit session. Asking for the REFRESH is
  // therefore correct: the modem performs the UICC reset that makes the newly
  // enabled profile live, which nothing reachable over Bluetooth can do.
  //
  // Measured on a 9eSIM: committing without the refresh flag leaves the modem
  // on the previous profile, and answering the card's proactive commands from
  // here takes them away from the modem and breaks its SIM session.
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => null;

  @override
  NotificationStrategy get notificationStrategy => NotificationStrategy.twoStep;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    return connectedReader != null ? [connectedReader!] : [];
  }

  @override
  Future<void> connect(Reader reader) async {
    return await runExclusive(() async {
      _disconnectRequested = false;
      updateConnectedReader(reader);
      final readerName = reader.id;
      final parts = readerName.split('|');
      final deviceId = (parts.isNotEmpty ? parts.last : readerName).trim();
      final displayName = parts.isNotEmpty
          ? parts.first.split(':').last.trim()
          : readerName.trim();

      // Extract devicePrefix and deviceName for UI (last 6 chars is deviceName)
      final cleanName = displayName.trim();
      if (cleanName.length >= 6) {
        _deviceName = cleanName.substring(cleanName.length - 6).toUpperCase();
        _devicePrefix = cleanName.substring(0, cleanName.length - 6);
      } else {
        _deviceName = cleanName.toUpperCase();
        _devicePrefix = "";
      }

      _lastDeviceId = deviceId;
      _lastDeviceName = displayName;

      if (_initialized &&
          _linkReady &&
          _device!.remoteId.toString() == deviceId) {
        _log.fine("NBLESim transport is already connected.");
        return;
      }

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          // 1. Establish BLE connection and discover services if not already active
          if (_txChar == null ||
              _rxChar == null ||
              _device == null ||
              _device!.remoteId.toString() != deviceId) {
            _log.info(
              "Connecting to NBLESim device: $displayName ($deviceId) - Attempt ${attempt + 1}",
            );

            await _tearDownTransport(disconnectDevice: _device != null);
            final connectGeneration = _transportGeneration;

            _device = BluetoothDevice.fromId(deviceId);

            // Wait for Bluetooth adapter to be ready
            if (await Ble.adapterState.first != BluetoothAdapterState.on) {
              _log.info("Waiting for Bluetooth adapter to be ON...");
              reportConnectStep(ReaderConnectStep.waitingForBluetooth);
              await Ble.adapterState
                  .where((s) => s == BluetoothAdapterState.on)
                  .first
                  .timeout(
                    const Duration(seconds: 5),
                    onTimeout: () => throw AppException(
                      AppErrorCode.ERROR_BLUETOOTH_DISABLED,
                    ),
                  );
            }

            // This loop is the retry, so the link gets one try per pass and
            // the pass is the attempt worth showing.
            reportConnectStep(
              ReaderConnectStep.connectingBluetooth,
              attempt: attempt + 1,
              attempts: 3,
            );
            await connectBleDevice(
              _device!,
              _log,
              attempts: 1,
              preferredMtu: 185,
            );
            _deviceConnected = true;
            _ensureConnectActive(connectGeneration);

            reportConnectStep(ReaderConnectStep.discoveringServices);
            final services = await _device!.discoverServices();
            _ensureConnectActive(connectGeneration);
            final svc = services.firstWhere(
              (s) => s.uuid == uartService,
              orElse: () => throw AppException(
                AppErrorCode.ERROR_BLUETOOTH_SERVICE_NOT_FOUND,
                message: "NBLESim UART service not found",
              ),
            );

            _txChar = svc.characteristics.firstWhere(
              (c) => c.uuid == uartWrite,
            );
            _rxChar = svc.characteristics.firstWhere(
              (c) => c.uuid == uartNotify,
            );

            _rxSub = _rxChar!.onValueReceived.listen((data) {
              if (connectGeneration != _transportGeneration) return;
              _rxQueue.add(Uint8List.fromList(data));
              _signalRxWaiter();
            });
            reportConnectStep(ReaderConnectStep.enablingNotifications);
            await _rxChar!.setNotifyValue(true);
            _ensureConnectActive(connectGeneration);

            _connSub = _device!.connectionState.listen((state) {
              if (connectGeneration != _transportGeneration) return;
              _deviceConnected = state == BluetoothConnectionState.connected;
              if (state == BluetoothConnectionState.disconnected) {
                _log.info("NBLESim device disconnected.");
                _failPendingTransport(
                  AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
                  "NBLESim disconnected during an active command",
                  generation: connectGeneration,
                );
                _txChar = null;
                _rxChar = null;
                _stateController.add(EuiccPortState.closed);
                final dropped = _device;
                if (dropped != null) {
                  unawaited(_releaseLostLink(dropped));
                }
              }
            });
          }

          // 2. Perform Handshake
          // Handshake needs password
          final prefs = await SharedPreferences.getInstance();
          final storedPass = prefs.getString(storedPasswordKey(displayName));
          final hasStoredPassword = storedPass?.trim().isNotEmpty ?? false;
          String password = hasStoredPassword
              ? storedPass!.trim()
              : _buildDefaultPassword(displayName);
          _authKey = _buildAuthKey(password);
          final handshakeGeneration = _transportGeneration;

          reportConnectStep(ReaderConnectStep.authenticating);
          try {
            await _performHandshake(handshakeGeneration);
            await prefs.setString(storedPasswordKey(displayName), password);
            _password = password;
            _usingDefaultPassword = isDefaultPasswordFor(displayName, password);
          } on AppException catch (e) {
            if (e.code != AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD) rethrow;

            _log.warning("NBLESim wrong password, prompting for new one.");
            final savedPass = await _promptForNewPassword();
            // User cancelled or provided an empty password.
            if (savedPass == null) rethrow;

            // Store the new password before proving it. The writer issues one
            // challenge per link and the rejected attempt already consumed it,
            // so the password usually cannot be proven until the next
            // connection -- which reads it back from here. Persisting only
            // after a successful handshake would discard every password the
            // user types and fall back to the device default forever.
            await prefs.setString(
              storedPasswordKey(displayName),
              savedPass.trim(),
            );
            _password = savedPass;
            _usingDefaultPassword = isDefaultPasswordFor(
              displayName,
              savedPass,
            );
            _authKey = _buildAuthKey(savedPass);

            try {
              await _performHandshake(handshakeGeneration);
            } catch (retryError) {
              if (attempt == 2) rethrow;
              _log.info(
                "Handshake could not be retried on this link ($retryError); "
                "reconnecting so the writer issues a fresh challenge.",
              );
              _txChar = null;
              _rxChar = null;
              await _tearDownTransport(disconnectDevice: true);
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
          }

          // 3. Mode verification and auto-switch
          reportConnectStep(ReaderConnectStep.initializing);
          final currentMode = await getDeviceMode();
          _ensureConnectActive(handshakeGeneration);
          final refreshing =
              refreshingUntil != null &&
              DateTime.now().isBefore(refreshingUntil!);
          if (currentMode == 1 && refreshing) {
            // A profile state change is in flight. The writer drops to SIM
            // mode while it has no profile to serve, and forcing it back now
            // interrupts the reset the host's modem is performing.
            _log.info(
              "Writer is in SIM mode during a profile state change; leaving "
              "the mode alone.",
            );
          } else if (currentMode == 1) {
            _log.info("NBLESim in SIM mode, auto-switching to eUICC mode...");
            reportConnectStep(ReaderConnectStep.switchingMode);
            try {
              // Send switch command
              await _transmitCommand(
                HexUtils.hexToBytes("FE0C020001"),
                "set_mode",
              );
            } catch (e) {
              _log.warning(
                "Mode switch command sent but might have failed or device reset: $e",
              );
            }

            // Clean up and wait for reboot
            _initialized = false;
            _txChar = null;
            _rxChar = null;
            await _device?.disconnect().catchError((_) {});

            _log.info("Waiting for NBLESim to reboot into eUICC mode...");
            reportConnectStep(ReaderConnectStep.waitingForRestart);
            await Future.delayed(const Duration(seconds: 4));
            continue; // Retry connection in loop
          }

          // 4. Finalize
          if (!_linkReady) {
            throw AppException(
              AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
              message: "NBLESim disconnected while finalizing the handshake",
            );
          }
          _initialized = true;
          _stateController.add(EuiccPortState.open);
          _log.info("NBLESim successfully connected in eUICC mode.");
          return;
        } catch (e) {
          _log.warning("NBLESim connect attempt ${attempt + 1} failed: $e");

          if (_disconnectRequested) rethrow;

          if (e is AppException &&
              e.code == AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD) {
            await disconnect();
            rethrow;
          }

          if (attempt == 2) {
            // Last attempt failed, clean up and rethrow
            await disconnect();
            if (e is AppException) rethrow;
            throw AppException(
              AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
              originalError: e,
            );
          }

          // Reset characteristics to force discovery/connect on next attempt
          _txChar = null;
          _rxChar = null;
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    });
  }

  /// Releases a link the writer dropped on its own.
  ///
  /// Failing the in-flight command is not enough: the peripheral handle stays
  /// live, so CoreBluetooth keeps the pending connection and silently re-takes
  /// the writer the moment it comes back. A held peripheral does not advertise,
  /// so the card disappears from every later scan and cannot be reconnected
  /// until the app is restarted. Handing the peripheral back releases it.
  ///
  /// [connectedReader] and the last-device fields are deliberately left alone:
  /// [_transmitInternal] reconnects through them mid-transfer.
  Future<void> _releaseLostLink(BluetoothDevice device) async {
    if (_disconnectRequested) return;
    // A reconnect may already have swapped in a fresh peripheral; only the
    // handle that actually dropped should be handed back.
    if (!identical(_device, device)) return;
    _log.info("Releasing the dropped NBLESim link so the writer advertises.");
    try {
      await _tearDownTransport(disconnectDevice: true);
    } catch (error) {
      _log.fine("NBLESim lost-link cleanup failed: $error");
    }
  }

  @override
  Future<void> disconnect() async {
    _disconnectRequested = true;
    _failPendingTransport(
      AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
      "NBLESim was disconnected",
    );
    return await runExclusive(() async {
      await _tearDownTransport(disconnectDevice: true);
      _authKey = null;
      updateConnectedReader(null);
      _stateController.add(EuiccPortState.closed);
    });
  }

  @override
  void interruptPendingOperation() {
    _disconnectRequested = true;
    _failPendingTransport(
      AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
      'NBLESim operation deadline exceeded',
    );
  }

  @override
  List<AdapterAction> get extraActions {
    return [
      AdapterAction(
        icon: Icons.edit_note_rounded,
        label: "Customize",
        onPressed: (BuildContext context) =>
            NBLESimManageUI.showManagementDialog(context, this),
        key: "manage_nble_sim",
      ),
    ];
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    return await _transmitInternal(apdu, allowsReconnectForApdu(apdu));
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    // Provide a default AID if none specified, similar to GlocalMe
    final targetAids = (aids == null || aids.isEmpty)
        ? ["A0000005591010FFFFFFFF8900000100"]
        : aids;
    return await openLogicalChannel(aids: targetAids);
  }

  Future<int> getDeviceMode() async {
    try {
      final resp = await _transmitCommand(
        HexUtils.hexToBytes("FE0D000001"),
        "get_mode",
      );
      // Response format: [mode] [90] [00]
      // mode 0x01 = SIM, 0x02 = eUICC
      if (resp.length >= 3) {
        return resp[0];
      }
    } catch (e) {
      _log.warning("Failed to get NBLESim mode: $e");
      if (e is AppException &&
          (_isTransportFailure(e) ||
              e.code == AppErrorCode.ERROR_TRANSACTION_FAILED)) {
        rethrow;
      }
    }
    return 0; // Unknown
  }

  @override
  Future<List<AdapterMode>> getAvailableModes(Reader reader) async {
    return await super.getAvailableModes(reader);
  }

  @override
  Future<void> switchMode(Reader reader, AdapterMode mode) async {
    await super.switchMode(reader, mode);
  }

  static const int _swOk = 0x9000;
  static const int _swConditionsNotSatisfied = 0x6985;

  /// "Instruction not supported": the card answered, so it is alive even
  /// though it does not implement the command.
  static const int _swInsNotSupported = 0x6D00;

  @override
  Future<void> proactiveRefresh() async {
    // Called after a refresh-flagged profile switch and on recovery. The modem
    // resets the card to apply the switch, so the job here is to wait that out
    // rather than to answer anything.
    await _settleCard(reason: "proactive refresh");
  }

  @override
  Future<void> resetAfterProfileSwitch() async {
    // Never restart the writer just because a switch happened. This transport
    // cannot cleanly power cycle the card, and cutting its interface while the
    // eUICC is still committing a profile state change can roll that change
    // back and leave the card with nothing enabled at all -- which a handset
    // reports as a SIM failure. Only act when the card is actually stuck.
    await _settleCard(reason: "profile switch");
  }

  /// Waits for a window in which the card owes its terminal nothing.
  ///
  /// A card in a powered handset raises a proactive command every few seconds
  /// and the modem answers it. Those commands belong to the modem, so wait for
  /// a gap rather than answering them.
  @visibleForTesting
  Future<bool> waitForIdleWindow({
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final int sw;
      try {
        sw = _statusWord(
          await _transceiveControl(CatProactive.status(), "cat-status"),
        );
      } catch (e) {
        _log.info(
          "Card stopped answering while waiting for an idle window: $e",
        );
        return false;
      }
      if (sw == _swOk) return true;
      // Anything that is not "busy with a proactive command" will not clear by
      // waiting.
      if (sw >> 8 != 0x91) return false;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// How long the adapter stays completely silent before it first checks
  /// whether the reset has finished.
  ///
  /// Measured on a 9eSIM writer the card returns 25-31s after the commit, but
  /// only if nothing is talking to it meanwhile, so this floor is deliberately
  /// below the fast end: it costs one wasted probe on a quick card and buys an
  /// early finish on one. Nothing at all goes out before it elapses.
  @visibleForTesting
  static Duration settleQuietFloor = const Duration(seconds: 20);

  /// Longest the adapter keeps waiting for the card to report itself idle.
  /// A host slower than the one this was measured on gets the time it needs
  /// rather than being handed a card that is still mid-reset.
  @visibleForTesting
  static Duration settleMaxWait = const Duration(seconds: 150);

  /// Silence between checks. Doubles up to [settleMaxProbeGap] each time the
  /// card is not ready, so a slow host is not polled at a fixed rate.
  @visibleForTesting
  static Duration settleProbeGap = const Duration(seconds: 5);

  @visibleForTesting
  static Duration settleMaxProbeGap = const Duration(seconds: 20);

  Future<void> _settleCard({required String reason}) async {
    // Let go of the writer completely, including the idle ping that keeps this
    // link alive. Measured: while the app holds the Bluetooth session open the
    // card stays mid-transition at 6999 indefinitely, and the modem never gets
    // to reset it. The command-line tool has no keepalive, its link drops when
    // the reset happens, and the card is back within ~20s.
    //
    // Everything stronger was measured to make things worse: answering the
    // card's proactive commands takes them from the modem that owns them, and
    // restarting or mode-cycling the writer mid state change leaves the card
    // refusing the ISD-R until the SIM is re-seated.
    _log.info(
      "Releasing the writer after $reason so the host can reset the card...",
    );

    // Keep the keepalive and the SIM-mode correction suppressed for however
    // long this actually takes, not just the window a caller marked.
    final suppressUntil = DateTime.now().add(
      settleMaxWait + const Duration(seconds: 30),
    );
    if (refreshingUntil == null || refreshingUntil!.isBefore(suppressUntil)) {
      refreshingUntil = suppressUntil;
    }

    await runExclusive(() async {
      await _tearDownTransport(disconnectDevice: true);
    });

    await Future.delayed(settleQuietFloor);

    final started = DateTime.now();
    final deadline = started.add(settleMaxWait);
    var gap = settleProbeGap;
    while (true) {
      final sw = await _probeSettled();
      final waited = settleQuietFloor + DateTime.now().difference(started);
      if (sw == _swOk) {
        _log.info(
          "Card reported idle ${waited.inSeconds}s after the commit; the "
          "reset has finished.",
        );
        return;
      }
      final seen = sw == null ? "no answer" : "SW=${_swText(sw)}";
      if (!DateTime.now().isBefore(deadline)) {
        _log.warning(
          "Card had not reported idle ${waited.inSeconds}s after the commit "
          "($seen); continuing anyway so the caller can decide.",
        );
        return;
      }
      _log.info(
        "Card is not back yet ($seen); staying off the air for another "
        "${gap.inSeconds}s.",
      );
      await runExclusive(() async {
        await _tearDownTransport(disconnectDevice: true);
      });
      await Future.delayed(gap);
      final doubled = gap * 2;
      gap = doubled > settleMaxProbeGap ? settleMaxProbeGap : doubled;
    }
  }

  /// Sends a single bare STATUS to see whether the card is back, and nothing
  /// else.
  ///
  /// Deliberately minimal: an APDU trace of a client that switches this card
  /// reliably shows it sending exactly this while a REFRESH is pending,
  /// whereas re-opening a session -- channel cleanup, TERMINAL CAPABILITY,
  /// MANAGE CHANNEL, SELECT AID -- is what leaves the card refusing its ISD-R
  /// until it is physically re-seated.
  ///
  /// Returns the status word, or null when the card did not answer at all,
  /// which during a reset is the expected case rather than a failure.
  Future<int?> _probeSettled() async {
    try {
      return await runExclusive(() async {
        return _statusWord(
          await _transceiveControl(CatProactive.status(), "settle-status"),
        );
      });
    } catch (error) {
      _log.fine("Settle probe did not reach the card: $error");
      return null;
    }
  }

  /// Answers any proactive command the card is waiting on.
  ///
  /// Returns true when the card needs a real reset to settle, either because it
  /// asked for one or because the exchange did not clear its state.
  @visibleForTesting
  Future<bool> completePendingProactiveCommands() async {
    var cardAskedForReset = false;
    for (var attempt = 0; attempt < 6; attempt++) {
      final statusSw = _statusWord(
        await _transceiveControl(CatProactive.status(), "cat-status"),
      );
      // Idle: report whether a reset was requested along the way.
      if (statusSw == _swOk) return cardAskedForReset;

      final int fetchLength;
      if (statusSw >> 8 == 0x91) {
        fetchLength = statusSw & 0xFF;
      } else if (statusSw == _swConditionsNotSatisfied) {
        // Some eUICCs refuse STATUS while a profile state change owns the card
        // but still hand over the command that is blocking it.
        fetchLength = 0x00;
      } else {
        _log.info(
          "STATUS returned ${_swText(statusSw)}; the card needs a restart.",
        );
        return true;
      }

      final fetchResponse = await _transceiveControl(
        CatProactive.fetch(fetchLength),
        "cat-fetch",
      );
      final fetchSw = _statusWord(fetchResponse);
      if (fetchSw != _swOk) {
        _log.info(
          "FETCH returned ${_swText(fetchSw)}; the card needs a restart.",
        );
        return true;
      }

      final details = CatProactive.parseFetchResponse(fetchResponse);
      final decision = details.decision;
      _log.info("Card is waiting on $details, decision: ${decision.name}.");

      if (decision == CatResponseDecision.restartNaaSession) {
        // Actually perform it before reporting it done: dropping every logical
        // channel ends the application session, which is what a terminal does
        // for this REFRESH. The modem otherwise stays on the old profile.
        _log.info("Restarting the NAA session before acknowledging REFRESH.");
        try {
          await cleanupChannels();
        } catch (e) {
          _log.fine("Channel cleanup during the NAA session reset failed: $e");
        }
      }

      // Every fetched command gets an answer, including one asking for a reset
      // this reader cannot perform. Leaving the session unanswered is what
      // makes the card refuse everything afterwards and takes the writer off
      // the air with it; declining is honest and releases the card.
      final performed =
          decision == CatResponseDecision.acknowledgeSuccess ||
          decision == CatResponseDecision.restartNaaSession;
      final responseSw = _statusWord(
        await _transceiveControl(
          CatProactive.terminalResponse(
            details,
            generalResult: performed
                ? CatProactive.resultSuccess
                : CatProactive.resultUnableToProcess,
          ),
          "cat-terminal-response",
        ),
      );
      if (decision == CatResponseDecision.requiresCardReset) {
        // Note it, but keep draining: a card that raised one command usually
        // has more queued behind it, and stopping here strands them. Measured
        // on hardware, a stranded command takes the writer off the air.
        _log.info(
          "Card asked for a reset this reader cannot perform; declined it and "
          "kept draining.",
        );
        cardAskedForReset = true;
      }
      // 91xx means the card immediately queued another command, so loop again.
      if (responseSw != _swOk && responseSw >> 8 != 0x91) {
        _log.info(
          "TERMINAL RESPONSE returned ${_swText(responseSw)}; "
          "the card needs a restart.",
        );
        return true;
      }
    }

    _log.warning("Card kept queueing proactive commands; restarting it.");
    return true;
  }

  /// Writer mode 2: serving the enabled profile and manageable over BLE.
  static const int _modeEuicc = 2;

  @override
  Future<bool?> isServingProfile() async {
    try {
      final mode = await getDeviceMode();
      if (mode == 0) return null;
      // Mode 1 is the fallback card the writer presents when it has no usable
      // profile to serve, so it doubles as a direct readout of whether a
      // switch actually produced something the handset can use.
      return mode == _modeEuicc;
    } catch (e) {
      _log.info("Could not read the writer mode: $e");
      return null;
    }
  }

  @override
  Future<bool?> isCatBusy() async {
    try {
      final sw = _statusWord(
        await _transceiveControl(CatProactive.status(), "cat-status"),
      );
      if (sw == _swOk) return false;
      // The card answered and simply does not implement STATUS here. It is not
      // busy, and reporting otherwise makes the pre-switch guard refuse a
      // perfectly healthy card.
      if (sw == _swInsNotSupported) return false;
      // 91xx is ordinary traffic between the card and its modem, not a fault:
      // it clears within seconds. Callers wait for a gap rather than refusing.
      if (sw >> 8 == 0x91) return true;
      // 6985/6999 mean a state change owns the card; a switch started now
      // could not be completed.
      if (sw == _swConditionsNotSatisfied || sw == 0x6999) return true;
      _log.info("STATUS returned ${_swText(sw)}; cannot tell if it is busy.");
      return null;
    } catch (e) {
      _log.info("Could not determine whether the card is busy: $e");
      return null;
    }
  }

  /// Sends a control APDU, reassembling 61xx and retrying 6Cxx responses.
  Future<Uint8List> _transceiveControl(Uint8List apdu, String label) async {
    var current = apdu;
    final accumulated = BytesBuilder();
    for (var attempt = 0; attempt < 8; attempt++) {
      final response = await sendRawApdu(current);
      final sw = _statusWord(response);
      if (sw >> 8 == 0x61) {
        accumulated.add(response.sublist(0, response.length - 2));
        current = Uint8List.fromList([current[0], 0xC0, 0x00, 0x00, sw & 0xFF]);
        continue;
      }
      if (sw >> 8 == 0x6C) {
        current = Uint8List.fromList([
          ...current.sublist(0, current.length - 1),
          sw & 0xFF,
        ]);
        continue;
      }
      accumulated.add(response);
      return accumulated.toBytes();
    }
    throw AppException(
      AppErrorCode.ERROR_TRANSACTION_FAILED,
      message: "NBLESim $label did not finish reassembling a response",
    );
  }

  static int _statusWord(Uint8List response) => response.length < 2
      ? -1
      : (response[response.length - 2] << 8) | response[response.length - 1];

  static String _swText(int sw) => sw < 0
      ? "a truncated response"
      : "SW=${sw.toRadixString(16).padLeft(4, '0').toUpperCase()}";

  Future<void> _performHandshake(int generation) async {
    if (_authKey == null) {
      throw AppException(
        AppErrorCode.ERROR_UNKNOWN,
        message: "Auth key not initialized",
      );
    }

    final challenge = await _waitForFrame(
      (p) => p.length >= 17 && p[0] == 0xE0,
      const Duration(seconds: 5),
      "challenge",
      generation: generation,
    );
    _log.info(
      "Handshake challenge received: ${HexUtils.bytesToHex(challenge)}",
    );

    final block = challenge.sublist(1, 17);
    final plain = _tripleDesEcb(block, _authKey!, decrypt: true);

    int counter = (plain[7] | (plain[8] << 8)) & 0xFFFF;
    final oldCounter = counter;
    counter = (counter + 1) & 0xFFFF;
    _log.info("Counter incremented from $oldCounter to $counter");

    plain[7] = counter & 0xFF;
    plain[8] = (counter >> 8) & 0xFF;
    _log.info("Block with new counter: ${HexUtils.bytesToHex(plain)}");

    final responseBlock = _tripleDesEcb(plain, _authKey!, decrypt: false);
    final payload = Uint8List(1 + responseBlock.length);
    payload[0] = 0xE0;
    payload.setAll(1, responseBlock);

    _log.info("Sending handshake response: ${HexUtils.bytesToHex(payload)}");
    await _writeFrame(payload);

    final ack = await _waitForFrame(
      (p) => p.length >= 3 && p[0] == 0xE0 && (p[1] == 0x90 || p[1] == 0x6A),
      const Duration(seconds: 5),
      "auth ack",
      generation: generation,
    );
    _log.info("Handshake ACK received: ${HexUtils.bytesToHex(ack)}");

    final sw = HexUtils.bytesToHex(ack.sublist(1, 3)).toUpperCase();
    if (sw == "6A86") {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_WRONG_PASSWORD,
        message: "NBLESim wrong password",
      );
    }
    if (sw == "6881" || sw == "6A81" || sw == "6A82") {
      throw AppException(
        AppErrorCode.ERROR_REMOTE_AUTH_FAILED,
        message: "NBLESim auth failed SW=$sw",
      );
    }
    _log.info("Handshake successful");
    _nextCounter = 0;
    _resetIdleTimer();
  }

  String? _lastDeviceId;
  String? _lastDeviceName;

  Future<Uint8List> _transmitInternal(
    Uint8List apdu,
    bool allowReconnect,
  ) async {
    if (_disconnectRequested) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: "NBLESim was explicitly disconnected",
      );
    }
    if (!_initialized) {
      if (!allowReconnect) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'NBLESim stale channel close skipped while disconnected',
        );
      }
      if (connectedReader == null) {
        // Try to reconnect using stored device info
        if (_lastDeviceId != null && _lastDeviceName != null) {
          _log.info(
            "No reader selected, attempting to reconnect to last device: $_lastDeviceName",
          );

          try {
            // Create a reader from the stored device info
            final reader = Reader(
              id: "$_lastDeviceName | $_lastDeviceId",
              name: _lastDeviceName!,
              source: this,
            );

            _log.info("Attempting to reconnect to: $_lastDeviceName");
            await connect(reader);
            return await _transmitCommand(apdu, "apdu");
          } catch (e) {
            _log.warning("Failed to reconnect to device: $e");
            // If reconnection failed, throw BLE disconnected error
            throw AppException(
              AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
              message: "BLE device disconnected and reconnection failed",
              originalError: e,
            );
          }
        }

        // If we don't have stored device info, throw BLE disconnected error
        _log.severe("Cannot reconnect: No device information available");
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: "BLE device disconnected and cannot be found",
        );
      }
      await connect(connectedReader!);
    }

    return await _transmitCommand(apdu, "apdu");
  }

  Future<Uint8List> _transmitCommand(Uint8List apdu, String label) async {
    _idleTimer?.cancel();
    final commandGeneration = _transportGeneration;
    try {
      _ensureTransportActive(commandGeneration, label);
      _rxQueue.clear();
      _rxFailure = null;

      final counter = _nextCounter;
      _nextCounter = (_nextCounter + 1) & 0xFF;

      // Web Bluetooth writes are capped at 20 bytes by writeBleChunks. Keep
      // each NBLE protocol frame within that write so its header, counter and
      // checksum are never split across independent GATT operations.
      final frames = encodeFramesForTransport(
        counter,
        apdu,
        maxWriteSize: kIsWeb ? _webFrameWriteSize : _nativeFrameWriteSize,
      );
      _apduTrace.fine(() => ">> ${HexUtils.bytesToHex(apdu)}");
      _log.fine(
        () =>
            "[NBLESim $label] TX counter=${counter.toRadixString(16)} len=${apdu.length} apdu=${HexUtils.bytesToHex(apdu)} frames=${frames.length} frames=${frames.map((f) => HexUtils.bytesToHex(f)).join(", ")}",
      );
      for (final f in frames) {
        _ensureTransportActive(commandGeneration, label);
        await _writeFrame(f);
      }

      await _maybeInjectTestDisconnect(label, apdu);
      _ensureTransportActive(commandGeneration, label);

      final respFrames = await _waitForResponseFrames(
        counter: counter,
        generation: commandGeneration,
        timeout: _apduResponseTimeout,
        description: "$label resp",
      );

      final decoded = _decodeFrames(respFrames);
      if (decoded.counter != counter) {
        throw AppException(
          AppErrorCode.ERROR_TRANSACTION_FAILED,
          message:
              "NBLESim response counter mismatch: expected $counter, "
              "received ${decoded.counter}",
        );
      }
      final apduResp = decoded.apdu;
      _apduTrace.fine(() => "<< ${HexUtils.bytesToHex(apduResp)}");

      final sw1 = apduResp[apduResp.length - 2];
      final sw2 = apduResp[apduResp.length - 1];
      final sw =
          "${sw1.toRadixString(16).padLeft(2, '0')}"
          "${sw2.toRadixString(16).padLeft(2, '0')}";

      if (!((sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x91 || sw1 == 0x61)) {
        _log.fine(() => "[NBLESim $label] RX status SW=$sw");
      } else {
        _log.fine(
          () =>
              "[NBLESim $label] RX success apdu=${HexUtils.bytesToHex(apduResp)} SW=$sw",
        );
      }

      return apduResp;
    } catch (error, stackTrace) {
      if (error is AppException && _isTransportFailure(error)) {
        _failPendingTransport(
          error.code,
          error.message ?? error.toString(),
          generation: commandGeneration,
        );
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (error is AppException &&
          error.code == AppErrorCode.ERROR_TRANSACTION_FAILED) {
        _failPendingTransport(
          AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
          "NBLESim protocol state became invalid",
          generation: commandGeneration,
        );
        Error.throwWithStackTrace(
          AppException(
            AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
            message: "NBLESim protocol response was invalid",
            originalError: error,
          ),
          stackTrace,
        );
      }
      _failPendingTransport(
        AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
        "NBLESim transport failed during $label",
        generation: commandGeneration,
      );
      Error.throwWithStackTrace(
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
          message: "NBLESim transport failed during $label",
          originalError: error,
        ),
        stackTrace,
      );
    } finally {
      _resetIdleTimer();
    }
  }

  Future<List<Uint8List>> _waitForResponseFrames({
    required int counter,
    required int generation,
    required Duration timeout,
    required String description,
  }) async {
    final deadline = DateTime.now().add(timeout);
    final frames = <Uint8List>[];
    final first = await _waitForResponseStart(
      counter: counter,
      generation: generation,
      deadline: deadline,
      description: description,
    );
    frames.add(first);

    var expectedSequence = 1;
    var current = first;
    while ((current[0] & 0x20) == 0) {
      current = await _waitForFrame(
        (_) => true,
        _remaining(deadline),
        description,
        generation: generation,
      );
      if (current.isEmpty || (current[0] & 0x1F) != expectedSequence) {
        throw AppException(
          AppErrorCode.ERROR_TRANSACTION_FAILED,
          message:
              "NBLESim response frame sequence mismatch: expected "
              "$expectedSequence",
        );
      }
      frames.add(current);
      expectedSequence = (expectedSequence + 1) & 0x1F;
    }
    return frames;
  }

  Future<Uint8List> _waitForResponseStart({
    required int counter,
    required int generation,
    required DateTime deadline,
    required String description,
  }) async {
    while (true) {
      final first = await _waitForFrame(
        (_) => true,
        _remaining(deadline),
        description,
        generation: generation,
      );
      if (first.length < 2 || (first[0] & 0x1F) != 0) {
        throw AppException(
          AppErrorCode.ERROR_TRANSACTION_FAILED,
          message: "NBLESim response did not start with frame sequence 0",
        );
      }
      if (first[1] == counter) return first;

      _log.fine(
        "Discarding stale NBLESim response for counter ${first[1]} "
        "while waiting for $counter",
      );
      var stale = first;
      while ((stale[0] & 0x20) == 0) {
        stale = await _waitForFrame(
          (_) => true,
          _remaining(deadline),
          "stale $description",
          generation: generation,
        );
        if (stale.isEmpty) {
          throw AppException(
            AppErrorCode.ERROR_TRANSACTION_FAILED,
            message: "NBLESim stale response contained an empty frame",
          );
        }
      }
    }
  }

  Duration _remaining(DateTime deadline) {
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!_initialized) return;
    // No keepalive while a profile state change is being applied: holding the
    // link open stops the host from resetting the card.
    if (refreshingUntil != null && DateTime.now().isBefore(refreshingUntil!)) {
      return;
    }
    _idleTimer = Timer(const Duration(seconds: 12), _sendIdlePing);
  }

  Future<void> _sendIdlePing() async {
    if (!_initialized) return;
    try {
      await runExclusive(() async {
        if (!_initialized) return;
        await _transmitCommand(
          HexUtils.hexToBytes("99980000FB0000"),
          "idle-ping",
        );
      });
    } catch (e) {
      _log.warning("Idle ping failed: $e");
    }
  }

  Future<void> _writeFrame(Uint8List frame) async {
    if (_txChar == null || _device == null || !_deviceConnected) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: "NBLESim not connected",
      );
    }
    try {
      await writeBleChunks(
        device: _device!,
        characteristic: _txChar!,
        data: frame,
        maxChunkSize: 180,
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains("device is not connected") ||
          errStr.contains("not_connected")) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          originalError: e,
        );
      }
      rethrow;
    }
  }

  Future<Uint8List> _waitForFrame(
    bool Function(Uint8List) match,
    Duration timeout,
    String description, {
    int? generation,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      for (var i = 0; i < _rxQueue.length; i++) {
        final frame = _rxQueue[i];
        if (match(frame)) {
          _rxQueue.removeAt(i);
          return frame;
        }
      }

      final failure = _rxFailure;
      if (failure != null) {
        _rxFailure = null;
        throw failure;
      }

      if (generation != null) {
        _ensureTransportActive(generation, description);
      }

      final now = DateTime.now();
      if (now.isAfter(deadline)) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: "NBLESim waitForFrame timeout: $description",
        );
      }

      final signal = Completer<void>();
      _rxSignal = signal;
      // A notification or disconnect can land after the queue/failure checks
      // above but before the waiter is installed. Recheck once the completer is
      // visible so that event cannot be lost and turn into a false timeout.
      final transportChanged =
          generation != null &&
          (generation != _transportGeneration || !_linkReady);
      if (_rxQueue.any(match) || _rxFailure != null || transportChanged) {
        signal.complete();
      }
      try {
        await signal.future.timeout(deadline.difference(now));
      } on TimeoutException {
        // Re-enter the loop so it reports the typed timeout above.
      } finally {
        if (identical(_rxSignal, signal)) _rxSignal = null;
      }
    }
  }

  void _signalRxWaiter() {
    final signal = _rxSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
  }

  bool get _linkReady =>
      _deviceConnected &&
      _device != null &&
      _txChar != null &&
      _rxChar != null &&
      _rxSub != null &&
      _connSub != null;

  Future<void> _tearDownTransport({required bool disconnectDevice}) async {
    _transportGeneration++;
    _initialized = false;
    _deviceConnected = false;
    _testBppTransferArmed = false;
    _idleTimer?.cancel();
    _idleTimer = null;

    final rxSub = _rxSub;
    final connSub = _connSub;
    final device = _device;
    _rxSub = null;
    _connSub = null;
    _device = null;
    _txChar = null;
    _rxChar = null;
    _rxQueue.clear();
    _rxFailure = null;
    _signalRxWaiter();

    try {
      await rxSub?.cancel();
    } catch (error) {
      _log.fine("NBLESim RX listener cleanup failed: $error");
    }
    try {
      await connSub?.cancel();
    } catch (error) {
      _log.fine("NBLESim connection listener cleanup failed: $error");
    }
    if (disconnectDevice && device != null) {
      try {
        await device.disconnect();
      } catch (error) {
        _log.fine("NBLESim GATT disconnect cleanup failed: $error");
      }
    }
  }

  void _failPendingTransport(
    AppErrorCode code,
    String message, {
    int? generation,
  }) {
    if (generation != null && generation != _transportGeneration) return;
    _transportGeneration++;
    _initialized = false;
    _deviceConnected = false;
    _testBppTransferArmed = false;
    _txChar = null;
    _rxChar = null;
    _rxFailure = AppException(code, message: message);
    _rxQueue.clear();
    _signalRxWaiter();
  }

  void _ensureTransportActive(int generation, String description) {
    if (generation == _transportGeneration && _linkReady) {
      return;
    }
    throw _rxFailure ??
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: "NBLESim transport interrupted during $description",
        );
  }

  void _ensureConnectActive(int generation) {
    if (!_disconnectRequested &&
        generation == _transportGeneration &&
        _deviceConnected) {
      return;
    }
    throw _rxFailure ??
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: "NBLESim connection attempt was interrupted",
        );
  }

  bool _isTransportFailure(AppException error) =>
      error.code == AppErrorCode.ERROR_BLUETOOTH_TIMEOUT ||
      error.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED ||
      error.code == AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED;

  Future<void> _maybeInjectTestDisconnect(String label, Uint8List apdu) async {
    if (label != "apdu") return;

    final triggeredFaults = <String>[];

    if (_testDisconnectAtApdus.isNotEmpty) {
      _testApduCount++;
      if (_testDisconnectAtApdus.contains(_testApduCount) &&
          _testDisconnectsTriggered.add(_testApduCount)) {
        triggeredFaults.add("APDU $_testApduCount");
      }
    }

    final isBppStoreData =
        apdu.length >= 4 &&
        apdu[1] == 0xE2 &&
        (apdu[2] == 0x11 || apdu[2] == 0x91);
    if (isBppStoreData && _testDisconnectAtBppBlocks.isNotEmpty) {
      if (_apduDataStartsWithBppRoot(apdu)) {
        _testBppTransferArmed = true;
        _testBppBlockCount = 0;
      }
      if (_testBppTransferArmed) {
        _testBppBlockCount++;
        if (_testDisconnectAtBppBlocks.contains(_testBppBlockCount) &&
            _testBppDisconnectsTriggered.add(_testBppBlockCount)) {
          triggeredFaults.add("BPP STORE DATA block $_testBppBlockCount");
        }
      }
    }

    if (triggeredFaults.isEmpty) return;

    final faultDescription = triggeredFaults.join(" and ");

    _log.warning("NBLESim test fault: disconnecting after $faultDescription");
    final generation = _transportGeneration;
    await _device?.disconnect();
    _failPendingTransport(
      AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
      "NBLESim test fault disconnected after $faultDescription",
      generation: generation,
    );
  }

  static Set<int> _parseTestDisconnectPoints(String raw) => raw
      .split(',')
      .map((value) => int.tryParse(value.trim()))
      .whereType<int>()
      .where((value) => value > 0)
      .toSet();

  static bool _apduDataStartsWithBppRoot(Uint8List apdu) {
    final dataOffset = _apduDataOffset(apdu);
    return dataOffset != null &&
        apdu.length >= dataOffset + 2 &&
        apdu[dataOffset] == 0xBF &&
        apdu[dataOffset + 1] == 0x36;
  }

  static int? _apduDataOffset(Uint8List apdu) {
    if (apdu.length < 5) return null;

    final shortLength = apdu[4];
    if (shortLength != 0) {
      return apdu.length >= 5 + shortLength ? 5 : null;
    }

    if (apdu.length < 7) return null;
    final extendedLength = (apdu[5] << 8) | apdu[6];
    if (extendedLength == 0 || apdu.length < 7 + extendedLength) return null;
    return 7;
  }

  String _buildDefaultPassword(String name) {
    return defaultPasswordForDeviceName(name);
  }

  Future<String?> _promptForNewPassword() async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _log.severe("Cannot prompt for NBLESim password: no navigator context");
      return null;
    }

    String password = "";
    bool obscureText = true;
    final l10n = AppLocalizations.of(context)!;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateBuilder) => AlertDialog(
          title: Text(l10n.remoteReaderPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.authFailedCheckPassword),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.password,
                  hintText: l10n.devicePasswordHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setStateBuilder(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                obscureText: obscureText,
                autofocus: true,
                onChanged: (val) => password = val,
                onSubmitted: (val) => Navigator.pop(context, val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
              child: Text(l10n.ok),
            ),
          ],
        ),
      ),
    );
  }

  static String calculatePasswordHex(String value) {
    if (value.trim().length == 6 &&
        RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value.trim())) {
      return value.trim().toUpperCase();
    }

    // Use original case-sensitive, whitespace-preserved string for CRC24 derivation
    int crc = 0xB704CE;
    final bytes = utf8.encode(value);
    for (int b in bytes) {
      crc ^= (b << 16);
      for (int i = 0; i < 8; i++) {
        crc <<= 1;
        if ((crc & 0x1000000) != 0) {
          crc ^= 0x1864CFB;
        }
      }
    }

    return (crc & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Uint8List _buildAuthKey(String password) {
    // Auth password is the exactly calculated hex version
    String passUsed = calculatePasswordHex(password);

    // Auth base derives from the last 2 characters of the deviceName identifier and the parsed password.
    String last2 = _deviceName!.substring(_deviceName!.length - 2);
    final authBase = last2 + passUsed;
    final hex = "$authBase$authBase${authBase}00000000";

    // Enough to tell a wrong device suffix from a wrongly reduced password
    // without writing the key itself to the log.
    _log.fine(
      "Derived auth key from device suffix $last2 and a "
      "${passUsed.length}-character password hex "
      "(${passUsed == password.trim().toUpperCase() ? 'verbatim' : 'hashed'})",
    );
    return HexUtils.hexToBytes(hex);
  }

  Uint8List _tripleDesEcb(
    Uint8List data,
    Uint8List key, {
    required bool decrypt,
  }) {
    final engine = pc.DESedeEngine();
    final cipher = pc.ECBBlockCipher(engine);
    cipher.init(!decrypt, pc.KeyParameter(key));
    final out = Uint8List(data.length);
    var offset = 0;
    while (offset < data.length) {
      offset += cipher.processBlock(data, offset, out, offset);
    }
    return out;
  }

  static int _sumCheck(Uint8List payload) {
    var total = 0;
    for (final b in payload) {
      total = (total + (b & 0xFF)) & 0xFFFF;
    }
    return total;
  }

  @visibleForTesting
  static List<Uint8List> encodeFramesForTransport(
    int counter,
    Uint8List apdu, {
    required int maxWriteSize,
  }) {
    if (maxWriteSize < 2) {
      throw ArgumentError.value(
        maxWriteSize,
        'maxWriteSize',
        'must leave room for an NBLE frame header and payload',
      );
    }

    final builder = BytesBuilder(copy: false);
    builder.addByte(counter & 0xFF);
    builder.add(apdu);
    final body = builder.takeBytes();

    final fullBuilder = BytesBuilder(copy: false);
    fullBuilder.add(body);
    final sum = _sumCheck(body);
    fullBuilder.addByte((sum >> 8) & 0xFF);
    fullBuilder.addByte(sum & 0xFF);
    final full = fullBuilder.takeBytes();

    final frames = <Uint8List>[];
    var seq = 0;
    final chunkLen = maxWriteSize - 1;
    for (var offset = 0; offset < full.length;) {
      final len = (full.length - offset) < chunkLen
          ? (full.length - offset)
          : chunkLen;
      final chunk = Uint8List.sublistView(full, offset, offset + len);
      offset += len;
      final last = offset >= full.length;
      final header = (last ? 0x20 : 0x00) | (seq & 0x1F);
      seq = (seq + 1) & 0x1F;
      final frame = Uint8List(1 + chunk.length);
      frame[0] = header;
      frame.setAll(1, chunk);
      frames.add(frame);
    }
    return frames;
  }

  _DecodedFrames _decodeFrames(List<Uint8List> frames) {
    final builder = BytesBuilder(copy: false);
    for (final f in frames) {
      builder.add(Uint8List.sublistView(f, 1));
    }
    final buf = builder.takeBytes();

    if (buf.length < 3) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: "NBLESim payload too short",
      );
    }
    final raw = Uint8List.sublistView(buf, 0, buf.length - 2);
    final checksum = (buf[buf.length - 2] << 8) | buf[buf.length - 1];
    final expected = _sumCheck(raw);
    final valid = checksum == expected;
    if (!valid) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message:
            "NBLESim checksum mismatch: got ${checksum.toRadixString(16)}, "
            "expected ${expected.toRadixString(16)}",
      );
    }
    final counter = raw[0];
    final apdu = Uint8List.sublistView(raw, 1);
    if (apdu.length < 2) {
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: "NBLESim APDU too short",
      );
    }
    return _DecodedFrames(counter: counter, apdu: apdu);
  }
}

class _DecodedFrames {
  final int counter;
  final Uint8List apdu;

  _DecodedFrames({required this.counter, required this.apdu});
}

class NBLESimStoredPassword {
  const NBLESimStoredPassword({
    required this.deviceName,
    required this.password,
  });

  final String deviceName;
  final String password;
}

class NBLESimManageUI {
  static Future<void> showManagementDialog(
    BuildContext context,
    BaseAdapter adapter,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ManageDialog(adapter: adapter),
    );
  }
}

class _ManageDialog extends StatefulWidget {
  final BaseAdapter adapter;
  const _ManageDialog({required this.adapter});

  @override
  State<_ManageDialog> createState() => _ManageDialogState();
}

class _ManageDialogState extends State<_ManageDialog> {
  bool _loading = true;
  String? _error;
  late TextEditingController _nameController;
  late TextEditingController _passController;
  final Logger _log = Logger('ManageDialog');
  String _namePrefix = "";
  String _fullDeviceName = "";
  String _initialName = "";
  String _initialPassword = "";
  bool _usingDefaultPassword = false;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final info = await _getDeviceCredentials();
      if (!mounted) return;

      setState(() {
        _nameController = TextEditingController(text: info['name']);
        _passController = TextEditingController(text: info['password']);
        _nameController.addListener(() => setState(() {}));
        _passController.addListener(() => setState(() {}));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        // If read fails (e.g., 6D00), just allow user to write.
        _log.info("Read failed, but allowing write: $e");
        setState(() {
          _nameController = TextEditingController(text: "");
          _passController = TextEditingController(text: "");
          _nameController.addListener(() => setState(() {}));
          _passController.addListener(() => setState(() {}));
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, String>> _getDeviceCredentials() async {
    if (widget.adapter is NBLESimAdapter) {
      final nble = widget.adapter as NBLESimAdapter;
      // Get deviceName prefix
      final fullName = nble.connectedReader?.name ?? "";
      final deviceName = nble.deviceName ?? "";
      _initialName = deviceName;
      _initialPassword = nble.password ?? "";
      _usingDefaultPassword = nble.usingDefaultPassword;
      if (fullName.toUpperCase().endsWith(deviceName.toUpperCase()) &&
          deviceName.isNotEmpty) {
        _namePrefix = fullName.substring(
          0,
          fullName.length - deviceName.length,
        );
      } else {
        _namePrefix = "";
      }

      _fullDeviceName = fullName.trim().isNotEmpty
          ? fullName.trim()
          : '$_namePrefix$deviceName';

      // if deviceName and password is null, fallback to empty
      return {"name": nble.deviceName ?? "", "password": nble.password ?? ""};
    }
    _fullDeviceName = "";
    _initialName = "";
    _initialPassword = "";
    _usingDefaultPassword = false;
    return {"name": "", "password": ""};
  }

  bool _passwordWasNotChanged(String password) {
    return password.trim() == _initialPassword.trim() ||
        NBLESimAdapter.calculatePasswordHex(password) ==
            NBLESimAdapter.calculatePasswordHex(_initialPassword);
  }

  Future<String?> _passwordForUpdate(
    BuildContext context,
    String newName,
  ) async {
    final password = _passController.text;
    final nameChanged = newName.toUpperCase() != _initialName.toUpperCase();
    final isRenameOnly =
        _usingDefaultPassword &&
        nameChanged &&
        _passwordWasNotChanged(password);
    if (!isRenameOnly) return password;

    final newDefaultPassword = NBLESimAdapter.defaultPasswordForDeviceName(
      newName,
    );
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.defaultPasswordWillChangeTitle),
        content: Text(
          l10n.defaultPasswordWillChangeMessage(newDefaultPassword),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    return confirmed == true ? newDefaultPassword : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Reading device info..."),
          ],
        ),
      );
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text("Failed to read writer"),
        content: Text(_error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(l10n.customize),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.customizeDescription),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.deviceName,
              hintText: "123456",
              border: const OutlineInputBorder(),
              prefixText: _namePrefix,
              prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-fA-F0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passController,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: l10n.password,
              hintText: l10n.devicePasswordHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.password),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePass = !_obscurePass;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed:
              _nameController.text.length == 6 &&
                  _passController.text.isNotEmpty
              ? () async {
                  final newName = _nameController.text.toUpperCase();
                  final passwordInput = await _passwordForUpdate(
                    context,
                    newName,
                  );
                  if (passwordInput == null || !context.mounted) return;

                  final navigatorContext = Navigator.of(
                    context,
                    rootNavigator: true,
                  ).context;
                  Navigator.pop(context); // Close this dialog

                  // Show a global loading or just process
                  _performUpdate(navigatorContext, newName, passwordInput);
                }
              : null, // Grey out if condition unmet
          child: Text(l10n.ok),
        ),
      ],
    );
  }

  Future<void> _performUpdate(
    BuildContext context,
    String newName,
    String passwordInput,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final newPass = NBLESimAdapter.calculatePasswordHex(passwordInput);
    final newFullDeviceName = '$_namePrefix$newName';

    // Show a small processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await widget.adapter.runExclusive(() async {
        final payload = "111111$newName$newPass";
        Uint8List resp;
        try {
          resp = await widget.adapter.sendRawApdu(
            HexUtils.hexToBytes("3027000009$payload"),
          );
          if (HexUtils.bytesToHex(resp).endsWith("6E00")) {
            throw Exception("CLA 0x30 not supported");
          }
        } catch (e) {
          _log.info("CLA 0x30 write failed, trying 0x80: $e");
          resp = await widget.adapter.sendRawApdu(
            HexUtils.hexToBytes("8027000009$payload"),
          );
        }

        final hex = HexUtils.bytesToHex(resp).toUpperCase();
        if (!hex.endsWith("9000") &&
            !hex.endsWith("6100") &&
            !hex.contains("9000")) {
          if (hex != "9000") {
            throw Exception("Update failed with response: $hex");
          }
        }
      });

      await NBLESimAdapter.savePasswordForDevice(
        previousDeviceName: _fullDeviceName,
        deviceName: newFullDeviceName,
        password: passwordInput,
      );

      if (context.mounted) {
        Navigator.pop(context); // Remove progress
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.success),
            content: Text(l10n.customizeSuccess),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove progress
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.failed),
            content: Text(l10n.customizeFailed(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    }
  }
}
