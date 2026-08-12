import 'package:flutter/material.dart';
import 'package:mywallet/core/utils/date_utils.dart';

import '../../../core/utils/currency_utils.dart';

class RecentTransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String date;
  final bool isExpense;

  const RecentTransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 0,
        minTileHeight: 40,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.black12,
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(title),
        subtitle: Text(
          '$subtitle - ${AppDateUtils.formatDateTime(DateTime.parse(date))} ',
        ),
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
