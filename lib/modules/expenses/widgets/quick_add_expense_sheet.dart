import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../budgets/services/budget_alert_service.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../screens/add_expense_screen.dart';

/// Fastest way to log an expense: type the amount, tap a category chip (the
/// ones you use most are shown first) and Save. Date is today and the payment
/// mode is the one you used last. Use "More options" for the full form.
class QuickAddExpenseSheet extends StatefulWidget {
  const QuickAddExpenseSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const QuickAddExpenseSheet(),
    );
  }

  @override
  State<QuickAddExpenseSheet> createState() => _QuickAddExpenseSheetState();
}

class _QuickAddExpenseSheetState extends State<QuickAddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  List<({int id, String name})> _categories = [];
  int? _selected;
  String _paymentMode = 'Cash';
  bool _loading = true;
  bool _saving = false;
  bool _showCategoryError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final db = await AppDatabase.database;

      final since = DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String();
      final used = await db.rawQuery(
        '''
        SELECT c.id AS id, c.category_name AS name
        FROM expenses e
        JOIN categories c ON e.category_id = c.id
        WHERE c.transaction_type_id = 0 AND COALESCE(c.is_active, 1) = 1
          AND date(e.date) >= date(?)
        GROUP BY c.id
        ORDER BY COUNT(*) DESC
        LIMIT 8
        ''',
        [since],
      );
      final all = await db.query(
        'categories',
        where: 'transaction_type_id = 0 AND COALESCE(is_active, 1) = 1',
        orderBy: 'id ASC',
      );

      final list = <({int id, String name})>[
        for (final r in used) (id: r['id'] as int, name: r['name'] as String),
      ];
      for (final r in all) {
        if (list.length >= 8) break;
        final id = r['id'] as int;
        if (!list.any((c) => c.id == id)) {
          list.add((id: id, name: r['category_name'] as String));
        }
      }

      final last = await db.query(
        'expenses',
        columns: ['payment_mode'],
        orderBy: 'id DESC',
        limit: 1,
      );
      final mode = last.isEmpty ? null : last.first['payment_mode'] as String?;

      if (!mounted) return;
      setState(() {
        _categories = list;
        if (mode != null && mode.isNotEmpty) _paymentMode = mode;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (_selected == null) setState(() => _showCategoryError = true);
    if (!valid || _selected == null) return;

    setState(() => _saving = true);
    try {
      final category = _categories.firstWhere((c) => c.id == _selected);
      final expense = ExpenseModel(
        amount: double.parse(_amount.text.trim()),
        categoryId: category.id,
        categoryName: category.name,
        date: DateTime.now().toIso8601String(),
        paymentMode: _paymentMode,
        notes: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: AppDateUtils.getCurrentTimestamp(),
      );

      await context.read<ExpenseProvider>().addExpense(expense);
      await BudgetAlertService().checkAfterExpense(
        categoryId: expense.categoryId,
        dateIso: expense.date,
      );
      if (!mounted) return;
      final dashboard = context.read<DashboardProvider>();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Added ${CurrencyUtils.formatAmount(expense.amount)} to ${category.name}',
          ),
        ),
      );
      await dashboard.loadDashboardData();
    } catch (_) {
      if (mounted) {
        SnackbarUtils.showSnackbar(context, 'Unable to save. Please try again.');
        setState(() => _saving = false);
      }
    }
  }

  void _openFullForm() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick add expense',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${CurrencyUtils.symbol} ',
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Enter an amount';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text('Category', style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_categories.isEmpty)
                const Text(
                  'No expense categories yet. Use "More options" to add one.',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final c in _categories)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _selected == c.id,
                        onSelected: (_) => setState(() {
                          _selected = c.id;
                          _showCategoryError = false;
                        }),
                      ),
                  ],
                ),
              if (_showCategoryError)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Pick a category',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today - $_paymentMode',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : _openFullForm,
                    child: const Text('More options'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
