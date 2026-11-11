import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../euicc_adapter.dart';
import '../../utils/hex_utils.dart';
import '../../utils/error_codes.dart';

class TelephonyAdapter extends BaseAdapter {
  static final Logger _log = Logger('TelephonyAdapter');
  static const MethodChannel _channel = MethodChannel(
    'ee.nekoko.telephony_plugin',
  );
  static const EventChannel _eventChannel = EventChannel(
    'ee.nekoko.telephony_plugin/event',
  );

  Stream<Map<String, dynamic>> get simStateStream => _eventChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event));

  TelephonyAdapter() : super(_log);

  int? _slotIndex;
  int? _portIndex;

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => true;

  @override
  String? get lastAtr => null; // TelephonyManager doesn't give ATR directly

  @override
  bool get supportsRawApdu => false;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    try {
      // Check if we have the MODIFY_PHONE_STATE permission (privileged)
      // We rely on the native plugin to handle this check or fail gracefully,
      // but strictly we can explicity check if the user/system granted it if exposed.
      // Since standard permission_handler doesn't cover MODIFY_PHONE_STATE,
      // we'll assume listSlots returns empty or we check via a specific call if available.

      // Better approach: Ask the channel if it's capable/privileged
      final bool hasPermission = await _channel.invokeMethod(
        'hasPrivilegedPermission',
      );
      if (!hasPermission) {
        log.info(
          'MODIFY_PHONE_STATE not granted. Disabling Telephony/TMAPI slots.',
        );
        return [];
      }

      final List<dynamic> result = await _channel.invokeMethod('listSlots');
      final List<Reader> readers = [];

      for (final slot in result) {
        final int slotIndex = slot['slotIndex'];
        final List<dynamic> ports = slot['ports'] ?? [];

        final int simState = slot['simState'] ?? 0;

        for (final port in ports) {
          final int portIndex = port['portIndex'] ?? 0;

          String label = "TM Slot ${slotIndex + 1}";
          if (ports.length > 1) {
            label += " Port $portIndex";
          }

          if (simState == 1) {
            label += "|No SIM Card";
          }

          // Use a machine-readable string that we can parse back in connect()
          final cardId = slot['cardId']?.toString() ?? "";
          final id = "$label|telephony:$slotIndex:$portIndex:$cardId";
          readers.add(Reader(id: id, name: label, source: this));
        }
      }

      return readers;
    } catch (e) {
      log.warning('Failed to list Telephony readers: $e');
      return [];
    }
  }

  @override
  Future<void> connect(Reader reader) async {
    return await runExclusive(() async {
      await disconnect();

      updateConnectedReader(reader);
      final readerName = reader.id;
      final parts = readerName.split('|');
      final descriptor = parts.firstWhere(
        (p) => p.startsWith('telephony:'),
        orElse: () => "",
      );

      if (descriptor.isEmpty) {
        throw AppException(
          AppErrorCode.ERROR_UNKNOWN,
          message: 'Invalid telephony reader name: $readerName',
        );
      }

      final subParts = descriptor.split(':');
      if (subParts.length < 3) {
        throw AppException(
          AppErrorCode.ERROR_UNKNOWN,
          message: 'Invalid telephony reader descriptor: $descriptor',
        );
      }
      _slotIndex = int.parse(subParts[1]);
      _portIndex = int.parse(subParts[2]);

      log.info('Connecting to TM Slot ${_slotIndex! + 1} Port $_portIndex');
      _stateController.add(EuiccPortState.open);
    });
  }

  @override
  Future<void> disconnect() async {
    return await runExclusive(() async {
      if (connectedReader != null) {
        _slotIndex = null;
        _portIndex = null;
        updateConnectedReader(null);
        _stateController.add(EuiccPortState.closed);
      }
    });
  }

  @override
  Future<void> reconnect() async {
    return await runExclusive(() async {
      if (_slotIndex != null) {
        log.info('Telephony reconnect for slot $_slotIndex port $_portIndex');
        try {
          await _channel.invokeMethod('cleanupAllChannels', {
            'slotIndex': _slotIndex,
            'portIndex': _portIndex,
          });
        } catch (e) {
          log.warning('Telephony cleanup failed: $e');
        }
      }
      final reader = connectedReader;
      if (reader != null) {
        await connect(reader);
      }
    });
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    if (_slotIndex == null) {
      throw AppException(AppErrorCode.ERROR_UNKNOWN, message: 'Not connected');
    }
    final apduHex = HexUtils.bytesToHex(apdu);
    final String responseHex = await _channel.invokeMethod('transmit', {
      'slotIndex': _slotIndex,
      'portIndex': _portIndex,
      'channel': 0, // Basic channel
      'apdu': apduHex,
    });
    return HexUtils.hexToBytes(responseHex);
  }

  @override
  Future<void> cleanupChannels() async {
    if (_slotIndex == null) return;
    log.info('Ensuring single channel: cleaning up all channels...');
    try {
      await _channel.invokeMethod('cleanupAllChannels', {
        'slotIndex': _slotIndex,
        'portIndex': _portIndex,
      });
    } catch (e) {
      log.warning('Failed to cleanup channels: $e');
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await runExclusive(() async {
      if (_slotIndex == null) {
        throw AppException(
          AppErrorCode.ERROR_UNKNOWN,
          message: 'Not connected to Telephony reader',
        );
      }

      await cleanupChannels();

      if (aids != null && aids.isNotEmpty) {
        TelephonyAdapter._log.info("Telephony Native Scan for AIDs: $aids");

        for (final aid in aids) {
          try {
            // Try to open native channel directly with this AID
            final Map<dynamic, dynamic> result = await TelephonyAdapter._channel
                .invokeMethod('openChannel', {
                  'slotIndex': _slotIndex,
                  'portIndex': _portIndex,
                  'aid': aid,
                });

            final int? handle = result['channel'];
            if (handle != null) {
              TelephonyAdapter._log.info(
                "Telephony opened channel for AID $aid: handle=$handle",
              );
              return _TelephonyChannel(
                this,
                _slotIndex!,
                _portIndex!,
                handle,
                aid,
              );
            }
          } catch (e) {
            TelephonyAdapter._log.fine("Telephony open failed for $aid: $e");
          }
        }
        // If all failed, throw or fallback?
        // If we can't open with any AID, and Telephony requires AID, we are stuck.
        throw AppException(
          AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
          message: "Failed to open Telephony channel for any provided AID",
        );
      }

      // Legacy fallback (lazy open)
      return _TelephonyChannel(this, _slotIndex!, _portIndex!, null, null);
    });
  }
}

