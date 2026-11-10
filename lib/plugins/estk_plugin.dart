import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'plugin_base.dart';
import 'session_plugin.dart';
import '../models/euicc_profile.dart';
import '../models/asn1/rsp_definitions.g.dart';
import '../adapter/euicc_adapter.dart';
import '../utils/hex_utils.dart';
import '../theme/app_theme.dart';
import '../settings/app_settings.dart';
import 'package:logging/logging.dart';

class EstkDatabase {
  static final EstkDatabase _instance = EstkDatabase._internal();
  factory EstkDatabase() => _instance;
  EstkDatabase._internal();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    try {
      return _database = await (_opening ??= _initDatabase());
    } finally {
      _opening = null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'estk_plugin.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE estk_mappings (
            eid1 TEXT,
            aid1 TEXT,
            eid2 TEXT,
            aid2 TEXT,
            PRIMARY KEY (eid1, aid1)
          )
        ''');
        await db.execute('''
          CREATE TABLE estk_metadata (
            eid TEXT PRIMARY KEY,
            metadata TEXT,
            lastUpdated INTEGER
          )
        ''');
      },
    );
  }

  Future<void> saveMapping(
    String eid1,
    String aid1,
    String eid2,
    String aid2,
  ) async {
    final db = await database;
    await db.insert('estk_mappings', {
      'eid1': eid1,
      'aid1': aid1,
      'eid2': eid2,
      'aid2': aid2,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Symmetric mapping
    await db.insert('estk_mappings', {
      'eid1': eid2,
      'aid1': aid2,
      'eid2': eid1,
      'aid2': aid1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>?> getMapping(String eid, String aid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'estk_mappings',
      where: 'eid1 = ? AND aid1 = ?',
      whereArgs: [eid, aid],
    );
    if (maps.isEmpty) return null;
    return {
      'eid2': maps.first['eid2'] as String,
      'aid2': maps.first['aid2'] as String,
    };
  }

  Future<bool> hasAnyMapping(String eid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'estk_mappings',
      where: 'eid1 = ?',
      whereArgs: [eid],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<void> saveMetadata(String eid, Map<String, String> metadata) async {
    final db = await database;
    final jsonStr = metadata.entries
        .map((e) => "${e.key}:${e.value}")
        .join(";");
    await db.insert('estk_metadata', {
      'eid': eid,
      'metadata': jsonStr,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>?> getMetadata(String eid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'estk_metadata',
      where: 'eid = ?',
      whereArgs: [eid],
    );
    if (maps.isEmpty) return null;
    final metadataStr = maps.first['metadata'] as String;
    final parts = metadataStr.split(";");
    final result = <String, String>{};
    for (var part in parts) {
      final kv = part.split(":");
      if (kv.length == 2) result[kv[0]] = kv[1];
    }
    return result;
  }
}

class EstkPlugin extends ProfilePlugin implements SessionPlugin {
  static final Logger _log = Logger('EstkPlugin');

  @override
  String get id => 'estk_plugin';

  @override
  String get name => 'ESTKme';

  @override
  String? get aid => null;

  static const String atrSignature = "6573746B6D65";
  static const String aidChan1 = "A06573746B6D65FFFF4953442D522030";
  static const String aidChan2 = "A06573746B6D65FFFF4953442D522031";
  static const String aidMgt = "A06573746B6D65FFFFFFFFFFFF6D6774";

  final EstkDatabase _db = EstkDatabase();
  final Set<String> _processedEids = {};

  static Future<bool> isEstkMaxDevice(String eid, String? aid) async {
    final normalizedEid = eid.toUpperCase();
    final normalizedAid = aid?.toUpperCase();

    // If we are currently on the second slot (AID ending in 31), it is definitely an ESTK Max device
    if (normalizedAid == aidChan2) return true;

    // Check AppSettings first (cached for this device)
    if (AppSettings().isEstkMax(normalizedEid)) return true;

    // Otherwise, check if this EID is already known to be a dual-slot device in our database
    return await EstkDatabase().hasAnyMapping(normalizedEid);
  }

  @override
  Future<Map<String, dynamic>?> probeReaderCapabilities(
    String? eid,
    String? aid,
  ) async {
    if (eid != null && await isEstkMaxDevice(eid, aid)) {
      return {'isEstkMax': true};
    }
    return null;
  }

  // Cache preferred AID per ATR
  final Map<String, String> _preferredAids = {};

  @override
  List<String> getExtraAids(String atr) {
    if (atr.toUpperCase().contains(atrSignature.toUpperCase())) {
      final preferred = _preferredAids[atr];
      if (preferred == aidChan1) {
        return [aidChan1, aidChan2];
      }
      return [
        aidChan2,
        aidChan1,
      ]; // Default to Chan2 then Chan1? Or whatever order.
    }
    return [];
  }

  @override
  Future<bool> isInterested(Adapter adapter, String? eid) async {
    final atr = adapter.lastAtr?.toUpperCase() ?? "";
    return atr.contains(atrSignature.toUpperCase());
  }

  @override
  bool isMatch(EuiccProfile profile) => false;

  @override
  List<PluginAction> getEidActions(
    BuildContext context,
    String? eid, {
    String? aid,
  }) {
    if (eid == null) return [];
    final currentAid = aid?.toUpperCase();
    if (currentAid != aidChan1 && currentAid != aidChan2) return [];

    return [
      PluginAction(
        label: "ESTK Info",
        icon: Icons.developer_board,
        onTap: () => _showEstkInfo(context, eid),
      ),
    ];
  }

  Future<void> _showEstkInfo(BuildContext context, String eid) async {
    final normalizedEid = eid.toUpperCase();
    final metadata = await _db.getMetadata(normalizedEid);

    // Check for dual-slot mapping
    String? currentAid;
    String? otherEid;

    // Try to find the mapping for this EID
    final mapping1 = await _db.getMapping(normalizedEid, aidChan1);
    final mapping2 = await _db.getMapping(normalizedEid, aidChan2);

    if (mapping1 != null) {
      currentAid = aidChan1;
      otherEid = mapping1['eid2'];
    } else if (mapping2 != null) {
      currentAid = aidChan2;
      otherEid = mapping2['eid2'];
    }

    if (!context.mounted) return;

    final theme = Theme.of(context);

    // Format metadata for display
    final displayData = <String, String>{};
    if (metadata != null) {
      if (metadata.containsKey('estk.me.2025.serial')) {
        displayData['Serial Number'] = metadata['estk.me.2025.serial']!;
      }
      if (metadata.containsKey('estk.me.2025.bootloader')) {
        displayData['Bootloader'] = metadata['estk.me.2025.bootloader']!;
      }
      if (metadata.containsKey('estk.me.2025.fw')) {
        displayData['Firmware'] = metadata['estk.me.2025.fw']!;
      }
      if (metadata.containsKey('estk.me.2025.sku')) {
        displayData['SKU'] = metadata['estk.me.2025.sku']!;
      }
      if (metadata.containsKey('estk.me.2025.lang')) {
        displayData['Language'] = metadata['estk.me.2025.lang']!;
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.developer_board,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "ESTK Device Info",
                        style: AppTheme.defaultFont(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // EID Section(s)
                if (otherEid != null) ...[
                  // Dual-slot device
                  _buildEidCard(
                    context,
                    label: "SE0 (Slot 1)",
                    eid: currentAid == aidChan1 ? eid : otherEid,
                    isActive: currentAid == aidChan1,
                  ),
                  const SizedBox(height: 12),
                  _buildEidCard(
                    context,
                    label: "SE1 (Slot 2)",
                    eid: currentAid == aidChan2 ? eid : otherEid,
                    isActive: currentAid == aidChan2,
                  ),
                ] else ...[
                  // Single slot device
                  _buildEidCard(
                    context,
                    label: "EID",
                    eid: eid,
                    isActive: true,
                  ),
                ],

                if (displayData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: displayData.entries.map(
                        (e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${e.key}:",
                                  style: AppTheme.defaultFont(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceSubtle(context),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  e.value,
                                  style: AppTheme.defaultFont(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList()..removeLast(), // Remove padding from last item
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppTheme.onSurfaceSubtle(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "No ESTK metadata available for this card.",
                            style: AppTheme.defaultFont(
                              fontSize: 13,
                              color: AppTheme.onSurfaceSubtle(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      "Close",
                      style: AppTheme.defaultFont(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEidCard(
    BuildContext context, {
    required String label,
    required String eid,
    required bool isActive,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: eid));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : AppTheme.surfaceSubtle(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: AppTheme.defaultFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceSubtle(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "ACTIVE",
                            style: AppTheme.defaultFont(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eid,
                    style: AppTheme.mono(
                      TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppTheme.onSurfaceSubtle(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> beforeCommand(
    String command,
    Map<String, dynamic> params,
    Channel channel,
  ) async {}

  @override
  Future<void> afterCommand(
    String command,
    Map<String, dynamic> params,
    dynamic result,
    Channel channel,
  ) async {
    if (command == 'getEid' && result is String) {
      final eid = result.toUpperCase();
      final currentAid = (channel.aid ?? "").toUpperCase();

      _log.info("afterCommand: getEid completed, AID=$currentAid, EID=$eid");

      if (currentAid == aidChan1 || currentAid == aidChan2) {
        _log.info("Opened ESTK channel: $currentAid for EID: $eid");

        // Avoid repeated processing of the same EID in this app session
        if (_processedEids.contains(eid)) {
          return;
        }

        // Check if mapping already exists in database
        final existingMapping = await _db.getMapping(eid, currentAid);

        if (existingMapping != null) {
          _processedEids.add(eid);
          _log.info(
            "ESTK mapping already exists in database for $eid ($currentAid)",
          );
          // Check if metadata exists
          final metadata = await _db.getMetadata(eid);
          if (metadata == null) {
            await _readMetadata(channel, eid);
          }
          return;
        }

        // No mapping exists, attempt dual-slot detection
        // Mark as processed early to avoid concurrent execution for the SAME reader operation
        // but we'll remove it if it fails or needs retry.
        _processedEids.add(eid);

        _log.info("No ESTK mapping found, attempting dual-slot detection...");

        try {
          // Try to read metadata from MGT channel
          await _readMetadata(channel, eid);

          // Check for dual slot mapping
          await _checkDualSlot(channel, eid, currentAid);
        } catch (e) {
          _log.warning("ESTK detection sequence failed for $eid: $e");
          _processedEids.remove(eid); // Allow retry
        }
      } else {
        _log.info(
          "Not an ESTK channel (AID=$currentAid), skipping ESTK detection",
        );
      }
    }
  }

  /// Helper to read a value from MGT channel, handling 6C (wrong length) responses
  Future<String> _readMgtValue(Channel channel, int cmdData) async {
    var merged = "";

    while (true) {
      final resp = await channel.transmit(
        0x00,
        0x00,
        cmdData,
        0x00,
        Uint8List.fromList([]),
      );

      if (resp.length < 2) break;

      final sw1 = resp[resp.length - 2];
      final data = resp.sublist(0, resp.length - 2);

      merged += HexUtils.bytesToHex(data);
      if (sw1 != 0x6c) break;
    }

    return merged;
  }

  Future<void> _readMetadata(Channel channel, String eid) async {
    try {
      if (channel.adapter is! BaseAdapter) return;
      final adapter = channel.adapter as BaseAdapter;
      final mgtChannel = await adapter.openLogicalChannel(
        aids: [aidMgt],
        skipCleanup: true,
      );
      try {
        final metadata = <String, String>{};

        // Read serial number
        _log.info("Reading ESTK serial number...");
        final serialHex = await _readMgtValue(mgtChannel, 0);
        _log.info("Serial response: $serialHex");

        if (serialHex.isNotEmpty) {
          final serialBytes = HexUtils.hexToBytes(serialHex);
          final serial = String.fromCharCodes(serialBytes.where((b) => b != 0));

          if (serial.isNotEmpty) {
            metadata['estk.me.2025.serial'] = serial;

            // Read bootloader version
            _log.info("Reading ESTK bootloader...");
            final blHex = await _readMgtValue(mgtChannel, 1);
            if (blHex.isNotEmpty) {
              final blBytes = HexUtils.hexToBytes(blHex);
              metadata['estk.me.2025.bootloader'] = String.fromCharCodes(
                blBytes.where((b) => b != 0),
              );
            }

            // Read firmware version
            _log.info("Reading ESTK firmware...");
            final fwHex = await _readMgtValue(mgtChannel, 2);
            if (fwHex.isNotEmpty) {
              final fwBytes = HexUtils.hexToBytes(fwHex);
              metadata['estk.me.2025.fw'] = String.fromCharCodes(
                fwBytes.where((b) => b != 0),
              );
            }

            // Read SKU
            _log.info("Reading ESTK SKU...");
            final skuHex = await _readMgtValue(mgtChannel, 3);
            if (skuHex.isNotEmpty) {
              final skuBytes = HexUtils.hexToBytes(skuHex);
              metadata['estk.me.2025.sku'] = String.fromCharCodes(
                skuBytes.where((b) => b != 0),
              );
            }

            // Read language
            _log.info("Reading ESTK language...");
            final langHex = await _readMgtValue(mgtChannel, 4);
            if (langHex.isNotEmpty) {
              metadata['estk.me.2025.lang'] = langHex;
            }
          } else {
            metadata['estk.me.2025.sku'] = "ESTKme (pre-2025)";
          }
        } else {
          metadata['estk.me.2025.sku'] = "ESTKme (pre-2025)";
        }

        if (metadata.isNotEmpty) {
          await _db.saveMetadata(eid, metadata);
          _log.info("ESTK metadata saved for $eid: $metadata");
        }
      } finally {
        await mgtChannel.close();
      }
    } catch (e) {
      _log.warning("Failed to read ESTK metadata: $e");
    }
  }

  Future<void> _checkDualSlot(Channel channel, String eid1, String aid1) async {
    final otherAid = aid1 == aidChan1 ? aidChan2 : aidChan1;
    try {
      if (channel.adapter is! BaseAdapter) return;
      final adapter = channel.adapter as BaseAdapter;

      _log.info(
        "Opening other ESTK channel ($otherAid) to detect dual-slot...",
      );
      final otherChannel = await adapter.openLogicalChannel(
        aids: [otherAid],
        skipCleanup: true,
      );
      try {
        // Send GetEID command on the other channel using proper ASN.1 encoding
        _log.info("Sending GetEID command on second channel...");

        final request = GetEuiccDataRequest(
          tagList: Uint8List.fromList([0x5A]),
        );
        final requestData = request.encode();

        final eid2Resp = await otherChannel.transmit(
          0x80,
          0xE2,
          0x91,
          0x00,
          requestData,
        );

        _log.info("GetEID response: ${HexUtils.bytesToHex(eid2Resp)}");

        if (eid2Resp.length > 2) {
          final sw1 = eid2Resp[eid2Resp.length - 2];
          final sw2 = eid2Resp[eid2Resp.length - 1];

          _log.info(
            "Status words: SW1=${sw1.toRadixString(16)}, SW2=${sw2.toRadixString(16)}",
          );

          if (sw1 == 0x90 && sw2 == 0x00) {
            // Parse ASN.1 response to extract EID
            final data = eid2Resp.sublist(0, eid2Resp.length - 2);
            _log.info("ASN.1 data to parse: ${HexUtils.bytesToHex(data)}");

            try {
              final response = GetEuiccDataResponse.decode(data);
              if (response.eidValue != null) {
                final eid2Str = HexUtils.bytesToHex(response.eidValue!);
                _log.info("Extracted EID from second channel: $eid2Str");

                if (eid2Str != eid1) {
                  _log.info(
                    "Dual slot ESTK detected: $eid1 ($aid1) <-> $eid2Str ($otherAid)",
                  );
                  await _db.saveMapping(eid1, aid1, eid2Str, otherAid);
                  // Mark both as Estk Max in settings for fast lookup
                  AppSettings().markAsEstkMax(eid1);
                  AppSettings().markAsEstkMax(eid2Str);
                } else {
                  _log.info(
                    "Same EID on both channels, not a dual-slot device",
                  );
                }
              } else {
                _log.warning("EID value not present in ASN.1 response");
              }
            } catch (e) {
              _log.warning("Failed to decode ASN.1 response: $e");
            }
          } else if (sw1 == 0x61) {
            _log.info("Got 61xx, need to send GET RESPONSE");
            // Need to send GET RESPONSE
            final getRespCmd = await otherChannel.transmit(
              0x80,
              0xC0,
              0x00,
              0x00,
              null,
              sw2,
            );
            _log.info("GET RESPONSE: ${HexUtils.bytesToHex(getRespCmd)}");

            if (getRespCmd.length > 2) {
              final data = getRespCmd.sublist(0, getRespCmd.length - 2);
              _log.info(
                "ASN.1 data from GET RESPONSE: ${HexUtils.bytesToHex(data)}",
              );

              try {
                final response = GetEuiccDataResponse.decode(data);
                if (response.eidValue != null) {
                  final eid2Str = HexUtils.bytesToHex(response.eidValue!);
                  _log.info("Extracted EID from GET RESPONSE: $eid2Str");

                  if (eid2Str != eid1) {
                    _log.info(
                      "Dual slot ESTK detected: $eid1 ($aid1) <-> $eid2Str ($otherAid)",
                    );
                    await _db.saveMapping(eid1, aid1, eid2Str, otherAid);
                  } else {
                    _log.info(
                      "Same EID on both channels, not a dual-slot device",
                    );
                  }
                }
              } catch (e) {
                _log.warning("Failed to decode GET RESPONSE ASN.1: $e");
              }
            }
          }
        }
      } finally {
        await otherChannel.close();
      }
    } catch (e) {
      if (e is PlatformException &&
          (e.code == 'CHANNEL_NOT_FOUND' || e.code == 'CHANNEL_FAILED')) {
        _log.info(
          "Secondary ESTK channel not available (likely single-slot device): $e",
        );
      } else {
        _log.warning("Second ESTK channel detection failed: $e");
      }
    }
  }

  @override
  Future<List<AdapterMode>> getAvailableModes(
    Adapter adapter,
    Reader reader,
  ) async {
    final eid = reader.eid;
    final aid = reader.aid;
    if (eid == null || aid == null) return [];

    final mapping = await _db.getMapping(eid, aid.toUpperCase());
    if (mapping != null) {
      final otherAid = mapping['aid2'];
      return [
        AdapterMode(
          id: 'estk_${aid.toUpperCase()}',
          label: 'Slot ${aid.toUpperCase().endsWith("30") ? "1" : "2"}',
          value: aid, // Current
        ),
        AdapterMode(
          id: 'estk_$otherAid',
          label: 'Switch to Slot ${otherAid!.endsWith("30") ? "1" : "2"}',
          value: otherAid,
        ),
      ];
    }
    return [];
  }

  @override
  Future<void> switchMode(
    Adapter adapter,
    Reader reader,
    AdapterMode mode,
  ) async {
    if (!mode.id.startsWith('estk_')) return;

    final targetAid = mode.value as String;
    final atr = adapter.lastAtr;
    if (atr != null) {
      _preferredAids[atr] = targetAid;
      _log.info("Switching ESTK preference to AID: $targetAid");
    }
  }
}
