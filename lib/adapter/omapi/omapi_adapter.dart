import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:collection/collection.dart';
import '../euicc_adapter.dart';
import '../../utils/hex_utils.dart';
import '../../settings/app_settings.dart';
import '../../utils/error_codes.dart';
import '../../utils/apdu_exception.dart';
import 'omapi_safety.dart';

const Set<String> _estkSlotAids = {
  'A06573746B6D65FFFF4953442D522030',
  'A06573746B6D65FFFF4953442D522031',
};

List<String> omapiPreferredAidReuseCandidates(List<String> aids) {
  if (aids.isEmpty) return aids;
  final preferredAid = aids.first;
  return _estkSlotAids.contains(preferredAid.toUpperCase())
      ? [preferredAid]
      : aids;
}

List<String> omapiNativeOpenCandidates(
  List<String> aids,
  Iterable<String> trackedAids,
) {
  if (aids.isEmpty) return aids;
  final preferredAid = aids.first;
  if (!_estkSlotAids.contains(preferredAid.toUpperCase())) {
    return List<String>.from(aids);
  }

  final tracked = trackedAids.map((aid) => aid.toUpperCase()).toSet();
  return [
    preferredAid,
    ...aids.skip(1).where((aid) => !tracked.contains(aid.toUpperCase())),
  ];
}

class OmapiAdapter extends BaseAdapter {
  static final Logger _log = Logger('OmapiAdapter');
  static const MethodChannel _channel = MethodChannel('ee.nekoko.omapi_plugin');
  static const EventChannel _eventChannel = EventChannel(
    'ee.nekoko.omapi_plugin/event',
  );
  static final OmapiSafetyLatch _safety = OmapiSafetyLatch();

  bool get isPoisoned => _safety.isPoisoned;

  static Future<T> _invoke<T>(String method, [dynamic arguments]) =>
      _safety.invoke<T>(_channel, method, arguments);

  Stream<Map<String, dynamic>> get simStateStream => _eventChannel
      .receiveBroadcastStream()
      .map((event) => Map<String, dynamic>.from(event));

  OmapiAdapter() : super(_log);

  String? _internalReaderName;
  String? _lastAtr;
  final Map<int, String> _channelMappings = {};
  final Map<String, int> _nextChannelIds = {};
  final Map<int, int> _refCounts = {};
  final Map<int, Timer> _pendingCloses = {};
  final OmapiChannelOwnershipTracker _channelOwnership =
      OmapiChannelOwnershipTracker();
  bool _profileSwitchInProgress = false;
  List<Reader>? _lastReaders;
  DateTime? _lastListTime;

  final StreamController<EuiccPortState> _stateController =
      StreamController<EuiccPortState>.broadcast();

  @override
  Stream<EuiccPortState> get stateStream => _stateController.stream;

  @override
  bool get requiresRefresh => true; // OMAPI requires refresh flag set to 1

  @override
  String? get lastAtr => _lastAtr;

  @override
  bool get supportsRawApdu => false;

  @override
  Future<List<Reader>> listReaders({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastReaders != null &&
        _lastListTime != null &&
        now.difference(_lastListTime!) < const Duration(seconds: 2)) {
      _log.info('Using cached OMAPI readers (${_lastReaders!.length})');
      return _lastReaders!;
    }

    try {
      final List<dynamic> result = await _invoke('listReaders');
      final readers = result.map((nameStr) {
        final name = nameStr as String;
        String displayName = name;
        if (name.startsWith("SIM")) {
          // "SIM1" -> "Slot 1-0"
          final match = RegExp(r'SIM(\d+)').firstMatch(name);
          if (match != null) {
            final index = int.parse(match.group(1)!);
            displayName = "SIM $index";
          }
        }
        return Reader(id: "omapi:$name", name: displayName, source: this);
      }).toList();

      _lastReaders = readers;
      _lastListTime = now;
      return readers;
    } catch (e) {
      if (isOmapiSessionCorruptedError(e)) rethrow;
      log.warning('Failed to list OMAPI readers: $e');
      return [];
    }
  }

