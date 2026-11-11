import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import 'eap_aka_codec.dart';
import 'ike_datagram_codec.dart';
import 'models.dart';

typedef VowifiAkaProvider =
    Future<VowifiAkaResponse?> Function(VowifiAkaChallenge challenge);

class VowifiEpdgTunnel {
  VowifiEpdgTunnel._({
    required this.localAddress,
    required this.localPort,
    required InternetAddress remoteAddress,
    required int remotePort,
    required RawDatagramSocket outer,
    required _DatagramInbox inbox,
    required bool natt,
    required int spiIn,
    required int spiOut,
    required Uint8List encIn,
    required Uint8List encOut,
    required Uint8List integIn,
    required Uint8List integOut,
    required int integLength,
    required String integAlgorithm,
    required InternetAddress pcscfAddress,
    required int pcscfPort,
    void Function(String info)? onInfo,
  }) {
    _remoteAddress = remoteAddress;
    _remotePort = remotePort;
    _outer = outer;
    _natt = natt;
    _spiIn = spiIn;
    _spiOut = spiOut;
    _encIn = encIn;
    _encOut = encOut;
    _integIn = integIn;
    _integOut = integOut;
    _integLength = integLength;
    _integAlgorithm = integAlgorithm;
    _pcscfAddress = pcscfAddress;
    _pcscfPort = pcscfPort;
    _onInfo = onInfo;
    _inbox = inbox;
    _inbox.packetHandler = _handleOuterDatagram;
    _inbox.errorHandler = (error, stackTrace) {
      if (!_packets.isClosed) _packets.addError(error, stackTrace);
    };
    _inbox.doneHandler = () {
      if (!_packets.isClosed) _packets.close();
    };
    if (_natt) {
      _nattKeepalive = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sendNattKeepalive(),
      );
    }
  }

  final InternetAddress localAddress;
  final int localPort;
  late final InternetAddress _remoteAddress;
  late final int _remotePort;
  late final RawDatagramSocket _outer;
  late final _DatagramInbox _inbox;
  late final bool _natt;
  late final int _spiIn;
  late final int _spiOut;
  late final Uint8List _encIn;
  late final Uint8List _encOut;
  late final Uint8List _integIn;
  late final Uint8List _integOut;
  late final int _integLength;
  late final String _integAlgorithm;
  late final InternetAddress _pcscfAddress;
  late int _pcscfPort;
  late final void Function(String info)? _onInfo;
  Timer? _nattKeepalive;
  final StreamController<Uint8List> _packets =
      StreamController<Uint8List>.broadcast();

  int _seqOut = 1;
  bool _closed = false;
  bool _imsSecEnabled = false;
  int _imsSpiOut = 0;
  int _imsSpiIn = 0;
  int _imsSeqOut = 1;
  final Map<int, int> _imsSeqBySpi = <int, int>{};
  Uint8List _imsAuthKey = Uint8List(0);
  int _imsPortOut = 0;
  int _imsPortIn = 0;
  int _imsPeerPortIn = 0;
  final List<
    ({
      int spiIn,
      int spiOut,
      int portOut,
      int portIn,
      int peerPortIn,
      Uint8List authKey,
    })
  >
  _imsCandidates =
      <
        ({
          int spiIn,
          int spiOut,
          int portOut,
          int portIn,
          int peerPortIn,
          Uint8List authKey,
        })
      >[];
  bool _imsTcpMode = false;
  bool _imsTcpEstablished = false;
  int _imsTcpLocalPort = 0;
  int _imsTcpPeerPort = 0;
  int _imsTcpSeqOut = 0;
  int _imsTcpAckNext = 0;
  bool _imsTcpSynSent = false;
  int _imsTcpSynInSeq = 0;
  int _imsTcpSynRetries = 0;

  Stream<Uint8List> get packets => _packets.stream;
  String get pcscfHost => _pcscfAddress.address;
  int get pcscfPort => _pcscfPort;
  void setRemotePort(int port) {
    if (port > 0 && port <= 65535) {
      _pcscfPort = port;
    }
  }

  void configureImsIpSec({
    required int spiIn,
    required int spiOut,
    required int portC,
    required int portIn,
    required int peerPortIn,
    required Uint8List ik,
  }) {
    if (spiIn == 0 || spiOut == 0 || ik.isEmpty) {
      return;
    }
    final sameTuple =
        _imsSecEnabled && _imsSpiIn == spiIn && _imsSpiOut == spiOut;
    _imsSecEnabled = true;
    _imsSpiIn = spiIn;
    _imsSpiOut = spiOut;
    if (!sameTuple || _imsSeqOut == 0) {
      _imsSeqOut = _imsSeqBySpi[spiOut] ?? 1;
    }
    _imsAuthKey = Uint8List.fromList(ik);
    _imsPortOut = portC > 0 ? portC : localPort;
    _imsPortIn = portIn > 0 ? portIn : _imsPortOut;
    _imsPeerPortIn = peerPortIn > 0 ? peerPortIn : _pcscfPort;
    _imsSeqBySpi.putIfAbsent(spiOut, () => 1);
    _addImsCandidate(
      spiIn: _imsSpiIn,
      spiOut: _imsSpiOut,
      portOut: _imsPortOut,
      portIn: _imsPortIn,
      peerPortIn: _imsPeerPortIn,
      authKey: _imsAuthKey,
    );
  }

  static Future<VowifiEpdgTunnel> attach({
    required VowifiSmsConfig config,
    required VowifiAkaProvider akaProvider,
    void Function(String info)? onInfo,
  }) async {
    final targets = await _resolveTargets(config);
    onInfo?.call('trying auth profile imsclient-exact');
    Object? lastError;
    for (final target in targets) {
      onInfo?.call(
        'trying ePDG target ${target.address.address}:${target.port}',
      );
      try {
        return await _attachSingle(
          config: config,
          target: target,
          akaProvider: akaProvider,
          onInfo: onInfo,
        );
      } catch (error) {
        onInfo?.call(
          'auth profile imsclient-exact failed for ${target.address.address}:${target.port}: $error',
        );
        lastError = error;
      }
    }
    throw StateError('ePDG attach failed: $lastError');
  }

  static Future<VowifiEpdgTunnel> _attachSingle({
    required VowifiSmsConfig config,
    required _UdpTarget target,
    required VowifiAkaProvider akaProvider,
    void Function(String info)? onInfo,
  }) async {
    final outer = await RawDatagramSocket.bind(
      target.address.type == InternetAddressType.IPv6
          ? InternetAddress.anyIPv6
          : InternetAddress.anyIPv4,
      0,
    );
    outer.readEventsEnabled = true;
    outer.writeEventsEnabled = false;
    final inbox = _DatagramInbox(outer);
    // Every failed target would otherwise leave its socket and listener open,
    // and attach tries each resolved address on two ports.
    try {
      final local = outer.address;
      final state = _buildSaInit(config, local, target.address, target.port);
      onInfo?.call(
        'IKE_SA_INIT send spi_i=${_hex(state.spiI)} local=${local.address}:0 remote=${target.address.address}:${target.port}',
      );
      await _sendDatagram(
        outer,
        state.message,
        target.address,
        target.port,
        natt: target.port == 4500,
        ike: true,
      );
      final rawSa = await inbox.readIkeMessage(const Duration(seconds: 10));
      final sa = _parseSaInitResponse(rawSa, state);
      final natt = sa.natDetected || target.port == 4500;
      final remotePort = natt ? 4500 : target.port;
      onInfo?.call(
        'sa_init selected=${_transformSummary(sa.selected)} natt=$natt responder=${target.address.address}:$remotePort',
      );

      final auth = await _continueIkeAuth(
        outer: outer,
        inbox: inbox,
        remoteAddress: target.address,
        remotePort: remotePort,
        natt: natt,
        bootstrap: sa,
        config: config,
        akaProvider: akaProvider,
        onInfo: onInfo,
      );
      final pcscf = auth.pcscf4.isNotEmpty
          ? auth.pcscf4.first
          : auth.pcscf6.isNotEmpty
          ? auth.pcscf6.first
          : throw StateError('ePDG auth completed without P-CSCF');
      final localIp = pcscf.type == InternetAddressType.IPv6
          ? (auth.ip6 ??
                InternetAddress.tryParse('::') ??
                InternetAddress.anyIPv6)
          : (auth.ip4 ??
                InternetAddress.tryParse('0.0.0.0') ??
                InternetAddress.anyIPv4);
      final childKeys = _deriveChildKeys(sa, auth);
      final localPort = 10000 + _secureRandom.nextInt(50000);
      onInfo?.call(
        'ePDG bootstrap responder=${target.address.address}:$remotePort local=${localIp.address}:0 spi_i=${_hex(sa.localSpi)} spi_r=${_hex(sa.remoteSpi)} transforms=${_transformSummary(sa.selected)} natt=${sa.natDetected}',
      );
      onInfo?.call(
        'ePDG child_sa spi_i=0x${auth.childSpiI.toRadixString(16).padLeft(8, '0')} spi_r=0x${auth.childSpiR.toRadixString(16).padLeft(8, '0')} transforms=${auth.childSa.length}',
      );
      if (auth.ip4 != null) {
        onInfo?.call('ePDG assigned ip4=${auth.ip4!.address}');
      }
      if (auth.ip6 != null) {
        onInfo?.call('ePDG assigned ip6=${auth.ip6!.address}');
      }
      if (auth.pcscf4.isNotEmpty) {
        onInfo?.call(
          'ePDG pcscf4=[${auth.pcscf4.map((value) => value.address).join(' ')}]',
        );
      }
      if (auth.pcscf6.isNotEmpty) {
        onInfo?.call(
          'ePDG pcscf6=[${auth.pcscf6.map((value) => value.address).join(' ')}]',
        );
      }
      return VowifiEpdgTunnel._(
        localAddress: localIp,
        localPort: localPort,
        remoteAddress: target.address,
        remotePort: remotePort,
        outer: outer,
        inbox: inbox,
        natt: natt,
        spiIn: auth.childSpiI,
        spiOut: auth.childSpiR,
        encIn: childKeys.encIn,
        encOut: childKeys.encOut,
        integIn: childKeys.integIn,
        integOut: childKeys.integOut,
        integLength: childKeys.integLength,
        integAlgorithm: childKeys.integAlgorithm,
        pcscfAddress: pcscf,
        pcscfPort: 5060,
        onInfo: onInfo,
      );
    } catch (_) {
      await inbox.close();
      outer.close();
      rethrow;
    }
  }

  Future<void> send(Uint8List payload) async {
    if (_closed) {
      throw StateError('Tunnel is closed');
    }
    final inner = _imsSecEnabled
        ? (() {
            final tcp = _buildImsTcpDataPacket(payload);
            if (tcp != null) {
              return tcp;
            }
            return _buildIpPacket(
              src: localAddress,
              dst: _pcscfAddress,
              protocol: 50,
              payload: _buildImsNullEspPacket(
                spi: _imsSpiOut,
                seq: _nextImsSeq(_imsSpiOut),
                authKey: _imsAuthKey,
                nextHeader: 17,
                payload: _buildUdpDatagram(
                  src: localAddress,
                  dst: _pcscfAddress,
                  srcPort: _imsPortOut,
                  dstPort: _pcscfPort,
                  payload: payload,
                ),
              ),
            );
          })()
        : _buildIpUdp(
            src: localAddress,
            dst: _pcscfAddress,
            srcPort: localPort,
            dstPort: _pcscfPort,
            payload: payload,
          );
    final esp = _wrapEsp(inner);
    // Similar to Go soft-esp tx logs.
    await _sendDatagram(_outer, esp, _remoteAddress, _remotePort, natt: _natt);
  }

  Future<void> close() async {
    _closed = true;
    _nattKeepalive?.cancel();
    _nattKeepalive = null;
    _inbox.packetHandler = null;
    _inbox.errorHandler = null;
    _inbox.doneHandler = null;
    await _inbox.close();
    _packets.close();
    _outer.close();
  }

  void _sendNattKeepalive() {
    if (_closed || !_natt) {
      return;
    }
    try {
      _outer.send(const <int>[0xff], _remoteAddress, _remotePort);
    } catch (_) {
      // Runs from a timer; a dead socket is reported through the inbox.
    }
  }

  void _handleOuterDatagram(Uint8List datagram) {
    final payload = _unwrapEsp(datagram);
    if (payload == null) {
      return;
    }
    if (_imsSecEnabled) {
      final ims = _tryDecodeImsWithCandidates(payload);
      if (ims.payload != null) {
        _onInfo?.call('soft-esp rx sip len=${ims.payload!.length}');
        // _onInfo?.call(
        //   'soft-esp rx sip dump:\n${_formatSipPayloadForLog(ims.payload!)}',
        // );
        _packets.add(ims.payload!);
        return;
      }
      if (ims.meta?.tcp != null) {
        _onImsTcpSegment(ims.meta!.tcp!, 0, ims.meta!.spiIn);
        return;
      }
      if (ims.reason.isNotEmpty) {
        _onInfo?.call('soft-esp rx drop ims reason=${ims.reason}');
      }
    }
    final sip = _extractUdpPayload(
      payload,
      localAddress: localAddress,
      localPort: localPort,
      remoteAddress: _pcscfAddress,
      remotePort: _pcscfPort,
    );
    if (sip != null) {
      _onInfo?.call('soft-esp rx sip len=${sip.length}');
      // _onInfo?.call('soft-esp rx sip dump:\n${_formatSipPayloadForLog(sip)}');
      _packets.add(sip);
      return;
    }
    final anySrcSip = _extractUdpPayloadAnySource(
      payload,
      localAddress: localAddress,
      localPort: localPort,
    );
    if (anySrcSip != null && _looksLikeSip(anySrcSip)) {
      _onInfo?.call('soft-esp rx sip len=${anySrcSip.length}');
      // _onInfo?.call(
      //   'soft-esp rx sip dump:\n${_formatSipPayloadForLog(anySrcSip)}',
      // );
      _packets.add(anySrcSip);
      return;
    }
    final anyUdpSip = _extractAnyUdpPayload(payload);
    if (anyUdpSip != null && _looksLikeSip(anyUdpSip)) {
      _onInfo?.call('soft-esp rx sip len=${anyUdpSip.length}');
      // _onInfo?.call(
      //   'soft-esp rx sip dump:\n${_formatSipPayloadForLog(anyUdpSip)}',
      // );
      _packets.add(anyUdpSip);
    }
  }

  int _nextImsSeq(int spi) {
    final next = _imsSeqBySpi[spi] ?? 1;
    _imsSeqBySpi[spi] = next + 1;
    _imsSeqOut = _imsSeqBySpi[spi] ?? (next + 1);
    return next;
  }

  void _addImsCandidate({
    required int spiIn,
    required int spiOut,
    required int portOut,
    required int portIn,
    required int peerPortIn,
    required Uint8List authKey,
  }) {
    if (spiIn == 0 || spiOut == 0 || authKey.isEmpty) {
      return;
    }
    for (final candidate in _imsCandidates) {
      if (candidate.spiIn == spiIn &&
          candidate.spiOut == spiOut &&
          candidate.portOut == portOut &&
          candidate.portIn == portIn &&
          candidate.peerPortIn == peerPortIn &&
          _constantEquals(candidate.authKey, authKey)) {
        return;
      }
    }
    _imsCandidates.add((
      spiIn: spiIn,
      spiOut: spiOut,
      portOut: portOut,
      portIn: portIn,
      peerPortIn: peerPortIn,
      authKey: Uint8List.fromList(authKey),
    ));
  }

  // ignore: unused_element -- kept for debugging the exchange
  Uint8List? _extractImsFromCandidates(Uint8List payload) {
    for (final candidate in _imsCandidates) {
      final sip = _extractImsProtectedUdpPayload(
        payload,
        localAddress: localAddress,
        localPort: candidate.portIn,
        remoteAddress: _pcscfAddress,
        remotePort: candidate.peerPortIn,
        spiIn: candidate.spiIn,
        authKey: candidate.authKey,
      );
      if (sip != null) {
        _imsSpiIn = candidate.spiIn;
        _imsSpiOut = candidate.spiOut;
        _imsPortOut = candidate.portOut;
        _imsPortIn = candidate.portIn;
        _imsPeerPortIn = candidate.peerPortIn;
        _imsAuthKey = Uint8List.fromList(candidate.authKey);
        return sip;
      }
    }
    return null;
  }

  ({Uint8List? payload, _ImsProtectedMeta? meta, String reason})
  _tryDecodeImsWithCandidates(Uint8List payload) {
    final first = _extractImsProtectedPayloadWithReason(
      payload,
      localAddress: localAddress,
      localPort: _imsPortIn,
      remoteAddress: _pcscfAddress,
      remotePort: _imsPeerPortIn,
      spiIn: _imsSpiIn,
      authKey: _imsAuthKey,
    );
    if (first.payload != null || first.meta?.tcp != null) {
      if (first.meta?.tcp != null && first.payload != null) {
        _onImsTcpSegment(
          first.meta!.tcp!,
          first.payload!.length,
          first.meta!.spiIn,
        );
      }
      return first;
    }
    if (!(first.reason.startsWith('spi-got=') || first.reason == 'icv')) {
      return first;
    }
    for (final candidate in _imsCandidates) {
      if (candidate.spiIn == _imsSpiIn &&
          candidate.portIn == _imsPortIn &&
          candidate.peerPortIn == _imsPeerPortIn &&
          _constantEquals(candidate.authKey, _imsAuthKey)) {
        continue;
      }
      final next = _extractImsProtectedPayloadWithReason(
        payload,
        localAddress: localAddress,
        localPort: candidate.portIn,
        remoteAddress: _pcscfAddress,
        remotePort: candidate.peerPortIn,
        spiIn: candidate.spiIn,
        authKey: candidate.authKey,
      );
      if (next.payload == null && next.meta?.tcp == null) {
        continue;
      }
      _imsSpiIn = candidate.spiIn;
      _imsSpiOut = candidate.spiOut;
      _imsPortOut = candidate.portOut;
      _imsPortIn = candidate.portIn;
      _imsPeerPortIn = candidate.peerPortIn;
      _imsAuthKey = Uint8List.fromList(candidate.authKey);
      _onInfo?.call(
        'soft-esp ims-ipsec auto-switch spi-in=0x${_imsSpiIn.toRadixString(16).padLeft(8, '0')} spi-out=0x${_imsSpiOut.toRadixString(16).padLeft(8, '0')} in=$_imsPortIn<-$_imsPeerPortIn',
      );
      if (next.meta?.tcp != null && next.payload != null) {
        _onImsTcpSegment(
          next.meta!.tcp!,
          next.payload!.length,
          next.meta!.spiIn,
        );
      }
      return next;
    }
    return first;
  }

  Uint8List? _buildImsTcpDataPacket(Uint8List sip) {
    if (!(_imsSecEnabled &&
        _imsTcpMode &&
        _imsTcpEstablished &&
        _imsTcpLocalPort > 0 &&
        _imsTcpPeerPort > 0)) {
      return null;
    }
    final seq = _imsTcpSeqOut;
    final ack = _imsTcpAckNext;
    final sport = _imsTcpLocalPort;
    final dport = _imsTcpPeerPort;
    _imsTcpSeqOut += sip.length;
    final tcp = _buildTcpSegment(
      src: localAddress,
      dst: _pcscfAddress,
      srcPort: sport,
      dstPort: dport,
      seq: seq,
      ack: ack,
      flags: 0x18,
      window: 8192,
      options: Uint8List(0),
      payload: sip,
    );
    final gmEsp = _buildImsNullEspPacket(
      spi: _imsSpiOut,
      seq: _nextImsSeq(_imsSpiOut),
      authKey: _imsAuthKey,
      nextHeader: 6,
      payload: tcp,
    );
    return _buildIpPacket(
      src: localAddress,
      dst: _pcscfAddress,
      protocol: 50,
      payload: gmEsp,
    );
  }

  void _onImsTcpSegment(_ImsTcpSegmentMeta meta, int payloadLength, int spiIn) {
    const tcpFlagFin = 0x01;
    const tcpFlagSyn = 0x02;
    const tcpFlagAck = 0x10;
    if (payloadLength == 0) {
      _onInfo?.call(
        'soft-esp ims-tcp rx flags=0x${meta.flags.toRadixString(16).padLeft(2, '0')} seq=${meta.seq} ack=${meta.ack} ${meta.srcPort}->${meta.dstPort} spi-in=0x${spiIn.toRadixString(16).padLeft(8, '0')}',
      );
    }
    var sendFlags = 0;
    var sendSeq = 0;
    var sendAck = 0;
    Uint8List sendOpts = Uint8List(0);
    var synRetry = 0;

    if ((meta.flags & tcpFlagSyn) != 0 && (meta.flags & tcpFlagAck) == 0) {
      if (!_imsTcpMode ||
          _imsTcpPeerPort != meta.srcPort ||
          _imsTcpLocalPort != meta.dstPort) {
        _imsTcpMode = true;
        _imsTcpEstablished = false;
        _imsTcpPeerPort = meta.srcPort;
        _imsTcpLocalPort = meta.dstPort;
        _imsTcpSeqOut = _randomU32();
        _imsTcpAckNext = meta.seq + 1;
        _imsTcpSynSent = false;
        _imsTcpSynInSeq = meta.seq;
        _imsTcpSynRetries = 0;
      } else if (_imsTcpSynInSeq == 0) {
        _imsTcpSynInSeq = meta.seq;
        _imsTcpSynRetries = 0;
        final nextAck = meta.seq + 1;
        if (nextAck > _imsTcpAckNext || _imsTcpAckNext == 0) {
          _imsTcpAckNext = nextAck;
        }
      } else {
        final nextAck = meta.seq + 1;
        if (nextAck > _imsTcpAckNext || _imsTcpAckNext == 0) {
          _imsTcpAckNext = nextAck;
        }
        if (meta.seq == _imsTcpSynInSeq && !_imsTcpEstablished) {
          _imsTcpSynRetries++;
        } else if (meta.seq != _imsTcpSynInSeq) {
          _imsTcpSynInSeq = meta.seq;
          _imsTcpSynRetries = 0;
        }
      }
      sendFlags = tcpFlagSyn | tcpFlagAck;
      sendSeq = _imsTcpSynSent ? _imsTcpSeqOut - 1 : _imsTcpSeqOut;
      sendAck = _imsTcpAckNext;
      sendOpts = _buildSynAckOptions(meta, _imsTcpSynRetries);
      if (!_imsTcpSynSent) {
        _imsTcpSeqOut++;
        _imsTcpSynSent = true;
      }
      synRetry = _imsTcpSynRetries;
    } else if ((meta.flags & tcpFlagSyn) != 0 &&
        (meta.flags & tcpFlagAck) != 0 &&
        _imsTcpMode &&
        meta.srcPort == _imsTcpPeerPort &&
        meta.dstPort == _imsTcpLocalPort) {
      if (meta.ack == _imsTcpSeqOut) {
        _imsTcpEstablished = true;
        final next = meta.seq + 1;
        if (next > _imsTcpAckNext) {
          _imsTcpAckNext = next;
        }
        sendFlags = tcpFlagAck;
        sendSeq = _imsTcpSeqOut;
        sendAck = _imsTcpAckNext;
      }
    } else if (_imsTcpMode &&
        meta.srcPort == _imsTcpPeerPort &&
        meta.dstPort == _imsTcpLocalPort) {
      if ((meta.flags & tcpFlagAck) != 0 &&
          !_imsTcpEstablished &&
          meta.ack == _imsTcpSeqOut) {
        _imsTcpEstablished = true;
      }
      var advance = payloadLength;
      if ((meta.flags & tcpFlagFin) != 0) {
        advance++;
      }
      if (advance > 0) {
        final next = meta.seq + advance;
        if (next > _imsTcpAckNext) {
          _imsTcpAckNext = next;
        }
        sendFlags = tcpFlagAck;
        sendSeq = _imsTcpSeqOut;
        sendAck = _imsTcpAckNext;
      }
    }
    if (sendFlags != 0) {
      final profiles = <({int spi, Uint8List key, String label})>[];
      final seen = <String>{};
      void addProfile(int spi, Uint8List key, String label) {
        if (spi == 0 || key.isEmpty) {
          return;
        }
        final id = '${spi.toRadixString(16)}:${base64.encode(key)}';
        if (!seen.add(id)) {
          return;
        }
        profiles.add((spi: spi, key: Uint8List.fromList(key), label: label));
      }

      if (spiIn != 0) {
        for (final cand in _imsCandidates) {
          if (cand.spiIn == spiIn) {
            addProfile(cand.spiOut, cand.authKey, 'cand:spi-out');
            addProfile(cand.spiIn, cand.authKey, 'cand:spi-in');
          }
        }
      }
      for (final cand in _imsCandidates) {
        addProfile(cand.spiOut, cand.authKey, 'global:spi-out');
        addProfile(cand.spiIn, cand.authKey, 'global:spi-in');
      }
      addProfile(_imsSpiOut, _imsAuthKey, 'active:spi-out');
      if (profiles.isEmpty) {
        return;
      }
      var selected = profiles.first;
      if (sendFlags == (tcpFlagSyn | tcpFlagAck) && synRetry > 0) {
        final idx = synRetry >= profiles.length
            ? profiles.length - 1
            : synRetry;
        selected = profiles[idx];
      }
      _sendImsTcpControlWithIms(
        flags: sendFlags,
        seq: sendSeq,
        ack: sendAck,
        options: sendOpts,
        spiOut: selected.spi,
        authKey: selected.key,
      );
    }
  }

  void _sendImsTcpControlWithIms({
    required int flags,
    required int seq,
    required int ack,
    required Uint8List options,
    required int spiOut,
    required Uint8List authKey,
  }) {
    final sport = _imsTcpLocalPort;
    final dport = _imsTcpPeerPort;
    if (sport == 0 || dport == 0) {
      return;
    }
    final tcp = _buildTcpSegment(
      src: localAddress,
      dst: _pcscfAddress,
      srcPort: sport,
      dstPort: dport,
      seq: seq,
      ack: ack,
      flags: flags,
      window: 8192,
      options: options,
      payload: Uint8List(0),
    );
    final gmEsp = _buildImsNullEspPacket(
      spi: spiOut,
      seq: _nextImsSeq(spiOut),
      authKey: authKey,
      nextHeader: 6,
      payload: tcp,
    );
    final inner = _buildIpPacket(
      src: localAddress,
      dst: _pcscfAddress,
      protocol: 50,
      payload: gmEsp,
    );
    final esp = _wrapEsp(inner);
    unawaited(
      _sendDatagram(_outer, esp, _remoteAddress, _remotePort, natt: _natt),
    );
    _onInfo?.call(
      'soft-esp ims-tcp tx flags=0x${flags.toRadixString(16).padLeft(2, '0')} seq=$seq ack=$ack $sport->$dport spi=0x${spiOut.toRadixString(16).padLeft(8, '0')}',
    );
  }

  Uint8List _wrapEsp(Uint8List inner) {
    final blockSize = 16;
    final padLength =
        (blockSize - ((inner.length + 2) % blockSize)) % blockSize;
    final useV6 =
        localAddress.type == InternetAddressType.IPv6 ||
        _pcscfAddress.type == InternetAddressType.IPv6;
    final plain = BytesBuilder(copy: false)
      ..add(inner)
      ..add(List<int>.generate(padLength, (index) => index + 1))
      ..addByte(padLength)
      ..addByte(useV6 ? 41 : 4);
    final iv = _randomBytes(blockSize);
    final ciphertext = _cbcCrypt(true, _encOut, iv, plain.takeBytes());
    final esp = BytesBuilder(copy: false)
      ..add(_u32(_spiOut))
      ..add(_u32(_seqOut++))
      ..add(iv)
      ..add(ciphertext);
    final raw = esp.takeBytes();
    final icv = _hmac(_integAlgorithm, _integOut, raw).sublist(0, _integLength);
    return Uint8List.fromList(<int>[...raw, ...icv]);
  }

  Uint8List? _unwrapEsp(Uint8List packet) {
    final raw = _stripNatt(packet);
    if (raw.length < 8 + 16 + _integLength) {
      return null;
    }
    if (_readU32(raw, 0) != _spiIn) {
      return null;
    }
    final body = raw.sublist(0, raw.length - _integLength);
    final gotIcv = raw.sublist(raw.length - _integLength);
    final wantIcv = _hmac(
      _integAlgorithm,
      _integIn,
      body,
    ).sublist(0, _integLength);
    if (!_constantEquals(gotIcv, wantIcv)) {
      return null;
    }
    final iv = body.sublist(8, 24);
    final ciphertext = body.sublist(24);
    final clear = _cbcCrypt(false, _encIn, iv, ciphertext);
    if (clear.length < 2) {
      return null;
    }
    final padLength = clear[clear.length - 2];
    final nextHeader = clear[clear.length - 1];
    if ((nextHeader != 4 && nextHeader != 41) || padLength + 2 > clear.length) {
      return null;
    }
    return Uint8List.sublistView(clear, 0, clear.length - padLength - 2);
  }
}

