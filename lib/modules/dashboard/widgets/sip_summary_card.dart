import 'package:flutter/material.dart';
import 'package:mywallet/core/widgets/vertical_spacing.dart';

import '../../../core/utils/currency_utils.dart';

class SipSummaryCard extends StatelessWidget {
  final double monthlySipTotal;

  final int totalSipCount;

  const SipSummaryCard({
    super.key,
    required this.monthlySipTotal,
    required this.totalSipCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.repeat),
            SizedBox(width: 8),
            Text('SIP Summary',
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
                  'Monthly SIP',
                  CurrencyUtils.formatAmount(monthlySipTotal),
                ),
                _buildRow('Active SIPs', '$totalSipCount'),
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
