import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../utils/apdu_exception.dart';
import '../settings/app_settings.dart';
import '../utils/hex_utils.dart';
import '../utils/error_codes.dart';
import '../plugins/plugin_manager.dart';
import '../plugins/session_plugin.dart';

enum EuiccPortState { closed, open }

class AdapterMode {
  final String id;
  final String label;
  final dynamic value;
  final bool isSelected;
  AdapterMode({
    required this.id,
    required this.label,
    required this.value,
    this.isSelected = false,
  });
}

class AdapterAction {
  final IconData icon;
  final String label;
  final Future<void> Function(BuildContext context) onPressed;
  final String key;

  AdapterAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.key,
  });
}

enum ReaderStrategy { slow, fast }

enum NotificationStrategy { twoStep, combined }

typedef RawApduTransmitter = Future<Uint8List> Function(Uint8List apdu);

abstract class Channel {
  int get channelNumber;
  Adapter get adapter;
  String? get aid;

  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]);
  Future<void> close();
}

class Reader {
  final String id;
  String name;
  Adapter source;
  dynamic context;
  String? eid;
  String? aid;
  bool isEstkMax;
  bool isEstk;

  Reader({
    required this.id,
    required this.name,
    required this.source,
    this.context,
    this.eid,
    this.aid,
    this.isEstkMax = false,
    this.isEstk = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reader && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reader{id: $id, name: $name, source: ${source.runtimeType}}';
}

abstract class Adapter {
  Future<List<Reader>> listReaders({bool force = false});

  Future<void> connect(Reader reader);
  Future<void> disconnect();

  // Updated signature: accepts optional list of AIDs to test natively
  Future<Channel> openChannel({List<String>? aids});
  Future<void> closeChannel(Channel channel);
  Future<Uint8List> transmit(
    Channel channel,
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]);

  Future<T> runTransaction<T>(Future<T> Function(Channel channel) action);
  Future<Uint8List> sendRawApdu(Uint8List apdu);
  Future<Uint8List> sendApdu(Uint8List apdu);

  Future<T> runExclusive<T>(Future<T> Function() action);
  Future<void> reconnect();
  Future<void> cleanupChannels();
  Future<void> setProfileSwitchInProgress(bool value);
  Future<void> proactiveRefresh();

  Stream<EuiccPortState> get stateStream;
  bool get requiresRefresh;
  String? get lastAtr;
  Reader? get connectedReader;
  void updateConnectedReader(Reader? reader);
  String? get simIccid;
  String? get currentEid;
  set currentEid(String? value);
  DateTime? get refreshingUntil;
  set refreshingUntil(DateTime? value);

  ReaderStrategy get readerStrategy;
  NotificationStrategy get notificationStrategy;
  List<AdapterAction> get extraActions;

  Future<List<AdapterMode>> getAvailableModes(Reader reader);
  Future<void> switchMode(Reader reader, AdapterMode mode);

  /// Whether the adapter supports sending raw APDUs (e.g. to the basic channel).
  /// This is required for features that need direct SIM APDU access.
  bool get supportsRawApdu;
}

/// Base implementation of Channel that handles CLA mapping and uses ApduChainer
class BaseChannel implements Channel {
  @override
  final BaseAdapter adapter;
  @override
  final int channelNumber;
  final Logger _log;

  BaseChannel(this.adapter, this.channelNumber) : _log = adapter.log;

  @override
  String? get aid => null;

  @override
  Future<void> close() async {
    if (channelNumber == 0) return;
    _log.info("Closing logical channel $channelNumber...");
    try {
      // MANAGE CHANNEL [Close]
      await adapter.sendApdu(
        Uint8List.fromList([0x00, 0x70, 0x80, channelNumber, 0x00]),
      );
      _log.info("Logical channel $channelNumber closed.");
    } catch (e) {
      _log.warning("Failed to close logical channel $channelNumber: $e");
    }
  }

  @override
  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) async {
    return await adapter.runExclusive(() async {
      return await ApduChainer.transceive(
        transmitter: _sendToAdapter,
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        le: le,
        log: _log,
      );
    });
  }

  Future<Uint8List> _sendToAdapter(Uint8List apdu) async {
    if (apdu.length < 4) throw Exception("Invalid APDU length");

    // Map CLA to logical channel
    int cla = apdu[0];
    int effectiveCla;
    if (channelNumber < 4) {
      effectiveCla = (cla & 0xFC) | channelNumber;
    } else if (channelNumber < 20) {
      effectiveCla = (cla & 0xF0) | 0x40 | (channelNumber - 4);
    } else {
      throw Exception("Unsupported logical channel number: $channelNumber");
    }

    final modApdu = Uint8List.fromList(apdu);
    modApdu[0] = effectiveCla;

    // Logging
    if (AppSettings().enableApduLogging) {
      _log.info("[CH $channelNumber] >> ${HexUtils.bytesToHex(modApdu)}");
    }

    final resp = await sendRawApdu(modApdu);

    if (AppSettings().enableApduLogging) {
      _log.info("[CH $channelNumber] << ${HexUtils.bytesToHex(resp)}");
    }

    return resp;
  }

