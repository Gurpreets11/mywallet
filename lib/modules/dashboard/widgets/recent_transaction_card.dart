import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

class RecentTransactionCard extends StatelessWidget {
  final String title;

  final String subtitle;

  final double amount;

  final bool isExpense;

  const RecentTransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isExpense ? Icons.arrow_upward : Icons.arrow_downward),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          CurrencyUtils.formatAmount(amount),
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
