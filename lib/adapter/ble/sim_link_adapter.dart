import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ble/ble.dart';
import 'package:logging/logging.dart';
import '../euicc_adapter.dart';
import '../../utils/hex_utils.dart';
import '../../utils/error_codes.dart';
import 'ble_adapter.dart';
import 'ble_transport_utils.dart';

class SimLinkAdapter extends BaseAdapter implements BleAdapter {
  static final Logger _log = Logger('SimLinkAdapter');

  SimLinkAdapter() : super(_log);
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription? _rxSub;
  StreamSubscription? _connSub;
  String? _lastAtr;

  final Guid serviceUuid = Guid('6E400001-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid txCharUuid = Guid('6E400002-B5A3-F393-E0A9-E50E24DCCA9E');
  final Guid rxCharUuid = Guid('6E400003-B5A3-F393-E0A9-E50E24DCCA9E');

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => false;

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
    return await runExclusive(() async {
      updateConnectedReader(reader);
      final readerName = reader.id;
      final deviceId = readerName.split('|').last;
      _device = BluetoothDevice.fromId(deviceId);

      log.info("Connecting to SimLink (NBLESim) device: $deviceId");
      try {
        await connectBleDevice(_device!, log, progress: connectProgress);
        log.info("Connected to device: $deviceId");

        await _connSub?.cancel();
        _connSub = _device!.connectionState.listen((state) {
          if (state == BluetoothConnectionState.disconnected) {
            log.warning("SimLink disconnected unexpectedly");
            _txChar = null;
            _rxChar = null;
            _stateController.add(EuiccPortState.closed);
          }
        });

        reportConnectStep(ReaderConnectStep.discoveringServices);
        List<BluetoothService> services = await _device!.discoverServices();
        BluetoothService service = services.firstWhere(
          (s) => s.uuid == serviceUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_SERVICE_NOT_FOUND,
            message: "SimLink service not found",
          ),
        );

        _txChar = service.characteristics.firstWhere(
          (c) => c.uuid == txCharUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: "TX characteristic not found",
          ),
        );
        _rxChar = service.characteristics.firstWhere(
          (c) => c.uuid == rxCharUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: "RX characteristic not found",
          ),
        );

        reportConnectStep(ReaderConnectStep.enablingNotifications);
        await _rxChar!.setNotifyValue(true);

        log.info("SimLink protocol init...");
        reportConnectStep(ReaderConnectStep.initializing);
        // Reset APDU mode
        await _transmitRaw({"cmd": "APDU", "action": 2});
        // Start APDU mode
        await _transmitRaw({"cmd": "APDU", "action": 0});

        // Query terminal capabilities
        try {
          final getDataCmd = "80AA00000AA9088100820101830107";
          await _transmit(getDataCmd);
          log.info("Terminal capabilities queried");
        } catch (e) {
          log.warning("GET DATA (terminal capabilities) failed: $e");
        }

        // The first channel setup happens in openChannel usually,
        // but the reference does it here to verify availability.

        _stateController.add(EuiccPortState.open);
      } catch (e) {
        log.shout("Connection failed: $e");
        await disconnect();
        if (e is AppException) rethrow;
        if (e is TimeoutException) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
            originalError: e,
          );
        }
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
          originalError: e,
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    return await runExclusive(() async {
      log.info("Disconnecting from SimLink device...");
      try {
        if (_txChar != null) {
          await _transmitRaw({"cmd": "APDU", "action": 2});
        }
      } catch (_) {}

      await _rxSub?.cancel();
      _rxSub = null;
      await _connSub?.cancel();
      _connSub = null;
      await _device?.disconnect();
      _device = null;
      _txChar = null;
      _rxChar = null;
      updateConnectedReader(null);
      _stateController.add(EuiccPortState.closed);
    });
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    final hex = HexUtils.bytesToHex(apdu);
    final respHex = await _transmit(hex);
    return HexUtils.hexToBytes(respHex);
  }

  Future<String> _transmit(String apduHex) async {
    // Reference special handling for C0 (GET RESPONSE)
    if (apduHex.length == 10 && apduHex.substring(2).startsWith('c00000')) {
      int len = int.parse(apduHex.substring(8), radix: 16);
      if (len > 0x4F || len == 0) {
        return await _transmitRaw({
          "cmd": "APDU",
          "data": "${apduHex.substring(0, 2)}c000004f",
          "action": 1,
        });
      }
    }

    return await _transmitRaw({"cmd": "APDU", "data": apduHex, "action": 1});
  }

  Future<String> _transmitRaw(
    Map<String, dynamic> obj, {
    bool isRetry = false,
  }) async {
    if (_device == null || _txChar == null || _rxChar == null) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
        message: "SimLink not connected",
      );
    }

    final jsonStr = jsonEncode(obj);
    log.fine("SimLink TX >> $jsonStr");

    final completer = Completer<String>();
    String accumulatedResponse = "";

    _rxSub = _rxChar!.onValueReceived.listen((data) {
      final chunk = utf8.decode(data);
      accumulatedResponse += chunk;
      try {
        final decoded = jsonDecode(accumulatedResponse);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('error')) {
            final error = decoded['error'];
            if (error == "APDU channel not open!" && !isRetry) {
              log.info("SimLink channel not open, attempting auto-reopen...");
              _rxSub?.cancel();
              _rxSub = null;

              (() async {
                try {
                  await _transmitRaw({
                    "cmd": "APDU",
                    "action": 0,
                  }, isRetry: true);
                  final result = await _transmitRaw(obj, isRetry: true);
                  if (!completer.isCompleted) completer.complete(result);
                } catch (e) {
                  if (!completer.isCompleted) completer.completeError(e);
                }
              })();
              return;
            } else {
              if (!completer.isCompleted) completer.complete("");
            }
          } else if (decoded.containsKey('data')) {
            if (!completer.isCompleted) {
              completer.complete(decoded['data'] as String);
            }
          } else {
            // Some other response?
            // If it's valid JSON but doesn't have data/error, maybe it's just an ACK?
            if (!completer.isCompleted) completer.complete("");
          }
        }
      } catch (e) {
        // Not a complete JSON yet, keep waiting
      }
    });

    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      await writeBleChunks(
        device: _device!,
        characteristic: _txChar!,
        data: bytes,
      );

      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: "SimLink transmission timeout",
        ),
      );
    } finally {
      await _rxSub?.cancel();
      _rxSub = null;
    }
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await openLogicalChannel(aids: aids);
  }
}
