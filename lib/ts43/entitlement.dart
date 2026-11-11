import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'sim/identity.dart';
import 'enums.dart';
import 'errors.dart';
import 'types.dart';

const defaultEntitlementTimeout = Duration(seconds: 30);

/// One bundled carrier entitlement record. Ported from `entitlementRecord`.
class EntitlementRecord {
  final String mccMnc;
  final String? gid1;
  final String carrierName;
  final String channel;
  final String entitlementServer;
  final String app;
  final String appName;
  final String entitlementVersion;
  final String provisioningVersion;
  final String requestVersion;
  final int timeoutSeconds;
  final int transferTypePsim;
  final int transferTypeEsim;
  final int pollingIntervalMinutes;
  final int pollingTimeoutMinutes;
  final bool useHttpPost;
  final bool supportPsimToEsim;
  final bool supportEsimToEsim;
  final bool useSmdsDelayedDownload;
  final bool useTempTokenConversion;
  final bool setTargetTerminalFields;
  final bool restrictOldTerminalFields;

  EntitlementRecord({
    required this.mccMnc,
    required this.gid1,
    required this.carrierName,
    required this.channel,
    required this.entitlementServer,
    required this.app,
    required this.appName,
    required this.entitlementVersion,
    required this.provisioningVersion,
    required this.requestVersion,
    required this.timeoutSeconds,
    required this.transferTypePsim,
    required this.transferTypeEsim,
    required this.pollingIntervalMinutes,
    required this.pollingTimeoutMinutes,
    required this.useHttpPost,
    required this.supportPsimToEsim,
    required this.supportEsimToEsim,
    required this.useSmdsDelayedDownload,
    required this.useTempTokenConversion,
    required this.setTargetTerminalFields,
    required this.restrictOldTerminalFields,
  });

  factory EntitlementRecord.fromJson(Map<String, dynamic> j) {
    return EntitlementRecord(
      mccMnc: j['mccmnc'] as String? ?? '',
      gid1: j['gid1'] as String?,
      carrierName: j['carrierName'] as String? ?? '',
      channel: j['channel'] as String? ?? '',
      entitlementServer: j['entitlementServer'] as String? ?? '',
      app: j['app'] as String? ?? '',
      appName: j['appName'] as String? ?? '',
      entitlementVersion: j['entitlementVersion'] as String? ?? '',
      provisioningVersion: j['provisioningVersion'] as String? ?? '',
      requestVersion: j['requestVersion'] as String? ?? '',
      timeoutSeconds: (j['timeoutSeconds'] as num?)?.toInt() ?? 0,
      transferTypePsim: (j['transferTypePsim'] as num?)?.toInt() ?? 0,
      transferTypeEsim: (j['transferTypeEsim'] as num?)?.toInt() ?? 0,
      pollingIntervalMinutes:
          (j['acquireConfigurationPollingIntervalMinutes'] as num?)?.toInt() ??
          0,
      pollingTimeoutMinutes:
          (j['acquireConfigurationPollingTimeoutMinutes'] as num?)?.toInt() ??
          0,
      useHttpPost: j['useHttpPost'] as bool? ?? false,
      supportPsimToEsim: j['supportPsimToEsimTransfer'] as bool? ?? false,
      supportEsimToEsim: j['supportEsimToEsimTransfer'] as bool? ?? false,
      useSmdsDelayedDownload: j['useSmdsDelayedDownload'] as bool? ?? false,
      useTempTokenConversion: j['useTempTokenConversion'] as bool? ?? false,
      setTargetTerminalFields: j['setTargetTerminalFields'] as bool? ?? false,
      restrictOldTerminalFields:
          j['restrictOldTerminalFields'] as bool? ?? false,
    );
  }

  Entitlement toEntitlement(SimType sourceSimType, int transferType) {
    final e = Entitlement(
      server: entitlementServer,
      channel: normalizeChannel(EntitlementChannel(channel)),
      usePost: useHttpPost,
      sourceSimType: sourceSimType,
      transferType: transferType,
      useTempTokenConversion: useTempTokenConversion,
      setTargetTerminalFields: setTargetTerminalFields,
      restrictOldTerminalFields: restrictOldTerminalFields,
      useSmdsDelayedDownload: useSmdsDelayedDownload,
      pollInterval: Duration(minutes: pollingIntervalMinutes),
      pollTimeout: Duration(minutes: pollingTimeoutMinutes),
      app: app,
      appName: appName,
      provisioningVersion: provisioningVersion,
      requestVersion: requestVersion,
      version: entitlementVersion,
    );
    if (timeoutSeconds > 0) {
      e.timeout = Duration(seconds: timeoutSeconds);
    }
    return e;
  }