class _UdpTarget {
  const _UdpTarget(this.address, this.port);

  final InternetAddress address;
  final int port;
}

class _InitState {
  const _InitState({
    required this.spiI,
    required this.nonceI,
    required this.privateKey,
    required this.publicKey,
    required this.group,
    required this.localAddress,
    required this.localPort,
    required this.remoteAddress,
    required this.remotePort,
    required this.message,
  });

  final Uint8List spiI;
  final Uint8List nonceI;
  final BigInt privateKey;
  final Uint8List publicKey;
  final int group;
  final InternetAddress localAddress;
  final int localPort;
  final InternetAddress remoteAddress;
  final int remotePort;
  final Uint8List message;
}

class _Transform {
  const _Transform(this.type, this.id, this.keyLength);

  final int type;
  final int id;
  final int keyLength;
}

class _BootstrapState {
  _BootstrapState({
    required this.localSpi,
    required this.remoteSpi,
    required this.selected,
    required this.nonceI,
    required this.nonceR,
    required this.sharedKey,
    required this.skD,
    required this.skAi,
    required this.skAr,
    required this.skEi,
    required this.skEr,
    required this.skPi,
    required this.skPr,
    required this.natDetected,
    required this.saInitRequest,
    required this.localAddress,
    required this.localPort,
    required this.remoteAddress,
    required this.remotePort,
  });

