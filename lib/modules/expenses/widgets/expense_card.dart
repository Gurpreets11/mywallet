import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Show the date on the card. The list hides it when transactions are
  /// already grouped under date headings.
  final bool showDate;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onTap,
    required this.onEdit,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final meta = <String>[
      if ((expense.subcategoryName ?? '').isNotEmpty) expense.subcategoryName!,
      if (expense.paymentMode.isNotEmpty) expense.paymentMode,
      if (showDate) _formatDate(expense.date),
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.errorContainer.withValues(
                  alpha: .55,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.categoryName?.isNotEmpty == true
                                ? expense.categoryName!
                                : 'Expense',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyUtils.formatAmount(expense.amount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                    if ((expense.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        expense.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.more_vert, size: 20, color: muted),
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
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete'),
                    ),
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
    return date == null ? value : AppDateUtils.formatDate(date);
  }
}
