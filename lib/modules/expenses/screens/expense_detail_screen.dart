import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/expense_model.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(expense.date);
    return Scaffold(
      appBar: AppBar(title: const Text('Expense details')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          CircleAvatar(radius: 28, backgroundColor: theme.colorScheme.errorContainer, child: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.error, size: 28)),
          const SizedBox(height: 14),
          Text('Expense amount', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 5),
          Text(CurrencyUtils.formatAmount(expense.amount), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(expense.categoryName ?? 'Uncategorized', style: theme.textTheme.titleSmall),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Transaction information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _DetailRow(label: 'Category', value: expense.categoryName ?? '-'),
          _DetailRow(label: 'Subcategory', value: expense.subcategoryName ?? '-'),
          _DetailRow(label: 'Payment mode', value: expense.paymentMode),
          _DetailRow(label: 'Date', value: date == null ? expense.date : AppDateUtils.formatDateTime(date)),
          _DetailRow(label: 'Notes', value: (expense.notes ?? '').trim().isEmpty ? '-' : expense.notes!.trim(), last: true),
        ]))),
      ]))),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _DetailRow({required this.label, required this.value, this.last = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: EdgeInsets.only(bottom: last ? 0 : 15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 125, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
      const SizedBox(width: 12),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
    ]));
  }
}
