import 'package:flutter/material.dart';
import 'package:mywallet/core/utils/date_utils.dart';

import '../../../core/utils/currency_utils.dart';
import '../models/dashboard_transaction_model.dart';

class RecentTransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final String date;
  final bool isExpense;
  final TransactionKind? kind;

  const RecentTransactionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.isExpense,
    this.kind,
  });

  Color get _color {
    if (kind == TransactionKind.investment) return Colors.blue;
    return isExpense ? Colors.red : Colors.green;
  }

  IconData get _icon {
    switch (kind) {
      case TransactionKind.loanEmi:
        return Icons.account_balance;
      case TransactionKind.investment:
        return Icons.trending_up;
      default:
        return isExpense ? Icons.arrow_upward : Icons.arrow_downward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(date);
    final when = parsed == null ? date : AppDateUtils.formatDateTime(parsed);
    return Card(
      color: Theme.of(context).colorScheme.surface,
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
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Icon(_icon, size: 16, color: _color),
        ),
        title: Text(title),
        subtitle: Text(subtitle.isEmpty ? when : '$subtitle - $when'),
        trailing: Text(
          CurrencyUtils.formatAmount(amount),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
