import 'dart:math';
import 'dart:async';
import 'package:ble/ble.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../euicc_adapter.dart';
import '../../utils/hex_utils.dart';
import '../../utils/error_codes.dart';
import 'ble_adapter.dart';
import 'bee_sim_command_pacer.dart';
import 'ble_transport_utils.dart';

/// Reports current firmware-row progress while [BeeSimAdapter.uploadFirmware]
/// streams data to the device. Carries the row index and the total number of
/// rows reported by the upstream upgrade-check response.
class BeeSimUpgradeStatus {
  const BeeSimUpgradeStatus({
    required this.crc,
    required this.totalRows,
    required this.currentRow,
  });

  final String crc;
  final int totalRows;
  final int currentRow;

  @override
  String toString() =>
      'BeeSimUpgradeStatus(crc=$crc, totalRows=$totalRows, currentRow=$currentRow)';
}

class BeeSimAdapter extends BaseAdapter implements BleAdapter {
  static final Logger _log = Logger('BeeSimAdapter');

  BeeSimAdapter() : super(_log);

  /// The JS client's `groupValue()` floor: a 20-byte frame is 2 bytes of
  /// `[total, index]` header plus 18 of payload. That is the BLE 4.0 minimum
  /// ATT payload, not a limit of the writer, so it is only the fallback.
  static const int _minFramePayload = 18;

  /// Upper bound on a frame, matching the MTU asked for at connect (247 - 3).
  static const int _maxFrameLength = 244;

  /// Frame payload for the current link.
  ///
  /// One frame has to land in one GATT write: the writer reassembles on the
  /// `[total, index]` header, so a frame split across two writes arrives as
  /// two malformed ones. Native links can carry the negotiated MTU, but
  /// [writeBleChunks] caps web writes at 20 bytes whatever the MTU says, so
  /// web stays on the floor rather than being split.
  int get _framePayload {
    final device = _device;
    if (kIsWeb || device == null) return _minFramePayload;
    final frameLength = calculateBleWriteChunkSize(
      device.mtuNow,
      maxChunkSize: _maxFrameLength,
    );
    return max(_minFramePayload, frameLength - 2);
  }

  /// Service used purely for documentation — discovery uses TX/RX char hints.
  /// JS picks the first writable + first notify-only characteristic, so we do
  /// the same and only treat AE01/AE02 as preference hints.
  final Guid serviceUuid = Guid('0000ae30-0000-1000-8000-00805f9b34fb');

  BluetoothDevice? _device;
  String? _deviceId;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription? _rxSub;
  StreamSubscription? _connSub;
  bool _isBeeSimConnected = false;
  bool _isConnecting = false;
  bool _disconnectRequested = false;
  bool _portIsOpen = false;
  final List<Uint8List> _rxQueue = [];
  Completer<void>? _rxSignal;
  AppException? _rxFailure;
  Future<void>? _pendingRxCleanup;
  int _transportGeneration = 0;
  bool _lastCommandFullyTransmitted = false;
  final BeeSimCommandPacer _commandPacer = BeeSimCommandPacer();

  String? _lastAtr;
  bool _initialized = false;
  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  final List<int> _rxBuffer = [];

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => _lastAtr;

