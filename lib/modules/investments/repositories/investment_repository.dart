import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

import '../models/investment_model.dart';

class InvestmentRepository {
  Future<int> insertInvestment(InvestmentModel investment) async {
    final Database db = await AppDatabase.database;

    return db.insert('investments', investment.toMap());
  }

  Future<List<InvestmentModel>> getAllInvestments() async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      'investments',
      orderBy: 'investment_date DESC',
    );

    return result.map((e) => InvestmentModel.fromMap(e)).toList();
  }

  Future<int> updateInvestment(InvestmentModel investment) async {
    final Database db = await AppDatabase.database;

    return db.update(
      'investments',
      investment.toMap(),
      where: 'id = ?',
      whereArgs: [investment.id],
    );
  }

  Future<int> deleteInvestment(int id) async {
    final Database db = await AppDatabase.database;

    return db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalInvestmentValue() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
      SELECT SUM(current_value)
      AS total
      FROM investments
    ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }
}
