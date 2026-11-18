import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../goals/models/savings_goal_model.dart';

/// Home-screen card: the goals closest to their deadline (max 2) or a prompt
/// to create the first goal.
class GoalsSummaryCard extends StatelessWidget {
  final List<GoalProgress> goals;
  final VoidCallback onTap;

  const GoalsSummaryCard({super.key, required this.goals, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    // Unfinished goals first (they arrive ordered by deadline).
    final open = goals.where((g) => !g.isReached).toList();
    final shown = (open.isNotEmpty ? open : goals).take(2).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: shown.isEmpty
              ? Row(
                  children: [
                    Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Set a savings goal and track your progress',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: muted),
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _row(theme, muted, shown[i]),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, Color muted, GoalProgress p) {
    final color = p.isReached
        ? Colors.green
        : (p.isOverdue ? Colors.red : theme.colorScheme.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                p.goal.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(p.fraction * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.fraction,
            minHeight: 7,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${CurrencyUtils.formatAmount(p.saved)} of '
          '${CurrencyUtils.formatAmount(p.goal.targetAmount)}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
