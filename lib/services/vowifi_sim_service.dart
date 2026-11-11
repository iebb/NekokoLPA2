import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../adapter/euicc_adapter.dart';
import '../adapter/omapi/omapi_adapter.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../settings/app_settings.dart';
import '../utils/vowifi_reader_support.dart';
import 'package:nlpa2/vowifi_sms/vowifi_sms_plugin.dart';
import 'package:logging/logging.dart';

class VowifiCardInfo {
  const VowifiCardInfo({
    this.iccid = '',
    this.imsi = '',
    this.mncLength = 0,
    this.smsc = '',
    this.gid1 = '',
    this.gid2 = '',
    this.isimDomain = '',
    this.impi = '',
    this.impu = '',
  });

  final String iccid;
  final String imsi;
  final int mncLength;
  final String smsc;
  final String gid1;
  final String gid2;
  final String isimDomain;
  final String impi;
  final String impu;
}

class VowifiAkaResult {
  const VowifiAkaResult({
    required this.res,
    required this.ck,
    required this.ik,
    required this.auts,
  });

  final Uint8List res;
  final Uint8List ck;
  final Uint8List ik;
  final Uint8List auts;
}

class VowifiSimService {
  static final Logger _log = Logger('VowifiSimService');
  static final Object _apduLogKey = Object();

  Future<VowifiCardInfo> probe(
    Adapter adapter,
    Reader reader, {
    void Function(String line)? onLog,
  }) async {
    _ensureBasicChannelSupported(reader);
    return runZoned(
      () => adapter.runExclusive(() async {
        _emitLog(onLog, 'VoWiFi probe start: ${reader.name}');
        _log.info('VoWiFi probe start reader=${reader.name}');
        await adapter.connect(reader);
        await adapter.cleanupChannels();
        final iccid = await _readIccid(adapter);
        _emitLog(onLog, 'Read ICCID: $iccid');
        final imsi = await _readImsi(adapter);
        _emitLog(onLog, 'Read IMSI: $imsi');
        final mncLength = await _readMncLength(adapter);
        _emitLog(onLog, 'Read MNC length: $mncLength');
        final gid1 = await _readGid(adapter, const <int>[0x6F, 0x3E]);
        if (gid1.isNotEmpty) {
          _emitLog(onLog, 'Read GID1: $gid1');
        }
        final gid2 = await _readGid(adapter, const <int>[0x6F, 0x3F]);
        if (gid2.isNotEmpty) {
          _emitLog(onLog, 'Read GID2: $gid2');
        }
        final smsc = await _readSmsc(adapter);
        _emitLog(onLog, 'Read SMSC: $smsc');
        _IsimIdentities isim = const _IsimIdentities(
          impi: '',
          impu: '',
          domain: '',
        );
        try {
          isim = await _readIsimIdentities(adapter);
          _emitLog(
            onLog,
            'Read ISIM: impi=${isim.impi.isEmpty ? '<none>' : isim.impi} impu=${isim.impu.isEmpty ? '<none>' : isim.impu} domain=${isim.domain.isEmpty ? '<none>' : isim.domain}',
          );
        } catch (_) {}
        _emitLog(
          onLog,
          'SIM reader=${reader.name} atr=${adapter.lastAtr ?? ''} iccid=$iccid imsi=$imsi mnc_length=$mncLength smsc=$smsc impi=${isim.impi} impu=${isim.impu} isim_domain=${isim.domain}',
        );
        return VowifiCardInfo(
          iccid: iccid,
          imsi: imsi,
          mncLength: mncLength,
          smsc: smsc,
          gid1: gid1,
          gid2: gid2,
          isimDomain: isim.domain,
          impi: isim.impi,
          impu: isim.impu,
        );
      }),
      zoneValues: <Object?, Object?>{_apduLogKey: onLog},
    );
  }

