import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/income_model.dart';

class IncomeRepository {
  Future<int> insertIncome(
      IncomeModel income,
      ) async {
    final Database db =
    await AppDatabase.database;

    return await db.insert(
      'incomes',
      income.toMap(),
    );
  }

  Future<List<IncomeModel>>
  getAllIncomes() async {
    final Database db =
    await AppDatabase.database;

    final result =
    await db.rawQuery('''
      SELECT 
        i.*,
        c.category_name,
        s.subcategory_name
      FROM incomes i
      LEFT JOIN categories c
        ON i.category_id = c.id
      LEFT JOIN subcategories s
        ON i.subcategory_id = s.id
      ORDER BY i.date DESC
    ''');

    return result
        .map(
          (e) =>
          IncomeModel.fromMap(e),
    )
        .toList();
  }

  Future<int> updateIncome(
      IncomeModel income,
      ) async {
    final Database db =
    await AppDatabase.database;

    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(
      int id,
      ) async {
    final Database db =
    await AppDatabase.database;

    return await db.delete(
      'incomes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double>
  getCurrentMonthIncomeTotal() async {
    final Database db =
    await AppDatabase.database;

    final result =
    await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM incomes
    ''');

    return (result.first['total']
    as num?)
        ?.toDouble() ??
        0.0;
  }
}