import 'dart:async';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import '../settings/app_settings.dart';
import '../utils/hex_utils.dart';
import '../utils/platform_adapter.dart';
import 'euicc_adapter.dart';
import 'qrtr/qrtr_host.dart';
import 'se_hal_host.dart';

/// The eUICCs reached through the Secure Element HAL, one reader per SIM slot.
///
/// A reader either opens its own ISD-R channel (`hal:SIM1:owned`) or, when the
/// user has opted in, borrows channel 1 (`hal:SIM1`). Arbitrary APDUs are
/// limited to reads; profile changes go through dedicated native entry points
/// that check the card before they write.
class SeHalAdapter extends BaseAdapter {
  SeHalAdapter() : super(Logger('SeHalAdapter'));
  static const isdr = 'A0000005591010FFFFFFFF8900000100';
  final _states = StreamController<EuiccPortState>.broadcast();
  String? _atr;
  int _sessionGeneration = 0;

  @override
  void updateConnectedReader(Reader? reader) {
    // ProfileManager also updates metadata on the same live reader.
    if (connectedReader?.id != reader?.id) _sessionGeneration++;
    super.updateConnectedReader(reader);
  }

  static int slotFor(Reader reader) {
    if (!RegExp(r'^hal:SIM[12](:owned)?$').hasMatch(reader.id)) {
      throw ArgumentError('Invalid SE HAL reader');
    }
    return int.parse(reader.id['hal:SIM'.length]);
  }

  static bool ownsChannel(Reader reader) => reader.id.endsWith(':owned');

  int get slot =>
      slotFor(connectedReader ?? (throw StateError('SE HAL is disconnected')));

  @override
  Stream<EuiccPortState> get stateStream => _states.stream;
  @override
  bool get requiresRefresh => false;
  @override
  bool get supportsRawApdu => false;
  @override
  String? get lastAtr => _atr;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async =>
      PlatformX.isAndroid &&
          AppSettings().enableSeHalConnector &&
          await QrtrHost.isAvailable()
      ? [
          for (final slot in [1, 2]) readerForSlot(slot),
        ]
      : [];

  Reader readerForSlot(int slot) {
    if (slot < 1 || slot > 2) throw ArgumentError('Invalid SIM slot');
    return Reader(
      id: 'hal:SIM$slot${AppSettings().halUseBorrowed(slot) ? '' : ':owned'}',
      name: 'SE HAL-$slot',
      source: this,
    );
  }

  void validateReaderSettings(Reader reader) {
    if (reader.id != readerForSlot(slotFor(reader)).id) {
      throw StateError(
        'SE HAL ownership setting changed; refresh the reader list',
      );
    }
    if (!AppSettings().enableSeHalConnector) {
      throw StateError('SE HAL connector is disabled');
    }
  }

  @override
  Future<void> connect(Reader reader) => runExclusive(() async {
    validateReaderSettings(reader);
    if (!await QrtrHost.hasPermission() &&
        !await QrtrHost.requestPermission()) {
      throw StateError('Shizuku permission is required');
    }
    if (connectedReader != null) {
      throw StateError('Disconnect the current SE HAL reader first');
    }
    final atr = await SeHalHost.halAtr(slotFor(reader));
    validateReaderSettings(reader);
    if (ownsChannel(reader)) {
      try {
        await SeHalHost.halOpenOwned(slotFor(reader));
      } catch (e) {
        throw StateError('Could not open an ISD-R channel: $e');
      }
    } else {
      await SeHalHost.halUseBorrowed(slotFor(reader));
    }
    try {
      validateReaderSettings(reader);
    } catch (e) {
      try {
        await SeHalHost.halCloseOwned(slotFor(reader));
      } catch (cleanup) {
        SeHalHost.markUnconfirmedTeardown(slotFor(reader));
        log.warning('Ownership setting changed; teardown unconfirmed', cleanup);
      }
      rethrow;
    }
    _atr = HexUtils.bytesToHex(atr);
    updateConnectedReader(reader);
    _states.add(EuiccPortState.open);
  });

