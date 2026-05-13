import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
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
        onTap: onTap,

        leading: const CircleAvatar(
          child: Icon(Icons.payments),
        ),

        title: Text(
          CurrencyUtils.formatAmount(
            income.amount,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(income.paymentMode),

            Text(
              '${income.categoryName ?? ''}'
                  ' • '
                  '${income.subcategoryName ?? ''}',
            ),
          ],
        ),

        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit,
              ),
            ),

            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}