  final Uint8List localSpi;
  final Uint8List remoteSpi;
  final List<_Transform> selected;
  final Uint8List nonceI;
  final Uint8List nonceR;
  final Uint8List sharedKey;
  final Uint8List skD;
  final Uint8List skAi;
  final Uint8List skAr;
  final Uint8List skEi;
  final Uint8List skEr;
  final Uint8List skPi;
  final Uint8List skPr;
  final bool natDetected;
  final Uint8List saInitRequest;
  final InternetAddress localAddress;
  final int localPort;
  final InternetAddress remoteAddress;
  final int remotePort;
}

class _AuthState {
  _AuthState({
    required this.childSpiI,
    required this.childSpiR,
    required this.childSa,
    required this.ip4,
    required this.ip6,
    required this.pcscf4,
    required this.pcscf6,
    required this.payloads,
    required this.notifies,
  });

  final int childSpiI;
  final int childSpiR;
  final List<_Transform> childSa;
  final InternetAddress? ip4;
  final InternetAddress? ip6;
  final List<InternetAddress> pcscf4;
  final List<InternetAddress> pcscf6;
  final List<int> payloads;
  final List<_Notify> notifies;
}

class _AuthAlgorithms {
  const _AuthAlgorithms({
    required this.prfName,
    required this.encTransformId,
    required this.integTransformId,
    required this.encKeyLength,
    required this.integLength,
    required this.blockSize,
  });

  final String prfName;
  final int encTransformId;
  final int integTransformId;
  final int encKeyLength;
  final int integLength;
  final int blockSize;
}

class _ChildKeys {
  const _ChildKeys({
    required this.encIn,
    required this.encOut,
    required this.integIn,
    required this.integOut,
    required this.integLength,
    required this.integAlgorithm,
  });

  final Uint8List encIn;
  final Uint8List encOut;
  final Uint8List integIn;
  final Uint8List integOut;
  final int integLength;
  final String integAlgorithm;
}

class _DatagramInbox {
  _DatagramInbox(this.socket) {
    _sub = socket.listen(_onEvent, onError: _onError, onDone: _onDone);
  }

  final RawDatagramSocket socket;
  final List<Uint8List> _queue = <Uint8List>[];
  final List<Completer<Uint8List>> _waiters = <Completer<Uint8List>>[];
  late final StreamSubscription<RawSocketEvent> _sub;
  void Function(Uint8List datagram)? packetHandler;
  void Function(Object error, StackTrace stackTrace)? errorHandler;
  void Function()? doneHandler;

  void _onError(Object error, StackTrace stackTrace) {
    for (final waiter in _waiters.toList()) {
      if (!waiter.isCompleted) waiter.completeError(error, stackTrace);
    }
    errorHandler?.call(error, stackTrace);
  }

  void _onDone() => doneHandler?.call();

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }
    while (true) {
      final datagram = socket.receive();
      if (datagram == null) {
        break;
      }
      final raw = Uint8List.fromList(datagram.data);
      final stripped = _stripNatt(raw);
      if (stripped.length < 28 || stripped[17] >> 4 != 2) {
        packetHandler?.call(raw);
        continue;
      }
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete(raw);
      } else {
        _queue.add(raw);
      }
    }
  }

  Future<Uint8List> readIkeMessage(Duration timeout) async {
    if (_queue.isNotEmpty) {
      return _queue.removeAt(0);
    }
    final completer = Completer<Uint8List>();
    _waiters.add(completer);
    try {
      return await completer.future.timeout(timeout);
    } finally {
      _waiters.remove(completer);
    }
  }

  Future<void> close() async {
    await _sub.cancel();
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('Datagram inbox closed'));
      }
    }
    _waiters.clear();
    _queue.clear();
  }
}

// ignore: unused_element -- kept for debugging the exchange
String _formatSipPayloadForLog(Uint8List payload) {
  if (payload.isEmpty) {
    return '<empty>';
  }
  final decoded = latin1.decode(payload, allowInvalid: true);
  return decoded.isEmpty
      ? '<binary>'
      : '$decoded\n<body ${payload.length} bytes>';
}

const int _payloadSa = 33;
const int _payloadKe = 34;
const int _payloadIdi = 35;
const int _payloadIdr = 36;
const int _payloadAuth = 39;
const int _payloadNonce = 40;
const int _payloadNotify = 41;
const int _payloadTsi = 44;
const int _payloadTsr = 45;
const int _payloadSk = 46;
const int _payloadCp = 47;
const int _payloadEap = 48;
const int _exchangeIkeInit = 34;
const int _exchangeIkeAuth = 35;
const int _flagInitiator = 0x08;
const int _notifyNatSource = 16388;
const int _notifyNatDest = 16389;
const int _notifyEapOnly = 16417;
const int _notifyInitialContact = 16384;
const int _notifyDeviceIdentity = 41101;
const int _proposalIke = 1;
const int _proposalEsp = 3;
const int _transformEncr = 1;
const int _transformPrf = 2;
const int _transformInteg = 3;
const int _transformDh = 4;
const int _transformEsn = 5;
const int _encrAesCbc = 12;
const int _prfHmacMd5 = 1;
const int _prfHmacSha1 = 2;
const int _prfHmacSha256 = 5;
const int _integHmacMd5_96 = 1;
const int _integHmacSha1_96 = 2;
const int _integSha256_128 = 12;
const int _dhGroup2 = 2;
const int _eapCodeRequest = 1;
const int _eapCodeResponse = 2;
const int _eapCodeSuccess = 3;
const int _eapTypeAka = 23;
const int _eapSubtypeIdentity = 5;
const int _eapSubtypeChallenge = 1;
const int _attrRand = 1;
const int _attrAutn = 2;
const int _attrAnyIdReq = 13;
const int _attrFullAuthIdReq = 17;
const int _attrPermanentIdReq = 10;
const int _attrIdentity = 14;
const int _attrRes = 3;
const int _attrMac = 11;
// Synthetic fallback using the app's default TAC; normal sessions pass the
// configured device identity from AppSettings.
const String _defaultDeviceIdentity = '3538374100000000';

Future<List<_UdpTarget>> _resolveTargets(VowifiSmsConfig config) async {
  final addresses = <String>[
    ...config.epdgAddresses.where((value) => value.trim().isNotEmpty),
    if (config.epdgServer.trim().isNotEmpty) config.epdgServer.trim(),
  ];
  if (addresses.isEmpty) {
    throw StateError('Missing ePDG server');
  }
  final out = <_UdpTarget>[];
  final ports = <int>[config.epdgPort == 0 ? 500 : config.epdgPort];
  if (!ports.contains(4500)) {
    ports.add(4500);
  }
  for (final host in addresses) {
    final results = await InternetAddress.lookup(host);
    for (final result in results) {
      for (final port in ports) {
        out.add(_UdpTarget(result, port));
      }
    }
  }
  if (out.isEmpty) {
    throw StateError('Unable to resolve ePDG targets for ${addresses.first}');
  }
  return out;
}

_InitState _buildSaInit(
  VowifiSmsConfig config,
  InternetAddress localAddress,
  InternetAddress remoteAddress,
  int remotePort,
) {
  final spiI = _randomBytes(8);
  final nonceI = _randomBytes(16);
  final dh = _dhKeyPair(_dhGroup2);
  final payloads = <_Payload>[
    _encodeSaPayload(_dhGroup2),
    _Payload(
      kind: _payloadKe,
      body: Uint8List.fromList(<int>[
        ..._u16(_dhGroup2),
        0,
        0,
        ...dh.publicKey,
      ]),
    ),
    _Payload(kind: _payloadNonce, body: nonceI),
    _encodeRawNotify(_notifyNatSource, List<int>.filled(20, 0)),
    _encodeNotify(
      localAddress,
      remoteAddress,
      remotePort,
      spiI,
      Uint8List(8),
      _notifyNatDest,
    ),
  ];
  final message = _buildMessage(
    spiI: spiI,
    spiR: Uint8List(8),
    exchange: _exchangeIkeInit,
    flags: _flagInitiator,
    payloads: payloads,
  );
  return _InitState(
    spiI: spiI,
    nonceI: nonceI,
    privateKey: dh.privateKey,
    publicKey: dh.publicKey,
    group: _dhGroup2,
    localAddress: localAddress,
    localPort: 500,
    remoteAddress: remoteAddress,
    remotePort: remotePort,
    message: message,
  );
}