  Future<VowifiAkaResult> authenticateIms(
    Adapter adapter,
    Reader reader, {
    required Uint8List rand,
    required Uint8List autn,
    void Function(String line)? onLog,
  }) async {
    requireVowifiReader(adapter, reader);
    _ensureBasicChannelSupported(reader);
    return runZoned(
      () => adapter.runExclusive(() async {
        _emitLog(onLog, 'Starting IMS AKA');
        _log.info('VoWiFi AKA start reader=${reader.name}');
        await adapter.connect(reader);
        await adapter.cleanupChannels();
        await _selectAdfUsim(adapter);
        final payload = Uint8List.fromList(<int>[
          rand.length,
          ...rand,
          autn.length,
          ...autn,
        ]);
        final response = await _transmit(
          adapter,
          Uint8List.fromList(<int>[
            0x00,
            0x88,
            0x00,
            0x81,
            payload.length,
            ...payload,
          ]),
        );
        _emitLog(onLog, 'AKA APDU completed');
        return _parseAkaResponse(response);
      }),
      zoneValues: <Object?, Object?>{_apduLogKey: onLog},
    );
  }

  Future<VowifiAkaResponse> authenticateDigestChallenge(
    Adapter adapter,
    Reader reader, {
    required VowifiDigestChallenge challenge,
    void Function(String line)? onLog,
  }) async {
    requireVowifiReader(adapter, reader);
    final nonce = challenge.fields['nonce'] ?? '';
    final bytes = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(nonce)
        ? Uint8List.fromList([
            for (var i = 0; i < nonce.length; i += 2)
              int.parse(nonce.substring(i, i + 2), radix: 16),
          ])
        : base64.decode(base64.normalize(nonce));
    if (bytes.length < 32 || bytes.length > 256) {
      throw const FormatException('Invalid IMS AKA nonce length');
    }
    final aka = await authenticateIms(
      adapter,
      reader,
      rand: Uint8List.fromList(bytes.sublist(0, 16)),
      autn: Uint8List.fromList(bytes.sublist(16, 32)),
      onLog: onLog,
    );
    // AUTS is a resynchronization response, not a failed connection. SIP sends
    // it with an empty digest password and waits for the network's fresh nonce.
    return VowifiAkaResponse(
      res: aka.res,
      ck: aka.ck,
      ik: aka.ik,
      auts: aka.auts,
    );
  }

  Future<void> enableProfileBasic(
    Adapter adapter,
    Reader reader, {
    required String iccid,
  }) async {
    _ensureBasicChannelSupported(reader);
    await runZoned(
      () => adapter.runExclusive(() async {
        _log.info(
          'VoWiFi enable profile basic reader=${reader.name} iccid=$iccid',
        );
        await adapter.connect(reader);
        await adapter.cleanupChannels();
        await _selectIsdrOnBasic(adapter);

        var iccidHex = iccid;
        if (iccidHex.length.isOdd) {
          iccidHex = '${iccidHex}F';
        }
        final iccidBytes = Uint8List.fromList(
          _hexToBytes(_swapNibbles(iccidHex)),
        );
        final request = EnableProfileRequest(
          profileIdentifier: EnableProfileRequest_profileIdentifier(
            iccid: iccidBytes,
          ),
          refreshFlag: false,
        );
        final result = await _transmitEuicc(
          adapter,
          Uint8List.fromList(<int>[
            0x80,
            0xE2,
            0x91,
            0x00,
            ...request.encode(),
          ]),
        );
        if (result.data.isNotEmpty) {
          final response = EnableProfileResponse.decode(result.data);
          if (response.enableResult != null &&
              response.enableResult != EnableProfileResponse_enableResult.ok &&
              response.enableResult !=
                  EnableProfileResponse_enableResult
                      .profileNotInDisabledState) {
            throw StateError('ENABLE_FAILED:${response.enableResult!.name}');
          }
        }
      }),
      zoneValues: <Object?, Object?>{_apduLogKey: null},
    );
  }

