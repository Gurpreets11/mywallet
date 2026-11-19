import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/savings_goal_model.dart';
import '../repositories/goal_repository.dart';

/// Create ([goal] == null) or edit a savings goal.
Future<void> showGoalFormSheet(BuildContext context, {SavingsGoalModel? goal}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GoalFormSheet(goal: goal),
  );
}

class _GoalFormSheet extends StatefulWidget {
  final SavingsGoalModel? goal;
  const _GoalFormSheet({this.goal});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  DateTime? _targetDate;
  bool _saving = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    final target = g?.targetAmount;
    _amountController = TextEditingController(
      text: target == null
          ? ''
          : (target == target.roundToDouble()
                ? target.toStringAsFixed(0)
                : target.toString()),
    );
    _targetDate = g?.targetDate == null
        ? null
        : DateTime.tryParse(g!.targetDate!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 180)),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = GoalRepository();
    final dashboard = context.read<DashboardProvider>();
    final navigator = Navigator.of(context);
    final dateText = _targetDate == null
        ? null
        : DateTime(
            _targetDate!.year,
            _targetDate!.month,
            _targetDate!.day,
          ).toIso8601String().substring(0, 10);

    try {
      final goal = SavingsGoalModel(
        id: widget.goal?.id,
        name: _nameController.text.trim(),
        targetAmount: double.parse(_amountController.text.trim()),
        targetDate: dateText,
        createdAt: widget.goal?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
      );
      if (_isEdit) {
        await repo.updateGoal(goal);
      } else {
        await repo.addGoal(goal);
      }
      await dashboard.loadGoals();
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackbarUtils.showSnackbar(context, 'Could not save goal');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _isEdit ? 'Edit goal' : 'New savings goal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Goal name',
                hintText: 'e.g. New bike',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target amount',
                prefixText: '${CurrencyUtils.symbol} ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0)
                    ? 'Enter an amount greater than zero'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Target date (optional)',
                  prefixIcon: const Icon(Icons.event_outlined),
                  suffixIcon: _targetDate == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear date',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _targetDate = null),
                        ),
                ),
                child: Text(
                  _targetDate == null
                      ? 'No deadline'
                      : AppDateUtils.formatDate(_targetDate!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_isEdit ? 'Update goal' : 'Create goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
