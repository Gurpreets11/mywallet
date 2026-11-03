import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/income_model.dart';

class IncomeCard extends StatelessWidget {
  final IncomeModel income;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.south_west_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          CurrencyUtils.formatAmount(income.amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [income.categoryName, income.subcategoryName]
                        .where((e) => e != null && e.trim().isNotEmpty)
                        .join(' • ')
                        .isEmpty
                    ? 'Income'
                    : [income.categoryName, income.subcategoryName]
                          .where((e) => e != null && e.trim().isNotEmpty)
                          .join(' • '),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  Text(
                    '${income.paymentMode}  ·  ${AppDateUtils.formatDate(DateTime.parse(income.date))}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (income.isRecurring)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 13,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          income.recurringType ?? 'Recurring',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Income actions',
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
