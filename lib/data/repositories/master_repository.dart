import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_constants.dart';

class MasterRepository {
  Future<int> insertTransactionType(
      Map<String, dynamic> data,
      ) async {
    final Database db = await AppDatabase.database;

    return await db.insert(
      DatabaseConstants.tableTransactionTypes,
      data,
    );
  }

  Future<int> insertCategory(
      Map<String, dynamic> data,
      ) async {
    final Database db = await AppDatabase.database;

    return await db.insert(
      DatabaseConstants.tableCategories,
      data,
    );
  }

  Future<int> insertSubcategory(
      Map<String, dynamic> data,
      ) async {
    final Database db = await AppDatabase.database;

    return await db.insert(
      DatabaseConstants.tableSubcategories,
      data,
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionTypes() async {
    final Database db = await AppDatabase.database;

    return await db.query(
      DatabaseConstants.tableTransactionTypes,
    );
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(
      int transactionTypeId,
      ) async {
    final Database db = await AppDatabase.database;

    return await db.query(
      DatabaseConstants.tableCategories,
      where:
      '${DatabaseConstants.colTransactionTypeId} = ?',
      whereArgs: [transactionTypeId],
    );
  }

  Future<List<Map<String, dynamic>>> getSubcategoriesByCategory(
      int categoryId,
      ) async {
    final Database db = await AppDatabase.database;

    return await db.query(
      DatabaseConstants.tableSubcategories,
      where:
      '${DatabaseConstants.colCategoryId} = ?',
      whereArgs: [categoryId],
    );
  }
}