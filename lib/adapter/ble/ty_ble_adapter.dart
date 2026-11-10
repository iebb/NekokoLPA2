import 'dart:async';
import 'dart:typed_data';

import 'package:ble/ble.dart';
import 'package:logging/logging.dart';

import '../../utils/error_codes.dart';
import '../../utils/hex_utils.dart';
import '../euicc_adapter.dart';
import 'ble_adapter.dart';
import 'ble_transport_utils.dart';
import 'ty_ble_protocol.dart';

/// Adapter for Tianyu Bluetooth eSIM cards advertised as `<customer>-BT-<UID>`
/// and 9eSIM B0 Plus cards advertised as `9eSIM` followed by eight digits.
class TYBLEAdapter extends BaseAdapter implements BleAdapter {
  TYBLEAdapter() : super(_log);

  static final Logger _log = Logger('TYBLEAdapter');

  // Microchip ISSC Transparent UART service, verified on TES-BT-00000184.
  static final Guid serviceUuid = Guid('49535343-FE7D-4AE5-8FA9-9FAFD205E455');
  static final Guid notifyUuid = Guid('49535343-1E4D-4BD9-BA61-23C647249616');
  static final Guid writeUuid = Guid('49535343-8841-43F4-A8D4-ECBE34729BB3');

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();
  final TYBLEFrameDecoder _decoder = TYBLEFrameDecoder();
  final List<Uint8List> _responseQueue = [];

  Completer<void>? _responseSignal;
  bool _connected = false;
  bool _authenticated = false;

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => null;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async =>
      connectedReader == null ? [] : [connectedReader!];

  @override
  Future<void> connect(Reader reader) async {
    await runExclusive(() async {
      await _tearDown(clearReader: false, emitClosed: false);
      updateConnectedReader(reader);

      final deviceId = reader.id.split('|').last.trim();
      final deviceName = reader.name.trim();

      try {
        // Validate the UID and derive the PIN before opening a BLE connection.
        final authenticationApdu = TYBLEProtocol.authenticationApdu(deviceName);

        if (await Ble.adapterState.first != BluetoothAdapterState.on) {
          reportConnectStep(ReaderConnectStep.waitingForBluetooth);
          await Ble.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () =>
                    throw AppException(AppErrorCode.ERROR_BLUETOOTH_DISABLED),
              );
        }

        _device = BluetoothDevice.fromId(deviceId);
        _log.info('Connecting to TY BLE card: $deviceName ($deviceId)');
        await connectBleDevice(
          _device!,
          _log,
          preferredMtu: 512,
          progress: connectProgress,
        );
        _connected = true;

        reportConnectStep(ReaderConnectStep.discoveringServices);
        final services = await _device!.discoverServices();
        final service = services.firstWhere(
          (candidate) => candidate.uuid == serviceUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_SERVICE_NOT_FOUND,
            message: 'TY BLE ISSC UART service not found',
          ),
        );

        _writeCharacteristic = service.characteristics.firstWhere(
          (candidate) => candidate.uuid == writeUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: 'TY BLE write characteristic not found',
          ),
        );
        _notifyCharacteristic = service.characteristics.firstWhere(
          (candidate) => candidate.uuid == notifyUuid,
          orElse: () => throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CHARACTERISTIC_NOT_FOUND,
            message: 'TY BLE notify characteristic not found',
          ),
        );

        _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(
          _handleNotification,
        );
        reportConnectStep(ReaderConnectStep.enablingNotifications);
        await _notifyCharacteristic!.setNotifyValue(true);
        _connectionSubscription = _device!.connectionState.listen(
          _handleConnectionState,
        );

