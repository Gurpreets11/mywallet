import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

import '../models/investment_analytics_model.dart';
import '../models/investment_model.dart';
import '../models/investment_valuation_model.dart';
import '../utils/investment_utils.dart';

class InvestmentRepository {
  Future<int> insertInvestment(InvestmentModel investment) async {
    final Database db = await AppDatabase.database;

    return db.transaction((txn) async {
      final id = await txn.insert('investments', investment.toMap());
      // First point of the value history.
      await txn.insert('investment_valuations', {
        'investment_id': id,
        'value': investment.currentValue,
        'date': investment.investmentDate,
        'notes': 'Opening value',
        'created_at': DateTime.now().toIso8601String(),
      });
      return id;
    });
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

    return db.transaction((txn) async {
      final before = await txn.query(
        'investments',
        columns: ['current_value'],
        where: 'id = ?',
        whereArgs: [investment.id],
        limit: 1,
      );
      final changed = await txn.update(
        'investments',
        investment.toMap(),
        where: 'id = ?',
        whereArgs: [investment.id],
      );
      // Editing the current value on the form counts as a new valuation.
      if (before.isNotEmpty && investment.id != null) {
        final old = (before.first['current_value'] as num?)?.toDouble();
        if (old != investment.currentValue) {
          final today = DateTime.now();
          await txn.insert('investment_valuations', {
            'investment_id': investment.id,
            'value': investment.currentValue,
            'date': DateTime(
              today.year,
              today.month,
              today.day,
            ).toIso8601String(),
            'notes': 'Updated from edit screen',
            'created_at': today.toIso8601String(),
          });
        }
      }
      return changed;
    });
  }

  Future<int> deleteInvestment(int id) async {
    final Database db = await AppDatabase.database;

    return db.transaction((txn) async {
      await txn.delete(
        'investment_valuations',
        where: 'investment_id = ?',
        whereArgs: [id],
      );
      return txn.delete('investments', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Deletes an investment and returns its value history so the delete can
  /// be undone with [restoreInvestment].
  Future<List<InvestmentValuation>> deleteInvestmentWithHistory(int id) async {
    final history = await getValuations(id);
    await deleteInvestment(id);
    return history;
  }

  /// Puts back a deleted investment (same id) with its value history.
  Future<void> restoreInvestment(
    InvestmentModel investment,
    List<InvestmentValuation> valuations,
  ) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.insert(
        'investments',
        investment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final v in valuations) {
        await txn.insert(
          'investment_valuations',
          v.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Valuation history
  // ---------------------------------------------------------------------------

  /// Oldest first.
  Future<List<InvestmentValuation>> getValuations(int investmentId) async {
    final Database db = await AppDatabase.database;
    final rows = await db.query(
      'investment_valuations',
      where: 'investment_id = ?',
      whereArgs: [investmentId],
      orderBy: 'date(date) ASC, id ASC',
    );
    return rows.map(InvestmentValuation.fromMap).toList();
  }

  /// Records a value and makes the latest dated entry the investment's
  /// current value.
  Future<void> addValuation({
    required int investmentId,
    required double value,
    required DateTime date,
    String? notes,
  }) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.insert('investment_valuations', {
        'investment_id': investmentId,
        'value': value,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'notes': (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _syncCurrentValue(txn, investmentId);
    });
  }

  Future<void> deleteValuation(int valuationId, int investmentId) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'investment_valuations',
        where: 'id = ?',
        whereArgs: [valuationId],
      );
      await _syncCurrentValue(txn, investmentId);
    });
  }

  /// current_value = value of the most recent valuation (kept unchanged when
  /// no valuation is left).
  Future<void> _syncCurrentValue(Transaction txn, int investmentId) async {
    final latest = await txn.query(
      'investment_valuations',
      where: 'investment_id = ?',
      whereArgs: [investmentId],
      orderBy: 'date(date) DESC, id DESC',
      limit: 1,
    );
    if (latest.isEmpty) return;
    await txn.update(
      'investments',
      {'current_value': latest.first['value']},
      where: 'id = ?',
      whereArgs: [investmentId],
    );
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

  Future<double> getTotalInvestedAmount() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT SUM(invested_amount)
    AS total
    FROM investments
  ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalCurrentValue() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT SUM(current_value)
    AS total
    FROM investments
  ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAssetAllocation() async {
    final Database db = await AppDatabase.database;

    return db.rawQuery('''
    SELECT
      investment_type,
      SUM(current_value)
      AS total
    FROM investments
    GROUP BY investment_type
  ''');
  }

  Future<List<InvestmentModel>> getUpcomingSips() async {
    final Database db = await AppDatabase.database;

    final currentDay = DateTime.now().day;

    final result = await db.rawQuery(
      '''
    SELECT *
    FROM investments
    WHERE is_sip = 1
    AND sip_date >= ?
    ORDER BY sip_date ASC
  ''',
      [currentDay],
    );

    return result.map((e) => InvestmentModel.fromMap(e)).toList();
  }

  Future<double> getMonthlySipTotal() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT SUM(sip_amount)
    AS total
    FROM investments
    WHERE is_sip = 1
  ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<InvestmentAnalyticsModel> getInvestmentAnalytics() async {
    final investments = await getAllInvestments();

    if (investments.isEmpty) {
      return const InvestmentAnalyticsModel();
    }

    InvestmentModel? topPerformer;

    InvestmentModel? worstPerformer;

    InvestmentModel? highestRoi;

    InvestmentModel? highestInvestment;

    double topProfit = double.negativeInfinity;

    double worstProfit = double.infinity;

    double topRoi = double.negativeInfinity;

    double highestAmount = double.negativeInfinity;

    for (final investment in investments) {
      final profit = InvestmentUtils.calculateProfit(
        investedAmount: investment.investedAmount,

        currentValue: investment.currentValue,
      );

      final roi = InvestmentUtils.calculateRoi(
        investedAmount: investment.investedAmount,

        currentValue: investment.currentValue,
      );

      /// TOP PROFIT

      if (profit > topProfit) {
        topProfit = profit;

        topPerformer = investment;
      }

      /// WORST PROFIT

      if (profit < worstProfit) {
        worstProfit = profit;

        worstPerformer = investment;
      }

      /// ROI

      if (roi > topRoi) {
        topRoi = roi;

        highestRoi = investment;
      }

      /// HIGHEST INVESTMENT

      if (investment.investedAmount > highestAmount) {
        highestAmount = investment.investedAmount;

        highestInvestment = investment;
      }
    }

    return InvestmentAnalyticsModel(
      topPerformer: topPerformer,

      worstPerformer: worstPerformer,

      highestRoi: highestRoi,

      highestInvestment: highestInvestment,
    );
  }
}