  @override
  Future<void> connect(Reader reader) async {
    return await runExclusive(() async {
      await disconnect();

      final readerId = reader.id;
      // Strip prefix and error information: "omapi:SIM1 (Error: reason)" -> "SIM1"
      String realReaderName = readerId.split(' (').first;
      if (realReaderName.startsWith('omapi:')) {
        realReaderName = realReaderName.substring(6);
      }
      updateConnectedReader(reader);
      _internalReaderName = realReaderName;
      log.info('Connecting to OMAPI reader: $realReaderName');

      try {
        final Map<dynamic, dynamic> result = await _invoke('connect', {
          'reader': realReaderName,
        });

        _lastAtr = result['atr'] as String?;
        _nextChannelIds[realReaderName] = 1; // Reset channel counter on connect
        _stateController.add(EuiccPortState.open);
        log.info('Connected to OMAPI reader: $readerId');
      } on PlatformException catch (e) {
        if (isOmapiSessionCorruptedError(e)) rethrow;
        log.severe('Failed to connect to OMAPI reader: $e');
        if (e.code == 'SecurityException') {
          throw AppException(
            AppErrorCode.ERROR_OMAPI_SECURITYEXCEPTION,
            originalError: e,
          );
        }
        rethrow;
      } catch (e) {
        if (isOmapiSessionCorruptedError(e)) rethrow;
        log.severe('Failed to connect to OMAPI reader: $e');
        rethrow;
      }
    });
  }

  @override
  Future<void> disconnect() async {
    return await runExclusive(() async {
      if (_internalReaderName != null) {
        try {
          // Close all open channels
          for (final aid in _channelMappings.values.toList()) {
            try {
              await _invoke('closeChannel', {
                'reader': _internalReaderName,
                'aid': aid,
              });
            } catch (e) {
              if (isOmapiSessionCorruptedError(e)) rethrow;
              log.warning('Failed to close channel $aid: $e');
            }
          }
          _pendingCloses.forEach((_, timer) => timer.cancel());
          _pendingCloses.clear();
          _refCounts.clear();
          _channelMappings.clear();
          _channelOwnership.clear();

          await _invoke('disconnect', {'reader': _internalReaderName});
        } catch (e) {
          log.warning('Error during disconnect: $e');
          if (isOmapiSessionCorruptedError(e)) {
            _channelMappings.clear();
            _channelOwnership.clear();
            _pendingCloses.forEach((_, timer) => timer.cancel());
            _pendingCloses.clear();
            _refCounts.clear();
            updateConnectedReader(null);
            _internalReaderName = null;
            _lastAtr = null;
            _stateController.add(EuiccPortState.closed);
            rethrow;
          }
        }

        updateConnectedReader(null);
        _internalReaderName = null;
        _lastAtr = null;
        _stateController.add(EuiccPortState.closed);
      }
    });
  }

