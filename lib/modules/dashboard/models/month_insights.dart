/// One spending category this month compared with the same days last month.
class CategorySpend {
  final String name;
  final double amount;

  /// Spent in this category over the same days of last month.
  final double lastMonthAmount;

  /// Share of this month's total spending (0-1).
  final double share;

  const CategorySpend({
    required this.name,
    required this.amount,
    required this.lastMonthAmount,
    required this.share,
  });
}

/// This month so far compared with the same days of last month.
class MonthInsights {
  final double expenseThisMonth;
  final double expenseLastMonthSamePeriod;
  final double expenseLastMonthTotal;
  final double incomeThisMonth;
  final double incomeLastMonthSamePeriod;
  final List<CategorySpend> topCategories;

  /// Day of the month up to which both months are compared.
  final int day;

  const MonthInsights({
    required this.expenseThisMonth,
    required this.expenseLastMonthSamePeriod,
    required this.expenseLastMonthTotal,
    required this.incomeThisMonth,
    required this.incomeLastMonthSamePeriod,
    required this.topCategories,
    required this.day,
  });

  /// Percent change of [now] against [before]; null when there is nothing to
  /// compare with.
  static double? percentChange(double now, double before) {
    if (before <= 0) return null;
    return (now - before) / before * 100;
  }

  double? get expenseChange =>
      percentChange(expenseThisMonth, expenseLastMonthSamePeriod);
  double? get incomeChange =>
      percentChange(incomeThisMonth, incomeLastMonthSamePeriod);
}
