import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../settings/app_settings.dart';
import '../../src/rust/api/modem.dart' as rust;
import '../../utils/error_codes.dart';
import '../../utils/hex_utils.dart';
import '../../utils/platform_adapter.dart';
import '../euicc_adapter.dart';
import 'qrtr_host.dart';
import 'qrtr_socket.dart';

/// The readers reached over QRTR, the modem's own bus.
///
/// A bus has no device list, so what is offered is what the modem itself says
/// it has: one reader per card slot, named for the slot. The bus is only
/// reachable through Shizuku on Android, so nothing is offered on a device
/// whose SoC says there is no bus, or when the user does not want it. If the
/// slots cannot be asked for yet — permission has not been granted, the modem
/// is not answering — one reader for the modem as a whole is offered instead,
/// so there is still something to connect to.
///
/// The modem has no basic channel: the card is only reachable inside a logical
/// channel the modem opened for an AID, and the channel travels beside the
/// APDU rather than inside its class byte. That is why this adapter reports
/// [supportsRawApdu] as false and why its channels leave the CLA alone instead
/// of folding the channel number into it the way [BaseChannel] does.
class QrtrReaderAdapter extends BaseAdapter {
  QrtrReaderAdapter() : super(_log);

  static final Logger _log = Logger('QrtrReaderAdapter');

  /// How long the modem has to answer anything.
  static const Duration commandTimeout = Duration(seconds: 40);

  /// Name of the link, for logs.
  String get link => 'qrtr';

  /// Whether the user wants this reader at all.
  bool get isEnabled => AppSettings().enableQrtrConnector;

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  ModemSessionHandle? _handle;
  String? _atr;

  /// Slots the modem reported, the ones holding a card first.
  List<rust.ModemSlot> _slots = const [];

  /// The slot the connected reader stands for, if it stands for one.
  int? _slot;

  /// Logical channels this adapter opened, by the channel number the modem
  /// gave them.
  final Map<int, _QrtrLogicalChannel> _channels = {};

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => _atr;

  /// The card is reached only through a logical channel.
  @override
  bool get supportsRawApdu => false;

  // ---------------------------------------------------------------------
  // The readers this adapter offers
  // ---------------------------------------------------------------------

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    if (!isEnabled) return const [];

    // A Qualcomm device has the bus whether or not anything is plugged into
    // it; on Android Shizuku is what it takes to reach it.
    if (PlatformX.isAndroid) {
      if (!await QrtrHost.isSupported()) return const [];
      if (!await QrtrHost.isAvailable()) return const [];
    }

    final slots = await _slotNumbers();

