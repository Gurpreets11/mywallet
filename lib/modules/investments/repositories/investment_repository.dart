import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

import '../models/investment_analytics_model.dart';
import '../models/investment_model.dart';
import '../utils/investment_utils.dart';

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