  @override
  Future<void> cleanupChannels() async {
    log.info('Ensuring single channel: closing all logical channels...');
    _pendingCloses.forEach((_, timer) => timer.cancel());
    _pendingCloses.clear();
    _refCounts.clear();
    try {
      await _invoke('closeChannels', {'reader': _internalReaderName});
    } catch (e) {
      log.warning('Failed to close channels: $e');
      if (isOmapiSessionCorruptedError(e)) rethrow;
    } finally {
      _channelMappings.clear();
      _channelOwnership.clear();
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> reconnect() async {
    return await runExclusive(() async {
      _safety.ensureAvailable();
      log.info('Hard reconnect for OMAPI reader: $_internalReaderName');
      try {
        await _invoke('reset');
      } catch (e) {
        log.warning('OMAPI reset failed: $e');
        if (isOmapiSessionCorruptedError(e)) rethrow;
      }
      final reader = connectedReader;
      if (reader != null) {
        await connect(reader);
      }
    });
  }

  @override
  Future<Channel> openLogicalChannel({
    List<String>? aids,
    bool skipCleanup = false,
  }) async {
    // In OMAPI, we must not send raw MANAGE CHANNEL (0070) or SELECT (00A4)
    // We must use openChannel which uses higher-level Kotlin APIs
    return await openChannel(aids: aids);
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    if (_internalReaderName == null) {
      throw AppException(
        AppErrorCode.ERROR_OMAPI_READER_NOT_AVAILABLE,
        message: 'Not connected to OMAPI reader',
      );
    }
    final String apduHex = HexUtils.bytesToHex(apdu);

    final String responseHex = await _invoke('transmit', {
      'reader': _internalReaderName,
      'apdu': apduHex,
    });

    return HexUtils.hexToBytes(responseHex);
  }

  @override
  Future<Channel> openChannel({List<String>? aids}) async {
    return await runExclusive(() async {
      if (_internalReaderName == null) {
        throw AppException(
          AppErrorCode.ERROR_OMAPI_READER_NOT_AVAILABLE,
          message: 'Not connected to OMAPI reader',
        );
      }

      final readerId = _internalReaderName ?? "default";

      // 1. Check for same AID re-use
      // For eSTK slots, only reuse the first AID requested by the caller.
      if (aids != null && aids.isNotEmpty) {
        log.info(
          'Checking for re-use. Targets: $aids. Current mappings: $_channelMappings',
        );
        final reuseCandidates = omapiPreferredAidReuseCandidates(aids);

        for (final aid in reuseCandidates) {
          final existingId = _channelMappings.entries
              .firstWhereOrNull(
                (e) => e.value.toUpperCase() == aid.toUpperCase(),
              )
              ?.key;

          if (existingId != null) {
            final ownershipToken = _channelOwnership.currentToken(existingId);
            if (ownershipToken == null) {
              throw AppException(
                AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED,
                message:
                    'Tracked OMAPI channel $existingId for AID $aid has no current owner',
              );
            }
            _pendingCloses[existingId]?.cancel();
            _pendingCloses.remove(existingId);
            _refCounts[existingId] = (_refCounts[existingId] ?? 0) + 1;
            log.info(
              'Reusing existing logical channel $existingId for AID $aid (refs: ${_refCounts[existingId]})',
            );
            return _OmapiChannel(
              this,
              existingId,
              aid,
              ownershipToken,
            );
          }
        }
      }

      // 2. Otherwise open new
      if (AppSettings().ensureSingleChannel) {
        log.info(
          'Evaluating "ensureSingleChannel" cleanup. Current refcounts: $_refCounts',
        );
        if (_refCounts.values.every((c) => c <= 0)) {
          await cleanupChannels();
        } else {
          log.info(
            'Skipping "ensureSingleChannel" cleanup: active sessions detected ($_refCounts)',
          );
        }
      }
      final internalId = _nextChannelIds[readerId] ?? 1;
      _nextChannelIds[readerId] = (internalId % 3) + 1;
      if (aids != null && aids.isNotEmpty) {
        try {
          final nativeAids = omapiNativeOpenCandidates(
            aids,
            _channelMappings.values,
          );
          final result = await _invoke('openChannel', {
            'reader': _internalReaderName,
            'aids': nativeAids,
          });
          final resultMap = (result is Map) ? result : {'success': true};
          final String? selectedAid = resultMap['aid'] as String?;
          if (selectedAid != null) {
            _channelMappings[internalId] = selectedAid;
            final ownershipToken = _channelOwnership.claim(internalId);
            _refCounts[internalId] = (_refCounts[internalId] ?? 0) + 1;
            return _OmapiChannel(
              this,
              internalId,
              selectedAid,
              ownershipToken,
            );
          }
        } catch (e) {
          log.warning('Native scan failed: $e');
          if (isOmapiSessionCorruptedError(e)) {
            throw AppException(
              AppErrorCode.ERROR_OMAPI_SESSION_CORRUPTED,
              message: omapiRebootRequiredMessage,
              originalError: e,
            );
          }
          if (e is PlatformException &&
              (e.code == 'AccessControlException' ||
                  e.message == 'no APDU access allowed')) {
            throw AppException(
              AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED,
              message: 'ARA-M permissions not allowed',
              originalError: e,
            );
          }
          throw AppException(
            AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED,
            originalError: e,
          );
        }
      }
      log.info('Creating deferred logical channel placeholder: $internalId');
      _refCounts[internalId] = (_refCounts[internalId] ?? 0) + 1;
      return _OmapiChannel(this, internalId, null, null);
    });
  }

  Future<Uint8List> _transmitOnChannel(String aidHex, Uint8List apdu) async {
    return await runExclusive(() async {
      if (_internalReaderName == null) {
        throw AppException(
          AppErrorCode.ERROR_OMAPI_READER_NOT_AVAILABLE,
          message: 'Not connected to OMAPI reader',
        );
      }
      final String apduHex = HexUtils.bytesToHex(apdu);

      try {
        final String responseHex = await _invoke('transmitOnChannel', {
          'reader': _internalReaderName,
          'aid': aidHex,
          'apdu': apduHex,
        });

        return HexUtils.hexToBytes(responseHex);
      } catch (e) {
        if (e is PlatformException && e.code == 'BUSY') {
          throw CardBusyException(
            e.message ?? 'Card busy - session unavailable',
          );
        }
        rethrow;
      }
    });
  }

  Future<void> _requestCloseChannel(
    int channelId,
    String aidHex,
    int? ownershipToken, {
    bool immediate = false,
  }) async {
    if (!_channelOwnership.owns(channelId, ownershipToken)) {
      log.info(
        'Ignoring stale close for channel $channelId / AID $aidHex: ownership changed',
      );
      return;
    }

    _refCounts[channelId] = (_refCounts[channelId] ?? 1) - 1;
    if (_refCounts[channelId]! <= 0) {
      if (_profileSwitchInProgress || immediate) {
        await _finalizeCloseChannel(channelId, aidHex, ownershipToken);
        return;
      }
      log.info(
        'Channel $channelId close request pending: delaying 3s for AID $aidHex...',
      );
      _pendingCloses[channelId]?.cancel();
      _pendingCloses[channelId] = Timer(const Duration(seconds: 3), () async {
        try {
          await _finalizeCloseChannel(channelId, aidHex, ownershipToken);
        } catch (e) {
          log.severe('Deferred channel close failed: $e');
        }
        _pendingCloses.remove(channelId);
      });
    } else {
      log.info(
        'Channel $channelId decrement: still held by ${_refCounts[channelId]} refs',
      );
    }
  }

  Future<void> _finalizeCloseChannel(
    int channelId,
    String aidHex,
    int? ownershipToken,
  ) async {
    return await runExclusive(() async {
      if (_internalReaderName == null) return;
      if (!_channelOwnership.owns(channelId, ownershipToken)) {
        log.info(
          'Skipping stale finalized close for channel $channelId / AID $aidHex',
        );
        return;
      }

      try {
        await _invoke('closeChannel', {
          'reader': _internalReaderName,
          'aid': aidHex,
        });
        log.info(
          'Closed logical channel AID: $aidHex on reader: $_internalReaderName',
        );
      } catch (e) {
        log.warning('Failed to close channel for $aidHex: $e');
        if (isOmapiSessionCorruptedError(e)) rethrow;
      } finally {
        if (_channelOwnership.releaseIfOwned(channelId, ownershipToken)) {
          _channelMappings.remove(channelId);
          _refCounts.remove(channelId);
        }
      }
    });
  }

  void _ensureAidNotOwnedByAnotherChannel(String aidHex, int channelId) {
    final existing = _channelMappings.entries.firstWhereOrNull(
      (entry) =>
          entry.key != channelId &&
          entry.value.toUpperCase() == aidHex.toUpperCase(),
    );
    if (existing != null) {
      throw AppException(
        AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED,
        message:
            'AID $aidHex is already owned by logical channel ${existing.key}',
      );
    }
  }

  Future<Map<dynamic, dynamic>> _openChannelInKotlin(
    String aidHex,
    int channelId,
  ) async {
    return await runExclusive(() async {
      if (_internalReaderName == null) {
        throw AppException(
          AppErrorCode.ERROR_OMAPI_READER_NOT_AVAILABLE,
          message: 'Not connected to reader',
        );
      }
      _ensureAidNotOwnedByAnotherChannel(aidHex, channelId);

      try {
        final result = await _invoke('openChannel', {
          'reader': _internalReaderName,
          'aid': aidHex,
        });

        _channelMappings[channelId] = aidHex;
        final ownershipToken = _channelOwnership.claim(channelId);
        // Small delay for SE stability after select
        await Future.delayed(const Duration(milliseconds: 50));

        final resultMap = result is bool
            ? <dynamic, dynamic>{"success": result}
            : Map<dynamic, dynamic>.from(result as Map);
        resultMap['_ownershipToken'] = ownershipToken;
        return resultMap;
      } catch (e) {
        if (isOmapiSessionCorruptedError(e)) rethrow;
        // If first attempt fails, try heavy cleanup and retry once
        log.warning(
          'Initial openChannel for $aidHex failed ($e). Retrying after cleanup...',
        );
        try {
          await cleanupChannels();
          _ensureAidNotOwnedByAnotherChannel(aidHex, channelId);
          final result = await _invoke('openChannel', {
            'reader': _internalReaderName,
            'aid': aidHex,
          });
          _channelMappings[channelId] = aidHex;
          final ownershipToken = _channelOwnership.claim(channelId);
          await Future.delayed(const Duration(milliseconds: 50));

          final resultMap = result is bool
              ? <dynamic, dynamic>{"success": result}
              : Map<dynamic, dynamic>.from(result as Map);
          resultMap['_ownershipToken'] = ownershipToken;
          return resultMap;
        } catch (retryE) {
          log.severe('Retry openChannel failed for $aidHex: $retryE');
          if (retryE is PlatformException &&
              (retryE.code == 'AccessControlException' ||
                  retryE.message == 'no APDU access allowed')) {
            throw AppException(
              AppErrorCode.ERROR_OMAPI_PERMISSION_DENIED,
              message: 'ARA-M permissions not allowed',
              originalError: retryE,
            );
          }
          throw AppException(
            AppErrorCode.ERROR_OMAPI_CHANNEL_OPEN_FAILED,
            originalError: retryE,
          );
        }
      }
    });
  }

  /// Initialize OMAPI event stream
  static void initializeEventStream() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final Map<String, dynamic> eventData = Map<String, dynamic>.from(event);
        _log.info('OMAPI Event: $eventData');
      },
      onError: (error) {
        _log.warning('OMAPI Event error: $error');
      },
    );
  }

  @override
  Future<void> setProfileSwitchInProgress(bool value) async {
    // This marker is local metadata, not an OMAPI operation, so it remains callable after poison.
    _profileSwitchInProgress = value;
    await _channel.invokeMethod('setProfileSwitchInProgress', {'value': value});
  }
}

