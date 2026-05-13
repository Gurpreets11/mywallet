import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../models/loan_model.dart';

class LoanCard extends StatelessWidget {
  final LoanModel loan;

  final VoidCallback onTap;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isBorrowed = loan.loanType == 'BORROWED';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(
          backgroundColor: isBorrowed
              ? Colors.red.shade100
              : Colors.green.shade100,
          child: Icon(
            isBorrowed ? Icons.arrow_downward : Icons.arrow_upward,
            color: isBorrowed ? Colors.red : Colors.green,
          ),
        ),

        title: Text(
          loan.personName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding: '
              '${CurrencyUtils.formatAmount(loan.outstandingAmount)}',
            ),

            Text(
              'EMI: '
              '${CurrencyUtils.formatAmount(loan.emiAmount)}',
            ),
          ],
        ),

        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: const Text('Edit'),
              onTap: onEdit,
            ),
            PopupMenuItem(
              value: 'delete',
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
