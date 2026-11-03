import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.errorContainer.withValues(
                  alpha: .55,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.categoryName?.isNotEmpty == true
                          ? expense.categoryName!
                          : 'Expense',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if ((expense.subcategoryName ?? '').isNotEmpty)
                          expense.subcategoryName!,
                        expense.paymentMode,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if ((expense.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        expense.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(expense.date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.formatAmount(expense.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More actions',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.more_horiz,
                      size: 21,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : AppDateUtils.formatDateTime(date);
  }
}