_BootstrapState _parseSaInitResponse(Uint8List raw, _InitState state) {
  if (raw.length < 28) {
    throw StateError('Short IKE_SA_INIT response');
  }
  final stripped = _stripNatt(raw);
  if (!_constantEquals(stripped.sublist(0, 8), state.spiI)) {
    throw StateError('IKE SPI mismatch');
  }
  var nextPayload = stripped[16];
  final length = _readU32(stripped, 24);
  var offset = 28;
  Uint8List? nonceR;
  Uint8List? keR;
  Uint8List? remoteSpi;
  final selected = <_Transform>[];
  final notifies = <_Notify>[];
  remoteSpi = stripped.sublist(8, 16);
  while (nextPayload != 0 && offset + 4 <= length) {
    final current = nextPayload;
    nextPayload = stripped[offset];
    final payloadLength = _readU16(stripped, offset + 2);
    final body = stripped.sublist(offset + 4, offset + payloadLength);
    switch (current) {
      case _payloadSa:
        selected.addAll(_parseSa(body));
      case _payloadKe:
        keR = body.sublist(4);
      case _payloadNonce:
        nonceR = body;
      case _payloadNotify:
        notifies.add(_parseNotify(body));
    }
    offset += payloadLength;
  }
  if (nonceR == null || keR == null) {
    throw StateError('Incomplete IKE_SA_INIT response');
  }
  final shared = _dhShared(state.group, state.privateKey, keR);
  final algs = _selectAlgorithms(selected);
  final keys = _deriveIkeKeys(
    shared: shared,
    nonceI: state.nonceI,
    nonceR: nonceR,
    spiI: state.spiI,
    spiR: remoteSpi,
    algs: algs,
  );
  final natDetected = _detectNat(
    notifies: notifies,
    localAddress: state.localAddress,
    remoteAddress: state.remoteAddress,
    remotePort: state.remotePort,
    spiI: state.spiI,
    spiR: remoteSpi,
  );
  return _BootstrapState(
    localSpi: state.spiI,
    remoteSpi: remoteSpi,
    selected: selected,
    nonceI: state.nonceI,
    nonceR: nonceR,
    sharedKey: shared,
    skD: keys[0],
    skAi: keys[1],
    skAr: keys[2],
    skEi: keys[3],
    skEr: keys[4],
    skPi: keys[5],
    skPr: keys[6],
    natDetected: natDetected,
    saInitRequest: state.message,
    localAddress: state.localAddress,
    localPort: state.localPort,
    remoteAddress: state.remoteAddress,
    remotePort: state.remotePort,
  );
}

Future<_AuthState> _continueIkeAuth({
  required RawDatagramSocket outer,
  required _DatagramInbox inbox,
  required InternetAddress remoteAddress,
  required int remotePort,
  required bool natt,
  required _BootstrapState bootstrap,
  required VowifiSmsConfig config,
  required VowifiAkaProvider akaProvider,
  void Function(String info)? onInfo,
}) async {
  final algs = _selectAlgorithms(bootstrap.selected);
  final idi = _buildRootNai(config);
  final childSpiI = _randomU32();
  var messageId = 1;
  final initialInner = <_Payload>[
    _Payload(kind: _payloadIdi, body: _encodeIdPayload(3, idi)),
    _Payload(kind: _payloadIdr, body: _encodeIdPayload(2, 'ims')),
    _Payload(kind: _payloadCp, body: _encodeCfgRequest(includeIPv6: true)),
    _Payload(kind: _payloadSa, body: _encodeChildSa(childSpiI)),
    _Payload(kind: _payloadTsi, body: _encodeTsAnyDualStack()),
    _Payload(kind: _payloadTsr, body: _encodeTsAnyDualStack()),
    _encodeRawNotify(_notifyInitialContact, const <int>[]),
    _encodeRawNotify(_notifyEapOnly, const <int>[]),
    _encodeDeviceIdentityNotify(
      config.deviceIdentity.trim().isEmpty
          ? _defaultDeviceIdentity
          : config.deviceIdentity,
    ),
  ];
  final initial = _buildEncryptedRequest(
    bootstrap: bootstrap,
    algs: algs,
    messageId: messageId,
    inner: initialInner,
  );
  onInfo?.call(
    'go_ike_auth1 profile=imsclient-exact plain_len=${_buildInnerPayloads(initialInner).length}',
  );
  await _sendDatagram(
    outer,
    initial,
    remoteAddress,
    remotePort,
    natt: natt,
    ike: true,
  );
  Uint8List msk = Uint8List(0);
  while (true) {
    final raw = await inbox.readIkeMessage(const Duration(seconds: 10));
    final response = _decryptIkeAuthResponse(
      raw: raw,
      bootstrap: bootstrap,
      algs: algs,
      messageId: messageId,
    );
    onInfo?.call(
      'ike_auth msgid=$messageId payloads=${response.payloads} notifies=${response.notifies.length}(${_formatNotifies(response.notifies)}) eap=${response.eap != null}',
    );
    if (response.eap != null) {
      onInfo?.call(
        'ike_auth eap code=${response.eap!.code} type=${response.eap!.type} subtype=${response.eap!.subtype} attrs=${response.eap!.attributes.length}',
      );
    }
    if (response.eap == null) {
      if (response.childSpiR == 0 || response.childSa.isEmpty) {
        throw StateError('IKE_AUTH finished without CHILD_SA');
      }
      return _AuthState(
        childSpiI: childSpiI,
        childSpiR: response.childSpiR,
        childSa: response.childSa,
        ip4: response.ip4,
        ip6: response.ip6,
        pcscf4: response.pcscf4,
        pcscf6: response.pcscf6,
        payloads: response.payloads,
        notifies: response.notifies,
      );
    }
    final eap = response.eap!;
    if (eap.code == _eapCodeRequest &&
        eap.type == _eapTypeAka &&
        eap.subtype == _eapSubtypeIdentity &&
        _requestsIdentity(eap.attributes)) {
      messageId++;
      final req = _buildEncryptedRequest(
        bootstrap: bootstrap,
        algs: algs,
        messageId: messageId,
        inner: <_Payload>[
          _Payload(
            kind: _payloadEap,
            body: _buildAkaIdentityResponse(eap.identifier, idi),
          ),
        ],
      );
      await _sendDatagram(
        outer,
        req,
        remoteAddress,
        remotePort,
        natt: natt,
        ike: true,
      );
      continue;
    }
    if (eap.code == _eapCodeRequest &&
        eap.type == _eapTypeAka &&
        eap.subtype == _eapSubtypeChallenge) {
      final challenge = _parseAkaChallenge(eap.attributes);
      final aka = await akaProvider(
        VowifiAkaChallenge(
          rand: challenge.rand,
          autn: challenge.autn,
          imsi: config.imsi,
        ),
      );
      if (aka == null) {
        throw StateError('No AKA response available');
      }
      if (aka.auts.isNotEmpty) {
        messageId++;
        final req = _buildEncryptedRequest(
          bootstrap: bootstrap,
          algs: algs,
          messageId: messageId,
          inner: <_Payload>[
            _Payload(
              kind: _payloadEap,
              body: VowifiEapAkaCodec.buildSynchronizationFailureResponse(
                identifier: eap.identifier,
                auts: aka.auts,
              ),
            ),
          ],
        );
        onInfo?.call('EAP-AKA synchronization failure; sending AUTS');
        await _sendDatagram(
          outer,
          req,
          remoteAddress,
          remotePort,
          natt: natt,
          ike: true,
        );
        continue;
      }
      final keys = _deriveEapAkaKeys(idi, aka.ik, aka.ck);
      msk = keys[1];
      messageId++;
      final req = _buildEncryptedRequest(
        bootstrap: bootstrap,
        algs: algs,
        messageId: messageId,
        inner: <_Payload>[
          _Payload(
            kind: _payloadEap,
            body: _buildAkaChallengeResponse(eap.identifier, aka.res, keys[0]),
          ),
        ],
      );
      await _sendDatagram(
        outer,
        req,
        remoteAddress,
        remotePort,
        natt: natt,
        ike: true,
      );
      continue;
    }
    if (eap.code == _eapCodeSuccess) {
      if (msk.isEmpty) {
        throw StateError('EAP success without MSK');
      }
      onInfo?.call(
        'DEBUG: EAP success, keeping established IKE SK keys and using MSK only for AUTH (len=${msk.length})',
      );
      messageId++;
      onInfo?.call('DEBUG: sending final IKE_AUTH request msgID=$messageId');
      final req = _buildEncryptedRequest(
        bootstrap: bootstrap,
        algs: algs,
        messageId: messageId,
        inner: <_Payload>[
          _Payload(
            kind: _payloadAuth,
            body: _buildFinalAuth(
              bootstrap: bootstrap,
              algs: algs,
              identity: idi,
              msk: msk,
            ),
          ),
        ],
      );
      await _sendDatagram(
        outer,
        req,
        remoteAddress,
        remotePort,
        natt: natt,
        ike: true,
      );
      continue;
    }
    throw StateError('Unhandled EAP packet subtype=${eap.subtype}');
  }
}

class _AuthDecodeState {
  _AuthDecodeState({
    this.childSpiR = 0,
    this.childSa = const <_Transform>[],
    this.ip4,
    this.ip6,
    this.pcscf4 = const <InternetAddress>[],
    this.pcscf6 = const <InternetAddress>[],
    this.payloads = const <int>[],
    this.notifies = const <_Notify>[],
    this.eap,
  });

  final int childSpiR;
  final List<_Transform> childSa;
  final InternetAddress? ip4;
  final InternetAddress? ip6;
  final List<InternetAddress> pcscf4;
  final List<InternetAddress> pcscf6;
  final List<int> payloads;
  final List<_Notify> notifies;
  final _EapPacket? eap;
}

_AuthDecodeState _decryptIkeAuthResponse({
  required Uint8List raw,
  required _BootstrapState bootstrap,
  required _AuthAlgorithms algs,
  required int messageId,
}) {
  final packet = _stripNatt(raw);
  if (packet.length < 28 + 4 + algs.blockSize + algs.integLength) {
    throw StateError('Short IKE_AUTH response');
  }
  if (packet[16] != _payloadSk || _readU32(packet, 20) != messageId) {
    throw StateError('Unexpected IKE_AUTH header');
  }
  final body = packet.sublist(0, packet.length - algs.integLength);
  final gotIcv = packet.sublist(packet.length - algs.integLength);
  final wantIcv = _integrityMac(
    algs,
    bootstrap.skAr,
    body,
  ).sublist(0, algs.integLength);
  if (!_constantEquals(gotIcv, wantIcv)) {
    throw StateError('IKE_AUTH integrity check failed');
  }
  final nextInner = packet[28];
  final skLength = _readU16(packet, 30);
  final ivStart = 32;
  final ivEnd = ivStart + algs.blockSize;
  final cipherEnd = 28 + skLength - algs.integLength;
  final clear = _cbcCrypt(
    false,
    bootstrap.skEr,
    packet.sublist(ivStart, ivEnd),
    packet.sublist(ivEnd, cipherEnd),
  );
  final padLength = clear[clear.length - 1];
  final plain = clear.sublist(0, clear.length - padLength - 1);
  var current = nextInner;
  var offset = 0;
  int childSpiR = 0;
  List<_Transform> childSa = const <_Transform>[];
  InternetAddress? ip4;
  InternetAddress? ip6;
  final pcscf4 = <InternetAddress>[];
  final pcscf6 = <InternetAddress>[];
  final payloads = <int>[];
  final notifies = <_Notify>[];
  _EapPacket? eap;
  while (current != 0 && offset + 4 <= plain.length) {
    final next = plain[offset];
    final length = _readU16(plain, offset + 2);
    final segment = plain.sublist(offset + 4, offset + length);
    payloads.add(current);
    switch (current) {
      case _payloadSa:
        final parsed = _parseChildSa(segment);
        childSpiR = parsed.$1;
        childSa = parsed.$2;
      case _payloadEap:
        eap = _parseEap(segment);
      case _payloadCp:
        final cfg = _parseConfigReply(segment);
        ip4 = cfg.$1 ?? ip4;
        ip6 = cfg.$2 ?? ip6;
        pcscf4.addAll(cfg.$3);
        pcscf6.addAll(cfg.$4);
      case _payloadNotify:
        notifies.add(_parseNotify(segment));
    }
    current = next;
    offset += length;
  }
  return _AuthDecodeState(
    childSpiR: childSpiR,
    childSa: childSa,
    ip4: ip4,
    ip6: ip6,
    pcscf4: pcscf4,
    pcscf6: pcscf6,
    payloads: payloads,
    notifies: notifies,
    eap: eap,
  );
}

String _formatNotifies(List<_Notify> notifies) {
  if (notifies.isEmpty) {
    return 'none';
  }
  return notifies.map((notify) => notify.type.toString()).join(',');
}

_ChildKeys _deriveChildKeys(_BootstrapState boot, _AuthState auth) {
  var encKeyLen = 16;
  var integKeyLen = 20;
  var integLength = 12;
  var integAlgorithm = 'sha1';
  for (final transform in auth.childSa) {
    switch (transform.type) {
      case _transformEncr:
        encKeyLen = transform.keyLength == 0 ? 16 : transform.keyLength ~/ 8;
      case _transformInteg:
        switch (transform.id) {
          case _integSha256_128:
            integKeyLen = 32;
            integLength = 16;
            integAlgorithm = 'sha256';
          case _integHmacMd5_96:
            integKeyLen = 16;
            integLength = 12;
            integAlgorithm = 'md5';
          default:
            integKeyLen = 20;
            integLength = 12;
            integAlgorithm = 'sha1';
        }
    }
  }
  final algs = _selectAlgorithms(boot.selected);
  final seed = Uint8List.fromList(<int>[...boot.nonceI, ...boot.nonceR]);
  final need = 2 * (encKeyLen + integKeyLen);
  final keymat = _prfPlusByName(algs.prfName, boot.skD, seed, need);
  final encOut = keymat.sublist(0, encKeyLen);
  final integOut = keymat.sublist(encKeyLen, encKeyLen + integKeyLen);
  final encIn = keymat.sublist(
    encKeyLen + integKeyLen,
    2 * encKeyLen + integKeyLen,
  );
  final integIn = keymat.sublist(2 * encKeyLen + integKeyLen);
  return _ChildKeys(
    encIn: encIn,
    encOut: encOut,
    integIn: integIn,
    integOut: integOut,
    integLength: integLength,
    integAlgorithm: integAlgorithm,
  );
}

