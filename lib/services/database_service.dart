// ignore_for_file: unused_element
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'db_init_native.dart' if (dart.library.js_interop) 'db_init_web.dart';
import 'database_transfer_service.dart';
import '../utils/platform_adapter.dart';
import 'package:logging/logging.dart';

class NotificationRecord {
  final String eid;
  final String iccid;
  final int seqNumber;
  final String content; // Base64 encoded pending notification
  final int timestamp;
  final int status; // 0: Pending, 1: Sent, 2: Failed
  final int? responseCode;
  final String? responseContent;
  final String? notificationServer; // RSP server address
  final String? notificationType; // install, delete, enable, disable
  final int deletePending; // 0: false, 1: true

  NotificationRecord({
    required this.eid,
    required this.iccid,
    required this.seqNumber,
    required this.content,
    required this.timestamp,
    required this.status,
    this.responseCode,
    this.responseContent,
    this.notificationServer,
    this.notificationType,
    this.deletePending = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'eid': eid,
      'iccid': iccid,
      'seqNumber': seqNumber,
      'content': content,
      'timestamp': timestamp,
      'status': status,
      'responseCode': responseCode,
      'responseContent': responseContent,
      'notificationServer': notificationServer,
      'notificationType': notificationType,
      'deletePending': deletePending,
    };
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  @visibleForTesting
  DatabaseService.withDatabase(Database database) : _database = database;

  Database? _database;
  final Map<String, int?> _profileSizeCache = {};
  static final Logger _log = Logger('DatabaseService');

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final factory = await initDb();

    String path;
    if (kIsWeb) {
      path = 'nekokolpa2.db';
    } else {
      // On Windows, use a user-writable directory instead of Program Files
      if (PlatformX.isWindows) {
        // Use %LOCALAPPDATA%\NekokoLPA2\databases\ for user data
        final localAppData = PlatformX.getEnv('LOCALAPPDATA');
        if (localAppData != null && localAppData.isNotEmpty) {
          final dbDir = join(localAppData, 'NekokoLPA2', 'databases');
          // Ensure directory exists
          PlatformX.ensureDirectory(dbDir);
          path = join(dbDir, 'nekokolpa2.db');
        } else {
          path = join(
            await (factory?.getDatabasesPath() ?? getDatabasesPath()),
            'nekokolpa2.db',
          );
        }
      } else {
        path = join(
          await (factory?.getDatabasesPath() ?? getDatabasesPath()),
          'nekokolpa2.db',
        );
      }
    }

    if (kDebugMode) {
      _log.fine('Opening database at path: $path (kIsWeb: $kIsWeb)');
      _log.fine('Using databaseFactory: ${factory ?? "Default"}');
    }

    try {
      final db = await (factory ?? databaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 18,
          onCreate: (db, version) async {
            if (kDebugMode) _log.fine('Creating database tables...');
            await db.execute('''
            CREATE TABLE notifications (
              eid TEXT,
              iccid TEXT,
              seqNumber INTEGER,
              content TEXT,
              timestamp INTEGER,
              status INTEGER,
              responseCode INTEGER,
              responseContent TEXT,
              notificationServer TEXT,
              notificationType TEXT,
              deletePending INTEGER DEFAULT 0,
              PRIMARY KEY (eid, seqNumber, iccid)
            )
          ''');
            await createNotificationDeliveryReceipts(db);
            await db.execute('''
            CREATE TABLE profile_storage (
              eid TEXT,
              iccid TEXT,
              spaceConsumed INTEGER,
              version INTEGER,
              info2Before TEXT,
              info2After TEXT,
              bppLength INTEGER,
              PRIMARY KEY (eid, iccid)
            )
          ''');
            await db.execute('''
            CREATE TABLE profile_metadata (
              iccid TEXT PRIMARY KEY,
              nickname TEXT,
              name TEXT,
              providerName TEXT,
              mcc TEXT,
              mnc TEXT,
              enabled INTEGER,
              profileClass INTEGER,
              profileSize INTEGER,
              gid1 TEXT,
              gid2 TEXT,
              tags TEXT,
              lastSeen INTEGER,
              eid TEXT,
              customIcon TEXT
            )
          ''');
            await db.execute('''
            CREATE TABLE profile_msisdn (
              iccid TEXT PRIMARY KEY,
              msisdn TEXT,
              lastUpdated INTEGER
            )
          ''');
            await db.execute('''
            CREATE TABLE operator_icons (
              mcc TEXT,
              mnc TEXT,
              gid1 TEXT,
              gid2 TEXT,
              image TEXT,
              lastUpdated INTEGER,
              PRIMARY KEY (mcc, mnc, gid1, gid2)
            )
          ''');
            await db.execute('''
            CREATE TABLE card_status_cache (
              iccid TEXT PRIMARY KEY,
              data TEXT,
              lastUpdated INTEGER,
              expiry INTEGER
            )
          ''');
            await db.execute('''
            CREATE TABLE remote_servers (
              url TEXT PRIMARY KEY,
              lastConnected INTEGER
            )
          ''');
            await db.execute('''
            CREATE TABLE scheduled_notifications (
              text TEXT,
              scheduledDate INTEGER,
              iccid TEXT,
              lastUpdated INTEGER,
              eid TEXT,
              PRIMARY KEY (text, scheduledDate)
            )
          ''');
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            if (kDebugMode) {
              _log.info(
                'Upgrading database from $oldVersion to $newVersion...',
              );
            }

            if (oldVersion < 8) {}
            if (oldVersion < 9) {
              await db.execute('''
              CREATE TABLE IF NOT EXISTS operator_icons (
                mcc TEXT,
                mnc TEXT,
                gid1 TEXT,
                gid2 TEXT,
                image TEXT,
                lastUpdated INTEGER,
                PRIMARY KEY (mcc, mnc, gid1, gid2)
              )
            ''');
            }
            if (oldVersion < 10) {
              try {
                await db.execute(
                  'ALTER TABLE profile_metadata ADD COLUMN gid1 TEXT',
                );
                await db.execute(
                  'ALTER TABLE profile_metadata ADD COLUMN gid2 TEXT',
                );
              } catch (e) {
                if (kDebugMode) _log.warning('Error upgrading to v10: $e');
              }
            }
            if (oldVersion < 11) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v11: Creating card_status_cache table...',
                );
              }
              await db.execute('''
              CREATE TABLE IF NOT EXISTS card_status_cache (
                iccid TEXT PRIMARY KEY,
                data TEXT,
                lastUpdated INTEGER,
                expiry INTEGER
              )
            ''');
            }
            if (oldVersion < 12) {
              if (kDebugMode) {
                _log.info('Upgrading to v12: Creating remote_servers table...');
              }
              await db.execute('''
              CREATE TABLE IF NOT EXISTS remote_servers (
                url TEXT PRIMARY KEY,
                lastConnected INTEGER
              )
            ''');
            }
            if (oldVersion < 13) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v13: Adding tags column to profile_metadata...',
                );
              }
              try {
                await db.execute(
                  'ALTER TABLE profile_metadata ADD COLUMN tags TEXT',
                );
              } catch (e) {
                if (kDebugMode) _log.warning('Error upgrading to v13: $e');
              }
            }
            if (oldVersion < 14) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v14: Creating scheduled_notifications table...',
                );
              }
              await db.execute('''
              CREATE TABLE IF NOT EXISTS scheduled_notifications (
                text TEXT,
                scheduledDate INTEGER,
                iccid TEXT,
                lastUpdated INTEGER,
                PRIMARY KEY (text, scheduledDate)
              )
            ''');
            }
            if (oldVersion < 15) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v15: Adding eid column to profile_metadata...',
                );
              }
              try {
                await db.execute(
                  'ALTER TABLE profile_metadata ADD COLUMN eid TEXT',
                );
              } catch (e) {
                if (kDebugMode) _log.warning('Error upgrading to v15: $e');
              }
            }
            if (oldVersion < 16) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v16: Adding eid column to scheduled_notifications...',
                );
              }
              try {
                await db.execute(
                  'ALTER TABLE scheduled_notifications ADD COLUMN eid TEXT',
                );
              } catch (e) {
                if (kDebugMode) _log.warning('Error upgrading to v16: $e');
              }
            }
            if (oldVersion < 17) {
              if (kDebugMode) {
                _log.info(
                  'Upgrading to v17: Adding customIcon column to profile_metadata...',
                );
              }
              try {
                await db.execute(
                  'ALTER TABLE profile_metadata ADD COLUMN customIcon TEXT',
                );
              } catch (e) {
                if (kDebugMode) _log.warning('Error upgrading to v17: $e');
              }
            }
            if (oldVersion < 18) await createNotificationDeliveryReceipts(db);
          },
        ),
      );
      if (kDebugMode) _log.info('Database opened successfully');
      return db;
    } catch (e) {
      if (kDebugMode) _log.severe('Error opening database: $e');
      rethrow;
    }
  }

  /// A minimal receipt survives deletion of visible history. The payload itself
  /// remains deletable; its hash distinguishes a reused sequence from a resend.
  static Future<void> createNotificationDeliveryReceipts(
    DatabaseExecutor db,
  ) async {
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS notification_delivery_receipts (
      eid TEXT COLLATE NOCASE,
      seqNumber INTEGER,
      iccid TEXT COLLATE NOCASE,
      contentHash TEXT NOT NULL,
      PRIMARY KEY (eid, seqNumber, iccid)
    )''',
    );
    final sent = await db.query(
      'notifications',
      where: 'status = 1',
      orderBy: 'timestamp ASC',
    );
    for (final row in sent) {
      await db.insert(
        'notification_delivery_receipts',
        {
          'eid': row['eid'],
          'seqNumber': row['seqNumber'],
          'iccid': row['iccid'],
          'contentHash': _notificationHash(row['content'] as String),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static String _notificationHash(String content) =>
      sha256.convert(utf8.encode(content)).toString();

  static Future<void> _saveDeliveryReceipt(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    await db.insert(
      'notification_delivery_receipts',
      {
        'eid': row['eid'],
        'seqNumber': row['seqNumber'],
        'iccid': row['iccid'],
        'contentHash': _notificationHash(row['content'] as String),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveNotification(NotificationRecord record) async {
    final db = await database;
    await db.transaction((tx) async {
      await tx.insert(
        'notifications',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (record.status == 1) await _saveDeliveryReceipt(tx, record.toMap());
    });
  }

  Future<void> updateNotificationStatus(
    String eid,
    int seqNumber,
    String iccid,
    int status, {
    int? responseCode,
    String? responseContent,
  }) async {
    final db = await database;
    await db.transaction((tx) async {
      final values = <String, Object?>{'status': status};
      if (responseCode != null) values['responseCode'] = responseCode;
      if (responseContent != null) values['responseContent'] = responseContent;
      const where =
          'eid = ? COLLATE NOCASE AND seqNumber = ? AND iccid = ? COLLATE NOCASE';
      final args = [eid, seqNumber, iccid];
      await tx.update('notifications', values, where: where, whereArgs: args);
      if (status == 1) {
        for (final row in await tx.query(
          'notifications',
          where: where,
          whereArgs: args,
        )) {
          await _saveDeliveryReceipt(tx, row);
        }
      }
    });
  }

  Future<NotificationRecord?> getNotification(
    String eid,
    int seqNumber,
    String iccid,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where:
          'eid = ? COLLATE NOCASE AND seqNumber = ? AND iccid = ? COLLATE NOCASE',
      whereArgs: [eid, seqNumber, iccid],
    );
    if (maps.isEmpty) return null;
    return NotificationRecord(
      eid: maps.first['eid'],
      iccid: maps.first['iccid'],
      seqNumber: maps.first['seqNumber'],
      content: maps.first['content'],
      timestamp: maps.first['timestamp'],
      status: maps.first['status'],
      responseCode: maps.first['responseCode'],
      responseContent: maps.first['responseContent'],
      notificationServer: maps.first['notificationServer'],
      notificationType: maps.first['notificationType'],
      deletePending: maps.first['deletePending'] ?? 0,
    );
  }

  Future<List<NotificationRecord>> getNotifications(String eid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'eid = ? COLLATE NOCASE',
      whereArgs: [eid],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return NotificationRecord(
        eid: maps[i]['eid'],
        iccid: maps[i]['iccid'],
        seqNumber: maps[i]['seqNumber'],
        content: maps[i]['content'],
        timestamp: maps[i]['timestamp'],
        status: maps[i]['status'],
        responseCode: maps[i]['responseCode'],
        responseContent: maps[i]['responseContent'],
        notificationServer: maps[i]['notificationServer'],
        notificationType: maps[i]['notificationType'],
        deletePending: maps[i]['deletePending'] ?? 0,
      );
    });
  }

  Future<List<NotificationRecord>> getAllNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) {
      return NotificationRecord(
        eid: maps[i]['eid'],
        iccid: maps[i]['iccid'],
        seqNumber: maps[i]['seqNumber'],
        content: maps[i]['content'],
        timestamp: maps[i]['timestamp'],
        status: maps[i]['status'],
        responseCode: maps[i]['responseCode'],
        responseContent: maps[i]['responseContent'],
        notificationServer: maps[i]['notificationServer'],
        notificationType: maps[i]['notificationType'],
        deletePending: maps[i]['deletePending'] ?? 0,
      );
    });
  }

  Future<void> setDeletePending(
    String eid,
    int seqNumber,
    String iccid,
    bool isPending,
  ) async {
    final db = await database;
    await db.update(
      'notifications',
      {'deletePending': isPending ? 1 : 0},
      where:
          'eid = ? COLLATE NOCASE AND seqNumber = ? AND iccid = ? COLLATE NOCASE',
      whereArgs: [eid, seqNumber, iccid],
    );
  }

  Future<List<NotificationRecord>> getDeletePendingNotifications(
    String eid,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'eid = ? COLLATE NOCASE AND deletePending = 1',
      whereArgs: [eid],
    );
    return List.generate(maps.length, (i) {
      return NotificationRecord(
        eid: maps[i]['eid'],
        iccid: maps[i]['iccid'],
        seqNumber: maps[i]['seqNumber'],
        content: maps[i]['content'],
        timestamp: maps[i]['timestamp'],
        status: maps[i]['status'],
        responseCode: maps[i]['responseCode'],
        responseContent: maps[i]['responseContent'],
        notificationServer: maps[i]['notificationServer'],
        notificationType: maps[i]['notificationType'],
        deletePending: maps[i]['deletePending'] ?? 0,
      );
    });
  }

  Future<void> deleteNotification(
    String eid,
    int seqNumber,
    String iccid,
  ) async {
    final db = await database;
    await db.transaction((tx) async {
      const where =
          'eid = ? COLLATE NOCASE AND seqNumber = ? AND iccid = ? COLLATE NOCASE';
      final args = [eid, seqNumber, iccid];
      for (final row in await tx.query(
        'notifications',
        where: where,
        whereArgs: args,
      )) {
        if (row['status'] == 1) await _saveDeliveryReceipt(tx, row);
      }
      await tx.delete('notifications', where: where, whereArgs: args);
    });
  }

  Future<bool> isNotificationSent(
    String eid,
    int seqNumber,
    String iccid, {
    String? content,
  }) async {
    final db = await database;
    const where =
        'eid = ? COLLATE NOCASE AND seqNumber = ? AND iccid = ? COLLATE NOCASE';
    final args = [eid, seqNumber, iccid];
    final receipts = await db.query(
      'notification_delivery_receipts',
      where: where,
      whereArgs: args,
    );
    if (receipts.any(
      (r) => content == null || r['contentHash'] == _notificationHash(content),
    )) {
      return true;
    }
    // Older imported databases may contain sent history without ledger rows.
    final records = await db.query(
      'notifications',
      where: '$where AND status = 1',
      whereArgs: args,
    );
    return records.any((r) => content == null || r['content'] == content);
  }

  Future<Set<int>> getSentNotificationSequences(String eid) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT seqNumber FROM notifications WHERE eid = ? COLLATE NOCASE AND status = 1
      UNION SELECT seqNumber FROM notification_delivery_receipts WHERE eid = ? COLLATE NOCASE
    ''',
      [eid, eid],
    );
    return rows.map((r) => r['seqNumber'] as int).toSet();
  }

  Future<int> getPendingNotificationCount({String? eid}) async {
    final db = await database;
    if (eid != null) {
      return Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM notifications WHERE eid = ? COLLATE NOCASE AND status IN (0, 2)',
              [eid],
            ),
          ) ??
          0;
    }
    // Count only pending (0) and failed (2) notifications, excluding sent (1).
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM notifications WHERE status IN (0, 2)',
          ),
        ) ??
        0;
  }

  Future<void> saveMsisdn(String iccid, String msisdn) async {
    final db = await database;
    await db.insert('profile_msisdn', {
      'iccid': iccid,
      'msisdn': msisdn,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMsisdn(String iccid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_msisdn',
      where: 'iccid = ?',
      whereArgs: [iccid],
    );
    if (maps.isNotEmpty) {
      return maps.first['msisdn'] as String?;
    }
    return null;
  }

  Future<void> saveProfileSize(
    String eid,
    String iccid,
    int size, {
    String? info2Before,
    String? info2After,
    int? bppLength,
  }) async {
    final db = await database;
    await db.insert('profile_storage', {
      'eid': eid,
      'iccid': iccid,
      'spaceConsumed': size,
      'version': 2000,
      'info2Before': info2Before,
      'info2After': info2After,
      'bppLength': bppLength,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _profileSizeCache['${eid}_$iccid'] = size;
  }

  Future<int?> getProfileSize(String eid, String iccid) async {
    final cacheKey = '${eid}_$iccid';
    if (_profileSizeCache.containsKey(cacheKey)) {
      return _profileSizeCache[cacheKey];
    }

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profile_storage',
      where: 'eid = ? AND iccid = ?',
      whereArgs: [eid, iccid],
    );
    if (maps.isNotEmpty) {
      final size = maps.first['spaceConsumed'] as int?;
      _profileSizeCache[cacheKey] = size;
      return size;
    }
    _profileSizeCache[cacheKey] = null;
    return null;
  }

  bool hasCachedProfileSize(String eid, String iccid) =>
      _profileSizeCache.containsKey('${eid}_$iccid');

  Future<void> preloadProfileSizes(String eid, Iterable<String> iccids) async {
    final missingIccids = iccids
        .where((iccid) => !_profileSizeCache.containsKey('${eid}_$iccid'))
        .toSet()
        .toList();
    if (missingIccids.isEmpty) return;

    final db = await database;
    const chunkSize = 200;
    for (var start = 0; start < missingIccids.length; start += chunkSize) {
      final end = (start + chunkSize < missingIccids.length)
          ? start + chunkSize
          : missingIccids.length;
      final chunk = missingIccids.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final rows = await db.query(
        'profile_storage',
        columns: ['iccid', 'spaceConsumed'],
        where: 'eid = ? AND iccid IN ($placeholders)',
        whereArgs: [eid, ...chunk],
      );

      final found = <String>{};
      for (final row in rows) {
        final iccid = row['iccid'] as String?;
        if (iccid == null) continue;
        found.add(iccid);
        _profileSizeCache['${eid}_$iccid'] = row['spaceConsumed'] as int?;
      }

      for (final iccid in chunk) {
        if (!found.contains(iccid)) {
          _profileSizeCache['${eid}_$iccid'] = null;
        }
      }
    }
  }

  int? getProfileSizeSync(String eid, String iccid) {
    return _profileSizeCache['${eid}_$iccid'];
  }

  Future<String> getDatabasePath() async {
    final db = await database;
    return db.path;
  }

  // Operator Icons
  Future<void> saveOperatorIcon({
    required String mcc,
    required String mnc,
    String? gid1,
    String? gid2,
    required String image,
  }) async {
    try {
      final db = await database;
      await db.insert('operator_icons', {
        'mcc': mcc,
        'mnc': mnc,
        'gid1': gid1 ?? "",
        'gid2': gid2 ?? "",
        'image': image,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) _log.warning('Error saving operator icon: $e');
      rethrow;
    }
  }

  Future<String?> getOperatorIcon({
    required String mcc,
    required String mnc,
    String? gid1,
    String? gid2,
  }) async {
    try {
      final db = await database;
      // Try exact match first (with GIDs) - only if gid1/gid2 columns exist
      try {
        final List<Map<String, dynamic>> maps = await db.query(
          'operator_icons',
          where: 'mcc = ? AND mnc = ? AND gid1 = ? AND gid2 = ?',
          whereArgs: [mcc, mnc, gid1 ?? "", gid2 ?? ""],
        );
        if (maps.isNotEmpty) {
          return maps.first['image'] as String?;
        }
      } catch (e) {
        // If gid1/gid2 columns don't exist, fall back to MCC/MNC only query
        if (kDebugMode) {
          _log.fine('Query with gid1/gid2 failed, trying without: $e');
        }
      }

      // Fallback to MCC/MNC only query
      try {
        final List<Map<String, dynamic>> fallbackMaps = await db.query(
          'operator_icons',
          where: 'mcc = ? AND mnc = ?',
          whereArgs: [mcc, mnc],
        );
        if (fallbackMaps.isNotEmpty) {
          return fallbackMaps.first['image'] as String?;
        }
      } catch (e) {
        if (kDebugMode) _log.warning('Error querying operator_icons: $e');
      }
    } catch (e) {
      if (kDebugMode) _log.severe('Error in getOperatorIcon: $e');
    }

    return null;
  }

  Future<void> clearOperatorIcons() async {
    final db = await database;
    await db.delete('operator_icons');
  }

  Future<void> saveCardStatus(String iccid, String data, int expiry) async {
    final db = await database;
    await db.insert('card_status_cache', {
      'iccid': iccid,
      'data': data,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCardStatus(String iccid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'card_status_cache',
      where: 'iccid = ?',
      whereArgs: [iccid],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> getUnsentCount(String eid) async {
    return getPendingNotificationCount(eid: eid);
  }

  Future<void> saveRemoteServer(String url) async {
    final db = await database;
    await db.insert('remote_servers', {
      'url': url,
      'lastConnected': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getRemoteServers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'remote_servers',
      orderBy: 'lastConnected DESC',
    );
    return maps.map((m) => m['url'] as String).toList();
  }

  Future<void> deleteRemoteServer(String url) async {
    final db = await database;
    await db.delete('remote_servers', where: 'url = ?', whereArgs: [url]);
  }

  Future<void> _onCreateCallback(Database db, int version) async {
    if (kDebugMode) _log.fine('Creating database tables...');
    await db.execute('''
      CREATE TABLE notifications (
        eid TEXT,
        iccid TEXT,
        seqNumber INTEGER,
        content TEXT,
        timestamp INTEGER,
        status INTEGER,
        responseCode INTEGER,
        responseContent TEXT,
        notificationServer TEXT,
        notificationType TEXT,
        deletePending INTEGER DEFAULT 0,
        PRIMARY KEY (eid, seqNumber, iccid)
      )
    ''');
    await createNotificationDeliveryReceipts(db);
    await db.execute('''
      CREATE TABLE profile_storage (
        eid TEXT,
        iccid TEXT,
        spaceConsumed INTEGER,
        version INTEGER,
        info2Before TEXT,
        info2After TEXT,
        bppLength INTEGER,
        PRIMARY KEY (eid, iccid)
      )
    ''');
    await db.execute('''
      CREATE TABLE profile_metadata (
        iccid TEXT PRIMARY KEY,
        nickname TEXT,
        name TEXT,
        providerName TEXT,
        mcc TEXT,
        mnc TEXT,
        enabled INTEGER,
        profileClass INTEGER,
        profileSize INTEGER,
        gid1 TEXT,
        gid2 TEXT,
        tags TEXT,
        lastSeen INTEGER,
        eid TEXT,
        customIcon TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE profile_msisdn (
        iccid TEXT PRIMARY KEY,
        msisdn TEXT,
        lastUpdated INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE operator_icons (
        mcc TEXT,
        mnc TEXT,
        gid1 TEXT,
        gid2 TEXT,
        image TEXT,
        lastUpdated INTEGER,
        PRIMARY KEY (mcc, mnc, gid1, gid2)
      )
    ''');
    await db.execute('''
      CREATE TABLE card_status_cache (
        iccid TEXT PRIMARY KEY,
        data TEXT,
        lastUpdated INTEGER,
        expiry INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE remote_servers (
        url TEXT PRIMARY KEY,
        lastConnected INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE scheduled_notifications (
        text TEXT,
        scheduledDate INTEGER,
        iccid TEXT,
        lastUpdated INTEGER,
        eid TEXT,
        PRIMARY KEY (text, scheduledDate)
      )
    ''');
  }

  Future<void> _onUpgradeCallback(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (kDebugMode) {
      _log.info('Upgrading database from \$oldVersion to \$newVersion...');
    }

    if (oldVersion < 8) {}
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS operator_icons (
          mcc TEXT,
          mnc TEXT,
          gid1 TEXT,
          gid2 TEXT,
          image TEXT,
          lastUpdated INTEGER,
          PRIMARY KEY (mcc, mnc, gid1, gid2)
        )
      ''');
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE profile_metadata ADD COLUMN gid1 TEXT');
        await db.execute('ALTER TABLE profile_metadata ADD COLUMN gid2 TEXT');
      } catch (e) {
        if (kDebugMode) _log.warning('Error upgrading to v10: \$e');
      }
    }
    if (oldVersion < 11) {
      if (kDebugMode) {
        _log.info('Upgrading to v11: Creating card_status_cache table...');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS card_status_cache (
          iccid TEXT PRIMARY KEY,
          data TEXT,
          lastUpdated INTEGER,
          expiry INTEGER
        )
      ''');
    }
    if (oldVersion < 12) {
      if (kDebugMode) {
        _log.info('Upgrading to v12: Creating remote_servers table...');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS remote_servers (
          url TEXT PRIMARY KEY,
          lastConnected INTEGER
        )
      ''');
    }
    if (oldVersion < 13) {
      if (kDebugMode) {
        _log.info(
          'Upgrading to v13: Adding tags column to profile_metadata...',
        );
      }
      try {
        await db.execute('ALTER TABLE profile_metadata ADD COLUMN tags TEXT');
      } catch (e) {
        if (kDebugMode) _log.warning('Error upgrading to v13: \$e');
      }
    }
    if (oldVersion < 14) {
      if (kDebugMode) {
        _log.info(
          'Upgrading to v14: Creating scheduled_notifications table...',
        );
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS scheduled_notifications (
          text TEXT,
          scheduledDate INTEGER,
          iccid TEXT,
          lastUpdated INTEGER,
          eid TEXT,
          PRIMARY KEY (text, scheduledDate)
        )
      ''');
    }
    if (oldVersion < 15) {
      if (kDebugMode) {
        _log.info('Upgrading to v15: Adding eid column to profile_metadata...');
      }
      try {
        await db.execute('ALTER TABLE profile_metadata ADD COLUMN eid TEXT');
      } catch (e) {
        if (kDebugMode) _log.warning('Error upgrading to v15: \$e');
      }
    }
    if (oldVersion < 16) {
      if (kDebugMode) {
        _log.info(
          'Upgrading to v16: Adding eid column to scheduled_notifications...',
        );
      }
      try {
        await db.execute(
          'ALTER TABLE scheduled_notifications ADD COLUMN eid TEXT',
        );
      } catch (e) {
        if (kDebugMode) _log.warning('Error upgrading to v16: \$e');
      }
    }
    if (oldVersion < 17) {
      if (kDebugMode) {
        _log.info(
          'Upgrading to v17: Adding customIcon column to profile_metadata...',
        );
      }
      try {
        await db.execute(
          'ALTER TABLE profile_metadata ADD COLUMN customIcon TEXT',
        );
      } catch (e) {
        if (kDebugMode) _log.warning('Error upgrading to v17: \$e');
      }
    }
    if (oldVersion < 18) await createNotificationDeliveryReceipts(db);
  }

  Future<void> resetDatabase() async {
    final db = await database;
    final tables = [
      'notifications',
      'notification_delivery_receipts',
      'profile_storage',
      'profile_metadata',
      'profile_msisdn',
      'operator_icons',
      'card_status_cache',
      'remote_servers',
      'scheduled_notifications',
    ];
    for (var table in tables) {
      try {
        await db.delete(table);
      } catch (e) {
        _log.warning('Failed to clear table $table: $e');
      }
    }
    _profileSizeCache.clear();
  }

  Future<Uint8List> exportDatabase() async {
    return DatabaseTransferService.createSnapshot(await database);
  }

  Future<void> importDatabaseBytes(Uint8List bytes) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final temporaryFile = File(
      join(
        temporaryDirectory.path,
        'nekokolpa2_import_${DateTime.now().microsecondsSinceEpoch}.db',
      ),
    );

    try {
      await temporaryFile.writeAsBytes(bytes, flush: true);
      await importDatabase(temporaryFile.path);
    } finally {
      try {
        if (await temporaryFile.exists()) await temporaryFile.delete();
      } catch (e) {
        _log.warning('Failed to remove temporary database import: $e');
      }
    }
  }

  Future<void> importDatabase(String path) async {
    final factory = await initDb();
    Database? externalDb;
    try {
      externalDb = await (factory ?? databaseFactory).openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );
      final importedRows = await DatabaseTransferService.merge(
        source: externalDb,
        target: await database,
      );
      if (kDebugMode) {
        _log.info('Imported $importedRows database rows from $path');
      }
      _profileSizeCache.clear();
    } finally {
      await externalDb?.close();
    }
  }
}