  /// Subclasses can override this to provide session-specific transmission logic
  Future<Uint8List> sendRawApdu(Uint8List apdu) => adapter.sendRawApdu(apdu);
}

/// Base implementation of Adapter with synchronized execution and centralized runTransaction
abstract class BaseAdapter implements Adapter {
  final Logger log;
  BaseAdapter(this.log);

  @override
  DateTime? refreshingUntil;

  @override
  String? get simIccid => null;

  @override
  String? currentEid;

  Reader? _currentReader;
  @override
  Reader? get connectedReader => _currentReader;

  @override
  void updateConnectedReader(Reader? reader) {
    _currentReader = reader;
  }

  @override
  Future<void> proactiveRefresh() async {}

  @override
  Future<void> setProfileSwitchInProgress(bool value) async {}

  @override
  ReaderStrategy get readerStrategy => ReaderStrategy.fast;

  @override
  NotificationStrategy get notificationStrategy =>
      NotificationStrategy.combined;

  @override
  List<AdapterAction> get extraActions => [];

  @override
  bool get supportsRawApdu => true;

  @override
  Future<List<AdapterMode>> getAvailableModes(Reader reader) async {
    final modes = <AdapterMode>[];
    for (final plugin in PluginManager().plugins) {
      if (plugin is SessionPlugin) {
        modes.addAll(
          await (plugin as SessionPlugin).getAvailableModes(this, reader),
        );
      }
    }
    return modes;
  }

  @override
  Future<void> switchMode(Reader reader, AdapterMode mode) async {
    for (final plugin in PluginManager().plugins) {
      if (plugin is SessionPlugin) {
        await (plugin as SessionPlugin).switchMode(this, reader, mode);
      }
    }
  }

  Future<void>? _lock;

  @override
  Future<T> runExclusive<T>(Future<T> Function() action) async {
    if (Zone.current[this] == true) {
      return await action();
    }

    while (_lock != null) {
      await _lock;
    }

    final completer = Completer<void>();
    _lock = completer.future;

    try {
      return await runZoned(
        () async => await action(),
        zoneValues: {this: true},
      );
    } finally {
      _lock = null;
      completer.complete();
    }
  }

  @override
  Future<Uint8List> sendApdu(Uint8List apdu) async {
    return await runExclusive(() async {
      return await ApduChainer.transceive(
        transmitter: (a) async {
          if (AppSettings().enableApduLogging) {
            log.info("[RAW] >> ${HexUtils.bytesToHex(a)}");
          }
          final r = await sendRawApdu(a);
          if (AppSettings().enableApduLogging) {
            log.info("[RAW] << ${HexUtils.bytesToHex(r)}");
          }
          return r;
        },
        cla: apdu[0],
        ins: apdu[1],
        p1: apdu[2],
        p2: apdu[3],
        data: apdu.length > 5
            ? apdu.sublist(
                5,
                apdu.length - (apdu.length > 5 && apdu.last == 0 ? 1 : 0),
              )
            : null,
        log: log,
      );
    });
  }

  @override
  Future<void> reconnect() async {
    final reader = connectedReader;
    if (reader != null) {
      log.info("Reconnecting ${reader.name}...");
      await disconnect();
      await connect(reader);
    }
  }

  @override
  Future<void> closeChannel(Channel channel) async {
    await channel.close();
  }

  @override
  Future<Uint8List> transmit(
    Channel channel,
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) async {
    return await channel.transmit(cla, ins, p1, p2, data, le);
  }

  @override
  Future<void> cleanupChannels() async {
    log.info("Cleaning up logical channels (1-3)...");
    for (var i = 1; i <= 3; i++) {
      try {
        await sendRawApdu(Uint8List.fromList([0x00, 0x70, 0x80, i, 0x00]));
      } catch (_) {}
    }
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(Channel channel) action,
  ) async {
    return await runExclusive(() async {
      log.info("Starting transaction...");
      final channel = await openChannel();
      try {
        final result = await action(channel);
        log.info("Transaction finished successfully.");
        return result;
      } catch (e) {
        log.warning("Transaction failed: $e");
        rethrow;
      } finally {
        await closeChannel(channel);
      }
    });
  }