  VowifiSmsConfig deriveSmsConfig(
    VowifiCardInfo info, {
    required VowifiTransport transport,
    required bool tlsSkipVerify,
    String sipServerOverride = '',
    String deviceIdentity = '',
  }) {
    final normalizedSipServer = sipServerOverride.trim();
    final mncLength = info.mncLength == 2 || info.mncLength == 3
        ? info.mncLength
        : 2;
    final imsi = info.imsi.trim();
    if (imsi.length < 3 + mncLength) {
      throw StateError('IMSI unavailable for IMS normalization');
    }
    final mcc = imsi.substring(0, 3);
    final mnc = imsi.substring(3, 3 + mncLength);
    final paddedMnc = mnc.padLeft(3, '0');
    final domain = 'ims.mnc$paddedMnc.mcc$mcc.3gppnetwork.org';
    final epdgServer = 'epdg.epc.mnc$paddedMnc.mcc$mcc.pub.3gppnetwork.org';
    final username = info.impi.contains('@')
        ? info.impi.split('@').first
        : imsi;
    final privateIdentity = info.impi.isNotEmpty
        ? info.impi
        : '$username@$domain';
    final publicIdentity = info.impu;
    final defaultPort = transport == VowifiTransport.tls ? 5061 : 5060;
    final sipServer = normalizedSipServer.isNotEmpty
        ? normalizedSipServer
        : '$domain:$defaultPort';
    if (info.smsc.trim().isEmpty) {
      throw StateError('SMSC unavailable on current profile');
    }
    return VowifiSmsConfig(
      sipServer: sipServer,
      domain: domain,
      privateIdentity: privateIdentity,
      publicIdentity: publicIdentity,
      username: username,
      password: '',
      smsc: info.smsc.trim(),
      transport: VowifiTransport.udp,
      tlsSkipVerify: tlsSkipVerify,
      useEpdg: true,
      epdgServer: epdgServer,
      epdgPort: 500,
      imsi: imsi,
      mcc: mcc,
      mnc: mnc,
      mncLength: mncLength,
      apn: 'ims',
      deviceIdentity: deviceIdentity,
    );
  }

  void _ensureBasicChannelSupported(Reader reader) {
    if (reader.source is OmapiAdapter) {
      throw UnsupportedError(
        'VoWiFi SIM access requires direct raw APDUs on the basic channel; OMAPI is not supported.',
      );
    }
  }

  void _emitLog(void Function(String line)? onLog, String line) {
    onLog?.call(line);
  }

  void _emitApduLog(String line) {
    final sink = Zone.current[_apduLogKey] as void Function(String line)?;
    sink?.call(line);
  }

  Future<String> _readIccid(Adapter adapter) async {
    await _selectFile(adapter, const <int>[0x3F, 0x00]);
    await _selectFile(adapter, const <int>[0x2F, 0xE2]);
    final raw = await _readBinary(adapter, 10);
    return _decodeIccid(raw);
  }

  Future<String> _readImsi(Adapter adapter) async {
    try {
      await _selectAdfUsim(adapter);
      final raw = await _readImsiEf(adapter);
      final imsi = _decodeImsi(raw);
      if (imsi.isNotEmpty) {
        return imsi;
      }
    } catch (_) {}
    await _selectFile(adapter, const <int>[0x3F, 0x00]);
    await _selectFile(adapter, const <int>[0x7F, 0x20]);
    final raw = await _readImsiEf(adapter);
    final imsi = _decodeImsi(raw);
    if (imsi.isEmpty) {
      throw StateError('IMSI unavailable');
    }
    return imsi;
  }

  Future<Uint8List> _readImsiEf(Adapter adapter) async {
    final fcp = await _selectFile(adapter, const <int>[0x6F, 0x07]);
    var length = _parseFcpLength(fcp);
    if (length <= 0 || length > 255) {
      length = 9;
    }
    return _readBinary(adapter, length);
  }

