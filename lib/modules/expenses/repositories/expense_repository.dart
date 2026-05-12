import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  Future<int> insertExpense(ExpenseModel expense) async {
    final Database db = await AppDatabase.database;

    return await db.insert(DatabaseConstants.tableExpenses, expense.toMap());
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final Database db = await AppDatabase.database;

    /*final List<Map<String, dynamic>> maps =
    await db.query(
      DatabaseConstants.tableExpenses,
      orderBy:
      '${DatabaseConstants.colDate} DESC',
    );*/

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
  SELECT 
    e.*,
    c.category_name,
    s.subcategory_name
  FROM expenses e
  LEFT JOIN categories c
    ON e.category_id = c.id
  LEFT JOIN subcategories s
    ON e.subcategory_id = s.id
  ORDER BY e.date DESC
''');

    return maps.map((e) => ExpenseModel.fromMap(e)).toList();
  }

  Future<int> updateExpense(ExpenseModel expense) async {
    final Database db = await AppDatabase.database;

    return await db.update(
      DatabaseConstants.tableExpenses,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final Database db = await AppDatabase.database;

    return await db.delete(
      DatabaseConstants.tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ExpenseModel?> getExpenseById(int id) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      DatabaseConstants.tableExpenses,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return ExpenseModel.fromMap(result.first);
  }

  Future<double> getCurrentMonthExpenseTotal() async {
    final Database db = await AppDatabase.database;

    final now = DateTime.now();

    final startDate = DateTime(now.year, now.month, 1).toIso8601String();

    final endDate = DateTime(now.year, now.month + 1, 0).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM expenses
    WHERE date BETWEEN ? AND ?
  ''',
      [startDate, endDate],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<ExpenseModel>> searchExpenses(String keyword) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      DatabaseConstants.tableExpenses,
      where: 'notes LIKE ?',
      whereArgs: ['%$keyword%'],
    );

    return result.map((e) => ExpenseModel.fromMap(e)).toList();
  }
}
