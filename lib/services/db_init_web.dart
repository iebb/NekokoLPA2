import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    deferred as sqflite_ffi
    show sqfliteFfiInit, databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    deferred as sqflite_ffi_web
    show databaseFactoryFfiWeb;
import 'package:flutter/foundation.dart';

Future<DatabaseFactory?> initDb() async {
  if (kDebugMode) {
    print('Initializing database factory for Web...');
  }
  await sqflite_ffi.loadLibrary();
  await sqflite_ffi_web.loadLibrary();
  sqflite_ffi.sqfliteFfiInit();
  sqflite_ffi.databaseFactory = sqflite_ffi_web.databaseFactoryFfiWeb;
  return sqflite_ffi_web.databaseFactoryFfiWeb;
}
