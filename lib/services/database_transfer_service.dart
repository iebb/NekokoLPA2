import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Creates portable SQLite backups and merges them into the app database.
///
/// File pickers on mobile expose documents through scoped providers rather
/// than ordinary writable paths. Keeping the SQLite work here lets the UI
/// pass complete database bytes to and from those providers.
class DatabaseTransferService {
  static const supportedTables = <String>[
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

  /// Returns a consistent copy of the live SQLite database.
  static Future<Uint8List> createSnapshot(Database database) async {
    if (kIsWeb) {
      throw UnsupportedError('Database file export is not supported on web.');
    }

    final checkpoint = await database.rawQuery('PRAGMA wal_checkpoint(FULL)');
    if (checkpoint.isNotEmpty) {
      final busy = checkpoint.first['busy'];
      if (busy is int && busy != 0) {
        throw StateError('Could not checkpoint the database for export.');
      }
    }

    // Hold an exclusive transaction while reading so no app write can race
    // the file snapshot after the WAL checkpoint.
    return database.transaction(
      (_) => File(database.path).readAsBytes(),
      exclusive: true,
    );
  }

  /// Validates [source] and atomically merges its supported rows into [target].
  ///
  /// Existing rows with the same primary key are replaced. Tables absent from
  /// an older backup are skipped, and columns unknown to the current app are
  /// ignored so backups from adjacent schema versions remain importable.
  static Future<int> merge({
    required Database source,
    required Database target,
  }) async {
    final quickCheck = await source.rawQuery('PRAGMA quick_check');
    if (quickCheck.isEmpty || quickCheck.first.values.first != 'ok') {
      throw const FormatException('The selected file is not a valid database.');
    }

    final sourceTableRows = await source.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final sourceTables = sourceTableRows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    final tables = supportedTables
        .where((table) => sourceTables.contains(table))
        .toList(growable: false);

    if (tables.isEmpty) {
      throw const FormatException(
        'The selected database does not contain supported NekokoLPA2 data.',
      );
    }

    final rowsByTable = <String, List<Map<String, Object?>>>{};
    final targetColumnsByTable = <String, Set<String>>{};
    for (final table in tables) {
      rowsByTable[table] = await source.query(table);
      final columnRows = await target.rawQuery('PRAGMA table_info("$table")');
      targetColumnsByTable[table] = columnRows
          .map((row) => row['name'])
          .whereType<String>()
          .toSet();
    }

    var importedRows = 0;
    await target.transaction((transaction) async {
      for (final table in tables) {
        final targetColumns = targetColumnsByTable[table]!;
        for (final row in rowsByTable[table]!) {
          final compatibleRow = Map<String, Object?>.fromEntries(
            row.entries.where((entry) => targetColumns.contains(entry.key)),
          );
          if (compatibleRow.isEmpty) continue;
          await transaction.insert(
            table,
            compatibleRow,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedRows++;
        }
      }
    });

    return importedRows;
  }
}
