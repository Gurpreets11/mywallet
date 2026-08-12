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
    return Card(
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 0,
        minTileHeight: 40,
        onTap: onTap,

        leading: const CircleAvatar(
          child: Icon(Icons.payments, size: 20),
          radius: 16,
        ),

        title: Text(
          CurrencyUtils.formatAmount(income.amount),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(income.paymentMode),
            Text(
              '${income.categoryName ?? ''}'
              ' • '
              '${income.subcategoryName ?? ''}',
            ),
            Text(AppDateUtils.formatDateTime(DateTime.parse(income.date))),
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
