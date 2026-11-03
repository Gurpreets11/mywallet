import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_responsive_content.dart';
import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../widgets/budget_progress_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<BudgetProvider>().load(),
    );
  }

  Future<void> _showBudgetForm({BudgetModel? existing}) async {
    final provider = context.read<BudgetProvider>();
    int? categoryId = existing?.categoryId;
    String? categoryName = existing?.categoryName;
    final amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(0) ?? '',
    );
    int alert = existing?.alertPercentage ?? 80;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Create monthly budget' : 'Edit budget',
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Expense category',
                      ),
                      items: provider.categories
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['category_name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: existing != null
                          ? null
                          : (value) {
                              setDialogState(() {
                                categoryId = value;
                                if (value != null) {
                                  categoryName = provider.categories
                                      .firstWhere(
                                        (c) => c['id'] == value,
                                      )['category_name']
                                      .toString();
                                }
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly budget',
                        prefixText: '₹ ',
                      ),
                      validator: (value) {
                        final amount = double.tryParse((value ?? '').trim());
                        return amount == null || amount <= 0
                            ? 'Enter an amount greater than zero'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: alert,
                      decoration: const InputDecoration(
                        labelText: 'Alert when used',
                      ),
                      items: const [70, 80, 90, 100]
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text('$v% of budget'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => alert = v ?? 80),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final selected = categoryId!;
                final name =
                    categoryName ??
                    provider.categories
                        .firstWhere((c) => c['id'] == selected)['category_name']
                        .toString();
                final budget = BudgetModel(
                  id: existing?.id,
                  categoryId: selected,
                  categoryName: name,
                  amount: double.parse(amountController.text.trim()),
                  month: provider.month,
                  year: provider.year,
                  alertPercentage: alert,
                );
                await provider.save(budget);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text(
          'Delete the ${budget.categoryName} budget for this month?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && budget.id != null && mounted) {
      await context.read<BudgetProvider>().delete(budget.id!);
    }
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
        actions: [
          IconButton(
            onPressed: () => _showBudgetForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Add budget',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budget_add_fab',
        onPressed: () => _showBudgetForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: AppResponsiveContent(
        maxWidth: 900,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => provider.changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_monthName(provider.month)} ${provider.year}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => provider.changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly overview',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryValue(
                                  label: 'Budget',
                                  value: provider.totalBudget,
                                ),
                              ),
                              Expanded(
                                child: _SummaryValue(
                                  label: 'Spent',
                                  value: provider.totalSpent,
                                ),
                              ),
                              Expanded(
                                child: _SummaryValue(
                                  label: 'Remaining',
                                  value: provider.totalRemaining,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: provider.totalBudget <= 0
                                ? 0
                                : (provider.totalSpent / provider.totalBudget)
                                      .clamp(0.0, 1.0)
                                      .toDouble(),
                            minHeight: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: provider.budgets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 52,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text('No budgets for this month'),
                                const SizedBox(height: 6),
                                const Text(
                                  'Create category-wise limits to track spending.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: () => _showBudgetForm(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create budget'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.budgets.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final budget = provider.budgets[index];
                              return BudgetProgressCard(
                                budget: budget,
                                onEdit: () => _showBudgetForm(existing: budget),
                                onDelete: () => _deleteBudget(budget),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        '₹${value.toStringAsFixed(0)}',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}
