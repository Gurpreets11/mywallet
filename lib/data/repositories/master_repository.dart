import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_constants.dart';
import '../../modules/dashboard/models/dashboard_chart_model.dart';

class MasterRepository {
  Future<int> insertTransactionType(Map<String, dynamic> data) async {
    final Database db = await AppDatabase.database;

    return await db.insert(DatabaseConstants.tableTransactionTypes, data);
  }

  Future<int> insertCategory(Map<String, dynamic> data) async {
    final Database db = await AppDatabase.database;

    return await db.insert(DatabaseConstants.tableCategories, data);
  }

  Future<int> insertSubcategory(Map<String, dynamic> data) async {
    final Database db = await AppDatabase.database;

    return await db.insert(DatabaseConstants.tableSubcategories, data);
  }

  Future<List<Map<String, dynamic>>> getTransactionTypes() async {
    final Database db = await AppDatabase.database;

    return await db.query(DatabaseConstants.tableTransactionTypes);
  }

  Future<List<Map<String, dynamic>>> getCategoriesByType(
    int transactionTypeId,
  ) async {
    final Database db = await AppDatabase.database;

    return await db.query(
      DatabaseConstants.tableCategories,
      where: '${DatabaseConstants.colTransactionTypeId} = ?',
      whereArgs: [transactionTypeId],
    );
  }

  Future<List<Map<String, dynamic>>> getSubcategoriesByCategory(
    int categoryId,
  ) async {
    final Database db = await AppDatabase.database;

    return await db.query(
      DatabaseConstants.tableSubcategories,
      where: '${DatabaseConstants.colCategoryId} = ?',
      whereArgs: [categoryId],
    );
  }

  Future<String> getCategoryName(int categoryId) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      DatabaseConstants.tableCategories,
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (result.isEmpty) {
      return '';
    }

    return result.first['category_name'].toString();
  }

  Future<String> getSubcategoryName(int subcategoryId) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      DatabaseConstants.tableSubcategories,
      where: 'id = ?',
      whereArgs: [subcategoryId],
    );

    if (result.isEmpty) {
      return '';
    }

    return result.first['subcategory_name'].toString();
  }


  /*Future<List<DashboardChartModel>> getMonthlyExpenseChart() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT
      strftime('%m', transaction_date) as month,
      SUM(amount) as total
    FROM transactions
    WHERE transaction_type = 'EXPENSE'
    GROUP BY strftime('%m', transaction_date)
    ORDER BY month
  ''');

    return result.map((e) {
      return DashboardChartModel(
        month: e['month'].toString(),
        amount: (e['total'] as num).toDouble(),
      );
    }).toList();
  }*/

  Future<List<DashboardChartModel>> getMonthlyExpenseChart() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT
      strftime('%m', date) AS month,
      SUM(amount) AS total
    FROM expenses
    GROUP BY strftime('%m', date)
    ORDER BY month
  ''');

    const months = {
      '1': 'Jan',
      '2': 'Feb',
      '3': 'Mar',
      '4': 'Apr',
      '5': 'May',
      '6': 'Jun',
      '7': 'Jul',
      '8': 'Aug',
      '9': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
    };

    return result.map((e) {
      return DashboardChartModel(
        month: months[e['month']].toString(),
        amount: (e['total'] as num).toDouble(),
      );
    }).toList();
  }

}
