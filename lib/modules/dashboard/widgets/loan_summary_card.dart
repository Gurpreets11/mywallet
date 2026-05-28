import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/vertical_spacing.dart';

class LoanSummaryCard extends StatelessWidget {
  final double totalOutstanding;
  final double totalPaid;
  final int activeLoans;
  final int closedLoans;

  const LoanSummaryCard({
    super.key,
    required this.totalOutstanding,
    required this.totalPaid,
    required this.activeLoans,
    required this.closedLoans,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        const Row(
          children: [
            Icon(Icons.account_balance),
            SizedBox(width: 8),
            Text(
              'Loan Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        VerticalSpacing(height: 10),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Outstanding', CurrencyUtils.formatAmount(totalOutstanding),),
                _buildRow('Paid Amount', CurrencyUtils.formatAmount(totalPaid)),
                _buildRow('Active Loans', activeLoans.toString()),
                _buildRow('Closed Loans', closedLoans.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
