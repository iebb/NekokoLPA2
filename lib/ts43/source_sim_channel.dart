import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../adapter/euicc_adapter.dart';
import 'sim/aka.dart';
import 'sim/identifier.dart';
import 'sim/identity.dart';
import 'sim/imsi.dart';
import 'sim/tlv.dart';
import 'sim/usim_files.dart';
import 'types.dart';

/// Thrown when the active profile's USIM applet cannot be reached on the
/// current reader (so EAP-AKA transfer is not possible there).
class SourceSimUnavailable implements Exception {
  final String message;
  const SourceSimUnavailable(this.message);
  @override
  String toString() => 'Source SIM unavailable: $message';
}

/// A [SourceChannel] backed by the managed eUICC's *enabled* profile, read
/// through its USIM applet. This is the analog of ts43-go's `driver/ccid`,
/// adapted to nlpa2's [Adapter]/[Channel] interface.
///
/// The profile to transfer MUST be enabled before use; the USIM ADF only
/// exists while its profile is active. APDUs go on a logical channel separate
/// from the ISD-R session used for LPA download/delete.
class SourceSimChannel implements SourceChannel {
  static final Logger _log = Logger('SourceSimChannel');

  final Adapter adapter;
  Channel? _channel;
  Uint8List? _usimAid;
  Identity? _cachedIdentity;

  SourceSimChannel(this.adapter);

  Future<Channel> _open() async {
    _channel ??= await adapter.openChannel();
    return _channel!;
  }

  /// Closes the underlying logical channel so the ISD-R session can resume.
  Future<void> dispose() async {
    final ch = _channel;
    _channel = null;
    _usimAid = null;
    if (ch != null) {
      try {
        await ch.close();
      } catch (e) {
        _log.warning('Failed to close source USIM channel: $e');
      }
    }
  }

  /// Sends an APDU on the USIM channel and returns the response data with the
  /// trailing SW stripped, throwing if the status word is not 9000.
  Future<Uint8List> _apdu(
    int cla,
    int ins,
    int p1,
    int p2, [
    Uint8List? data,
    int? le,
  ]) async {
    final ch = await _open();
    final resp = await ch.transmit(cla, ins, p1, p2, data, le);
    if (resp.length < 2) {
      throw const SourceSimUnavailable('short APDU response');
    }
    final sw1 = resp[resp.length - 2];
    final sw2 = resp[resp.length - 1];
    if (sw1 != 0x90 || sw2 != 0x00) {
      final sw = ((sw1 << 8) | sw2).toRadixString(16).padLeft(4, '0');
      throw SourceSimUnavailable('APDU status $sw');
    }
    return Uint8List.sublistView(resp, 0, resp.length - 2);
  }

  Future<void> _selectFid(int id) async {
    await _apdu(
      UsimFiles.selectCla,
      UsimFiles.selectIns,
      UsimFiles.selectByIdP1,
      UsimFiles.selectP2,
      UsimFiles.fid(id),
    );
  }

  Future<Uint8List> _discoverUsimAid() async {
    await _selectFid(UsimFiles.masterFile);
    final fcp = await _apdu(
      UsimFiles.selectCla,
      UsimFiles.selectIns,
      UsimFiles.selectByIdP1,
      UsimFiles.selectP2,
      UsimFiles.fid(UsimFiles.efDir),
    );
    final info = FileInfo.parse(fcp);
    if (!info.isLinearFixed) {
      throw const SourceSimUnavailable('EF_DIR is not linear fixed');
    }
    for (var record = 1; record <= info.recordCount; record++) {
      final data = await _apdu(
        UsimFiles.readRecordCla,
        UsimFiles.readRecordIns,
        record,
        UsimFiles.readRecordP2,
        null,
        info.recordSize,
      );
      final app = SimApplication.parseRecord(data);
      if (app == null) continue;
      if (app.label.toUpperCase() == 'USIM' ||
          bytesStartsWith(app.aid, UsimFiles.usimAidPrefix)) {
        return app.aid;
      }
    }
    // Fall back to the well-known USIM AID prefix.
    return UsimFiles.usimAidPrefix;
  }

  Future<void> _selectUsim() async {
    _usimAid ??= await _discoverUsimAid();
    await _apdu(
      UsimFiles.selectCla,
      UsimFiles.selectIns,
      UsimFiles.selectByNameP1,
      UsimFiles.selectP2,
      _usimAid!,
    );
  }

  Future<String> _readIccid() async {
    await _selectFid(UsimFiles.masterFile);
    await _selectFid(UsimFiles.efIccid);
    final raw = await _apdu(
      UsimFiles.readBinaryCla,
      UsimFiles.readBinaryIns,
      0x00,
      0x00,
      null,
      UsimFiles.iccidLength,
    );
    return decodeSwappedBcd(raw, stripLeadingNine: true);
  }

  Future<String> _readImsi() async {
    await _selectFid(UsimFiles.efImsi);
    final raw = await _apdu(
      UsimFiles.readBinaryCla,
      UsimFiles.readBinaryIns,
      0x00,
      0x00,
      null,
      UsimFiles.imsiLength,
    );
    return Imsi.fromBytes(raw).toString();
  }

  Future<Uint8List> _readAdministrativeData() async {
    await _selectFid(UsimFiles.efAd);
    return _apdu(
      UsimFiles.readBinaryCla,
      UsimFiles.readBinaryIns,
      0x00,
      0x00,
      null,
      UsimFiles.adLength,
    );
  }

  Future<String> _readGid1() async {
    try {
      await _selectFid(UsimFiles.efGid1);
      final raw = await _apdu(
        UsimFiles.readBinaryCla,
        UsimFiles.readBinaryIns,
        0x00,
        0x00,
        null,
        0x00,
      );
      return groupIdentifierString(raw);
    } catch (e) {
      _log.fine('EF_GID1 unavailable: $e');
      return '';
    }
  }

  @override
  Future<Identity> identity() async {
    if (_cachedIdentity != null) return _cachedIdentity!;
    final iccid = await _readIccid();
    await _selectUsim();
    final imsi = await _readImsi();
    final ad = await _readAdministrativeData();
    final gid1 = await _readGid1();
    final identity = Identity.derive(
      iccid: iccid,
      imsi: imsi,
      gid1: gid1,
      administrativeData: ad,
    );
    _cachedIdentity = identity;
    return identity;
  }

  @override
  Future<AkaResponse> authenticateAka(AkaRequest request) async {
    await _selectUsim();
    final data = request.marshal();
    final resp = await _apdu(
      UsimFiles.authenticateCla,
      UsimFiles.authenticateIns,
      UsimFiles.authenticateP1,
      UsimFiles.authenticateP2,
      data,
    );
    return AkaResponse.fromBytes(resp);
  }

  /// Probes whether the active profile's USIM applet is reachable, returning
  /// the source [Identity] on success. Throws [SourceSimUnavailable] otherwise.
  Future<Identity> probe() async {
    try {
      return await identity();
    } on SourceSimUnavailable {
      rethrow;
    } catch (e) {
      throw SourceSimUnavailable(e.toString());
    }
    // The channel stays open for the subsequent transfer flow.
  }
}