  Future<int> _readMncLength(Adapter adapter) async {
    await _selectAdfUsim(adapter);
    final fcp = await _selectFile(adapter, const <int>[0x6F, 0xAD]);
    var length = _parseFcpLength(fcp);
    if (length <= 0 || length > 255) {
      length = 4;
    }
    final raw = await _readBinary(adapter, length);
    if (raw.length < 4) {
      throw StateError('Short EF.AD');
    }
    final mncLength = raw[3] & 0x0F;
    if (mncLength < 2 || mncLength > 3) {
      throw StateError('Invalid MNC length');
    }
    return mncLength;
  }

  Future<String> _readGid(Adapter adapter, List<int> fileId) async {
    try {
      await _selectAdfUsim(adapter);
      final raw = await _readTransparentFile(adapter, fileId);
      final trimmed = _trimBytes(raw, const <int>[0x00, 0xFF]);
      return trimmed.isEmpty ? '' : _hex(trimmed);
    } catch (_) {
      return '';
    }
  }

  Future<String> _readSmsc(Adapter adapter) async {
    try {
      await _selectFile(adapter, const <int>[0x3F, 0x00]);
      await _selectFile(adapter, const <int>[0x7F, 0x10]);
      final fcp = await _selectFile(adapter, const <int>[0x6F, 0x42]);
      var length = _parseFcpRecordLength(fcp);
      if (length <= 0 || length > 255) {
        length = 0xFF;
      }
      final record = await _readRecord(adapter, 1, 0x04, length);
      final smsc = _decodeSmscFromSmspRecord(record);
      if (smsc.isNotEmpty) {
        return smsc;
      }
    } catch (_) {}

    await _selectAdfUsim(adapter);
    final fcp = await _selectFile(adapter, const <int>[0x6F, 0x42]);
    var length = _parseFcpRecordLength(fcp);
    if (length <= 0 || length > 255) {
      length = 0xFF;
    }
    final record = await _readRecord(adapter, 1, 0x04, length);
    final smsc = _decodeSmscFromSmspRecord(record);
    if (smsc.isEmpty) {
      throw StateError('SMSC unavailable');
    }
    return smsc;
  }

  Future<_IsimIdentities> _readIsimIdentities(Adapter adapter) async {
    await _selectAdfIsim(adapter);
    var impi = '';
    var domain = '';
    var impu = '';
    try {
      impi = _extractNai(
        await _readTransparentFile(adapter, const <int>[0x6F, 0x02]),
      );
    } catch (_) {}
    try {
      domain = _extractNai(
        await _readTransparentFile(adapter, const <int>[0x6F, 0x03]),
      );
    } catch (_) {}
    try {
      impu = _extractNai(
        await _readRecordFile(adapter, const <int>[0x6F, 0x04]),
      );
    } catch (_) {}
    if (impi.isEmpty && impu.isEmpty && domain.isEmpty) {
      throw StateError('ISIM identities unavailable');
    }
    return _IsimIdentities(impi: impi, impu: impu, domain: domain);
  }

  Future<Uint8List> _readTransparentFile(
    Adapter adapter,
    List<int> fileId,
  ) async {
    final fcp = await _selectFile(adapter, fileId);
    var length = _parseFcpLength(fcp);
    if (length <= 0 || length > 255) {
      length = 128;
    }
    return _readBinary(adapter, length);
  }

  Future<Uint8List> _readRecordFile(Adapter adapter, List<int> fileId) async {
    await _selectFile(adapter, fileId);
    return _readRecord(adapter, 1, 0x04, 0xFF);
  }

  Future<Uint8List> _selectAdfUsim(Adapter adapter) async {
    await _selectFile(adapter, const <int>[0x3F, 0x00]);
    final dirAid = await _findAidInEfDir(adapter, const <int>[
      0xA0,
      0x00,
      0x00,
      0x00,
      0x87,
      0x10,
      0x02,
    ]);
    if (dirAid.isEmpty) {
      throw StateError('USIM AID not found');
    }
    return _transmit(
      adapter,
      Uint8List.fromList(<int>[
        0x00,
        0xA4,
        0x04,
        0x00,
        dirAid.length,
        ...dirAid,
      ]),
    );
  }

