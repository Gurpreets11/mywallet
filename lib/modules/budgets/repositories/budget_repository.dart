import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  Future<List<BudgetModel>> getBudgets({
    required int month,
    required int year,
  }) async {
    final db = await AppDatabase.database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final rows = await db.rawQuery(
      '''
      SELECT b.*, COALESCE(SUM(e.amount), 0) AS spent_amount
      FROM budgets b LEFT JOIN expenses e
        ON e.category_id = b.category_id AND e.date >= ? AND e.date < ?
      WHERE b.month = ? AND b.year = ? GROUP BY b.id
      ORDER BY b.category_name COLLATE NOCASE
    ''',
      [start, end, month, year],
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final db = await AppDatabase.database;
    return db.rawQuery('''
      SELECT id, category_name FROM categories
      WHERE transaction_type_id = 0
        AND COALESCE(is_active, 1) = 1 ORDER BY category_name COLLATE NOCASE
    ''');
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final db = await AppDatabase.database;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await AppDatabase.database;
    return db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
