import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/month_insights.dart';

class MonthInsightsRepository {
  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  Future<MonthInsights> load() async {
    final Database db = await AppDatabase.database;
    final now = DateTime.now();

    final thisStart = DateTime(now.year, now.month, 1);
    final lastStart = DateTime(now.year, now.month - 1, 1);
    final lastDays = DateTime(now.year, now.month, 0).day;
    // Same days of last month (e.g. the 1st-15th), never past its last day.
    final compareDay = now.day > lastDays ? lastDays : now.day;
    final lastSameEnd = DateTime(lastStart.year, lastStart.month, compareDay);
    final lastEnd = DateTime(now.year, now.month, 0);

    Future<double> total(
      String table,
      DateTime from,
      DateTime to,
    ) async {
      final rows = await db.rawQuery(
        'SELECT SUM(amount) AS total FROM $table '
        'WHERE date(date) >= date(?) AND date(date) <= date(?)',
        [_day.format(from), _day.format(to)],
      );
      return (rows.first['total'] as num?)?.toDouble() ?? 0;
    }

    Future<Map<String, double>> byCategory(DateTime from, DateTime to) async {
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(c.category_name, e.category_name, 'Other') AS name,
               SUM(e.amount) AS total
        FROM expenses e
        LEFT JOIN categories c ON e.category_id = c.id
        WHERE date(e.date) >= date(?) AND date(e.date) <= date(?)
        GROUP BY name
        ORDER BY total DESC
        ''',
        [_day.format(from), _day.format(to)],
      );
      return {
        for (final r in rows)
          r['name'] as String: (r['total'] as num?)?.toDouble() ?? 0,
      };
    }

    final today = DateTime(now.year, now.month, now.day);
    final expenseNow = await total('expenses', thisStart, today);
    final expenseLastSame = await total('expenses', lastStart, lastSameEnd);
    final expenseLastFull = await total('expenses', lastStart, lastEnd);
    final incomeNow = await total('incomes', thisStart, today);
    final incomeLastSame = await total('incomes', lastStart, lastSameEnd);

    final thisCats = await byCategory(thisStart, today);
    final lastCats = await byCategory(lastStart, lastSameEnd);

    final top = [
      for (final e in thisCats.entries.take(3))
        CategorySpend(
          name: e.key,
          amount: e.value,
          lastMonthAmount: lastCats[e.key] ?? 0,
          share: expenseNow <= 0 ? 0 : e.value / expenseNow,
        ),
    ];

    return MonthInsights(
      expenseThisMonth: expenseNow,
      expenseLastMonthSamePeriod: expenseLastSame,
      expenseLastMonthTotal: expenseLastFull,
      incomeThisMonth: incomeNow,
      incomeLastMonthSamePeriod: incomeLastSame,
      topCategories: top,
      day: compareDay,
    );
  }
}