  Future<Uint8List> _selectAdfIsim(Adapter adapter) async {
    await _selectFile(adapter, const <int>[0x3F, 0x00]);
    final dirAid = await _findAidInEfDir(adapter, const <int>[
      0xA0,
      0x00,
      0x00,
      0x00,
      0x87,
      0x10,
      0x04,
    ]);
    if (dirAid.isEmpty) {
      throw StateError('ISIM AID not found');
    }
    return _transmit(
      adapter,
      Uint8List.fromList(<int>[
        0x00,
        0xA4,
        0x04,
        0x00,
        dirAid.length,
        ...dirAid,
      ]),
    );
  }

  Future<void> _selectIsdrOnBasic(Adapter adapter) async {
    final aidStrings = AppSettings().aids;
    Object? lastError;
    for (final aidString in aidStrings) {
      try {
        final clean = aidString.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
        if (clean.isEmpty || clean.length.isOdd) {
          continue;
        }
        final aid = _hexToBytes(clean);
        await _transmit(
          adapter,
          Uint8List.fromList(<int>[0x00, 0xA4, 0x04, 0x00, aid.length, ...aid]),
        );
        return;
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Unable to select ISD-R on basic channel: $lastError');
  }

  Future<Uint8List> _findAidInEfDir(Adapter adapter, List<int> prefix) async {
    final fcp = await _selectFile(adapter, const <int>[0x2F, 0x00]);
    var recordLength = _parseFcpRecordLength(fcp);
    if (recordLength <= 0 || recordLength > 255) {
      recordLength = 0x20;
    }
    for (var record = 1; record <= 32; record++) {
      try {
        final raw = await _readRecord(adapter, record, 0x04, recordLength);
        final trimmed = _trimBytes(raw, const <int>[0x00, 0xFF]);
        if (trimmed.isEmpty) {
          continue;
        }
        final aid = _findAidByPrefix(trimmed, prefix);
        if (aid.isNotEmpty) {
          return aid;
        }
      } catch (_) {
        if (record == 1) {
          rethrow;
        }
        break;
      }
    }
    return Uint8List(0);
  }

  Future<Uint8List> _selectFile(Adapter adapter, List<int> fileId) async {
    return _transmit(
      adapter,
      Uint8List.fromList(<int>[
        0x00,
        0xA4,
        0x00,
        0x04,
        fileId.length,
        ...fileId,
      ]),
    );
  }

  Future<Uint8List> _readBinary(Adapter adapter, int length) async {
    return _transmit(
      adapter,
      Uint8List.fromList(<int>[0x00, 0xB0, 0x00, 0x00, length]),
    );
  }

  Future<Uint8List> _readRecord(
    Adapter adapter,
    int record,
    int mode,
    int length,
  ) async {
    return _transmit(
      adapter,
      Uint8List.fromList(<int>[0x00, 0xB2, record, mode, length]),
    );
  }

  Future<Uint8List> _transmit(Adapter adapter, Uint8List request) async {
    var apdu = Uint8List.fromList(request);
    final secret = _carriesAkaVectors(request);
    _logApduRequest(apdu, secret);
    var response = await adapter.sendRawApdu(apdu);
    _emitApduLog(_formatApduResponse(response, secret));
    for (var tries = 0; tries < 6; tries++) {
      final sw = _sw(response);
      if (sw == 0x6700 && apdu.length >= 5) {
        apdu = Uint8List.fromList(
          List<int>.from(apdu)..[apdu.length - 1] = 0x00,
        );
        _logApduRequest(apdu, secret);
        response = await adapter.sendRawApdu(apdu);
        _emitApduLog(_formatApduResponse(response, secret));
        continue;
      }
      if ((sw >> 8) == 0x6C) {
        apdu = Uint8List.fromList(
          List<int>.from(apdu)..[apdu.length - 1] = sw & 0xFF,
        );
        _logApduRequest(apdu, secret);
        response = await adapter.sendRawApdu(apdu);
        _emitApduLog(_formatApduResponse(response, secret));
        continue;
      }
      break;
    }
    final data = BytesBuilder(copy: false);
    while (_sw(response) >> 8 == 0x61) {
      data.add(response.sublist(0, response.length - 2));
      final getResponse = Uint8List.fromList(<int>[
        0x00,
        0xC0,
        0x00,
        0x00,
        _sw(response) & 0xFF,
      ]);
      _logApduRequest(getResponse, secret);
      response = await adapter.sendRawApdu(getResponse);
      _emitApduLog(_formatApduResponse(response, secret));
    }
    final sw = _sw(response);
    if (sw != 0x9000) {
      throw StateError('APDU failed with ${sw.toRadixString(16)}');
    }
    data.add(response.sublist(0, response.length - 2));
    return data.toBytes();
  }

  Future<_ApduResult> _transmitEuicc(Adapter adapter, Uint8List request) async {
    var apdu = Uint8List.fromList(request);
    final secret = _carriesAkaVectors(request);
    _logApduRequest(apdu, secret);
    var response = await adapter.sendRawApdu(apdu);
    _emitApduLog(_formatApduResponse(response, secret));
    for (var tries = 0; tries < 6; tries++) {
      final sw = _sw(response);
      if (sw == 0x6700 && apdu.length >= 5) {
        apdu = Uint8List.fromList(
          List<int>.from(apdu)..[apdu.length - 1] = 0x00,
        );
        _logApduRequest(apdu, secret);
        response = await adapter.sendRawApdu(apdu);
        _emitApduLog(_formatApduResponse(response, secret));
        continue;
      }
      if ((sw >> 8) == 0x6C) {
        apdu = Uint8List.fromList(
          List<int>.from(apdu)..[apdu.length - 1] = sw & 0xFF,
        );
        _logApduRequest(apdu, secret);
        response = await adapter.sendRawApdu(apdu);
        _emitApduLog(_formatApduResponse(response, secret));
        continue;
      }
      break;
    }
    final data = BytesBuilder(copy: false);
    while (_sw(response) >> 8 == 0x61) {
      data.add(response.sublist(0, response.length - 2));
      final getResponse = Uint8List.fromList(<int>[
        0x00,
        0xC0,
        0x00,
        0x00,
        _sw(response) & 0xFF,
      ]);
      _logApduRequest(getResponse, secret);
      response = await adapter.sendRawApdu(getResponse);
      _emitApduLog(_formatApduResponse(response, secret));
    }
    final sw = _sw(response);
    if (sw != 0x9000 && (sw >> 8) != 0x91) {
      throw StateError('APDU failed with ${sw.toRadixString(16)}');
    }
    data.add(response.sublist(0, response.length - 2));
    return _ApduResult(Uint8List.fromList(data.toBytes()), sw);
  }

  int _sw(Uint8List response) {
    if (response.length < 2) {
      throw StateError('Short APDU response');
    }
    return (response[response.length - 2] << 8) | response.last;
  }

  /// AUTHENTICATE sends RAND and AUTN and returns RES, CK and IK. The log shows
  /// that it happened and how much moved, never the vectors themselves.
  bool _carriesAkaVectors(Uint8List request) =>
      request.length > 1 && request[1] == 0x88;

  void _logApduRequest(Uint8List apdu, bool secret) {
    if (secret && apdu.length > 5) {
      _emitApduLog(
        'APDU >> ${_hex(apdu.sublist(0, 5))} [${apdu.length - 5} bytes hidden]',
      );
    } else {
      _emitApduLog('APDU >> ${_hex(apdu)}');
    }
  }

  String _formatApduResponse(Uint8List response, [bool secret = false]) {
    final sw = _sw(response).toRadixString(16).padLeft(4, '0').toUpperCase();
    final data = response.sublist(0, response.length - 2);
    final prefix = data.isEmpty
        ? 'APDU << '
        : secret
        ? 'APDU << [${data.length} bytes hidden] '
        : 'APDU << ${_hex(data)} ';
    return '${prefix}SW=$sw';
  }

  String _hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }

  VowifiAkaResult _parseAkaResponse(Uint8List response) {
    if (response.isEmpty) {
      throw StateError('Short AKA response');
    }
    final fields = _splitLengthFields(response.sublist(1));
    if (response[0] == 0xDB) {
      if (fields.length < 3) {
        throw StateError('AKA response missing fields');
      }
      return VowifiAkaResult(
        res: fields[0],
        ck: fields[1],
        ik: fields[2],
        auts: Uint8List(0),
      );
    }
    if (response[0] == 0xDC) {
      if (fields.isEmpty) {
        throw StateError('AKA sync failure without AUTS');
      }
      return VowifiAkaResult(
        res: Uint8List(0),
        ck: Uint8List(0),
        ik: Uint8List(0),
        auts: fields[0],
      );
    }
    throw StateError('Unexpected AKA tag ${response[0]}');
  }

  List<Uint8List> _splitLengthFields(Uint8List raw) {
    final fields = <Uint8List>[];
    var offset = 0;
    while (offset < raw.length) {
      final length = raw[offset];
      offset++;
      if (offset + length > raw.length) {
        throw StateError('Invalid length field');
      }
      fields.add(Uint8List.fromList(raw.sublist(offset, offset + length)));
      offset += length;
    }
    return fields;
  }

  int _parseFcpLength(Uint8List fcp) {
    for (var index = 0; index + 3 < fcp.length; index++) {
      if (fcp[index] == 0x80 && fcp[index + 1] == 0x02) {
        return (fcp[index + 2] << 8) | fcp[index + 3];
      }
    }
    return 0;
  }

  int _parseFcpRecordLength(Uint8List fcp) {
    for (var index = 0; index + 5 < fcp.length; index++) {
      if (fcp[index] != 0x82) {
        continue;
      }
      final length = fcp[index + 1];
      if (length < 5 || index + 1 + length >= fcp.length) {
        continue;
      }
      return (fcp[index + 4] << 8) | fcp[index + 5];
    }
    return 0;
  }

  Uint8List _findAidByPrefix(Uint8List dirData, List<int> prefix) {
    for (var index = 0; index + 2 < dirData.length; index++) {
      if (dirData[index] != 0x4F) {
        continue;
      }
      final length = dirData[index + 1];
      if (index + 2 + length > dirData.length) {
        continue;
      }
      final aid = dirData.sublist(index + 2, index + 2 + length);
      if (aid.length >= prefix.length) {
        var matches = true;
        for (var inner = 0; inner < prefix.length; inner++) {
          if (aid[inner] != prefix[inner]) {
            matches = false;
            break;
          }
        }
        if (matches) {
          return Uint8List.fromList(aid);
        }
      }
    }
    return Uint8List(0);
  }

  Uint8List _trimBytes(Uint8List input, List<int> values) {
    var start = 0;
    var end = input.length;
    while (start < end && values.contains(input[start])) {
      start++;
    }
    while (end > start && values.contains(input[end - 1])) {
      end--;
    }
    return Uint8List.fromList(input.sublist(start, end));
  }

  String _decodeImsi(Uint8List raw) {
    if (raw.length < 2) {
      return '';
    }
    var digits = _decodeSwappedBcd(raw.sublist(1));
    if (digits.length < 2) {
      return '';
    }
    digits = digits.substring(1);
    if (raw[0] > 0) {
      final wanted = raw[0] * 2 - 1;
      if (wanted > 0 && digits.length > wanted) {
        digits = digits.substring(0, wanted);
      }
    }
    return digits;
  }

  String _decodeIccid(Uint8List raw) {
    return _decodeSwappedBcd(raw).replaceAll(RegExp(r'[fF]+$'), '');
  }

  String _decodeSwappedBcd(Uint8List raw) {
    final buffer = StringBuffer();
    for (final value in raw) {
      final lo = value & 0x0F;
      final hi = value >> 4;
      if (lo <= 9) {
        buffer.writeCharCode(48 + lo);
      }
      if (hi <= 9) {
        buffer.writeCharCode(48 + hi);
      }
    }
    return buffer.toString();
  }

  List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    return List<int>.generate(clean.length ~/ 2, (index) {
      final offset = index * 2;
      return int.parse(clean.substring(offset, offset + 2), radix: 16);
    });
  }