        // The card rejects all other BLE-channel data until this succeeds.
        reportConnectStep(ReaderConnectStep.authenticating);
        final authenticationResponse = await _transmitPayload(
          authenticationApdu,
          timeout: const Duration(seconds: 10),
          label: 'authenticate',
        );
        final status = HexUtils.bytesToHex(
          authenticationResponse,
        ).toUpperCase();
        if (status != '9000') {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
            message: status == '6982'
                ? 'TY BLE PIN authentication failed (SW=6982)'
                : 'TY BLE authentication returned an unexpected response: $status',
          );
        }

        _authenticated = true;
        _stateController.add(EuiccPortState.open);
        _log.info('TY BLE card authenticated successfully.');
      } catch (error) {
        _log.warning('TY BLE connection failed: $error');
        await _tearDown(clearReader: true, emitClosed: true);
        if (error is AppException) rethrow;
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_CONNECT_FAILED,
          message: 'Unable to connect to TY BLE card',
          originalError: error,
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    await runExclusive(() => _tearDown(clearReader: true, emitClosed: true));
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    return await runExclusive(() async {
      if (!_authenticated) {
        final reader = connectedReader;
        if (reader == null) {
          throw AppException(
            AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
            message: 'TY BLE card is not connected',
          );
        }
        await connect(reader);
      }
      return await _transmitPayload(
        apdu,
        timeout: const Duration(seconds: 100),
        label: 'APDU',
      );
    });
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async =>
      openLogicalChannel(aids: aids);

  void _handleNotification(List<int> value) {
    for (final frame in _decoder.add(value)) {
      _responseQueue.add(frame);
      _log.fine('TY BLE RX: ${HexUtils.bytesToHex(frame)}');
    }
    _signalResponseWaiter();
  }

  void _handleConnectionState(BluetoothConnectionState state) {
    _connected = state == BluetoothConnectionState.connected;
    if (state == BluetoothConnectionState.disconnected) {
      _authenticated = false;
      _stateController.add(EuiccPortState.closed);
      _signalResponseWaiter();
    }
  }

  Future<Uint8List> _transmitPayload(
    Uint8List payload, {
    required Duration timeout,
    required String label,
  }) async {
    if (!_connected || _device == null || _writeCharacteristic == null) {
      throw AppException(
        AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
        message: 'TY BLE card disconnected before $label',
      );
    }

    _decoder.clear();
    _responseQueue.clear();
    final request = TYBLEProtocol.frame(payload);
    _log.fine('TY BLE $label TX: ${HexUtils.bytesToHex(request)}');

    try {
      await writeBleChunks(
        device: _device!,
        characteristic: _writeCharacteristic!,
        data: request,
        maxChunkSize: 512,
      );
    } catch (error) {
      if (!_connected) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          originalError: error,
        );
      }
      throw AppException(
        AppErrorCode.ERROR_TRANSACTION_FAILED,
        message: 'TY BLE write failed during $label',
        originalError: error,
      );
    }

    return await _waitForResponse(timeout, label);
  }

  Future<Uint8List> _waitForResponse(Duration timeout, String label) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      if (_responseQueue.isNotEmpty) return _responseQueue.removeAt(0);
      if (!_connected) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED,
          message: 'TY BLE card disconnected during $label',
        );
      }

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: 'TY BLE timed out during $label',
        );
      }

      _responseSignal = Completer<void>();
      try {
        await _responseSignal!.future.timeout(remaining);
      } on TimeoutException {
        throw AppException(
          AppErrorCode.ERROR_BLUETOOTH_TIMEOUT,
          message: 'TY BLE timed out during $label',
        );
      } finally {
        _responseSignal = null;
      }
    }
  }

  void _signalResponseWaiter() {
    final signal = _responseSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
  }

  Future<void> _tearDown({
    required bool clearReader,
    required bool emitClosed,
  }) async {
    _authenticated = false;
    _connected = false;
    _signalResponseWaiter();
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _decoder.clear();
    _responseQueue.clear();
    if (clearReader) updateConnectedReader(null);
    if (emitClosed) _stateController.add(EuiccPortState.closed);
  }
}