class _Payload {
  const _Payload({required this.kind, required this.body});

  final int kind;
  final Uint8List body;
}

class _Notify {
  const _Notify(this.type, this.data);

  final int type;
  final Uint8List data;
}

class _EapPacket {
  const _EapPacket({
    required this.code,
    required this.identifier,
    required this.type,
    required this.subtype,
    required this.attributes,
  });

  final int code;
  final int identifier;
  final int type;
  final int subtype;
  final List<_AkaAttribute> attributes;
}

class _AkaAttribute {
  const _AkaAttribute(this.type, this.data);

  final int type;
  final Uint8List data;
}

class _AkaParsedChallenge {
  const _AkaParsedChallenge(this.rand, this.autn);

  final Uint8List rand;
  final Uint8List autn;
}

class _DhKeyPair {
  const _DhKeyPair(this.privateKey, this.publicKey);

  final BigInt privateKey;
  final Uint8List publicKey;
}

Uint8List _buildMessage({
  required Uint8List spiI,
  required Uint8List spiR,
  required int exchange,
  required int flags,
  required List<_Payload> payloads,
  int messageId = 0,
}) {
  final out = BytesBuilder(copy: false)
    ..add(spiI)
    ..add(spiR)
    ..addByte(payloads.isEmpty ? 0 : payloads.first.kind)
    ..addByte(0x20)
    ..addByte(exchange)
    ..addByte(flags)
    ..add(_u32(messageId))
    ..add(const <int>[0, 0, 0, 0]);
  for (var index = 0; index < payloads.length; index++) {
    final payload = payloads[index];
    final next = index + 1 < payloads.length ? payloads[index + 1].kind : 0;
    out.addByte(next);
    out.addByte(0);
    out.add(_u16(4 + payload.body.length));
    out.add(payload.body);
  }
  final bytes = out.takeBytes();
  bytes.setRange(24, 28, _u32(bytes.length));
  return bytes;
}

_Payload _encodeSaPayload(int group) {
  final proposals = <Uint8List>[
    _encodeIkeProposal(
      1,
      _encrAesCbc,
      128,
      _integHmacSha1_96,
      _prfHmacSha1,
      group,
    ),
    _encodeIkeProposal(
      2,
      _encrAesCbc,
      256,
      _integHmacSha1_96,
      _prfHmacSha1,
      group,
    ),
    _encodeIkeProposal(
      3,
      _encrAesCbc,
      128,
      _integSha256_128,
      _prfHmacSha256,
      group,
    ),
  ];
  final body = BytesBuilder(copy: false);
  for (var index = 0; index < proposals.length; index++) {
    final value = Uint8List.fromList(proposals[index]);
    if (index + 1 < proposals.length) {
      value[0] = 2;
    }
    body.add(value);
  }
  return _Payload(kind: _payloadSa, body: body.takeBytes());
}

Uint8List _encodeIkeProposal(
  int number,
  int encId,
  int keyBits,
  int integId,
  int prfId,
  int group,
) {
  final transforms = <Uint8List>[
    _encodeTransform(_transformEncr, encId, keyBits),
    _encodeTransform(_transformInteg, integId, 0),
    _encodeTransform(_transformPrf, prfId, 0),
    _encodeTransform(_transformDh, group, 0),
  ];
  final proposal = BytesBuilder(copy: false)
    ..add(const <int>[0, 0, 0, 0, 0, _proposalIke, 0, 0]);
  final bytes = proposal.takeBytes();
  bytes[4] = number;
  bytes[7] = transforms.length;
  final out = BytesBuilder(copy: false)..add(bytes);
  for (var index = 0; index < transforms.length; index++) {
    final value = Uint8List.fromList(transforms[index]);
    if (index + 1 < transforms.length) {
      value[0] = 3;
    }
    out.add(value);
  }
  final result = out.takeBytes();
  result.setRange(2, 4, _u16(result.length));
  return result;
}

Uint8List _encodeTransform(int kind, int id, int keyBits) {
  final out = BytesBuilder(copy: false)
    ..add(const <int>[0, 0, 0, 8, 0, 0, 0, 0]);
  final bytes = out.takeBytes();
  bytes[4] = kind;
  bytes.setRange(6, 8, _u16(id));
  if (keyBits != 0) {
    final withAttr = BytesBuilder(copy: false)
      ..add(bytes)
      ..add(const <int>[0x80, 0x0E])
      ..add(_u16(keyBits));
    final result = withAttr.takeBytes();
    result.setRange(2, 4, _u16(result.length));
    return result;
  }
  return bytes;
}

_Payload _encodeNotify(
  InternetAddress localAddress,
  InternetAddress remoteAddress,
  int remotePort,
  Uint8List spiI,
  Uint8List spiR,
  int type,
) {
  final data = type == _notifyNatDest
      ? _natHash(spiI, spiR, remoteAddress, remotePort)
      : _natHash(spiI, spiR, localAddress, 500);
  return _encodeRawNotify(type, data);
}

_Payload _encodeRawNotify(int type, List<int> data) {
  return _Payload(
    kind: _payloadNotify,
    body: Uint8List.fromList(<int>[0, 0, ..._u16(type), ...data]),
  );
}

List<_Transform> _parseSa(Uint8List body) {
  if (body.length < 8) {
    return const <_Transform>[];
  }
  final proposalLength = min(_readU16(body, 2), body.length);
  final spiSize = body[6];
  final transforms = body[7];
  var offset = 8 + spiSize;
  final out = <_Transform>[];
  for (
    var count = 0;
    count < transforms && offset + 8 <= proposalLength;
    count++
  ) {
    final length = _readU16(body, offset + 2);
    out.add(
      _Transform(
        body[offset + 4],
        _readU16(body, offset + 6),
        length >= 12 ? _readU16(body, offset + 10) : 0,
      ),
    );
    offset += length;
  }
  return out;
}

_Notify _parseNotify(Uint8List body) {
  return _Notify(_readU16(body, 2), body.sublist(4));
}

bool _detectNat({
  required List<_Notify> notifies,
  required InternetAddress localAddress,
  required InternetAddress remoteAddress,
  required int remotePort,
  required Uint8List spiI,
  required Uint8List spiR,
}) {
  for (final notify in notifies) {
    if (notify.type == _notifyNatDest) {
      final want = _natHash(spiI, spiR, localAddress, 500);
      if (!_constantEquals(want, notify.data)) {
        return true;
      }
    }
    if (notify.type == _notifyNatSource) {
      final want = _natHash(spiI, spiR, remoteAddress, remotePort);
      if (!_constantEquals(want, notify.data)) {
        return true;
      }
    }
  }
  return false;
}

_AuthAlgorithms _selectAlgorithms(List<_Transform> selected) {
  var prfName = 'sha1';
  var encTransformId = _encrAesCbc;
  var integTransformId = _integHmacSha1_96;
  var encKeyLength = 16;
  var integLength = 12;
  for (final transform in selected) {
    switch (transform.type) {
      case _transformEncr:
        encTransformId = transform.id;
        if (transform.keyLength == 256) {
          encKeyLength = 32;
        }
      case _transformPrf:
        switch (transform.id) {
          case _prfHmacMd5:
            prfName = 'md5';
          case _prfHmacSha256:
            prfName = 'sha256';
          default:
            prfName = 'sha1';
        }
      case _transformInteg:
        integTransformId = transform.id;
        integLength = transform.id == _integSha256_128 ? 16 : 12;
    }
  }
  return _AuthAlgorithms(
    prfName: prfName,
    encTransformId: encTransformId,
    integTransformId: integTransformId,
    encKeyLength: encKeyLength,
    integLength: integLength,
    blockSize: 16,
  );
}

List<Uint8List> _deriveIkeKeys({
  required Uint8List shared,
  required Uint8List nonceI,
  required Uint8List nonceR,
  required Uint8List spiI,
  required Uint8List spiR,
  required _AuthAlgorithms algs,
}) {
  final prfLength = algs.prfName == 'sha256'
      ? 32
      : algs.prfName == 'md5'
      ? 16
      : 20;
  final integKeyLength = algs.integTransformId == _integSha256_128
      ? 32
      : algs.integTransformId == _integHmacMd5_96
      ? 16
      : 20;
  final skeyseed = _prfByName(
    algs.prfName,
    Uint8List.fromList(<int>[...nonceI, ...nonceR]),
    shared,
  );
  final seed = Uint8List.fromList(<int>[
    ...nonceI,
    ...nonceR,
    ...spiI,
    ...spiR,
  ]);
  final total =
      prfLength +
      integKeyLength +
      integKeyLength +
      algs.encKeyLength +
      algs.encKeyLength +
      prfLength +
      prfLength;
  final keymat = _prfPlusByName(algs.prfName, skeyseed, seed, total);
  var offset = 0;
  final parts = <Uint8List>[];
  for (final length in <int>[
    prfLength,
    integKeyLength,
    integKeyLength,
    algs.encKeyLength,
    algs.encKeyLength,
    prfLength,
    prfLength,
  ]) {
    parts.add(keymat.sublist(offset, offset + length));
    offset += length;
  }
  return parts;
}

Uint8List _buildEncryptedRequest({
  required _BootstrapState bootstrap,
  required _AuthAlgorithms algs,
  required int messageId,
  required List<_Payload> inner,
}) {
  final plain = _buildInnerPayloads(inner);
  final iv = _randomBytes(algs.blockSize);
  final padLength =
      (algs.blockSize - ((plain.length + 1) % algs.blockSize)) % algs.blockSize;
  final clear = BytesBuilder(copy: false)
    ..add(plain)
    ..add(List<int>.filled(padLength, 0))
    ..addByte(padLength);
  final ciphertext = _cbcCrypt(true, bootstrap.skEi, iv, clear.takeBytes());
  final skLength = 4 + iv.length + ciphertext.length + algs.integLength;
  final packet = BytesBuilder(copy: false)
    ..add(bootstrap.localSpi)
    ..add(bootstrap.remoteSpi)
    ..addByte(_payloadSk)
    ..addByte(0x20)
    ..addByte(_exchangeIkeAuth)
    ..addByte(_flagInitiator)
    ..add(_u32(messageId))
    ..add(_u32(28 + skLength))
    ..addByte(inner.isEmpty ? 0 : inner.first.kind)
    ..addByte(0)
    ..add(_u16(skLength))
    ..add(iv)
    ..add(ciphertext);
  final raw = packet.takeBytes();
  final icv = _integrityMac(
    algs,
    bootstrap.skAi,
    raw,
  ).sublist(0, algs.integLength);
  return Uint8List.fromList(<int>[
    if (bootstrap.natDetected) ...const <int>[0, 0, 0, 0],
    ...raw,
    ...icv,
  ]);
}

Uint8List _buildInnerPayloads(List<_Payload> payloads) {
  final out = BytesBuilder(copy: false);
  for (var index = 0; index < payloads.length; index++) {
    final payload = payloads[index];
    final next = index + 1 < payloads.length ? payloads[index + 1].kind : 0;
    out.addByte(next);
    out.addByte(0);
    out.add(_u16(4 + payload.body.length));
    out.add(payload.body);
  }
  return out.takeBytes();
}

String _buildRootNai(VowifiSmsConfig config) {
  final mnc = config.mnc.padLeft(3, '0');
  return '0${config.imsi}@nai.epc.mnc$mnc.mcc${config.mcc}.3gppnetwork.org';
}

Uint8List _encodeIdPayload(int type, String value) {
  return Uint8List.fromList(<int>[type, 0, 0, 0, ...utf8.encode(value)]);
}

Uint8List _encodeCfgRequest({required bool includeIPv6}) {
  final out = BytesBuilder(copy: false)
    ..add(const <int>[1, 0, 0, 0])
    ..add(_encodeCfgAttr(1))
    ..add(_encodeCfgAttr(3));
  if (includeIPv6) {
    out
      ..add(_encodeCfgAttr(8))
      ..add(_encodeCfgAttr(10))
      ..add(_encodeCfgAttr(20))
      ..add(_encodeCfgAttr(21));
  }
  return out.takeBytes();
}

Uint8List _encodeCfgAttr(int kind, [List<int> value = const <int>[]]) {
  return Uint8List.fromList(<int>[
    ..._u16(kind),
    ..._u16(value.length),
    ...value,
  ]);
}

