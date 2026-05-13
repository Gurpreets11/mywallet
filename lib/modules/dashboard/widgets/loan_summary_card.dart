import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance),

                SizedBox(width: 8),

                Text(
                  'Loan Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildRow(
              'Outstanding',
              CurrencyUtils.formatAmount(totalOutstanding),
            ),

            _buildRow('Paid Amount', CurrencyUtils.formatAmount(totalPaid)),

            _buildRow('Active Loans', activeLoans.toString()),

            _buildRow('Closed Loans', closedLoans.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
