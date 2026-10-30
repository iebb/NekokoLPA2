import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ble/ble.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Unused
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import '../../utils/platform_adapter.dart';
import 'ble_adapter.dart';

class BleReaderInfo {
  final String id;
  final String name;
  final BleAdapterType type;

  BleReaderInfo({required this.id, required this.name, required this.type});

  factory BleReaderInfo.fromScanResult(ScanResult result) {
    final advertisedName = result.advertisementData.advName;
    final platformName = result.device.platformName;
    final displayName = platformName.isEmpty
        ? (advertisedName.isEmpty ? 'Unknown' : advertisedName)
        : platformName;
    final type =
        BleAdapterType.fromDeviceNames(
          displayName: displayName,
          advertisedName: advertisedName,
        ) ??
        BleAdapterType.redBle;
    return BleReaderInfo(
      id: result.device.remoteId.toString(),
      name: _readerName(type, displayName, advertisedName),
      type: type,
    );
  }

  /// The name a reader is listed, addressed and authenticated by.
  static String _readerName(
    BleAdapterType type,
    String displayName,
    String advertisedName,
  ) {
    final readerName = BleAdapterType.kindOf(type)?.readerName;
    return readerName?.call(displayName, advertisedName) ?? displayName;
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type.id};
  factory BleReaderInfo.fromJson(Map<String, dynamic> json) => BleReaderInfo(
    id: json['id'],
    name: json['name'],
    type: BleAdapterType.fromId(json['type']),
  );

  String get readerName => "${type.id}: $name|$id";
}

class BleManager extends ChangeNotifier {
  /// Service UUIDs that identify a reader: the built-in readers' and any a
  /// plugin's reader kind adds.
  static List<String> get _scanServiceUuids => [
    '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
    '0000ae30-0000-1000-8000-00805f9b34fb',
    for (final kind in BleAdapterType.kinds) ...kind.scanServiceUuids,
  ];

  static final Logger _log = Logger('BleManager');
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  final List<BleReaderInfo> _sessionReaders = [];
  List<BleReaderInfo> get sessionReaders => List.unmodifiable(_sessionReaders);

  final List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _isScanningSub;

  Future<void> init() async {
    _sessionReaders.clear();
    notifyListeners();
  }

  Future<void> _save() async {
    // Persistence disabled as per user request
  }

  Future<void> startScan() async {
    if (_isScanning) {
      _log.info("Scan already in progress, skipping.");
      return;
    }

    _log.info("Starting Bluetooth scan... (kIsWeb: $kIsWeb)");

    // Permissions check - only pertinent for mobile platforms
    if (!kIsWeb && (PlatformX.isAndroid || PlatformX.isIOS)) {
      try {
        if (await Permission.bluetoothScan.request().isDenied ||
            await Permission.bluetoothConnect.request().isDenied ||
            await Permission.location.request().isDenied) {
          _log.warning("Bluetooth/Location permissions denied");
          return;
        }
      } catch (e) {
        _log.warning("Permission check failed: $e");
      }
    }

    // Cancel any existing subscriptions
    await _scanSubscription?.cancel();
    await _isScanningSub?.cancel();
    _scanSubscription = null;
    _isScanningSub = null;

    _scanResults.clear();
    notifyListeners();

    // Wait for Bluetooth to be ready
    // On Web, we skip this explicit wait as the browser handles the prompt and state during requestDevice
    if (!kIsWeb) {
      try {
        final state = await Ble.adapterState.first;
        _log.info("Current Bluetooth adapter state: $state");
        if (state != BluetoothAdapterState.on) {
          _log.info("Waiting for Bluetooth adapter to be ON...");
          await Ble.adapterState
              .where((s) => s == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 10));
        }
      } catch (e) {
        _log.warning("Bluetooth adapter is not ON or timed out: $e");
        _isScanning = false;
        notifyListeners();
        return;
      }
    }

    // Check support
    if (kIsWeb) {
      final supported = await Ble.isSupported;
      _log.info("Checking Web Bluetooth support: $supported");
      if (!supported) {
        _log.warning("Web Bluetooth is not supported in this browser");
        return;
      }
    }

    // Track scanning state directly from the source
    _isScanningSub = Ble.isScanning.listen((scanning) {
      _log.info("FBP Scanning state: $scanning");
      _isScanning = scanning;
      notifyListeners();
    });