class _OmapiChannel extends BaseChannel {
  final OmapiAdapter _adapter;
  final int _internalId;
  String? _aidHex;
  int? _ownershipToken;
  Uint8List? _lastSelectResponse;

  _OmapiChannel(
    this._adapter,
    this._internalId,
    this._aidHex,
    this._ownershipToken,
  ) : super(_adapter, _internalId);

  @override
  int get channelNumber => _internalId;

  @override
  String? get aid => _aidHex;

  @override
  Future<void> close() async {
    if (_aidHex != null) {
      await _adapter._requestCloseChannel(
        _internalId,
        _aidHex!,
        _ownershipToken,
      );
    }
  }

  @override
  Future<Uint8List> sendRawApdu(Uint8List apdu) async {
    if (_aidHex == null) throw Exception('AID not selected');
    return await _adapter._transmitOnChannel(_aidHex!, apdu);
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
    // If SELECT AID (INS=A4, P1=04)
    if (ins == 0xA4 && p1 == 0x04 && data != null) {
      final targetAid = HexUtils.bytesToHex(data);

      // If we already have a channel open but for a DIFFERENT aid, we must switch.
      // Logical channels are usually pinned to the AID they were opened with.
      if (_aidHex != null && _aidHex != targetAid) {
        _adapter.log.info(
          'OMAPI: Switching AID from $_aidHex to $targetAid (closing old channel placeholder)',
        );
        try {
          // The old ownership must be retired before this handle claims the new AID.
          await _adapter._requestCloseChannel(
            _internalId,
            _aidHex!,
            _ownershipToken,
            immediate: true,
          );
          _aidHex = null;
          _ownershipToken = null;
        } catch (e) {
          _adapter.log.warning('Failed to close old channel during switch: $e');
          if (isOmapiSessionCorruptedError(e)) rethrow;
          _aidHex = null;
          _ownershipToken = null;
        }
      }

      if (_aidHex == null) {
        _adapter.log.info(
          'OMAPI Deferred Opening: Selecting AID $targetAid on channel $_internalId',
        );

        try {
          final result = await _adapter._openChannelInKotlin(
            targetAid,
            _internalId,
          );
          _aidHex = targetAid;
          _ownershipToken = result['_ownershipToken'] as int?;

          // Return the actual select response if provided by plugin
          final String? selectResp = result['selectResponse'];
          if (selectResp != null) {
            _lastSelectResponse = HexUtils.hexToBytes(selectResp);
            return _lastSelectResponse!;
          }
          _lastSelectResponse = Uint8List.fromList([0x90, 0x00]);
          return _lastSelectResponse!;
        } catch (e) {
          _adapter.log.severe(
            'Failed to open logical channel for AID $targetAid: $e',
          );
          rethrow;
        }
      } else if (_aidHex == targetAid) {
        // Already selected, return cached response
        return _lastSelectResponse ?? Uint8List.fromList([0x90, 0x00]);
      }
    }

    try {
      return await super.transmit(cla, ins, p1, p2, data, le);
    } catch (e) {
      final bool isChannelLost =
          (e is PlatformException && e.code == 'CHANNEL_NOT_FOUND');

      if (isChannelLost) {
        _adapter.log.warning(
          'Recovery trigger for error (lost=true) on AID $_aidHex, cleaning up and re-opening...',
        );
        try {
          // Simple re-open if just channel lost
          await OmapiAdapter._invoke('openChannel', {
            'reader': _adapter._internalReaderName,
            'aid': _aidHex,
          });
          _adapter._channelMappings[_internalId] = _aidHex!;
          _ownershipToken = _adapter._channelOwnership.claim(_internalId);

          // Otherwise just retry the raw transmission
          return await super.transmit(cla, ins, p1, p2, data, le);
        } catch (recoveryErr) {
          if (isOmapiSessionCorruptedError(recoveryErr)) rethrow;
          _adapter.log.warning(
            'Failed to recover from error on AID $_aidHex: $recoveryErr',
          );
          throw e; // Throw original error if recovery fails
        }
      }
      rethrow;
    }
  }
}
