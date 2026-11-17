import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../models/report_models.dart';

class ReportRepository {
  Future<FinancialReport> getYearlyReport(int year) async {
    final Database db = await AppDatabase.database;
    final start = '$year-01-01';
    final end = '${year + 1}-01-01';
    final incomeRows = await db.rawQuery(
      """
      SELECT CAST(strftime('%m', date(date)) AS INTEGER) AS month, COALESCE(SUM(amount), 0) AS total
      FROM incomes WHERE date(date) >= date(?) AND date(date) < date(?)
      GROUP BY strftime('%m', date(date))
    """,
      [start, end],
    );
    final expenseRows = await db.rawQuery(
      """
      SELECT CAST(strftime('%m', date(date)) AS INTEGER) AS month, COALESCE(SUM(amount), 0) AS total
      FROM expenses WHERE date(date) >= date(?) AND date(date) < date(?)
      GROUP BY strftime('%m', date(date))
    """,
      [start, end],
    );
    final income = <int, double>{}, expense = <int, double>{};
    for (final r in incomeRows) {
      income[(r['month'] as num).toInt()] =
          (r['total'] as num?)?.toDouble() ?? 0;
    }
    for (final r in expenseRows) {
      expense[(r['month'] as num).toInt()] =
          (r['total'] as num?)?.toDouble() ?? 0;
    }
    final monthly = List.generate(
      12,
      (i) => MonthlyReport(
        month: i + 1,
        income: income[i + 1] ?? 0,
        expense: expense[i + 1] ?? 0,
      ),
    );
    final categoryRows = await db.rawQuery(
      """
      SELECT COALESCE(NULLIF(c.category_name,''), NULLIF(e.category_name,''), 'Uncategorised') AS category_name,
             COALESCE(SUM(e.amount),0) AS total
      FROM expenses e LEFT JOIN categories c ON c.id=e.category_id
      WHERE date(e.date)>=date(?) AND date(e.date)<date(?)
      GROUP BY COALESCE(NULLIF(c.category_name,''), NULLIF(e.category_name,''), 'Uncategorised')
      ORDER BY total DESC
    """,
      [start, end],
    );
    final categories = categoryRows
        .map(
          (r) => CategoryExpenseReport(
            categoryName: r['category_name']?.toString() ?? 'Uncategorised',
            amount: (r['total'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((x) => x.amount > 0)
        .toList();
    return FinancialReport(
      year: year,
      totalIncome: monthly.fold(0.0, (s, x) => s + x.income),
      totalExpense: monthly.fold(0.0, (s, x) => s + x.expense),
      monthly: monthly,
      categories: categories,
    );
  }
}