  @override
  NotificationStrategy get notificationStrategy => NotificationStrategy.twoStep;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    return connectedReader != null ? [connectedReader!] : [];
  }

  @override
  Future<void> connect(Reader reader) async {
    final readerParts = reader.id.split('|');
    final requestedDeviceId = readerParts.isNotEmpty
        ? readerParts.last
        : reader.id;
    if (_deviceId != requestedDeviceId ||
        (!_transportReady && !_isConnecting)) {
      _cancelPendingCommand('BeeSIM is reconnecting.');
    }
    final connectGeneration = _transportGeneration;

    return await runExclusive(() async {
      if (connectGeneration != _transportGeneration) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'BeeSIM connection was cancelled.',
        );
      }
      _disconnectRequested = false;
      final deviceId = requestedDeviceId;

      if (_deviceId == deviceId && _transportReady) {
        updateConnectedReader(reader);
        _log.fine('BeeSIM device is already connected: $deviceId');
        return;
      }

      await _tearDown(
        clearReader: false,
        disconnectDevice: true,
        emitClosed: true,
      );
      updateConnectedReader(reader);
      _deviceId = deviceId;
      _device = BluetoothDevice.fromId(deviceId);
      _isConnecting = true;

      _log.info("Connecting to BeeSIM device: $deviceId");
      try {
        if (await Ble.adapterState.first != BluetoothAdapterState.on) {
          _log.info("Waiting for Bluetooth adapter to be ON...");
          reportConnectStep(ReaderConnectStep.waitingForBluetooth);
          await Ble.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () =>
                    throw AppException(AppErrorCode.ERROR_BLUETOOTH_DISABLED),
              );
        }
        _ensureConnectActive(connectGeneration);

        await connectBleDevice(_device!, _log, progress: connectProgress);
        _ensureConnectActive(connectGeneration);

        _isBeeSimConnected = true;
        _connSub = _device!.connectionState.listen((s) {
          if (s == BluetoothConnectionState.disconnected) {
            _handleUnexpectedDisconnect(deviceId);
          } else if (s == BluetoothConnectionState.connected &&
              _deviceId == deviceId &&
              connectGeneration == _transportGeneration &&
              !_disconnectRequested) {
            _isBeeSimConnected = true;
          }
        });

        reportConnectStep(ReaderConnectStep.discoveringServices);
        final services = await _device!.discoverServices();
        _ensureConnectActive(connectGeneration);

        // Mirror the JS client: pick the first writable characteristic for TX
        // and the first notify-or-indicate one that is NOT the writer for RX.
        // AE01/AE02 are preferred hints when present.
        BluetoothCharacteristic? writerHinted;
        BluetoothCharacteristic? notifierHinted;
        BluetoothCharacteristic? writerFallback;
        BluetoothCharacteristic? notifierFallback;

        for (var svc in services) {
          for (var c in svc.characteristics) {
            final uuid = c.uuid.toString().toLowerCase();
            final canWrite =
                c.properties.write || c.properties.writeWithoutResponse;
            final canNotify = c.properties.notify || c.properties.indicate;
            if (uuid.contains('ae01') && canWrite) {
              writerHinted = c;
            } else if (uuid.contains('ae02') && canNotify) {
              notifierHinted = c;
            } else if (canWrite && writerFallback == null) {
              writerFallback = c;
            } else if (canNotify && notifierFallback == null) {
              notifierFallback = c;
            }
          }
        }
        _txChar = writerHinted ?? writerFallback;
        _rxChar = notifierHinted ?? notifierFallback;
        if (_txChar != null) {
          _log.info("BeeSIM TX characteristic: ${_txChar!.uuid}");
        }
        if (_rxChar != null) {
          _log.info("BeeSIM RX characteristic: ${_rxChar!.uuid}");
        }

        if (_txChar == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: "BeeSIM write characteristic not found",
          );
        }
        if (_rxChar == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: "BeeSIM notify characteristic not found",
          );
        }

        reportConnectStep(ReaderConnectStep.enablingNotifications);
        await _rxChar!.setNotifyValue(true);
        _ensureConnectActive(connectGeneration);
        await Future.delayed(const Duration(milliseconds: 200));
        _ensureConnectActive(connectGeneration);

        _rxSub = _rxChar!.onValueReceived.listen((data) {
          if (data.length < 2) return;
          final total = data[0];
          final index = data[1];
          if (index == 1) {
            _rxBuffer.clear();
          }
          _rxBuffer.addAll(data.sublist(2));
          if (index == total) {
            final frame = Uint8List.fromList(_rxBuffer);
            _rxQueue.add(frame);
            if (_rxSignal != null && !_rxSignal!.isCompleted) {
              _rxSignal!.complete();
            }
          }
        });

        // BeeSIM's actual profile-install flow resets its command counter and
        // raises TX power to level 4. Keeping that level for this app session
        // covers every download entry point and avoids a weaker long transfer.
        _log.info("Initializing BeeSIM...");
        reportConnectStep(ReaderConnectStep.initializing);
        _commandPacer.reset();
        await _sendCommand(
          Uint8List.fromList([0xA0, 0x3E, 0x04, 0x00, 0x00]),
          "set power",
        );
        _ensureConnectActive(connectGeneration);

        _initialized = true;
        _emitPortState(EuiccPortState.open);
      } catch (e) {
        _log.severe("BeeSIM connect failed: $e");
        await _tearDown(
          clearReader: true,
          disconnectDevice: true,
          emitClosed: true,
        );
        rethrow;
      } finally {
        _isConnecting = false;
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _disconnectRequested = true;
    _cancelPendingCommand(
      'BeeSIM was disconnected.',
      code: AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
    );
    return await runExclusive(() async {
      await _tearDown(
        clearReader: true,
        disconnectDevice: true,
        emitClosed: true,
      );
    });
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    return await runExclusive(() async {
      if (_disconnectRequested) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'BeeSIM was disconnected.',
        );
      }
      if (!_transportReady) {
        if (connectedReader == null) {
          throw AppException(
            AppErrorCode.ERROR_UNKNOWN,
            message: "Not connected",
          );
        }
        await connect(connectedReader!);
      }
      return await _sendCommand(apdu, "apdu");
    });
  }

  static const _standardAid = "A0000005591010FFFFFFFF8900000100";

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await openLogicalChannel(aids: [_standardAid]);
  }

  @override
  Future<void> proactiveRefresh() async {
    _log.info("Proactive refresh: Sending BeeSIM reset command...");
    try {
      await _sendCommand(
        Uint8List.fromList([0xA0, 0x3F, 0x00, 0x00, 0x00]),
        "reset",
      );
    } catch (e) {
      _log.warning("Proactive refresh reset command failed: $e");
    }
  }

  /// Sends the firmware "check upgrade" probe and parses the response.
  ///
  /// Mirrors `checkUpgrading()` in beesim.js: the device answers with
  /// `[0x10, ...]` on success; bytes 49..50 are the crc, 51..52 totalRows,
  /// 53..54 currentRow (all big-endian).
  Future<BeeSimUpgradeStatus> checkUpgrading() async {
    return await runExclusive(() async {
      await _ensureConnected();
      final resp = await _sendCommand(
        Uint8List.fromList([0x00, 0x00, 0x00, 0x00, 0xF4, 0x01, 0x01]),
        'check upgrading',
      );
      if (resp.isEmpty || resp[0] != 0x10) {
        throw AppException(
          AppErrorCode.ERROR_UNKNOWN,
          message:
              'BeeSIM upgrade check failed: '
              '${resp.isEmpty ? '<empty>' : HexUtils.bytesToHex(resp)}',
        );
      }
      if (resp.length < 55) {
        throw AppException(
          AppErrorCode.ERROR_UNKNOWN,
          message:
              'BeeSIM upgrade check response too short (${resp.length} bytes)',
        );
      }
      final crc = HexUtils.bytesToHex(resp.sublist(49, 51));
      final totalRows = _beU16(resp, 51);
      final currentRow = _beU16(resp, 53);
      return BeeSimUpgradeStatus(
        crc: crc,
        totalRows: totalRows,
        currentRow: currentRow,
      );
    });
  }

  /// Writes a single firmware row coming back from the upgrade endpoint.
  /// The wire format is `<total:u16><index:u16><row bytes>` per the JS client
  /// (`r = Ee(total) + Ee(index) + row` then `sendCommand(r)`).
  ///
  /// Returns true if the device echoed the expected success marker
  /// (`resp[0] == 0x10 && resp[3] == 0x01`).
  Future<bool> writeFirmwareRow({
    required int totalRows,
    required int currentRow,
    required Uint8List rowBytes,
  }) async {
    return await runExclusive(() async {
      await _ensureConnected();
      final header = Uint8List(4)
        ..[0] = (totalRows >> 8) & 0xFF
        ..[1] = totalRows & 0xFF
        ..[2] = (currentRow >> 8) & 0xFF
        ..[3] = currentRow & 0xFF;
      final payload = Uint8List(header.length + rowBytes.length)
        ..setRange(0, header.length, header)
        ..setRange(header.length, header.length + rowBytes.length, rowBytes);
      final resp = await _sendCommand(payload, 'fw row $currentRow/$totalRows');
      return resp.length >= 4 && resp[0] == 0x10 && resp[3] == 0x01;
    });
  }

  /// Issues the BLE reset command (`A0 3F 00 00 00`) and clears local
  /// initialised state so the next APDU re-opens a channel.
  ///
  /// The device usually drops the BLE link as it reboots, so a timeout or
  /// connect-failed reply is expected and not treated as an error.
  Future<void> resetDevice() async {
    return await runExclusive(() async {
      try {
        await _sendCommand(
          Uint8List.fromList([0xA0, 0x3F, 0x00, 0x00, 0x00]),
          'reset',
        );
      } on AppException catch (e) {
        if (e.code != AppErrorCode.ERROR_BLUETOOTH_TIMEOUT &&
            (e.code != AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED ||
                !_lastCommandFullyTransmitted)) {
          rethrow;
        }
        _log.info('Reset acknowledged by disconnect (${e.code.name}).');
      } finally {
        _initialized = false;
      }
    });
  }

  Future<void> _ensureConnected() async {
    if (_disconnectRequested) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: 'BeeSIM was disconnected.',
      );
    }
    if (_initialized && _isBeeSimConnected && _txChar != null) return;
    final reader = connectedReader;
    if (reader == null) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: 'BeeSIM reader is not selected.',
      );
    }
    await connect(reader);
  }

  int _beU16(Uint8List bytes, int offset) =>
      ((bytes[offset] & 0xFF) << 8) | (bytes[offset + 1] & 0xFF);

  Future<Uint8List> _sendCommand(Uint8List data, String label) async {
    return await runExclusive(() => _sendCommandLocked(data, label));
  }

  Future<Uint8List> _sendCommandLocked(Uint8List data, String label) async {
    _lastCommandFullyTransmitted = false;
    _rxQueue.clear();
    _rxFailure = null;
    final framePayload = _framePayload;
    final frames = _encodeFrames(data, framePayload);
    _log.fine(
      () =>
          "[BeeSIM $label] TX len=${data.length} data=${HexUtils.bytesToHex(data)}",
    );

    final txChar = _txChar;
    final device = _device;
    if (txChar == null || device == null) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
        message: "BeeSIM TX characteristic is not available",
      );
    }
    final bool withoutResp =
        txChar.properties.writeWithoutResponse && !txChar.properties.write;
    final commandGeneration = _transportGeneration;

    try {
      final cooledDown = await _commandPacer.beforeCommand();
      if (cooledDown) {
        _log.fine('BeeSIM command burst complete; waited 1.2s before $label.');
      }
      _ensureCommandActive(commandGeneration);

      for (var i = 0; i < frames.length; i++) {
        _ensureCommandActive(commandGeneration);
        final f = frames[i];
        _log.fine(
          () =>
              "[BeeSIM $label] TX frame ${i + 1}/${frames.length} len=${f.length} data=${HexUtils.bytesToHex(f)}",
        );
        await writeBleChunks(
          device: device,
          characteristic: txChar,
          data: f,
          maxChunkSize: framePayload + 2,
        );
        if (i == frames.length - 1) {
          _lastCommandFullyTransmitted = true;
        }
        _ensureCommandActive(commandGeneration);
        if (!withoutResp && frames.length > 1) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      final resp = await _waitForResponse(const Duration(seconds: 100), label);
      _log.fine(
        () =>
            "[BeeSIM $label] RX len=${resp.length} data=${HexUtils.bytesToHex(resp)}",
      );
      return resp;
    } catch (_) {
      // A failed GATT write has the same uncertain transport state as a
      // response timeout. Never reuse its characteristics for another APDU.
      _initialized = false;
      rethrow;
    }
  }

  bool get _transportReady =>
      _initialized &&
      _isBeeSimConnected &&
      _device != null &&
      _txChar != null &&
      _rxChar != null &&
      _rxSub != null;

  void _handleUnexpectedDisconnect(String deviceId) {
    if (_deviceId != deviceId || (!_isBeeSimConnected && !_initialized)) {
      return;
    }

    _log.warning("BeeSIM disconnected unexpectedly");
    _cancelPendingCommand(
      "The connection has timed out unexpectedly.",
      code: AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
    );
    _txChar = null;
    _rxChar = null;
    _rxQueue.clear();
    _rxBuffer.clear();
    _commandPacer.reset();

    final rxSub = _rxSub;
    _rxSub = null;
    if (rxSub != null) {
      _pendingRxCleanup = _cancelRxSubscription(rxSub);
      unawaited(_pendingRxCleanup);
    }

    _emitPortState(EuiccPortState.closed);

    final dropped = _device;
    if (dropped != null) {
      unawaited(_releaseLostLink(dropped));
    }
  }

  /// Releases a link the writer dropped on its own.
  ///
  /// Clearing the characteristics is not enough: the peripheral handle stays
  /// live, so CoreBluetooth keeps the pending connection and silently re-takes
  /// the writer the moment it comes back. A held peripheral does not
  /// advertise, so the card disappears from every later scan and cannot be
  /// reconnected until the app is restarted. Handing the peripheral back
  /// releases it.
  ///
  /// [connectedReader] is deliberately kept: [sendRawApdu] reconnects through
  /// it mid-transfer.
  Future<void> _releaseLostLink(BluetoothDevice dropped) async {
    if (_disconnectRequested) return;
    // A reconnect builds a fresh peripheral for the same id, so compare the
    // handle rather than the id: only the one that dropped may be released.
    if (!identical(_device, dropped)) return;
    _log.info('Releasing the dropped BeeSIM link so the writer advertises.');
    try {
      await _tearDown(
        clearReader: false,
        disconnectDevice: true,
        emitClosed: false,
      );
    } catch (error) {
      _log.fine('BeeSIM lost-link cleanup failed: $error');
    }
  }

  void _cancelPendingCommand(
    String message, {
    AppErrorCode code = AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
  }) {
    _transportGeneration++;
    _initialized = false;
    _isBeeSimConnected = false;
    _isConnecting = false;
    _rxFailure = AppException(code, message: message);
    if (_rxSignal != null && !_rxSignal!.isCompleted) {
      _rxSignal!.complete();
    }
  }

  void _ensureCommandActive(int generation) {
    if (generation == _transportGeneration && _isBeeSimConnected) return;
    throw _rxFailure ??
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'BeeSIM command was cancelled.',
        );
  }

  void _ensureConnectActive(int generation) {
    if (generation == _transportGeneration && !_disconnectRequested) return;
    throw _rxFailure ??
        AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'BeeSIM connection was cancelled.',
        );
  }

  Future<void> _tearDown({
    required bool clearReader,
    required bool disconnectDevice,
    required bool emitClosed,
  }) async {
    _initialized = false;
    _isBeeSimConnected = false;
    _commandPacer.reset();

    final connSub = _connSub;
    final rxSub = _rxSub;
    final pendingRxCleanup = _pendingRxCleanup;
    final device = _device;
    _connSub = null;
    _rxSub = null;
    _pendingRxCleanup = null;
    _device = null;
    _deviceId = null;
    _txChar = null;
    _rxChar = null;
    _rxQueue.clear();
    _rxBuffer.clear();

    try {
      await connSub?.cancel();
    } catch (error) {
      _log.fine('BeeSIM connection-listener cleanup failed: $error');
    }
    try {
      await rxSub?.cancel();
    } catch (error) {
      _log.fine('BeeSIM notification-listener cleanup failed: $error');
    }
    await pendingRxCleanup;
    if (disconnectDevice && device != null) {
      try {
        await device.disconnect();
      } catch (error) {
        _log.fine('BeeSIM GATT disconnect cleanup failed: $error');
      }
    }

    if (clearReader) {
      updateConnectedReader(null);
    }
    if (emitClosed) {
      _emitPortState(EuiccPortState.closed);
    }
  }

  void _emitPortState(EuiccPortState state) {
    final nextOpen = state == EuiccPortState.open;
    if (_portIsOpen == nextOpen) return;
    _portIsOpen = nextOpen;
    _stateController.add(state);
  }

  Future<void> _cancelRxSubscription(StreamSubscription subscription) async {
    try {
      await subscription.cancel();
    } catch (error) {
      _log.fine('BeeSIM notification-listener cleanup failed: $error');
    }
  }

  /// Splits the command into 20-byte BLE notify frames following the JS
  /// client's `groupValue()` (max 18 bytes of payload per frame) and prepends
  /// the `[total, index]` framing header.
  List<Uint8List> _encodeFrames(Uint8List data, int payloadSize) {
    final frames = <Uint8List>[];
    int total = data.isEmpty ? 1 : (data.length / payloadSize).ceil();
    for (int i = 0; i < total; i++) {
      final start = i * payloadSize;
      final end = (start + payloadSize > data.length)
          ? data.length
          : start + payloadSize;
      final payload = data.sublist(start, end);

      final frame = Uint8List(2 + payload.length)
        ..[0] = total
        ..[1] = i + 1
        ..setRange(2, 2 + payload.length, payload);
      frames.add(frame);
    }
    return frames;
  }

  Future<Uint8List> _waitForResponse(
    Duration timeout,
    String description,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      if (_rxQueue.isNotEmpty) return _rxQueue.removeAt(0);

      final failure = _rxFailure;
      if (failure != null) {
        _rxFailure = null;
        throw failure;
      }

      if (_device == null || !_isBeeSimConnected) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
          message: "The connection has timed out unexpectedly.",
        );
      }

      final now = DateTime.now();
      if (now.isAfter(deadline)) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: "BeeSIM timeout: $description after ${timeout.inSeconds}s",
        );
      }

      _rxSignal = Completer<void>();
      try {
        await _rxSignal!.future.timeout(const Duration(milliseconds: 500));
      } on TimeoutException {
        // retry the loop
      } finally {
        _rxSignal = null;
      }
    }
  }
}