  /// Helper to iterate a list of AIDs and SELECT the first one that works.
  /// Returns the successful AID, or throws if none work.
  Future<String> selectAid(Channel channel, List<String> aids) async {
    for (final aid in aids) {
      final aidBytes = HexUtils.hexToBytes(aid);
      // eSTKme-specific AID check: skip if ATR doesn't match
      if (aid.toUpperCase().contains("6573746B") &&
          lastAtr != null &&
          !lastAtr!.toUpperCase().contains("6573746B")) {
        continue;
      }
      try {
        final resp = await channel.transmit(0x00, 0xA4, 0x04, 0x00, aidBytes);
        final sw1 = resp.length >= 2 ? resp[resp.length - 2] : 0;
        final sw2 = resp.length >= 2 ? resp[resp.length - 1] : 0;
        if ((sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x61 || sw1 == 0x9F) {
          return aid;
        }
      } catch (e) {
        log.fine("SELECT $aid failed: $e");
        if (e is AppException &&
            e.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED) {
          rethrow;
        }
      }
    }
    throw AppException(
      AppErrorCode.ERROR_APPLICATION_NOT_FOUND,
      message: "No supported AID found",
    );
  }

  /// Common helper to open a logical channel using MANAGE CHANNEL
  Future<Channel> openLogicalChannel({
    List<String>? aids,
    bool skipCleanup = false,
  }) async {
    return await runExclusive(() async {
      if (AppSettings().ensureSingleChannel && !skipCleanup) {
        await cleanupChannels();
      }

      // Try to open a logical channel
      log.info("Opening logical channel...");
      Channel channel;

      try {
        await sendApdu(
          Uint8List.fromList([
            0x80,
            0xAA,
            0x00,
            0x00,
            0x0A,
            0xA9,
            0x08,
            0x81,
            0x00,
            0x82,
            0x01,
            0x01,
            0x83,
            0x01,
            0x07,
          ]),
        );
        final resp = await sendApdu(
          Uint8List.fromList([0x00, 0x70, 0x00, 0x00, 0x01]),
        );
        if (resp.length < 2) {
          throw AppException(
            AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
            message: "Invalid MANAGE CHANNEL response",
          );
        }

        final sw1 = resp[resp.length - 2];
        final sw2 = resp[resp.length - 1];
        ApduValidator.validate(sw1, sw2);

        final chNum = resp[0];
        log.info("Logical channel $chNum opened.");
        channel = BaseChannel(this, chNum);
      } catch (e) {
        if (e is AppException &&
            e.code == AppErrorCode.ERROR_BLUETOOTH_NOT_CONNECTED) {
          rethrow;
        }
        log.warning(
          "MANAGE CHANNEL failed: $e. Falling back to basic channel (0).",
        );
        channel = BaseChannel(this, 0);
      }

      if (aids != null && aids.isNotEmpty) {
        try {
          final selectedAid = await selectAid(channel, aids);
          log.info("Successfully selected AID: $selectedAid");
          // Return a wrapped channel that reports this AID?
          // BaseChannel doesn't store AID, we need a wrapper or mod to BaseChannel.
          // For now, let's create an anonymous subclass or just rely on ProfileManager?
          // The user wants ProfileManager logic REMOVED. So we must return a channel that claims this AID.
          return _AidAwareChannel(channel, selectedAid);
        } catch (e) {
          log.warning("Failed to select any AID on opened channel: $e");
          await channel.close();
          rethrow;
        }
      }
      return channel;
    });
  }
}

class _AidAwareChannel implements Channel {
  final Channel _delegate;
  final String _aid;
  _AidAwareChannel(this._delegate, this._aid);
  @override
  int get channelNumber => _delegate.channelNumber;
  @override
  Adapter get adapter => _delegate.adapter;
  @override
  String? get aid => _aid;

  @override
  Future<Uint8List> transmit(
    int c,
    int i,
    int p1,
    int p2, [
    Uint8List? d,
    int? l,
  ]) => _delegate.transmit(c, i, p1, p2, d, l);
  @override
  Future<void> close() => _delegate.close();
}

/// Helper for APDU request chaining and response reassembly.
class ApduChainer {
  static final Logger _log = Logger('ApduChainer');

