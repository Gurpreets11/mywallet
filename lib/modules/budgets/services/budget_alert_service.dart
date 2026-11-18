import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/settings/app_preferences.dart';
import '../../../core/utils/currency_utils.dart';

/// Sends a notification when spending in a category reaches the budget's
/// alert percentage ("near limit") and again when the budget is fully used.
/// Each level is sent once per budget; the state is kept in
/// `budgets.last_alert_level`.
class BudgetAlertService {
  /// Call after an expense is saved. Never throws - alerts are best-effort.
  Future<void> checkAfterExpense({
    required int? categoryId,
    required String dateIso,
  }) async {
    if (categoryId == null) return;
    if (!AppPreferences.instance.budgetAlertsEnabled) return;

    try {
      final date = DateTime.tryParse(dateIso);
      if (date == null) return;

      final db = await AppDatabase.database;
      final budgets = await db.query(
        'budgets',
        where: 'category_id = ? AND month = ? AND year = ?',
        whereArgs: [categoryId, date.month, date.year],
        limit: 1,
      );
      if (budgets.isEmpty) return;
      final budget = budgets.first;

      final id = budget['id'] as int;
      final limit = (budget['amount'] as num).toDouble();
      if (limit <= 0) return;
      final alertPercent = (budget['alert_percentage'] as num?)?.toInt() ?? 80;
      final lastLevel = (budget['last_alert_level'] as num?)?.toInt() ?? 0;
      final name = (budget['category_name'] ?? 'this category').toString();

      final start = DateTime(date.year, date.month, 1).toIso8601String();
      final end = DateTime(date.year, date.month + 1, 1).toIso8601String();
      final spentRows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
        'WHERE category_id = ? AND date >= ? AND date < ?',
        [categoryId, start, end],
      );
      final spent = (spentRows.first['total'] as num).toDouble();

      final level = spent >= limit
          ? 2
          : (spent * 100 >= alertPercent * limit ? 1 : 0);

      if (level != lastLevel) {
        await db.update(
          'budgets',
          {'last_alert_level': level},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // Only notify when the level went UP (dropping back resets the state so
      // the alert can fire again later).
      if (level > lastLevel) {
        final percent = (spent * 100 / limit).round();
        await NotificationService.instance.showInstantNotification(
          id: 800000 + (id % 100000) * 10 + level,
          title: level == 2
              ? 'Budget limit reached: $name'
              : 'Budget almost used: $name',
          body: level == 2
              ? 'You have spent ${CurrencyUtils.formatAmount(spent)} of '
                    '${CurrencyUtils.formatAmount(limit)} ($percent%).'
              : 'You have used $percent% of your $name budget '
                    '(${CurrencyUtils.formatAmount(spent)} of '
                    '${CurrencyUtils.formatAmount(limit)}).',
        );
      }
    } catch (e) {
      debugPrint('Budget alert check failed: $e');
    }
  }
}
