import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/savings_goal_model.dart';
import '../repositories/goal_repository.dart';
import '../widgets/goal_form_sheet.dart';
import '../widgets/goal_history_sheet.dart';
import '../widgets/goal_money_sheet.dart';

/// All savings goals with progress, "save per month" hints and actions.
class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().loadGoals();
    });
  }

  Future<void> _delete(GoalProgress p) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete "${p.goal.name}"?',
      message:
          'The goal and its savings history are removed. '
          'Your income, expenses and accounts are not affected.',
    );
    if (!ok || !mounted) return;
    final dashboard = context.read<DashboardProvider>();
    final repo = GoalRepository();
    final contributions = await repo.getContributions(p.goal.id!);
    await repo.deleteGoal(p.goal.id!);
    await dashboard.loadGoals();
    if (!mounted) return;
    SnackbarUtils.showUndo(context, 'Goal deleted', () async {
      await repo.restoreGoal(p.goal, contributions);
      await dashboard.loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final goals = provider.goalProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: AppResponsiveContent(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: RefreshIndicator(
          onRefresh: () => context.read<DashboardProvider>().loadGoals(),
          child: goals.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      Icons.flag_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'No savings goals yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Set a target - a bike, a trip, an emergency fund - '
                        'and track how close you are.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  itemCount: goals.length,
                  itemBuilder: (context, i) => _GoalCard(
                    progress: goals[i],
                    onAdd: () =>
                        showGoalMoneySheet(context, progress: goals[i]),
                    onWithdraw: () => showGoalMoneySheet(
                      context,
                      progress: goals[i],
                      withdraw: true,
                    ),
                    onHistory: () => showGoalHistorySheet(context, goals[i].goal),
                    onEdit: () => showGoalFormSheet(context, goal: goals[i].goal),
                    onDelete: () => _delete(goals[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalProgress progress;
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.progress,
    required this.onAdd,
    required this.onWithdraw,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  String _hint() {
    final p = progress;
    if (p.isReached) return 'Goal reached';
    final deadline = p.deadline;
    if (deadline == null) {
      return '${CurrencyUtils.formatAmount(p.remaining)} to go';
    }
    if (p.isOverdue) {
      return 'Target date passed - ${CurrencyUtils.formatAmount(p.remaining)} to go';
    }
    final months = p.monthsLeft ?? 1;
    return 'Save ${CurrencyUtils.formatAmount(p.monthlyNeeded ?? 0)} / month '
        'for $months ${months == 1 ? 'month' : 'months'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final p = progress;
    final deadline = p.deadline;
    final barColor = p.isReached
        ? Colors.green
        : (p.isOverdue ? Colors.red : theme.colorScheme.primary);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  p.isReached ? Icons.emoji_events_outlined : Icons.flag_outlined,
                  size: 20,
                  color: barColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.goal.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'withdraw') onWithdraw();
                    if (v == 'history') onHistory();
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (p.saved > 0)
                      const PopupMenuItem(
                        value: 'withdraw',
                        child: Text('Take money out'),
                      ),
                    const PopupMenuItem(value: 'history', child: Text('History')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyUtils.formatAmount(p.saved),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'of ${CurrencyUtils.formatAmount(p.goal.targetAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      const Spacer(),
                      Text(
                        '${(p.fraction * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: barColor,
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
                      minHeight: 8,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deadline == null
                        ? _hint()
                        : '${_hint()}  •  by ${AppDateUtils.formatDate(deadline)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add money'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