    // Use scanResults stream for cumulative results and filter in code
    _scanSubscription = Ble.scanResults.listen((results) {
      final filtered = results.where((r) {
        final advName = r.advertisementData.advName;
        final platformName = r.device.platformName;
        final displayName = platformName.isEmpty ? advName : platformName;
        final matchedType = BleAdapterType.fromDeviceNames(
          displayName: displayName,
          advertisedName: advName,
        );

        _log.info("Found device: $displayName");
        // A writer that advertises non-connectably, or without its GATT
        // service, can never be connected to -- every attempt just times out.
        // Record what it actually broadcast so that is distinguishable from a
        // host-side failure.
        _log.fine(
          () =>
              "  adv[$displayName] connectable=${r.advertisementData.connectable} "
              "rssi=${r.rssi} "
              "services=${r.advertisementData.serviceUuids} "
              "serviceData=${r.advertisementData.serviceData.keys.toList()} "
              "msd=${r.advertisementData.manufacturerData.keys.toList()} "
              "txPower=${r.advertisementData.txPowerLevel}",
        );

        // Keywords filter
        final matchKeyword =
            matchedType != null &&
            (matchedType != BleAdapterType.glocalMe || !kIsWeb);

        if (matchKeyword) return true;

        // Service UUID filter
        final services = r.advertisementData.serviceUuids;
        final serviceIds = services.map((s) => s.toString().toLowerCase());
        final matchService =
            services.contains(Guid('4553')) ||
            serviceIds.any((id) => _scanServiceUuids.any(id.contains));

        return matchService;
      }).toList();

      _log.info(
        "Found ${results.length} total, ${filtered.length} matched filters",
      );
      _scanResults.clear();
      _scanResults.addAll(filtered);
      notifyListeners();
    });

    try {
      final services = [
        Guid('4553'),
        ..._scanServiceUuids.map(Guid.new),
        // Guid('544b') and Guid('6d65') are characteristics, not services
      ];

      final keywords = [
        'ESTKme',
        'eSIM_Writer',
        'BeeSIM',
        for (final kind in BleAdapterType.kinds) ...kind.scanKeywords,
        if (!kIsWeb) 'GlocalMe',
        '9eSIM',
      ];

      _log.info("Calling Ble.startScan with keywords: $keywords");
      await Ble.startScan(
        withServices: (kIsWeb) ? services : [],
        withKeywords: keywords,
        continuousUpdates: true,
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      _log.severe("Scan failed to start: $e");
      _isScanning = false;
      await _scanSubscription?.cancel();
      await _isScanningSub?.cancel();
      notifyListeners();
    }
  }

  /// Special helper for Web to just scan and return the reader name
  Future<String?> scanAndAddReaderForWeb() async {
    _log.info("scanAndAddReaderForWeb called");
    final completer = Completer<String?>();

    // Temporarily listen for the result
    final sub = Ble.scanResults.listen((results) {
      _log.info("scanResults emitted ${results.length} results");
      if (results.isNotEmpty && !completer.isCompleted) {
        final last = results.last;
        _log.info("Selected last result: ${last.device.platformName}");
        final readerName = addReader(last);
        _log.info("Added reader: $readerName");
        completer.complete(readerName);
      }
    });

    try {
      _log.info("Starting startScan...");
      await startScan();
      _log.info("startScan completed, waiting for result...");
      // Wait for the result to be processed by the stream listener
      // Usually it happens immediately after startScan returns on Web
      // Increased timeout to 5 seconds to be safe
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      _log.warning("Scan failed or timed out: $e");
      if (!completer.isCompleted) completer.complete(null);
      return null;
    } finally {
      await sub.cancel();
      _log.info("scanAndAddReaderForWeb sub cancelled");
    }
  }

  Future<void> stopScan() async {
    try {
      await Ble.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    await _isScanningSub?.cancel();
    _scanSubscription = null;
    _isScanningSub = null;
    _isScanning = false;
    notifyListeners();
  }

  String addReader(ScanResult result) {
    return addReaderInfo(BleReaderInfo.fromScanResult(result));
  }

  String addReaderInfo(BleReaderInfo info) {
    // Check if we already have this reader in the current session
    final existingIndex = _sessionReaders.indexWhere((r) => r.id == info.id);
    if (existingIndex >= 0) {
      // Return the name from the session reader so it matches what CompositeAdapter loads
      return _sessionReaders[existingIndex].readerName;
    }

    _sessionReaders.add(info);
    _save();
    notifyListeners();
    return info.readerName;
  }

  void removeReader(String id) {
    _sessionReaders.removeWhere((r) => r.id == id);
    _save();
    notifyListeners();
  }
}