  /// Transmits an APDU payload, handling both request chaining and response reassembly.
  static Future<Uint8List> transceive({
    required RawApduTransmitter transmitter,
    required int cla,
    required int ins,
    required int p1,
    required int p2,
    Uint8List? data,
    int? le,
    int? mss,
    Logger? log,
  }) async {
    final effectiveMss = mss ?? AppSettings().mss;
    final useLog = log ?? _log;

    // 1. Request Chaining (Splitting)
    if (data != null && data.length > effectiveMss) {
      return _transmitChainedRequest(
        transmitter: transmitter,
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        le: le,
        mss: effectiveMss,
        log: useLog,
      );
    }

    // 2. Single Body APDU
    final b = BytesBuilder();
    b.addByte(cla);
    b.addByte(ins);
    b.addByte(p1);
    b.addByte(p2);
    if (data != null && data.isNotEmpty) {
      if (data.length <= 255) {
        b.addByte(data.length);
        b.add(data);
      } else {
        // Extended length
        b.addByte(0x00);
        b.addByte((data.length >> 8) & 0xFF);
        b.addByte(data.length & 0xFF);
        b.add(data);
      }
    }

    // Handle Le
    if (le != null) {
      if (le > 255) {
        if (data == null) b.addByte(0x00); // Extended length preamble
        b.addByte((le >> 8) & 0xFF);
        b.addByte(le & 0xFF);
      } else {
        b.addByte(le);
      }
    } else {
      if (ins != 0xE2) {
        b.addByte(0x00);
      }
    }

    return _transceiveWithResponseReassembly(
      transmitter: transmitter,
      apdu: b.toBytes(),
      log: useLog,
    );
  }

  static Future<Uint8List> _transmitChainedRequest({
    required RawApduTransmitter transmitter,
    required int cla,
    required int ins,
    required int p1,
    required int p2,
    required Uint8List data,
    int? le,
    required int mss,
    required Logger log,
  }) async {
    int offset = 0;
    int blockNum = 0;
    Uint8List lastResponse = Uint8List(0);

    while (offset < data.length) {
      final remaining = data.length - offset;
      final isLast = remaining <= mss;
      final chunkSize = isLast ? remaining : mss;
      final chunk = data.sublist(offset, offset + chunkSize);

      int currentCla = cla;
      int currentP1 = p1;
      int currentP2 = p2;

      if (ins == 0xE2) {
        currentP1 = isLast ? (p1 | 0x80) : (p1 & 0x7F);
        currentP2 = blockNum;
        blockNum = (blockNum + 1) & 0xFF;
      } else {
        if (!isLast) {
          currentCla |= 0x10;
        }
      }

      final b = BytesBuilder();
      b.addByte(currentCla);
      b.addByte(ins);
      b.addByte(currentP1);
      b.addByte(currentP2);
      b.addByte(chunk.length);
      b.add(chunk);
      if (isLast && ins != 0xE2) {
        if (le != null) {
          if (le > 255) {
            b.addByte(0x00);
          } else {
            b.addByte(le);
          }
        } else {
          b.addByte(0x00);
        }
      }

      final apdu = b.toBytes();
      if (isLast) {
        lastResponse = await _transceiveWithResponseReassembly(
          transmitter: transmitter,
          apdu: apdu,
          log: log,
        );
      } else {
        lastResponse = await transmitter(apdu);
        if (lastResponse.length < 2) {
          throw Exception("Chained APDU failed: response too short");
        }
        final sw1 = lastResponse[lastResponse.length - 2];
        final sw2 = lastResponse[lastResponse.length - 1];
        ApduValidator.validate(sw1, sw2);
      }

      offset += chunkSize;
    }

    return lastResponse;
  }

  static Future<Uint8List> _transceiveWithResponseReassembly({
    required RawApduTransmitter transmitter,
    required Uint8List apdu,
    required Logger log,
    int maxGetResponse = 2048,
  }) async {
    var currentApdu = apdu;
    final accumulated = <int>[];

    for (var i = 0; i < maxGetResponse; i++) {
      final apduResp = await transmitter(currentApdu);

      if (apduResp.length < 2) return apduResp;

      final sw1 = apduResp[apduResp.length - 2];
      final sw2 = apduResp[apduResp.length - 1];

      if (sw1 == 0x61) {
        if (apduResp.length > 2) {
          accumulated.addAll(apduResp.sublist(0, apduResp.length - 2));
        }
        final cla = currentApdu[0];
        final le = sw2 == 0 ? 0x00 : sw2;
        currentApdu = Uint8List.fromList([cla, 0xC0, 0x00, 0x00, le]);
        continue;
      }

      if (sw1 == 0x6C) {
        final b = BytesBuilder();
        b.add(currentApdu.sublist(0, currentApdu.length - 1));
        b.addByte(sw2);
        currentApdu = b.toBytes();
        continue;
      }

      if (accumulated.isNotEmpty) {
        accumulated.addAll(apduResp);
        return Uint8List.fromList(accumulated);
      }

      return apduResp;
    }

    throw Exception("Too many APDU reassembly steps");
  }
}
