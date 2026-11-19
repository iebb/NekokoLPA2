import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../utils/hex_utils.dart';
import '../../utils/platform_adapter.dart';
import '../euicc_adapter.dart';
import 'phoenix_link.dart';

/// Reader support for Phoenix / Smartmouse style serial smart card readers.
///
/// These are the cheap RS-232 (often PL2303/CH340 based) readers sold for SIM
/// tooling: the reader only shifts levels, so the ISO 7816 framing, the card
/// reset and the T=0 handshake all happen here.
class PhoenixAdapter extends BaseAdapter {
  static final Logger _logger = Logger('PhoenixAdapter');

  PhoenixAdapter() : super(_logger);

  // ignore: close_sinks
  final StreamController<EuiccPortState> _state =
      StreamController<EuiccPortState>.broadcast();

  PhoenixLink? _link;
  String? _lastAtr;

  @override
  Stream<EuiccPortState> get stateStream => _state.stream;

  @override
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => _lastAtr;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    if (!PlatformX.isWindows) return const [];
    try {
      final ports = PhoenixLink.availablePorts();
      _logger.info('Phoenix: serial ports found: '
          '${ports.isEmpty ? "(none)" : ports.join(", ")}');
      return ports
          .map((port) => Reader(id: 'phoenix:$port', name: port, source: this))
          .toList();
    } catch (e) {
      _logger.warning('Phoenix reader enumeration failed: $e');
      return const [];
    }
  }

  @override
  Future<void> connect(Reader reader) async {
    _logger.info('Opening Phoenix reader ${reader.name}...');
    final link = PhoenixLink.open(reader.name);
    try {
      final atr = await link.reset();
      if (atr.isEmpty || (atr[0] != 0x3B && atr[0] != 0x3F)) {
        throw PhoenixException(
          '${reader.name}: no ATR -- the card did not answer. Check that the '
          'card is seated and the switch is set to 19200; if it worked before, '
          'unplug and replug the reader (this reader cannot power-cycle the '
          'card from software).',
        );
      }
      _link = link;
      _lastAtr = HexUtils.bytesToHex(atr);
      // The card needs a moment after the ATR before it accepts the first
      // APDU; without this settle the first command is silently dropped.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      updateConnectedReader(reader);
      _state.add(EuiccPortState.open);
      _logger.info('Phoenix reader ${reader.name} ready, ATR=$_lastAtr');
    } catch (e) {
      _link = null;
      _lastAtr = null;
      link.close();
      _logger.severe('Failed to bring up ${reader.name}: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    final link = _link;
    _link = null;
    _lastAtr = null;
    currentEid = null;
    updateConnectedReader(null);
    _state.add(EuiccPortState.closed);
    link?.close();
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) {
    return openLogicalChannel(aids: aids);
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    final link = _link;
    if (link == null) {
      throw PlatformException(
        code: 'DISCONNECTED',
        message: 'Phoenix serial reader is not connected',
      );
    }

    var cmd = apdu;
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      Uint8List rsp;
      try {
        rsp = await link.transceive(cmd);
      } catch (e) {
        lastError = e;
        _logger.fine('APDU tx=${HexUtils.bytesToHex(apdu)} -> $e');
        // A silent card usually means it lost its supply or was reset by line
        // noise. Resetting clears that, but it also closes every logical
        // channel and clears the selected AID, so the command cannot be
        // retransmitted unchanged: a logical-channel APDU would come back
        // 6881, and a basic-channel one would reach the default application.
        // Propagate instead, so the caller opens a fresh session.
        try {
          final atr = await link.reset();
          _logger.fine('Recovery reset, ATR=${HexUtils.bytesToHex(atr)}');
        } catch (_) {
          // keep the original error
        }
        throw PhoenixException(
          'APDU failed: $e. The card was reset, so the session has to be '
          'reopened (echoErrors=${link.echoErrors})',
        );
      }

      _logger.fine(
        'APDU tx=${HexUtils.bytesToHex(apdu)} rx=${HexUtils.bytesToHex(rsp)}',
      );
      if (rsp.length < 2) {
        lastError = 'short response (${rsp.length} bytes)';
        continue;
      }

      final sw1 = rsp[rsp.length - 2];
      final sw2 = rsp[rsp.length - 1];

      // Le rejected: the card tells us the length it wants. Rebuild the APDU
      // keeping the data field intact -- for case 4 the trailing byte is Le,
      // not data, and blindly replacing it corrupts the command (which makes
      // this card go silent until it is power-cycled).
      if (sw1 == 0x6C) {
        final bodyLen = apdu.length - 5;
        final lc = apdu[4];
        if (bodyLen > 0 && lc <= bodyLen) {
          cmd = Uint8List.fromList([
            ...apdu.sublist(0, 5),
            ...apdu.sublist(5, 5 + lc),
            sw2,
          ]);
        } else {
          cmd = Uint8List.fromList([...apdu.sublist(0, 4), sw2]);
        }
        continue;
      }

      // More data available: chain GET RESPONSE until it is drained.
      if (sw1 == 0x61) {
        // GET RESPONSE has to carry the same logical channel as the command.
        // Channels 0-3 sit in the low two bits of CLA (0x01 for channel 1);
        // 4-19 use 0x40 | (ch - 4). Sending CLA 0x00 here makes the card
        // answer on channel 0 and return 6F00 instead of the data.
        final int grCla = (apdu[0] & 0x40) != 0
            ? (apdu[0] & 0x4F)
            : (apdu[0] & 0x03);

        var body = rsp.sublist(0, rsp.length - 2);
        // SW2 = 0x00 means 256 bytes available, not zero (ISO 7816-4). A
        // chunked STORE DATA answers "61 00" for its whole response, so
        // treating it as empty silently drops the data.
        var remaining = sw2 == 0 ? 256 : sw2;
        var blocks = 0;
        while (true) {
          // Le is a single byte: 0 encodes 256.
          final int le = remaining >= 256 ? 0 : remaining;
          final more = await link.transceive(
            Uint8List.fromList([grCla, 0xC0, 0x00, 0x00, le]),
          );
          _logger.fine(
            'GET RESPONSE cla=${grCla.toRadixString(16)} le=$le -> '
            '${HexUtils.bytesToHex(more)}',
          );
          // Never fabricate a status word here: a truncated chain would then
          // look like a successful response and the caller would decode half
          // an ASN.1 object.
          if (more.length < 2) {
            throw PhoenixException(
              'GET RESPONSE returned ${more.length} byte(s) with $remaining '
              'still outstanding; the response is truncated',
            );
          }
          body = Uint8List.fromList(
            [...body, ...more.sublist(0, more.length - 2)],
          );
          final moreSw1 = more[more.length - 2];
          final moreSw2 = more[more.length - 1];
          if (moreSw1 != 0x61) {
            return Uint8List.fromList([...body, moreSw1, moreSw2]);
          }
          remaining = moreSw2 == 0 ? 256 : moreSw2;
          if (++blocks > 64) {
            throw PhoenixException(
              'GET RESPONSE chain did not finish after 64 blocks '
              '($remaining bytes still pending)',
            );
          }
        }
      }

      return rsp;
    }

    throw PhoenixException(
      'APDU failed: the card kept rejecting Le (lastError=$lastError, '
      'echoErrors=${link.echoErrors})',
    );
  }

  /// A profile switch only takes effect once the card is reset: it re-reads
  /// the active profile at start-up. On a serial reader there is no modem to
  /// ask for a REFRESH, so toggling RTS is the only way to make the card
  /// serve the new profile.
  @override
  Future<void> resetAfterProfileSwitch() async {
    final link = _link;
    if (link == null) return;
    _logger.info('Resetting the card so it starts serving the new profile');
    await link.reset();
  }

  @override
  Future<void> proactiveRefresh() async {
    final link = _link;
    if (link == null) return;
    _logger.info('Card asked for a REFRESH; resetting it instead');
    await link.reset();
  }
}
