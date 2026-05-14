import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

import '../models/investment_model.dart';

class InvestmentCard extends StatelessWidget {
  final InvestmentModel investment;

  final VoidCallback onTap;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const InvestmentCard({
    super.key,
    required this.investment,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double profit = investment.currentValue - investment.investedAmount;

    final bool isProfit = profit >= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,

        leading: CircleAvatar(child: Icon(_getIcon())),

        title: Text(
          investment.investmentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(investment.investmentType),

            const SizedBox(height: 4),

            Text(
              'Invested: '
              '${CurrencyUtils.formatAmount(investment.investedAmount)}',
            ),

            Text(
              'Current: '
              '${CurrencyUtils.formatAmount(investment.currentValue)}',
            ),
          ],
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyUtils.formatAmount(profit),
              style: TextStyle(
                color: isProfit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(onTap: onEdit, child: const Text('Edit')),

                PopupMenuItem(onTap: onDelete, child: const Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (investment.investmentType) {
      case 'MUTUAL_FUND':
        return Icons.pie_chart;

      case 'STOCK':
        return Icons.show_chart;

      case 'GOLD':
        return Icons.monetization_on;

      case 'FD':
        return Icons.account_balance;

      case 'CRYPTO':
        return Icons.currency_bitcoin;

      default:
        return Icons.wallet;
    }
  }
}
