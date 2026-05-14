import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

class SipSummaryCard
    extends StatelessWidget {

  final double monthlySipTotal;

  final int totalSipCount;

  const SipSummaryCard({
    super.key,
    required this.monthlySipTotal,
    required this.totalSipCount,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Row(
              children: [

                Icon(Icons.repeat),

                SizedBox(width: 8),

                Text(
                  'SIP Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildRow(
              'Monthly SIP',
              CurrencyUtils
                  .formatAmount(
                monthlySipTotal,
              ),
            ),

            _buildRow(
              'Active SIPs',
              '$totalSipCount',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
      String title,
      String value,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,

        children: [

          Text(title),

          Text(
            value,
            style: const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}