Uint8List _encodeChildSa(int spi) {
  final proposals = <Uint8List>[
    _encodeEspProposal(1, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 128),
      _encodeTransform(_transformInteg, _integHmacMd5_96, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
    _encodeEspProposal(2, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 256),
      _encodeTransform(_transformInteg, _integHmacMd5_96, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
    _encodeEspProposal(3, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 128),
      _encodeTransform(_transformInteg, _integHmacSha1_96, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
    _encodeEspProposal(4, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 256),
      _encodeTransform(_transformInteg, _integHmacSha1_96, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
    _encodeEspProposal(5, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 128),
      _encodeTransform(_transformInteg, _integSha256_128, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
    _encodeEspProposal(6, spi, <Uint8List>[
      _encodeTransform(_transformEncr, _encrAesCbc, 256),
      _encodeTransform(_transformInteg, _integSha256_128, 0),
      _encodeTransform(_transformEsn, 0, 0),
    ]),
  ];
  final out = BytesBuilder(copy: false);
  for (var index = 0; index < proposals.length; index++) {
    final proposal = Uint8List.fromList(proposals[index]);
    if (index + 1 < proposals.length) {
      proposal[0] = 2;
    }
    out.add(proposal);
  }
  return out.takeBytes();
}

Uint8List _encodeEspProposal(int number, int spi, List<Uint8List> transforms) {
  final out = BytesBuilder(copy: false)
    ..add(const <int>[0, 0, 0, 0, 0, _proposalEsp, 4, 0])
    ..add(_u32(spi));
  final bytes = out.takeBytes();
  bytes[4] = number;
  bytes[7] = transforms.length;
  final proposal = BytesBuilder(copy: false)..add(bytes);
  for (var index = 0; index < transforms.length; index++) {
    final transform = Uint8List.fromList(transforms[index]);
    if (index + 1 < transforms.length) {
      transform[0] = 3;
    }
    proposal.add(transform);
  }
  final result = proposal.takeBytes();
  result.setRange(2, 4, _u16(result.length));
  return result;
}

Uint8List _encodeTsAnyDualStack() {
  return Uint8List.fromList(<int>[
    2,
    0,
    0,
    0,
    ..._encodeTsSelector(
      7,
      InternetAddress.anyIPv4.rawAddress,
      InternetAddress('255.255.255.255').rawAddress,
    ),
    ..._encodeTsSelector(
      8,
      InternetAddress.anyIPv6.rawAddress,
      InternetAddress('ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff').rawAddress,
    ),
  ]);
}

Uint8List _encodeTsSelector(int kind, List<int> start, List<int> end) {
  final addrLen = kind == 8 ? 16 : 4;
  return Uint8List.fromList(<int>[
    kind,
    0,
    ..._u16(8 + (addrLen * 2)),
    ..._u16(0),
    ..._u16(65535),
    ...start.take(addrLen),
    ...end.take(addrLen),
  ]);
}

_Payload _encodeDeviceIdentityNotify(String identity) {
  final digits = identity.replaceAll(RegExp(r'\D'), '').isEmpty
      ? _defaultDeviceIdentity
      : identity.replaceAll(RegExp(r'\D'), '');
  final padded = digits.length.isEven ? digits : '${digits}f';
  final packed = <int>[];
  for (var index = 0; index < padded.length; index += 2) {
    packed.add(_swapBcdByte(padded[index], padded[index + 1]));
  }
  final data = <int>[..._u16(packed.length + 1), 0x02, ...packed];
  return _encodeRawNotify(_notifyDeviceIdentity, data);
}

int _swapBcdByte(String a, String b) {
  return (_bcdNibble(b) << 4) | _bcdNibble(a);
}

int _bcdNibble(String digit) {
  final lower = digit.toLowerCase();
  if (lower == 'f') {
    return 0x0F;
  }
  return int.parse(lower, radix: 16) & 0x0F;
}

(int, List<_Transform>) _parseChildSa(Uint8List body) {
  if (body.length < 12) {
    return (0, const <_Transform>[]);
  }
  final spi = _readU32(body, 8);
  final transforms = <_Transform>[];
  var offset = 12;
  while (offset + 8 <= body.length) {
    final length = _readU16(body, offset + 2);
    // A transform shorter than its own header would never advance the offset.
    if (length < 8) break;
    transforms.add(
      _Transform(
        body[offset + 4],
        _readU16(body, offset + 6),
        length >= 12 ? _readU16(body, offset + 10) : 0,
      ),
    );
    offset += length;
  }
  return (spi, transforms);
}

(
  InternetAddress?,
  InternetAddress?,
  List<InternetAddress>,
  List<InternetAddress>,
)
_parseConfigReply(Uint8List body) {
  if (body.length < 4) {
    return (null, null, const <InternetAddress>[], const <InternetAddress>[]);
  }
  var offset = 4;
  InternetAddress? ip4;
  InternetAddress? ip6;
  final pcscf4 = <InternetAddress>[];
  final pcscf6 = <InternetAddress>[];
  while (offset + 4 <= body.length) {
    final type = _readU16(body, offset);
    final length = _readU16(body, offset + 2);
    final value = body.sublist(offset + 4, offset + 4 + length);
    if (type == 1 && value.length >= 4) {
      ip4 = InternetAddress.fromRawAddress(value.sublist(0, 4));
    }
    if (type == 8 && value.length >= 16) {
      ip6 = InternetAddress.fromRawAddress(value.sublist(0, 16));
    }
    if (type == 20 && value.length >= 4) {
      pcscf4.add(InternetAddress.fromRawAddress(value.sublist(0, 4)));
    }
    if (type == 21 && value.length >= 16) {
      pcscf6.add(InternetAddress.fromRawAddress(value.sublist(0, 16)));
    }
    offset += 4 + length;
  }
  return (ip4, ip6, pcscf4, pcscf6);
}

_EapPacket _parseEap(Uint8List raw) {
  if (raw.length < 4) {
    throw StateError('Short EAP packet');
  }
  final code = raw[0];
  final identifier = raw[1];
  if (code == _eapCodeSuccess) {
    return const _EapPacket(
      code: _eapCodeSuccess,
      identifier: 0,
      type: 0,
      subtype: 0,
      attributes: <_AkaAttribute>[],
    );
  }
  final type = raw[4];
  final subtype = raw[5];
  final attributes = <_AkaAttribute>[];
  var offset = 8;
  while (offset + 4 <= raw.length) {
    final attrLength = raw[offset + 1] * 4;
    attributes.add(
      _AkaAttribute(raw[offset], raw.sublist(offset + 2, offset + attrLength)),
    );
    offset += attrLength;
  }
  return _EapPacket(
    code: code,
    identifier: identifier,
    type: type,
    subtype: subtype,
    attributes: attributes,
  );
}

bool _requestsIdentity(List<_AkaAttribute> attributes) {
  for (final attribute in attributes) {
    if (attribute.type == _attrAnyIdReq ||
        attribute.type == _attrFullAuthIdReq ||
        attribute.type == _attrPermanentIdReq) {
      return true;
    }
  }
  return false;
}

Uint8List _buildAkaIdentityResponse(int identifier, String identity) {
  final bytes = utf8.encode(identity);
  final attrLength = ((4 + bytes.length + 3) ~/ 4) * 4;
  final attr = Uint8List(attrLength);
  attr[0] = _attrIdentity;
  attr[1] = attrLength ~/ 4;
  attr.setRange(2, 4, _u16(bytes.length));
  attr.setRange(4, 4 + bytes.length, bytes);
  final out = BytesBuilder(copy: false)
    ..addByte(_eapCodeResponse)
    ..addByte(identifier)
    ..add(_u16(8 + attrLength))
    ..addByte(_eapTypeAka)
    ..addByte(_eapSubtypeIdentity)
    ..add(const <int>[0, 0])
    ..add(attr);
  return out.takeBytes();
}

_AkaParsedChallenge _parseAkaChallenge(List<_AkaAttribute> attributes) {
  Uint8List? rand;
  Uint8List? autn;
  for (final attribute in attributes) {
    if (attribute.type == _attrRand && attribute.data.length >= 18) {
      rand = attribute.data.sublist(2, 18);
    }
    if (attribute.type == _attrAutn && attribute.data.length >= 18) {
      autn = attribute.data.sublist(2, 18);
    }
  }
  if (rand == null || autn == null) {
    throw StateError('Missing EAP-AKA RAND/AUTN');
  }
  return _AkaParsedChallenge(rand, autn);
}

List<Uint8List> _deriveEapAkaKeys(String identity, Uint8List ik, Uint8List ck) {
  final mk = sha1.convert(<int>[...utf8.encode(identity), ...ik, ...ck]).bytes;
  var x = Uint8List.fromList(mk);
  final mod = BigInt.one << 160;
  final out = BytesBuilder(copy: false);
  for (var index = 0; index < 4; index++) {
    final w0 = _sha1Dss(x);
    x = _addMod160(x, w0, mod);
    final w1 = _sha1Dss(x);
    x = _addMod160(x, w1, mod);
    out.add(w0);
    out.add(w1);
  }
  final bytes = out.takeBytes();
  return <Uint8List>[bytes.sublist(16, 32), bytes.sublist(32, 96)];
}

Uint8List _buildAkaChallengeResponse(
  int identifier,
  Uint8List res,
  Uint8List authKey,
) {
  final resValue = Uint8List.fromList(<int>[..._u16(res.length * 8), ...res]);
  final resAttr = _encodeEapAkaAttr(_attrRes, resValue);
  final macAttr = _encodeEapAkaAttr(
    _attrMac,
    Uint8List.fromList(<int>[0, 0, ...List<int>.filled(16, 0)]),
  );
  final out = BytesBuilder(copy: false)
    ..addByte(_eapCodeResponse)
    ..addByte(identifier)
    ..add(const <int>[0, 0])
    ..addByte(_eapTypeAka)
    ..addByte(_eapSubtypeChallenge)
    ..add(const <int>[0, 0])
    ..add(resAttr)
    ..add(macAttr);
  final bytes = out.takeBytes();
  bytes.setRange(2, 4, _u16(bytes.length));
  final sum = Hmac(sha1, authKey).convert(bytes).bytes;
  final macOffset = 8 + resAttr.length + 4;
  bytes.setRange(macOffset, macOffset + 16, sum.take(16));
  return bytes;
}

Uint8List _encodeEapAkaAttr(int type, Uint8List value) {
  var data = Uint8List.fromList(value);
  final remainder = (data.length + 2) % 4;
  if (remainder != 0) {
    data = Uint8List.fromList(<int>[
      ...data,
      ...List<int>.filled(4 - remainder, 0),
    ]);
  }
  return Uint8List.fromList(<int>[type, (data.length + 2) ~/ 4, ...data]);
}

Uint8List _buildFinalAuth({
  required _BootstrapState bootstrap,
  required _AuthAlgorithms algs,
  required String identity,
  required Uint8List msk,
}) {
  final idRaw = _encodeIdPayload(3, identity);
  final signedOctets = Uint8List.fromList(<int>[
    ...bootstrap.saInitRequest,
    ...bootstrap.nonceR,
    ..._prfByName(algs.prfName, bootstrap.skPi, idRaw),
  ]);
  final tmp = _prfByName(
    algs.prfName,
    msk,
    Uint8List.fromList('Key Pad for IKEv2'.codeUnits),
  );
  final authData = _prfByName(algs.prfName, tmp, signedOctets);
  return Uint8List.fromList(<int>[2, 0, 0, 0, ...authData]);
}

Future<void> _sendDatagram(
  RawDatagramSocket socket,
  Uint8List data,
  InternetAddress address,
  int port, {
  required bool natt,
  bool ike = false,
}) async {
  final payload = ike ? VowifiIkeDatagramCodec.frame(data, natt: natt) : data;
  socket.send(payload, address, port);
}

Uint8List _buildIpUdp({
  required InternetAddress src,
  required InternetAddress dst,
  required int srcPort,
  required int dstPort,
  required Uint8List payload,
}) {
  return _buildIpPacket(
    src: src,
    dst: dst,
    protocol: 17,
    payload: _buildUdpDatagram(
      src: src,
      dst: dst,
      srcPort: srcPort,
      dstPort: dstPort,
      payload: payload,
    ),
  );
}

Uint8List? _extractUdpPayload(
  Uint8List packet, {
  required InternetAddress localAddress,
  required int localPort,
  required InternetAddress remoteAddress,
  required int remotePort,
}) {
  final parsed = _parseIpPacket(packet);
  if (parsed == null || parsed.protocol != 17 || parsed.l4.length < 8) {
    return null;
  }
  final srcPort = _readU16(parsed.l4, 0);
  final dstPort = _readU16(parsed.l4, 2);
  if (!_constantEquals(parsed.dst.rawAddress, localAddress.rawAddress) ||
      dstPort != localPort) {
    return null;
  }
  if (!_constantEquals(parsed.src.rawAddress, remoteAddress.rawAddress) ||
      srcPort != remotePort) {
    return null;
  }
  final udpLength = _readU16(parsed.l4, 4);
  if (udpLength < 8 || udpLength > parsed.l4.length) {
    return null;
  }
  return parsed.l4.sublist(8, udpLength);
}

int _ipv4Checksum(Uint8List data) {
  var sum = 0;
  for (var index = 0; index < data.length; index += 2) {
    sum += (data[index] << 8) + data[index + 1];
  }
  while ((sum >> 16) != 0) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }
  return (~sum) & 0xFFFF;
}

Uint8List _buildUdpDatagram({
  required InternetAddress src,
  required InternetAddress dst,
  required int srcPort,
  required int dstPort,
  required Uint8List payload,
}) {
  final udpLength = 8 + payload.length;
  final udp = Uint8List(udpLength);
  udp.setRange(0, 2, _u16(srcPort));
  udp.setRange(2, 4, _u16(dstPort));
  udp.setRange(4, 6, _u16(udpLength));
  udp.setRange(8, udp.length, payload);
  udp.setRange(6, 8, _u16(_udpChecksum(src, dst, udp, payload)));
  return udp;
}

Uint8List _buildIpPacket({
  required InternetAddress src,
  required InternetAddress dst,
  required int protocol,
  required Uint8List payload,
}) {
  if (src.type == InternetAddressType.IPv6 ||
      dst.type == InternetAddressType.IPv6) {
    final ip = Uint8List(40 + payload.length);
    ip[0] = 0x60;
    ip.setRange(4, 6, _u16(payload.length));
    ip[6] = protocol;
    ip[7] = 64;
    ip.setRange(8, 24, src.rawAddress);
    ip.setRange(24, 40, dst.rawAddress);
    ip.setRange(40, ip.length, payload);
    return ip;
  }
  final ip = Uint8List(20 + payload.length);
  ip[0] = 0x45;
  ip[8] = 64;
  ip[9] = protocol;
  ip.setRange(2, 4, _u16(ip.length));
  ip.setRange(12, 16, src.rawAddress);
  ip.setRange(16, 20, dst.rawAddress);
  ip.setRange(20, ip.length, payload);
  ip.setRange(10, 12, _u16(_ipv4Checksum(ip.sublist(0, 20))));
  return ip;
}

int _udpChecksum(
  InternetAddress src,
  InternetAddress dst,
  Uint8List udpHeaderAndPayload,
  Uint8List payload,
) {
  var sum = 0;
  void add16(int value) {
    sum += value & 0xFFFF;
  }

  void addBytes(List<int> bytes) {
    for (var index = 0; index + 1 < bytes.length; index += 2) {
      add16((bytes[index] << 8) | bytes[index + 1]);
    }
    if (bytes.length.isOdd) {
      add16(bytes.last << 8);
    }
  }

  addBytes(src.rawAddress);
  addBytes(dst.rawAddress);
  if (src.type == InternetAddressType.IPv6 ||
      dst.type == InternetAddressType.IPv6) {
    add16(0);
    add16(_readU16(udpHeaderAndPayload, 4));
    add16(0);
    add16(0x0011);
  } else {
    add16(0x0011);
    add16(_readU16(udpHeaderAndPayload, 4));
  }
  addBytes(udpHeaderAndPayload.sublist(0, 6));
  add16(0);
  addBytes(payload);
  while ((sum >> 16) != 0) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }
  final checksum = (~sum) & 0xFFFF;
  return checksum == 0 ? 0xFFFF : checksum;
}

Uint8List _buildImsNullEspPacket({
  required int spi,
  required int seq,
  required Uint8List authKey,
  required int nextHeader,
  required Uint8List payload,
}) {
  final padLength = (4 - ((payload.length + 2) % 4)) % 4;
  final plain = BytesBuilder(copy: false)
    ..add(payload)
    ..add(List<int>.generate(padLength, (index) => index + 1))
    ..addByte(padLength)
    ..addByte(nextHeader);
  final esp = BytesBuilder(copy: false)
    ..add(_u32(spi))
    ..add(_u32(seq))
    ..add(plain.takeBytes());
  final raw = esp.takeBytes();
  final icv = _hmac('md5', authKey, raw).sublist(0, 12);
  return Uint8List.fromList(<int>[...raw, ...icv]);
}

Uint8List? _extractImsProtectedUdpPayload(
  Uint8List packet, {
  required InternetAddress localAddress,
  required int localPort,
  required InternetAddress remoteAddress,
  required int remotePort,
  required int spiIn,
  required Uint8List authKey,
}) {
  final parsed = _parseIpPacket(packet);
  if (parsed == null || parsed.protocol != 50 || parsed.l4.length < 20) {
    return null;
  }
  if (!_constantEquals(parsed.dst.rawAddress, localAddress.rawAddress)) {
    return null;
  }
  if (!_constantEquals(parsed.src.rawAddress, remoteAddress.rawAddress)) {
    return null;
  }
  final esp = parsed.l4;
  if (esp.length < 22 || _readU32(esp, 0) != spiIn) {
    return null;
  }
  final body = esp.sublist(0, esp.length - 12);
  final gotIcv = esp.sublist(esp.length - 12);
  final wantIcv = _hmac('md5', authKey, body).sublist(0, 12);
  if (!_constantEquals(gotIcv, wantIcv)) {
    return null;
  }
  final clear = body.sublist(8);
  if (clear.length < 2) {
    return null;
  }
  final padLength = clear[clear.length - 2];
  final nextHeader = clear.last;
  if (nextHeader != 17 || padLength + 2 > clear.length) {
    return null;
  }
  final udp = clear.sublist(0, clear.length - padLength - 2);
  if (udp.length < 8) {
    return null;
  }
  final srcPort = _readU16(udp, 0);
  final dstPort = _readU16(udp, 2);
  if (dstPort != localPort || srcPort != remotePort) {
    return null;
  }
  final udpLength = _readU16(udp, 4);
  if (udpLength < 8 || udpLength > udp.length) {
    return null;
  }
  return udp.sublist(8, udpLength);
}

({Uint8List? payload, _ImsProtectedMeta? meta, String reason})
_extractImsProtectedPayloadWithReason(
  Uint8List packet, {
  required InternetAddress localAddress,
  required int localPort,
  required InternetAddress? remoteAddress,
  required int remotePort,
  required int spiIn,
  required Uint8List authKey,
}) {
  final parsed = _parseIpPacket(packet);
  if (parsed == null || parsed.protocol != 50 || parsed.l4.length < 20) {
    return (payload: null, meta: null, reason: '');
  }
  if (!_constantEquals(parsed.dst.rawAddress, localAddress.rawAddress)) {
    return (payload: null, meta: null, reason: 'dst');
  }
  if (remoteAddress != null &&
      !_constantEquals(parsed.src.rawAddress, remoteAddress.rawAddress)) {
    return (payload: null, meta: null, reason: 'src');
  }
  final esp = parsed.l4;
  if (esp.length < 22) {
    return (payload: null, meta: null, reason: 'esp-short');
  }
  final gotSpi = _readU32(esp, 0);
  if (gotSpi != spiIn) {
    return (
      payload: null,
      meta: null,
      reason:
          'spi-got=0x${gotSpi.toRadixString(16).padLeft(8, '0')}-want=0x${spiIn.toRadixString(16).padLeft(8, '0')}',
    );
  }
  final body = esp.sublist(0, esp.length - 12);
  final gotIcv = esp.sublist(esp.length - 12);
  final wantIcv = _hmac('md5', authKey, body).sublist(0, 12);
  if (!_constantEquals(gotIcv, wantIcv)) {
    return (payload: null, meta: null, reason: 'icv');
  }
  final clear = body.sublist(8);
  if (clear.length < 2) {
    return (payload: null, meta: null, reason: 'clear-short');
  }
  final padLength = clear[clear.length - 2];
  final nextHeader = clear.last;
  if (padLength + 2 > clear.length) {
    return (payload: null, meta: null, reason: 'trailer');
  }
  final inner = clear.sublist(0, clear.length - padLength - 2);
  switch (nextHeader) {
    case 17:
      if (inner.length < 8) {
        return (payload: null, meta: null, reason: 'udp-short');
      }
      final srcPort = _readU16(inner, 0);
      final dstPort = _readU16(inner, 2);
      if (dstPort != localPort || srcPort != remotePort) {
        return (
          payload: null,
          meta: null,
          reason:
              'udp-sport=$srcPort-dport=$dstPort-want-sport=$remotePort-want-dport=$localPort',
        );
      }
      final udpLength = _readU16(inner, 4);
      if (udpLength < 8 || udpLength > inner.length) {
        return (payload: null, meta: null, reason: 'udp-short');
      }
      return (
        payload: inner.sublist(8, udpLength),
        meta: _ImsProtectedMeta(spiIn: spiIn),
        reason: '',
      );
    case 6:
      final tcp = _extractSipFromTcpSegment(inner, localPort: localPort);
      return (
        payload: tcp.payload,
        meta: _ImsProtectedMeta(tcp: tcp.meta, spiIn: spiIn),
        reason: tcp.reason,
      );
    default:
      return (payload: null, meta: null, reason: 'trailer-nh=$nextHeader');
  }
}

Uint8List? _extractUdpPayloadAnySource(
  Uint8List packet, {
  required InternetAddress localAddress,
  required int localPort,
}) {
  final parsed = _parseIpPacket(packet);
  if (parsed == null || parsed.protocol != 17 || parsed.l4.length < 8) {
    return null;
  }
  final dstPort = _readU16(parsed.l4, 2);
  if (!_constantEquals(parsed.dst.rawAddress, localAddress.rawAddress) ||
      dstPort != localPort) {
    return null;
  }
  final udpLength = _readU16(parsed.l4, 4);
  if (udpLength < 8 || udpLength > parsed.l4.length) {
    return null;
  }
  return parsed.l4.sublist(8, udpLength);
}

Uint8List? _extractAnyUdpPayload(Uint8List packet) {
  final parsed = _parseIpPacket(packet);
  if (parsed == null || parsed.protocol != 17 || parsed.l4.length < 8) {
    return null;
  }
  final udpLength = _readU16(parsed.l4, 4);
  if (udpLength < 8 || udpLength > parsed.l4.length) {
    return null;
  }
  return parsed.l4.sublist(8, udpLength);
}

bool _looksLikeSip(Uint8List payload) {
  if (payload.isEmpty) {
    return false;
  }
  final text = latin1.decode(payload, allowInvalid: true).trimLeft();
  return text.startsWith('SIP/2.0 ') ||
      text.startsWith('REGISTER ') ||
      text.startsWith('INVITE ') ||
      text.startsWith('MESSAGE ') ||
      text.startsWith('OPTIONS ');
}

({Uint8List? payload, _ImsTcpSegmentMeta? meta, String reason})
_extractSipFromTcpSegment(Uint8List tcp, {required int localPort}) {
  if (tcp.length < 20) {
    return (payload: null, meta: null, reason: 'tcp-short');
  }
  final srcPort = _readU16(tcp, 0);
  final dstPort = _readU16(tcp, 2);
  final meta = _ImsTcpSegmentMeta(
    srcPort: srcPort,
    dstPort: dstPort,
    seq: _readU32(tcp, 4),
    ack: _readU32(tcp, 8),
    flags: tcp[13],
    mss: 0,
    hasWs: false,
    ws: 0,
    sackOk: false,
    hasTs: false,
    tsVal: 0,
  );
  if (dstPort != localPort) {
    return (
      payload: null,
      meta: meta,
      reason: 'tcp-dport=$dstPort-want=$localPort',
    );
  }
  final headerLength = ((tcp[12] >> 4) & 0xF) * 4;
  if (headerLength < 20 || headerLength > tcp.length) {
    return (payload: null, meta: meta, reason: 'tcp-hlen');
  }
  if (headerLength > 20) {
    var i = 20;
    while (i < headerLength) {
      final kind = tcp[i];
      if (kind == 0) {
        break;
      }
      if (kind == 1) {
        i++;
        continue;
      }
      if (i + 1 >= headerLength) {
        break;
      }
      final l = tcp[i + 1];
      if (l < 2 || i + l > headerLength) {
        break;
      }
      if (kind == 2 && l == 4) {
        meta.mss = _readU16(tcp, i + 2);
      } else if (kind == 3 && l == 3) {
        meta.hasWs = true;
        meta.ws = tcp[i + 2];
      } else if (kind == 4 && l == 2) {
        meta.sackOk = true;
      } else if (kind == 8 && l == 10) {
        meta.hasTs = true;
        meta.tsVal = _readU32(tcp, i + 2);
      }
      i += l;
    }
  }
  final payload = tcp.sublist(headerLength);
  if (payload.isEmpty) {
    return (
      payload: null,
      meta: meta,
      reason:
          'tcp-nodata sport=$srcPort dport=$dstPort flags=0x${meta.flags.toRadixString(16).padLeft(2, '0')} seq=${meta.seq} ack=${meta.ack}',
    );
  }
  return (payload: Uint8List.fromList(payload), meta: meta, reason: '');
}

_ParsedIpPacket? _parseIpPacket(Uint8List packet) {
  if (packet.isEmpty) {
    return null;
  }
  switch ((packet[0] >> 4) & 0xF) {
    case 4:
      if (packet.length < 20) {
        return null;
      }
      final ihl = (packet[0] & 0x0F) * 4;
      if (ihl < 20 || packet.length < ihl) {
        return null;
      }
      return _ParsedIpPacket(
        protocol: packet[9],
        src: InternetAddress.fromRawAddress(
          Uint8List.fromList(packet.sublist(12, 16)),
        ),
        dst: InternetAddress.fromRawAddress(
          Uint8List.fromList(packet.sublist(16, 20)),
        ),
        l4: Uint8List.fromList(packet.sublist(ihl)),
      );
    case 6:
      if (packet.length < 40) {
        return null;
      }
      return _ParsedIpPacket(
        protocol: packet[6],
        src: InternetAddress.fromRawAddress(
          Uint8List.fromList(packet.sublist(8, 24)),
        ),
        dst: InternetAddress.fromRawAddress(
          Uint8List.fromList(packet.sublist(24, 40)),
        ),
        l4: Uint8List.fromList(packet.sublist(40)),
      );
    default:
      return null;
  }
}

Uint8List _buildTcpSegment({
  required InternetAddress src,
  required InternetAddress dst,
  required int srcPort,
  required int dstPort,
  required int seq,
  required int ack,
  required int flags,
  required int window,
  required Uint8List options,
  required Uint8List payload,
}) {
  final paddedOptions = options.isEmpty
      ? Uint8List(0)
      : Uint8List.fromList(<int>[
          ...options,
          ...List<int>.filled((4 - (options.length % 4)) % 4, 0),
        ]);
  final headerLength = 20 + paddedOptions.length;
  final tcp = Uint8List(headerLength + payload.length);
  tcp.setRange(0, 2, _u16(srcPort));
  tcp.setRange(2, 4, _u16(dstPort));
  tcp.setRange(4, 8, _u32(seq));
  tcp.setRange(8, 12, _u32(ack));
  tcp[12] = ((headerLength ~/ 4) << 4) & 0xF0;
  tcp[13] = flags & 0xFF;
  tcp.setRange(14, 16, _u16(window));
  if (paddedOptions.isNotEmpty) {
    tcp.setRange(20, 20 + paddedOptions.length, paddedOptions);
  }
  if (payload.isNotEmpty) {
    tcp.setRange(headerLength, tcp.length, payload);
  }
  tcp.setRange(16, 18, _u16(_tcpChecksum(src, dst, tcp)));
  return tcp;
}

int _tcpChecksum(InternetAddress src, InternetAddress dst, Uint8List tcp) {
  var sum = 0;
  void add16(int value) => sum += value & 0xFFFF;
  void addBytes(List<int> bytes) {
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      add16((bytes[i] << 8) | bytes[i + 1]);
    }
    if (bytes.length.isOdd) {
      add16(bytes.last << 8);
    }
  }

  addBytes(src.rawAddress);
  addBytes(dst.rawAddress);
  if (src.type == InternetAddressType.IPv6 ||
      dst.type == InternetAddressType.IPv6) {
    add16((tcp.length >> 16) & 0xFFFF);
    add16(tcp.length & 0xFFFF);
    add16(0);
    add16(0x0006);
  } else {
    add16(0x0006);
    add16(tcp.length);
  }
  addBytes(tcp.sublist(0, 16));
  add16(0);
  addBytes(tcp.sublist(18));
  while ((sum >> 16) != 0) {
    sum = (sum & 0xFFFF) + (sum >> 16);
  }
  final checksum = (~sum) & 0xFFFF;
  return checksum == 0 ? 0xFFFF : checksum;
}

Uint8List _buildSynAckOptions(_ImsTcpSegmentMeta meta, int retries) {
  final profile = retries <= 0 ? 0 : (retries == 1 ? 1 : 2);
  if (profile == 2) {
    return Uint8List(0);
  }
  final mss = meta.mss > 0 ? meta.mss : 1360;
  final out = <int>[2, 4, (mss >> 8) & 0xFF, mss & 0xFF];
  if (profile == 1) {
    return Uint8List.fromList(out);
  }
  if (meta.sackOk) {
    out.addAll(const <int>[4, 2]);
  }
  if (meta.hasWs) {
    out.addAll(<int>[1, 3, 3, meta.ws]);
  }
  if (meta.hasTs) {
    final ts = Uint8List(10);
    ts[0] = 8;
    ts[1] = 10;
    ts.setRange(2, 6, _u32(DateTime.now().millisecondsSinceEpoch));
    ts.setRange(6, 10, _u32(meta.tsVal));
    out.addAll(const <int>[1, 1]);
    out.addAll(ts);
  }
  return Uint8List.fromList(out);
}

class _ParsedIpPacket {
  const _ParsedIpPacket({
    required this.protocol,
    required this.src,
    required this.dst,
    required this.l4,
  });

  final int protocol;
  final InternetAddress src;
  final InternetAddress dst;
  final Uint8List l4;
}

class _ImsProtectedMeta {
  const _ImsProtectedMeta({required this.spiIn, this.tcp});

  final int spiIn;
  final _ImsTcpSegmentMeta? tcp;
}

class _ImsTcpSegmentMeta {
  _ImsTcpSegmentMeta({
    required this.srcPort,
    required this.dstPort,
    required this.seq,
    required this.ack,
    required this.flags,
    required this.mss,
    required this.hasWs,
    required this.ws,
    required this.sackOk,
    required this.hasTs,
    required this.tsVal,
  });

  final int srcPort;
  final int dstPort;
  final int seq;
  final int ack;
  final int flags;
  int mss;
  bool hasWs;
  int ws;
  bool sackOk;
  bool hasTs;
  int tsVal;
}

_DhKeyPair _dhKeyPair(int group) {
  final prime = group == _dhGroup2 ? _modp2Prime : _modp14Prime;
  final width = group == _dhGroup2 ? 128 : 256;
  final secret = _randomBigInt(prime);
  final publicKey = _leftPad(
    _bigIntToBytes(BigInt.two.modPow(secret, prime)),
    width,
  );
  return _DhKeyPair(secret, publicKey);
}

Uint8List _dhShared(int group, BigInt privateKey, Uint8List peer) {
  final prime = group == _dhGroup2 ? _modp2Prime : _modp14Prime;
  final width = group == _dhGroup2 ? 128 : 256;
  final peerValue = BigInt.parse(_hex(peer), radix: 16);
  final shared = peerValue.modPow(privateKey, prime);
  return _leftPad(_bigIntToBytes(shared), width);
}

BigInt _randomBigInt(BigInt maxExclusive) {
  final width = (maxExclusive.bitLength / 8).ceil();
  while (true) {
    final candidate = BigInt.parse(_hex(_randomBytes(width)), radix: 16);
    if (candidate > BigInt.zero && candidate < maxExclusive) {
      return candidate;
    }
  }
}

Uint8List _prfByName(String name, Uint8List key, Uint8List data) {
  switch (name) {
    case 'md5':
      return Uint8List.fromList(Hmac(md5, key).convert(data).bytes);
    case 'sha256':
      return Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);
    default:
      return Uint8List.fromList(Hmac(sha1, key).convert(data).bytes);
  }
}

Uint8List _prfPlusByName(
  String name,
  Uint8List key,
  Uint8List seed,
  int count,
) {
  final out = BytesBuilder(copy: false);
  Uint8List previous = Uint8List(0);
  var counter = 1;
  while (out.length < count) {
    previous = _prfByName(
      name,
      key,
      Uint8List.fromList(<int>[...previous, ...seed, counter]),
    );
    out.add(previous);
    counter++;
  }
  final bytes = out.takeBytes();
  return bytes.sublist(0, count);
}

Uint8List _integrityMac(
  _AuthAlgorithms algs,
  Uint8List key,
  Uint8List message,
) {
  switch (algs.integTransformId) {
    case _integHmacMd5_96:
      return Uint8List.fromList(Hmac(md5, key).convert(message).bytes);
    case _integSha256_128:
      return Uint8List.fromList(Hmac(sha256, key).convert(message).bytes);
    default:
      return Uint8List.fromList(Hmac(sha1, key).convert(message).bytes);
  }
}

Uint8List _hmac(String name, Uint8List key, Uint8List data) {
  switch (name) {
    case 'md5':
      return Uint8List.fromList(Hmac(md5, key).convert(data).bytes);
    case 'sha256':
      return Uint8List.fromList(Hmac(sha256, key).convert(data).bytes);
    default:
      return Uint8List.fromList(Hmac(sha1, key).convert(data).bytes);
  }
}

Uint8List _cbcCrypt(bool encrypt, Uint8List key, Uint8List iv, Uint8List data) {
  final cipher = CBCBlockCipher(AESEngine())
    ..init(encrypt, ParametersWithIV(KeyParameter(key), iv));
  final out = Uint8List(data.length);
  for (var offset = 0; offset < data.length; offset += cipher.blockSize) {
    cipher.processBlock(data, offset, out, offset);
  }
  return out;
}

Uint8List _natHash(
  Uint8List spiI,
  Uint8List spiR,
  InternetAddress address,
  int port,
) {
  return Uint8List.fromList(
    sha1.convert(<int>[
      ...spiI,
      ...spiR,
      ...address.rawAddress,
      ..._u16(port),
    ]).bytes,
  );
}

Uint8List _stripNatt(Uint8List raw) {
  return VowifiIkeDatagramCodec.stripNattMarker(raw);
}

final Random _secureRandom = Random.secure();

Uint8List _randomBytes(int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = _secureRandom.nextInt(256);
  }
  return bytes;
}

