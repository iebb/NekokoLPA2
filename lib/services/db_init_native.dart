import 'package:sqflite/sqflite.dart' show DatabaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    deferred as sqflite_ffi
    show sqfliteFfiInit, databaseFactory, databaseFactoryFfi;
import '../utils/platform_adapter.dart';

Future<DatabaseFactory?> initDb() async {
  // Initialize FFI database factory for desktop platforms (Windows, Linux, macOS)
  if (PlatformX.isWindows || PlatformX.isLinux) {
    await sqflite_ffi.loadLibrary();
    sqflite_ffi.sqfliteFfiInit();
    sqflite_ffi.databaseFactory = sqflite_ffi.databaseFactoryFfi;
    return sqflite_ffi.databaseFactoryFfi;
  }
  return null;
  // On Android/iOS, sqflite uses the native implementation automatically
}
