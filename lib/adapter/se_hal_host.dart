import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Where the app reaches the Secure Element HAL, through the process Shizuku
/// runs.
///
/// The HAL is a Binder service only `shell` may call, so the calls are made by
/// the same user service the QRTR reader uses, over the same channel. Whether
/// Shizuku is there and allowed is asked through `QrtrHost`.
class SeHalHost {
  static const MethodChannel _channel = MethodChannel('nlpa2/qrtr');

  // The native service can outlive lost permission and adapter instances.
  static final _unconfirmedTeardowns = <int>{};

  static void markUnconfirmedTeardown(int slot) {
    if (slot < 1 || slot > 2) throw ArgumentError('Invalid SIM slot');
    _unconfirmedTeardowns.add(slot);
  }

  static Future<void> _abandonUnconfirmedSessions() async {
    for (final slot in _unconfirmedTeardowns.toList()) {
      await _channel.invokeMethod<void>('halInvalidateSessions', {
        'slot': slot,
      });
      _unconfirmedTeardowns.remove(slot); // Keep it if invalidation fails.
    }
  }

  static Future<void> halUseBorrowed(int slot) async {
    await _abandonUnconfirmedSessions();
    await _channel.invokeMethod<void>('halUseBorrowed', {'slot': slot});
  }

  static Future<void> halOpenOwned(int slot) async {
    await _abandonUnconfirmedSessions();
    await _channel.invokeMethod<void>('halOpenOwned', {'slot': slot});
  }

  static Future<void> halCloseOwned(int slot) =>
      _channel.invokeMethod<void>('halCloseOwned', {'slot': slot});

  static Future<Uint8List> halAtr(int slot) async {
    await _abandonUnconfirmedSessions();
    return (await _channel.invokeMethod<Uint8List>('halAtr', {'slot': slot}))!;
  }

  static Future<Uint8List> halRead(int slot, Uint8List apdu) async =>
      (await _channel.invokeMethod<Uint8List>('halRead', {
        'slot': slot,
        'data': apdu,
      }))!;

  static Future<Uint8List> halSwitchProfile(
    int slot,
    Uint8List iccid,
    Uint8List eid,
    bool enable,
  ) async => (await _channel.invokeMethod<Uint8List>('halSwitchProfile', {
    'slot': slot,
    'iccid': iccid,
    'eid': eid,
    'enable': enable,
  }))!;

  static Future<Uint8List> halRenameProfile(
    int slot,
    Uint8List iccid,
    Uint8List eid,
    String nickname,
  ) async => (await _channel.invokeMethod<Uint8List>('halRenameProfile', {
    'slot': slot,
    'iccid': iccid,
    'eid': eid,
    'nickname': Uint8List.fromList(utf8.encode(nickname)),
  }))!;

  static Future<Uint8List> halDeleteProfile(
    int slot,
    Uint8List iccid,
    Uint8List eid,
  ) async => (await _channel.invokeMethod<Uint8List>('halDeleteProfile', {
    'slot': slot,
    'iccid': iccid,
    'eid': eid,
  }))!;

  static Future<Uint8List> halRemoveNotification(
    int slot,
    int sequence,
    Uint8List eid,
    Uint8List response,
  ) async => (await _channel.invokeMethod<Uint8List>('halRemoveNotification', {
    'slot': slot,
    'sequence': sequence,
    'eid': eid,
    'response': response,
  }))!;

  static Future<void> halBeginDownload(int slot) =>
      _channel.invokeMethod<void>('halBeginDownload', {'slot': slot});

  static Future<void> halEndDownload(int slot) =>
      _channel.invokeMethod<void>('halEndDownload', {'slot': slot});

  static Future<Uint8List> halDownload(
    int slot,
    Uint8List payload,
    List<int> segments,
  ) async => (await _channel.invokeMethod<Uint8List>('halDownload', {
    'slot': slot,
    'data': payload,
    'segments': Int32List.fromList(segments),
  }))!;
}
