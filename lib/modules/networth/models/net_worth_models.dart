/// Assets and liabilities at one moment.
class NetWorthSnapshot {
  /// Sum of all account balances (cash, bank, wallets).
  final double cash;

  /// Current value of all investments.
  final double investments;

  /// Outstanding amount of loans you gave (money others owe you).
  final double receivable;

  /// Outstanding amount of loans you took (money you owe).
  final double liabilities;

  const NetWorthSnapshot({
    required this.cash,
    required this.investments,
    required this.receivable,
    required this.liabilities,
  });

  double get assets => cash + investments + receivable;
  double get netWorth => assets - liabilities;
}

/// Net worth at the end of one month.
class NetWorthPoint {
  /// First day of the month this point describes.
  final DateTime month;
  final NetWorthSnapshot snapshot;

  const NetWorthPoint({required this.month, required this.snapshot});
}

class NetWorthResult {
  final NetWorthSnapshot current;

  /// Oldest first; the last point is the current month (equal to [current]).
  final List<NetWorthPoint> trend;

  const NetWorthResult({required this.current, required this.trend});

  /// Change since the end of last month (null when there is no history).
  double? get changeSinceLastMonth {
    if (trend.length < 2) return null;
    return current.netWorth - trend[trend.length - 2].snapshot.netWorth;
  }

  double? get changePercent {
    if (trend.length < 2) return null;
    final base = trend[trend.length - 2].snapshot.netWorth;
    if (base == 0) return null;
    return (current.netWorth - base) / base.abs() * 100;
  }
}
