import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/savings_goal_model.dart';
import '../repositories/goal_repository.dart';

/// Add money to a goal, or take money out of it ([withdraw] = true).
Future<void> showGoalMoneySheet(
  BuildContext context, {
  required GoalProgress progress,
  bool withdraw = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalMoneySheet(progress: progress, withdraw: withdraw),
  );
}

class _GoalMoneySheet extends StatefulWidget {
  final GoalProgress progress;
  final bool withdraw;
  const _GoalMoneySheet({required this.progress, required this.withdraw});

  @override
  State<_GoalMoneySheet> createState() => _GoalMoneySheetState();
}

class _GoalMoneySheetState extends State<_GoalMoneySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final dashboard = context.read<DashboardProvider>();
    final navigator = Navigator.of(context);
    final amount = double.parse(_amountController.text.trim());
    final notes = _notesController.text.trim();

    try {
      await GoalRepository().addContribution(
        GoalContributionModel(
          goalId: widget.progress.goal.id!,
          amount: widget.withdraw ? -amount : amount,
          date: _date.toIso8601String(),
          notes: notes.isEmpty ? null : notes,
          createdAt: AppDateUtils.getCurrentTimestamp(),
        ),
      );
      await dashboard.loadGoals();
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtils.showSnackbar(context, 'Could not save');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.withdraw
                  ? 'Take money out of "${p.goal.name}"'
                  : 'Add money to "${p.goal.name}"',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved so far: ${CurrencyUtils.formatAmount(p.saved)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) {
                  return 'Enter an amount greater than zero';
                }
                if (widget.withdraw && n > p.saved) {
                  return 'You only have ${CurrencyUtils.formatAmount(p.saved)} saved';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(AppDateUtils.formatDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(widget.withdraw ? 'Take out' : 'Add money'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
