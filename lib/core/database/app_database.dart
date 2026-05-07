import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class AppDatabase {
  static Future<Database> get database async {
    return await DatabaseHelper.instance.database;
  }
}