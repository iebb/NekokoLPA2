import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Auto-loaded by `flutter test`. The app `DatabaseService` uses the global
/// sqflite `databaseFactory`, which is unset in the headless test VM (there are
/// no platform channels). Point it at the FFI factory so DB-backed code -- e.g.
/// the redaction-flag migration -- can open a database during tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