  String _swapNibbles(String hex) {
    final buffer = StringBuffer();
    for (var index = 0; index < hex.length; index += 2) {
      buffer.write(hex[index + 1]);
      buffer.write(hex[index]);
    }
    return buffer.toString();
  }

  String _decodeSmscFromSmspRecord(Uint8List record) {
    final trimmed = _trimBytes(record, const <int>[0x00, 0xFF]);
    if (trimmed.length >= 15) {
      final value = _decodeAddrField(
        trimmed.sublist(trimmed.length - 15, trimmed.length - 3),
      );
      if (value.isNotEmpty) {
        return value;
      }
    }
    for (var index = trimmed.length - 2; index >= 0; index--) {
      final length = trimmed[index];
      if (length < 2 || index + 1 + length > trimmed.length) {
        continue;
      }
      final value = _decodeAddrRaw(trimmed.sublist(index, index + 1 + length));
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _decodeAddrField(Uint8List field) {
    if (field.length < 2) {
      return '';
    }
    final length = field[0];
    if (length < 2 || length > field.length - 1) {
      return '';
    }
    return _decodeAddrRaw(field.sublist(0, 1 + length));
  }

  String _decodeAddrRaw(Uint8List raw) {
    if (raw.length < 3) {
      return '';
    }
    final length = raw[0];
    if (length < 2 || length > raw.length - 1) {
      return '';
    }
    final toa = raw[1];
    if ((toa & 0x80) == 0) {
      return '';
    }
    var digits = _decodeSwappedBcd(raw.sublist(2, 1 + length));
    digits = digits.replaceAll(RegExp(r'[fF]+$'), '');
    if (digits.length < 3) {
      return '';
    }
    final ton = (toa >> 4) & 0x07;
    return ton == 0x01 ? '+$digits' : digits;
  }

  String _extractNai(Uint8List raw) {
    for (var index = 0; index + 1 < raw.length; index++) {
      final tag = raw[index];
      if (tag != 0x80 && tag != 0x81) {
        continue;
      }
      final length = raw[index + 1];
      if (index + 2 + length > raw.length) {
        break;
      }
      final value = raw.sublist(index + 2, index + 2 + length);
      if (_isAscii(value)) {
        return ascii.decode(value);
      }
    }
    final trimmed = _trimBytes(raw, const <int>[0x00, 0xFF, 0x20]);
    if (_isAscii(trimmed) && ascii.decode(trimmed).contains('@')) {
      return ascii.decode(trimmed);
    }
    return '';
  }

  bool _isAscii(Uint8List bytes) {
    if (bytes.isEmpty) {
      return false;
    }
    for (final value in bytes) {
      if (value < 0x20 || value > 0x7E) {
        return false;
      }
    }
    return true;
  }
}

class _IsimIdentities {
  const _IsimIdentities({
    required this.impi,
    required this.impu,
    required this.domain,
  });

  final String impi;
  final String impu;
  final String domain;
}

class _ApduResult {
  const _ApduResult(this.data, this.sw);

  final Uint8List data;
  final int sw;
}
