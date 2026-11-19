import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../models/month_insights.dart';

/// Home-screen card: this month so far vs the same days of last month, and
/// the three categories you spent the most on.
class MonthInsightsCard extends StatelessWidget {
  final MonthInsights? insights;

  const MonthInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final data = insights;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: data == null
            ? Text('Loading...', style: TextStyle(color: muted))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _compareRow(
                    context,
                    label: 'Spent this month',
                    now: data.expenseThisMonth,
                    before: data.expenseLastMonthSamePeriod,
                    change: data.expenseChange,
                    // Spending less is the good direction.
                    lowerIsBetter: true,
                  ),
                  const SizedBox(height: 12),
                  _compareRow(
                    context,
                    label: 'Earned this month',
                    now: data.incomeThisMonth,
                    before: data.incomeLastMonthSamePeriod,
                    change: data.incomeChange,
                    lowerIsBetter: false,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Compared with the same days of last month '
                    '(1st-${data.day}). Last month you spent '
                    '${CurrencyUtils.formatAmount(data.expenseLastMonthTotal)} '
                    'in total.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: muted),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Top spending',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data.topCategories.isEmpty)
                    Text(
                      'No spending recorded this month yet.',
                      style: TextStyle(color: muted, fontSize: 13),
                    )
                  else
                    for (final c in data.topCategories) _categoryRow(context, c),
                ],
              ),
      ),
    );
  }

  Widget _compareRow(
    BuildContext context, {
    required String label,
    required double now,
    required double before,
    required double? change,
    required bool lowerIsBetter,
  }) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget? chip;
    if (change != null) {
      final up = change >= 0;
      final good = lowerIsBetter ? !up : up;
      final color = good ? Colors.green : Colors.red;
      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 2),
            Text(
              '${change.abs().toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              Text(
                CurrencyUtils.formatAmount(now),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Last month: ${CurrencyUtils.formatAmount(before)}',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
        if (chip != null) chip,
      ],
    );
  }

  Widget _categoryRow(BuildContext context, CategorySpend c) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    String? delta;
    Color? deltaColor;
    if (c.lastMonthAmount > 0) {
      final pct = (c.amount - c.lastMonthAmount) / c.lastMonthAmount * 100;
      delta = '${pct >= 0 ? '+' : '-'}${pct.abs().toStringAsFixed(0)}% vs last month';
      deltaColor = pct > 0 ? Colors.red : Colors.green;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                CurrencyUtils.formatAmount(c.amount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${(c.share * 100).toStringAsFixed(0)}% of spending',
                style: TextStyle(fontSize: 11, color: muted),
              ),
              const Spacer(),
              if (delta != null)
                Text(
                  delta,
                  style: TextStyle(fontSize: 11, color: deltaColor),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
