import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/savings_goal_model.dart';
import '../repositories/goal_repository.dart';

/// List of everything added to / taken out of a goal, with delete.
Future<void> showGoalHistorySheet(BuildContext context, SavingsGoalModel goal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalHistorySheet(goal: goal),
  );
}

class _GoalHistorySheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const _GoalHistorySheet({required this.goal});

  @override
  State<_GoalHistorySheet> createState() => _GoalHistorySheetState();
}

class _GoalHistorySheetState extends State<_GoalHistorySheet> {
  final _repo = GoalRepository();
  List<GoalContributionModel>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.getContributions(widget.goal.id!);
    if (mounted) setState(() => _items = items);
  }

  Future<void> _delete(GoalContributionModel c) async {
    final dashboard = context.read<DashboardProvider>();
    await _repo.deleteContribution(c.id!);
    await dashboard.loadGoals();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final items = _items;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'History - ${widget.goal.name}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (items == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text('Nothing added yet', style: TextStyle(color: muted)),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final out = c.amount < 0;
                  final date = DateTime.tryParse(c.date);
                  final meta = [
                    if (date != null) AppDateUtils.formatDate(date),
                    if ((c.notes ?? '').trim().isNotEmpty) c.notes!.trim(),
                  ].join(' • ');
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${out ? '-' : '+'} '
                              '${CurrencyUtils.formatAmount(c.amount.abs())}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: out ? Colors.red : Colors.green,
                              ),
                            ),
                            if (meta.isNotEmpty)
                              Text(
                                meta,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _delete(c),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
