import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../models/income_model.dart';

class IncomeDetailScreen extends StatelessWidget {
  final IncomeModel income;
  const IncomeDetailScreen({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(income.date);
    return Scaffold(
      appBar: AppBar(title: const Text('Income details')),
      body: SingleChildScrollView(
        child: AppResponsiveContent(maxWidth: 720, padding: const EdgeInsets.all(16), child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Center(child: Column(children: [CircleAvatar(radius: 28, backgroundColor: theme.colorScheme.primaryContainer, child: Icon(Icons.south_west_rounded, size: 28, color: theme.colorScheme.onPrimaryContainer)), const SizedBox(height: 12), Text(CurrencyUtils.formatAmount(income.amount), style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('Income received', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))])),
        const SizedBox(height: 24), const Divider(),
        _detailRow(context, 'Category', income.categoryName ?? '-'),
        _detailRow(context, 'Subcategory', income.subcategoryName ?? '-'),
        _detailRow(context, 'Payment mode', income.paymentMode),
        _detailRow(context, 'Date', date == null ? income.date : AppDateUtils.formatDate(date)),
        _detailRow(context, 'Recurring', income.isRecurring ? 'Yes' : 'No'),
        if (income.isRecurring) _detailRow(context, 'Recurring type', income.recurringType ?? '-'),
        _detailRow(context, 'Notes', (income.notes?.trim().isNotEmpty ?? false) ? income.notes! : '-'),
      ])))),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 135, child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))), const SizedBox(width: 12), Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)))]));
  }
}
