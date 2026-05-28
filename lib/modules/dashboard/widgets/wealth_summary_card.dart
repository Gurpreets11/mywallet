import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/vertical_spacing.dart';

class WealthSummaryCard extends StatelessWidget {
  final double investedAmount;
  final double currentValue;

  const WealthSummaryCard({
    super.key,
    required this.investedAmount,
    required this.currentValue,
  });

  @override
  Widget build(BuildContext context) {
    final double profit = currentValue - investedAmount;
    final double roi = investedAmount == 0
        ? 0
        : (profit / investedAmount) * 100;
    final bool isProfit = profit >= 0;

    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.account_balance_wallet),
            SizedBox(width: 8),
            Text(
              'Wealth Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        VerticalSpacing(height: 10),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildRow(
                  'Invested',
                  CurrencyUtils.formatAmount(investedAmount),
                ),
                _buildRow(
                  'Current Value',
                  CurrencyUtils.formatAmount(currentValue),
                ),
                _buildRow(
                  'Profit/Loss',
                  CurrencyUtils.formatAmount(profit),
                  valueColor: isProfit ? Colors.green : Colors.red,
                ),
                _buildRow(
                  'ROI',
                  '${roi.toStringAsFixed(2)}%',
                  valueColor: isProfit ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}