int _readU16(List<int> data, int offset) =>
    (data[offset] << 8) | data[offset + 1];

int _readU32(List<int> data, int offset) =>
    (data[offset] << 24) |
    (data[offset + 1] << 16) |
    (data[offset + 2] << 8) |
    data[offset + 3];

Uint8List _u16(int value) =>
    Uint8List.fromList(<int>[(value >> 8) & 0xFF, value & 0xFF]);

Uint8List _u32(int value) => Uint8List.fromList(<int>[
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
]);

int _randomU32() => _secureRandom.nextInt(0x7FFFFFFF);

bool _constantEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var out = 0;
  for (var index = 0; index < left.length; index++) {
    out |= left[index] ^ right[index];
  }
  return out == 0;
}

Uint8List _sha1Dss(Uint8List data) {
  final padded = Uint8List(64)..setRange(0, min(20, data.length), data);
  final w = Uint32List(80);
  for (var index = 0; index < 16; index++) {
    w[index] = _readU32(padded, index * 4);
  }
  for (var index = 16; index < 80; index++) {
    final value = w[index - 3] ^ w[index - 8] ^ w[index - 14] ^ w[index - 16];
    w[index] = ((value << 1) | (value >> 31)) & 0xFFFFFFFF;
  }
  var a = 0x67452301;
  var b = 0xEFCDAB89;
  var c = 0x98BADCFE;
  var d = 0x10325476;
  var e = 0xC3D2E1F0;
  for (var index = 0; index < 80; index++) {
    late int f;
    late int k;
    if (index < 20) {
      f = (b & c) | ((~b) & d);
      k = 0x5A827999;
    } else if (index < 40) {
      f = b ^ c ^ d;
      k = 0x6ED9EBA1;
    } else if (index < 60) {
      f = (b & c) | (b & d) | (c & d);
      k = 0x8F1BBCDC;
    } else {
      f = b ^ c ^ d;
      k = 0xCA62C1D6;
    }
    final temp = (((a << 5) | (a >> 27)) + f + e + k + w[index]) & 0xFFFFFFFF;
    e = d;
    d = c;
    c = ((b << 30) | (b >> 2)) & 0xFFFFFFFF;
    b = a;
    a = temp;
  }
  return Uint8List.fromList(<int>[
    ..._u32((0x67452301 + a) & 0xFFFFFFFF),
    ..._u32((0xEFCDAB89 + b) & 0xFFFFFFFF),
    ..._u32((0x98BADCFE + c) & 0xFFFFFFFF),
    ..._u32((0x10325476 + d) & 0xFFFFFFFF),
    ..._u32((0xC3D2E1F0 + e) & 0xFFFFFFFF),
  ]);
}

