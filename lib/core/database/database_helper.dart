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

  Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      DatabaseConstants.databaseName,
    );

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
    );
  }
}