    return slots.map(_readerFor).toList(growable: false);
  }

  /// The slot this reader stands for, when the reader is one slot of several.
  ///
  /// A reader that stands for the whole modem leaves this null, and then every
  /// slot holding a card is offered the AIDs in turn.
  int? slotOf(Reader reader) {
    final parts = reader.id.split(':');
    if (parts.length < 2) return null;

    final slot = int.tryParse(parts[1]);
    return slot == null || slot == 0 ? null : slot;
  }

  /// The card slots the modem reports, or the modem itself when it cannot be
  /// asked — slot zero standing for the whole modem.
  Future<List<int>> _slotNumbers() async {
    ModemSessionHandle? handle;

    try {
      handle = await _openSession();

      final slots = await handle.session.state().timeout(commandTimeout);
      if (slots.isEmpty) return const [0];

      return slots.map((slot) => slot.slot).toList(growable: false);
    } catch (e) {
      _log.fine('Could not ask the modem for its slots: $e');
      return const [0];
    } finally {
      try {
        await handle?.close();
      } catch (_) {}
    }
  }

  /// One reader per card slot; slot zero is the modem as a whole, which is
  /// what is offered when the slots cannot be asked for.
  Reader _readerFor(int slot) => Reader(
    id: slot == 0 ? 'qrtr:modem' : 'qrtr:$slot',
    name: slot == 0 ? 'QRTR' : 'QRTR-$slot',
    source: this,
  );

  // ---------------------------------------------------------------------
  // The session under the readers
  // ---------------------------------------------------------------------

  /// Open the modem's bus and wrap it in a session, once the user is known to
  /// have let the app use Shizuku.
  Future<ModemSessionHandle> openSession(Reader reader) async {
    if (PlatformX.isAndroid && !await QrtrHost.hasPermission()) {
      final granted = await QrtrHost.requestPermission();
      if (!granted) {
        throw AppException(
          AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED,
          message: 'Shizuku permission denied for the QRTR bus',
        );
      }
    }

    return _openSession();
  }

  /// Open the modem's bus and wrap it in a session.
  Future<ModemSessionHandle> _openSession() async {
    final socket = await openQrtrSocket();

    try {
      // The socket is Dart's, and the session asks it for every datagram: on
      // Android it is a socket in the process Shizuku runs, on Linux one this
      // process opened itself.
      final session = await rust.openQmiQrtrSession(
        address: () async {
          final address = await socket.address();
          return rust.QrtrSocketAddress(node: address.node, port: address.port);
        },
        send: (datagram) => socket.send(
          QrtrAddress(datagram.node, datagram.port),
          datagram.data,
        ),
        receive: (timeoutMs) async {
          final datagram = await socket.receive(timeoutMs);
          if (datagram == null) return null;

          return rust.QrtrSocketDatagram(
            node: datagram.from.node,
            port: datagram.from.port,
            data: datagram.data,
          );
        },
      );

      return ModemSessionHandle(session: session, close: socket.close);
    } catch (_) {
      await socket.close();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // One connection
  // ---------------------------------------------------------------------

  @override
  Future<void> connect(Reader reader) async {
    return runExclusive(() async {
      await _teardown();

      _log.info('Opening ${reader.name} over $link...');
      _slot = slotOf(reader);
      final handle = await openSession(reader);

      try {
        _log.info('Reading card status over $link...');
        final slots = await handle.session.state().timeout(
          commandTimeout,
          onTimeout: () => throw AppException(
            AppErrorCode.ERROR_UNKNOWN,
            message: 'The modem did not answer the card status query',
          ),
        );

        if (slots.isEmpty) {
          throw AppException(
            AppErrorCode.ERROR_UNKNOWN,
            message: 'The modem reported no card slot',
          );
        }

        _handle = handle;
        _slots = _orderSlots(slots);

        final card = _slots.firstWhere(
          (slot) => slot.present,
          orElse: () => _slots.first,
        );
        _atr = card.atr == null ? null : HexUtils.bytesToHex(card.atr!);
      } catch (_) {
        await handle.close();
        rethrow;
      }

      updateConnectedReader(reader);
      _stateController.add(EuiccPortState.open);
      _log.info(
        'Opened $link: ${_slots.length} slot(s)'
        '${_atr == null ? '' : ', ATR $_atr'}',
      );
    });
  }

  @override
  Future<void> disconnect() async {
    return runExclusive(() async {
      await _teardown();
      _stateController.add(EuiccPortState.closed);
    });
  }

  @override
  Future<void> cleanupChannels() async {
    for (final channel in _channels.values.toList()) {
      try {
        await channel.close();
      } catch (e) {
        _log.warning('Failed to close channel ${channel.channelNumber}: $e');
      }
    }
  }

  /// Not supported: without a logical channel there is nowhere to send an APDU.
  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    throw AppException(
      AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
      message:
          'The modem has no basic channel: open a logical channel for an AID '
          'before sending APDUs',
    );
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return runExclusive(() async {
      if (AppSettings().ensureSingleChannel) {
        await cleanupChannels();
      }

      final targetAids = (aids == null || aids.isEmpty)
          ? AppSettings().aids
          : aids;
      if (targetAids.isEmpty) {
        throw AppException(
          AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
          message: 'No AIDs configured for modem channel open',
        );
      }

      // A modem holds several slots and only one of them may carry the eUICC,
      // so the slots holding a card are offered the AIDs in turn — all of
      // them, unless the reader stands for one slot in particular.
      Object? lastError;
      for (final slot in _slots) {
        if (!slot.present) continue;
        if (_slot != null && slot.slot != _slot) continue;

        for (final aid in targetAids) {
          try {
            return await _openChannel(slot.slot, aid);
          } catch (e) {
            lastError = e;
            _log.fine('Slot ${slot.slot}: $aid did not open: $e');
          }
        }
      }

      throw AppException(
        AppErrorCode.ERROR_APPLICATION_NOT_FOUND,
        message: 'No supported AID found',
        originalError: lastError,
      );
    });
  }

  /// Ask the modem to open a logical channel selected to `aid`.
  ///
  /// The modem performs the selection itself — it takes the AID, selects it
  /// and hands back the channel to use from then on — so the caller must not
  /// select the AID again: a second SELECT inside the same channel is exactly
  /// what the card refuses with `ACCESS_DENIED`.
  Future<Channel> _openChannel(int slot, String aid) async {
    final session = _requireSession();
    final aidBytes = HexUtils.hexToBytes(aid);

    final channelNumber = await session.openChannel(slot: slot, aid: aidBytes);
    final channel = _QrtrLogicalChannel(this, slot, channelNumber, aid);
    _channels[channelNumber] = channel;

    _log.info('Slot $slot: logical channel $channelNumber opened for $aid');
    return channel;
  }

  /// Send one APDU on a channel the modem already opened.
  Future<Uint8List> transmitOnChannel(
    int slot,
    int channel,
    Uint8List apdu,
  ) async {
    final session = _requireSession();

    if (AppSettings().enableApduLogging) {
      log.info('[QRTR slot $slot ch $channel] >> ${HexUtils.bytesToHex(apdu)}');
    }

    final response = await session
        .transmit(slot: slot, channel: channel, apdu: apdu)
        .timeout(
          commandTimeout,
          onTimeout: () => throw AppException(
            AppErrorCode.ERROR_UNKNOWN,
            message: 'The modem did not answer an APDU on channel $channel',
          ),
        );

    if (AppSettings().enableApduLogging) {
      log.info(
        '[QRTR slot $slot ch $channel] << ${HexUtils.bytesToHex(response)}',
      );
    }

    return response;
  }

  Future<void> closeLogicalChannel(int channelNumber) async {
    final channel = _channels.remove(channelNumber);
    if (channel == null) return;

    try {
      await _requireSession().closeChannel(
        slot: channel.slot,
        channel: channelNumber,
      );
    } catch (e) {
      _log.warning('Failed to close logical channel $channelNumber: $e');
    }
  }

  /// Slots with a card first, so the common case does not probe empty ones.
  List<rust.ModemSlot> _orderSlots(List<rust.ModemSlot> slots) {
    final ordered = [...slots];
    ordered.sort((a, b) {
      int rank(rust.ModemSlot slot) {
        if (slot.present && slot.ready) return 0;
        if (slot.present) return 1;
        return 2;
      }

      return rank(a).compareTo(rank(b));
    });

    return ordered;
  }

  rust.ModemSession _requireSession() {
    final session = _handle?.session;
    if (session == null) {
      throw AppException(AppErrorCode.ERROR_UNKNOWN, message: 'Not connected');
    }

    return session;
  }

  Future<void> _teardown() async {
    await cleanupChannels();
    _channels.clear();

    final handle = _handle;
    _handle = null;
    _slots = const [];
    _atr = null;
    updateConnectedReader(null);

    if (handle != null) {
      try {
        await handle.close();
      } catch (e) {
        _log.warning('Failed to let the modem go: $e');
      }
    }
  }
}

/// An open modem session, and the bus under it.
class ModemSessionHandle {
  ModemSessionHandle({required this.session, required this.close});

  final rust.ModemSession session;

  /// Let the bus go: the QRTR socket, wherever it lives.
  final Future<void> Function() close;
}

/// A logical channel the modem opened for an AID.
///
/// Unlike [BaseChannel] this leaves the APDU's class byte alone: the modem
/// carries the channel beside the APDU, and a CLA naming a channel the card
/// never opened is exactly what the card rejects.
class _QrtrLogicalChannel implements Channel {
  _QrtrLogicalChannel(this._adapter, this.slot, this.channelNumber, this._aid);

  final QrtrReaderAdapter _adapter;
  final int slot;

  @override
  final int channelNumber;
  final String _aid;

  @override
  Adapter get adapter => _adapter;

  @override
  String? get aid => _aid;

  @override
  Future<Uint8List> transmit(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) {
    return _adapter.runExclusive(() async {
      return ApduChainer.transceive(
        transmitter: (apdu) =>
            _adapter.transmitOnChannel(slot, channelNumber, apdu),
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        le: le,
        log: _adapter.log,
      );
    });
  }

  @override
  Future<void> close() => _adapter.closeLogicalChannel(channelNumber);
}