Uint8List _addMod160(Uint8List left, Uint8List right, BigInt modulus) {
  final value =
      (BigInt.parse(_hex(left), radix: 16) +
          BigInt.parse(_hex(right), radix: 16) +
          BigInt.one) %
      modulus;
  return _leftPad(_bigIntToBytes(value), 20);
}

Uint8List _leftPad(Uint8List bytes, int width) {
  if (bytes.length >= width) {
    return bytes;
  }
  final out = Uint8List(width);
  out.setRange(width - bytes.length, width, bytes);
  return out;
}

Uint8List _bigIntToBytes(BigInt value) {
  if (value == BigInt.zero) {
    return Uint8List.fromList(const <int>[0]);
  }
  final hex = value.toRadixString(16);
  final normalized = hex.length.isOdd ? '0$hex' : hex;
  return Uint8List.fromList(
    List<int>.generate(
      normalized.length ~/ 2,
      (index) =>
          int.parse(normalized.substring(index * 2, index * 2 + 2), radix: 16),
      growable: false,
    ),
  );
}

final BigInt _modp2Prime = BigInt.parse(
  'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
  '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
  'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
  'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
  'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE65381'
  'FFFFFFFFFFFFFFFF',
  radix: 16,
);

final BigInt _modp14Prime = BigInt.parse(
  'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
  '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
  'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
  'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
  'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D'
  'C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F'
  '83655D23DCA3AD961C62F356208552BB9ED529077096966D'
  '670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B'
  'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9'
  'DE2BCBF6955817183995497CEA956AE515D2261898FA0510'
  '15728E5A8AACAA68FFFFFFFFFFFFFFFF',
  radix: 16,
);

String _transformSummary(List<_Transform> selected) {
  return selected.map((value) => '${value.type}/${value.id}').join(',');
}

String _hex(List<int> bytes) =>
    bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