  Entitlement entitlement(SimType sourceSimType) {
    switch (sourceSimType) {
      case SimType.esim:
        if (!supportEsimToEsim) {
          throw EntitlementException(
            '$entitlementUnsupported for MCCMNC $mccMnc eSIM source',
          );
        }
        return toEntitlement(sourceSimType, transferTypeEsim);
      case SimType.psim:
        if (!supportPsimToEsim) {
          throw EntitlementException(
            '$entitlementUnsupported for MCCMNC $mccMnc pSIM source',
          );
        }
        return toEntitlement(sourceSimType, transferTypePsim);
    }
  }
}

EntitlementChannel normalizeChannel(EntitlementChannel channel) {
  if (channel.value.isEmpty) return EntitlementChannel.google;
  return channel;
}

List<EntitlementRecord> parseEntitlementRecords(String jsonText) {
  final list = jsonDecode(jsonText) as List;
  return list
      .map((e) => EntitlementRecord.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Discovers a carrier entitlement config for the requested channel (or auto
/// google→samsung). Ported from `DiscoverEntitlementForChannel`.
Entitlement discoverEntitlementForChannel(
  List<EntitlementRecord> records,
  Identity identity,
  SimType sourceSimType,
  EntitlementChannel channel,
) {
  if (identity.mcc.isEmpty || identity.mnc.isEmpty) {
    throw const EntitlementException('source MCC/MNC is required');
  }
  if (channel.value.isEmpty) {
    return _discoverAuto(records, identity, sourceSimType);
  }
  final record = _selectRecord(
    records,
    identity.mccMnc,
    identity.gid1,
    normalizeChannel(channel),
  );
  return record.entitlement(sourceSimType);
}

Entitlement _discoverAuto(
  List<EntitlementRecord> records,
  Identity identity,
  SimType sourceSimType,
) {
  EntitlementException? unsupported;
  for (final channel in [
    EntitlementChannel.google,
    EntitlementChannel.samsung,
  ]) {
    EntitlementRecord record;
    try {
      record = _selectRecord(records, identity.mccMnc, identity.gid1, channel);
    } on EntitlementException catch (e) {
      if (e.message.startsWith(entitlementNotFound)) continue;
      rethrow;
    }
    try {
      return record.entitlement(sourceSimType);
    } on EntitlementException catch (e) {
      if (e.message.startsWith(entitlementUnsupported)) {
        unsupported ??= e;
        continue;
      }
      rethrow;
    }
  }
  if (unsupported != null) throw unsupported;
  throw EntitlementException(
    '$entitlementNotFound for MCCMNC ${identity.mccMnc}',
  );
}

EntitlementRecord _selectRecord(
  List<EntitlementRecord> records,
  String mccMnc,
  String gid1,
  EntitlementChannel channel,
) {
  final fallback = <EntitlementRecord>[];
  final gidMatches = <EntitlementRecord>[];
  for (final record in records) {
    if (record.mccMnc != mccMnc) continue;
    if (normalizeChannel(EntitlementChannel(record.channel)) != channel) {
      continue;
    }
    if (record.gid1 == null) {
      fallback.add(record);
      continue;
    }
    if (gid1.isNotEmpty && record.gid1!.toLowerCase() == gid1.toLowerCase()) {
      gidMatches.add(record);
    }
  }
  if (gidMatches.length == 1) return gidMatches.first;
  if (gidMatches.length > 1) {
    throw EntitlementException(
      '$entitlementAmbiguous for MCCMNC $mccMnc GID1 $gid1',
    );
  }
  if (fallback.length == 1) return fallback.first;
  if (fallback.length > 1) {
    throw EntitlementException('$entitlementAmbiguous for MCCMNC $mccMnc');
  }
  throw EntitlementException('$entitlementNotFound for MCCMNC $mccMnc');
}

/// Loads and caches the bundled entitlement database asset.
class Ts43EntitlementDb {
  static List<EntitlementRecord>? _cache;

  static Future<List<EntitlementRecord>> load() async {
    if (_cache != null) return _cache!;
    final text = await rootBundle.loadString('assets/ts43/entitlement.json');
    _cache = parseEntitlementRecords(text);
    return _cache!;
  }

  /// Returns true if the database contains any record for [mccMnc].
  static Future<bool> hasCarrier(String mccMnc) async {
    final records = await load();
    return records.any((r) => r.mccMnc == mccMnc);
  }

  static Future<Entitlement> discover(
    Identity identity,
    SimType sourceSimType, {
    EntitlementChannel channel = EntitlementChannel.none,
  }) async {
    final records = await load();
    return discoverEntitlementForChannel(
      records,
      identity,
      sourceSimType,
      channel,
    );
  }
}
