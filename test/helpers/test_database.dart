import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Gives every test a brand-new, empty MyWallet database (real schema and
/// migrations) in a temporary folder, using sqflite's desktop/FFI build.
///
/// Usage:
/// ```dart
/// void main() {
///   useFreshDatabase();
///   test('...', () async { ... });
/// }
/// ```
void useFreshDatabase() {
  late Directory dir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = Directory.systemTemp.createTempSync('mywallet_test_');
    await databaseFactory.setDatabasesPath(dir.path);
  });

  setUp(() async {
    await DatabaseHelper.instance.deleteDatabaseFile();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.closeDatabase();
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
}

/// Handy ISO timestamp for test data.
String iso(int y, int m, int d) => DateTime(y, m, d).toIso8601String();
