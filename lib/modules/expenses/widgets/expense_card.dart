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
    return Card(
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 0,
        minTileHeight: 40,
        onTap: onTap,
        leading: const CircleAvatar(
          radius: 16,
          child: Icon(Icons.money_off, size: 20),
        ),
        title: Text(
          CurrencyUtils.formatAmount(expense.amount),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.paymentMode),
            Text(
              '${expense.categoryName ?? ''}'
              ' • '
              '${expense.subcategoryName ?? ''}',
            ),
            Text(AppDateUtils.formatDateTime(DateTime.parse(expense.date))),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: const Icon(Icons.edit, size: 20),
              visualDensity: VisualDensity.compact,
            ),

            const SizedBox(width: 6), // control spacing manually
            IconButton(
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
