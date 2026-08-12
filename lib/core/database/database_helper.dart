import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';
import 'migrations.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  /*Future<Database> getDatabase() async {
    return await database;
  }*/

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = OFF;');
      },
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
      onOpen: (db) {
        print('Database opened');
      },
    );
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reopen database
  Future<Database> reopenDatabase() async {
    await closeDatabase();
    return await database;
  }

  /// Delete database completely
  Future<void> deleteDatabaseFile() async {
    await closeDatabase();

    final databasePath = await getDatabasesPath();

    final path = join(databasePath, DatabaseConstants.databaseName);

    await deleteDatabase(path);
  }

  /// Check whether database is open
  bool isDatabaseOpen() {
    return _database?.isOpen ?? false;
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    final databasePath = await getDatabasesPath();

    return join(databasePath, DatabaseConstants.databaseName);
  }
}
