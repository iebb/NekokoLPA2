import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nlpa2/services/database_transfer_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late Database source;
  late Database target;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'nekokolpa2_database_transfer_',
    );
    source = await databaseFactoryFfi.openDatabase(
      '${temporaryDirectory.path}/source.db',
    );
    target = await databaseFactoryFfi.openDatabase(
      '${temporaryDirectory.path}/target.db',
    );
  });

  tearDown(() async {
    await source.close();
    await target.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('creates a standalone SQLite snapshot with committed rows', () async {
    await source.execute('''
      CREATE TABLE remote_servers (
        url TEXT PRIMARY KEY,
        lastConnected INTEGER
      )
    ''');
    await source.insert('remote_servers', {
      'url': 'https://example.test',
      'lastConnected': 42,
    });

    final snapshot = await DatabaseTransferService.createSnapshot(source);

    expect(ascii.decode(snapshot.sublist(0, 16)), 'SQLite format 3\u0000');
    final exportedPath = '${temporaryDirectory.path}/exported.db';
    await File(exportedPath).writeAsBytes(snapshot, flush: true);
    final exported = await databaseFactoryFfi.openDatabase(
      exportedPath,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    addTearDown(exported.close);
    expect(await exported.query('remote_servers'), [
      {'url': 'https://example.test', 'lastConnected': 42},
    ]);
  });

  test('merges supported rows and replaces matching primary keys', () async {
    await _createRemoteServersTable(source);
    await _createRemoteServersTable(target);
    await source.insert('remote_servers', {
      'url': 'https://replace.test',
      'lastConnected': 2,
    });
    await source.insert('remote_servers', {
      'url': 'https://new.test',
      'lastConnected': 3,
    });
    await target.insert('remote_servers', {
      'url': 'https://replace.test',
      'lastConnected': 1,
    });
    await target.insert('remote_servers', {
      'url': 'https://keep.test',
      'lastConnected': 4,
    });

    final importedRows = await DatabaseTransferService.merge(
      source: source,
      target: target,
    );

    expect(importedRows, 2);
    expect(await target.query('remote_servers', orderBy: 'url'), [
      {'url': 'https://keep.test', 'lastConnected': 4},
      {'url': 'https://new.test', 'lastConnected': 3},
      {'url': 'https://replace.test', 'lastConnected': 2},
    ]);
  });

  test('accepts older schemas and ignores unknown source columns', () async {
    await source.execute('''
      CREATE TABLE profile_metadata (
        iccid TEXT PRIMARY KEY,
        nickname TEXT,
        futureColumn TEXT
      )
    ''');
    await target.execute('''
      CREATE TABLE profile_metadata (
        iccid TEXT PRIMARY KEY,
        nickname TEXT
      )
    ''');
    await source.insert('profile_metadata', {
      'iccid': '8901000000000000001',
      'nickname': 'Imported',
      'futureColumn': 'not-in-target',
    });

    await DatabaseTransferService.merge(source: source, target: target);

    expect(await target.query('profile_metadata'), [
      {'iccid': '8901000000000000001', 'nickname': 'Imported'},
    ]);
  });

  test(
    'backup imports preserve receipts after visible history was deleted',
    () async {
      for (final database in [source, target]) {
        await database.execute('''CREATE TABLE notification_delivery_receipts (
        eid TEXT, seqNumber INTEGER, iccid TEXT, contentHash TEXT,
        PRIMARY KEY(eid, seqNumber, iccid))''');
      }
      const receipt = {
        'eid': 'test-card',
        'seqNumber': 42,
        'iccid': 'test-profile',
        'contentHash': 'payload-sha256',
      };
      await source.insert('notification_delivery_receipts', receipt);
      expect(
        await DatabaseTransferService.merge(source: source, target: target),
        1,
      );
      expect(await target.query('notification_delivery_receipts'), [receipt]);
    },
  );

  test('rejects SQLite files without supported NekokoLPA2 tables', () async {
    await source.execute('CREATE TABLE unrelated (value TEXT)');

    await expectLater(
      DatabaseTransferService.merge(source: source, target: target),
      throwsA(isA<FormatException>()),
    );
  });

  test('rolls back every row when a merge fails', () async {
    await _createRemoteServersTable(source);
    await target.execute('''
      CREATE TABLE remote_servers (
        url TEXT PRIMARY KEY,
        lastConnected INTEGER NOT NULL CHECK(lastConnected >= 0)
      )
    ''');
    await source.insert('remote_servers', {
      'url': 'https://first.test',
      'lastConnected': 1,
    });
    await source.insert('remote_servers', {
      'url': 'https://invalid.test',
      'lastConnected': -1,
    });

    await expectLater(
      DatabaseTransferService.merge(source: source, target: target),
      throwsA(isA<DatabaseException>()),
    );
    expect(await target.query('remote_servers'), isEmpty);
  });
}

Future<void> _createRemoteServersTable(Database database) {
  return database.execute('''
    CREATE TABLE remote_servers (
      url TEXT PRIMARY KEY,
      lastConnected INTEGER
    )
  ''');
}