  @override
  Future<void> disconnect() => runExclusive(() async {
    final reader = connectedReader;
    // Drop local access even if Shizuku stopped or permission was revoked.
    // A failed cleanup must not pin CompositeAdapter to this reader.
    _atr = null;
    updateConnectedReader(null);
    _states.add(EuiccPortState.closed);
    if (reader == null) return;
    try {
      final slot = slotFor(reader);
      await SeHalHost.halEndDownload(slot);
      await SeHalHost.halCloseOwned(slot);
    } catch (e, stack) {
      SeHalHost.markUnconfirmedTeardown(slotFor(reader));
      log.warning('SE HAL teardown unconfirmed', e, stack);
    }
  });

  @override
  Future<void> cleanupChannels() async {} // Shared until reader disconnect.

  @override
  Future<Channel> openChannel({List<String>? aids}) => runExclusive(() async {
    if (connectedReader == null) throw StateError('SE HAL is not connected');
    if (aids != null && !aids.any((a) => a.toUpperCase() == isdr)) {
      throw StateError('SE HAL only supports ISD-R');
    }
    final channel = HalDownloadChannel(this);
    final eid = await channel.transmit(
      0x80,
      0xE2,
      0x91,
      0,
      HexUtils.hexToBytes('BF3E035C015A'),
    );
    if (eid.length != 23 ||
        HexUtils.bytesToHex(eid.sublist(0, 5)).toUpperCase() != 'BF3E125A10' ||
        eid[eid.length - 2] != 0x90 ||
        eid.last != 0) {
      throw StateError('SE HAL channel is not a readable ISD-R');
    }
    return channel;
  });

  // The native side only admits read-only ES10 requests here.
  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) =>
      SeHalHost.halRead(slot, apdu);
}

class HalDownloadChannel extends BaseChannel {
  HalDownloadChannel(SeHalAdapter adapter)
    : slot = adapter.slot,
      readerId = adapter.connectedReader!.id,
      generation = adapter._sessionGeneration,
      super(adapter, 1);
  final int slot;
  final String readerId;
  final int generation;

  void _checkSession() {
    final hal = adapter as SeHalAdapter;
    if (hal.connectedReader?.id != readerId ||
        hal._sessionGeneration != generation) {
      throw StateError('SE HAL reader changed; reopen the channel');
    }
  }

  @override
  String get aid => SeHalAdapter.isdr;

  @override
  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) {
    _checkSession();
    return adapter.runExclusive(() {
      _checkSession(); // The connection may have changed while waiting for the lock.
      if (cla == 0x80 &&
          ins == 0xE2 &&
          p1 == 0x91 &&
          p2 == 0 &&
          le == null &&
          data != null &&
          data.length >= 3 &&
          data[0] == 0xBF &&
          [0x2E, 0x38, 0x21].contains(data[1])) {
        return SeHalHost.halDownload(slot, data, [data.length]);
      }
      // The native read policy takes a whole short request, never chunks.
      if (data != null && data.length > 255) {
        throw ArgumentError('SE HAL read request exceeds short APDU capacity');
      }
      return ApduChainer.transceive(
        transmitter: (apdu) => adapter.sendRawApdu(
          Uint8List.fromList([
            (apdu[0] & 0xFC) | channelNumber,
            ...apdu.skip(1),
          ]),
        ),
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        le: le,
        mss: 255,
        log: adapter.log,
      );
    });
  }

  Future<Uint8List> loadBpp(Uint8List bpp, List<int> segmentLengths) {
    _checkSession();
    return adapter.runExclusive(() {
      _checkSession();
      return SeHalHost.halDownload(slot, bpp, segmentLengths);
    });
  }

  @override
  Future<void> close() async {} // Shared native channel: released at disconnect.
}