class _TelephonyChannel extends BaseChannel {
  final TelephonyAdapter _adapter;
  final int _slotIndex;
  final int _portIndex;
  int? _channelHandle;
  final String? _aid;

  _TelephonyChannel(
    this._adapter,
    this._slotIndex,
    this._portIndex,
    this._channelHandle,
    this._aid,
  ) : super(_adapter, _channelHandle ?? 0);

  @override
  String? get aid => _aid;

  @override
  Future<void> close() async {
    if (_channelHandle != null) {
      try {
        await TelephonyAdapter._channel.invokeMethod('closeChannel', {
          'slotIndex': _slotIndex,
          'portIndex': _portIndex,
          'channel': _channelHandle,
        });
      } catch (e) {
        TelephonyAdapter._log.warning('Failed to close telephony channel: $e');
      }
      _channelHandle = null;
    }
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    if (_channelHandle == null) {
      throw AppException(
        AppErrorCode.ERROR_CHANNEL_OPEN_FAILED,
        message: 'Channel not opened',
      );
    }
    final apduHex = HexUtils.bytesToHex(apdu);
    final String responseHex = await TelephonyAdapter._channel
        .invokeMethod('transmit', {
          'slotIndex': _slotIndex,
          'portIndex': _portIndex,
          'channel': _channelHandle,
          'apdu': apduHex,
        });
    return HexUtils.hexToBytes(responseHex);
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
    // If SELECT AID (INS=A4, P1=04) and channel not yet opened with an AID
    if (_channelHandle == null && ins == 0xA4 && p1 == 0x04 && data != null) {
      final targetAid = HexUtils.bytesToHex(data);
      TelephonyAdapter._log.info(
        'Telephony Opening: Selecting AID $targetAid on TM Slot ${_slotIndex + 1} Port $_portIndex',
      );

      try {
        final Map<dynamic, dynamic> result = await TelephonyAdapter._channel
            .invokeMethod('openChannel', {
              'slotIndex': _slotIndex,
              'portIndex': _portIndex,
              'aid': targetAid,
            });

        _channelHandle = result['channel'];
        final String? selectResponseHex = result['selectResponse'];

        if (selectResponseHex != null) {
          return HexUtils.hexToBytes(selectResponseHex);
        }
        return Uint8List.fromList([0x90, 0x00]);
      } catch (e) {
        final isRefreshing =
            _adapter.refreshingUntil != null &&
            DateTime.now().isBefore(_adapter.refreshingUntil!);
        if (!isRefreshing) {
          TelephonyAdapter._log.warning(
            'Initial openChannel failed ($e). No retry (not in refreshing state).',
          );
          rethrow;
        }

        TelephonyAdapter._log.info(
          'Initial openChannel failed ($e). Attempting cleanup and retry (refreshing state active)...',
        );

        // Retry logic: Attempt to cleanup stuck channels and retry
        try {
          await TelephonyAdapter._channel.invokeMethod('cleanupAllChannels', {
            'slotIndex': _slotIndex,
          });

          final Map<dynamic, dynamic> retryResult = await TelephonyAdapter
              ._channel
              .invokeMethod('openChannel', {
                'slotIndex': _slotIndex,
                'portIndex': _portIndex,
                'aid': targetAid,
              });

          _channelHandle = retryResult['channel'];
          final String? selectResponseHex = retryResult['selectResponse'];
          if (selectResponseHex != null) {
            return HexUtils.hexToBytes(selectResponseHex);
          }
          return Uint8List.fromList([0x90, 0x00]);
        } catch (retryError) {
          TelephonyAdapter._log.severe('Retry openChannel failed: $retryError');
          throw AppException(
            AppErrorCode.ERROR_CARD_UNSUPPORTED,
            message: "This card slot is unsupported or busy.",
          );
        }
      }
    }

    return await super.transmit(cla, ins, p1, p2, data, le);
  }
}
