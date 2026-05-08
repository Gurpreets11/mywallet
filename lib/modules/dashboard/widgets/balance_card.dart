import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;

  const BalanceCard({
    super.key,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3949AB),
            Color(0xFF1E88E5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            CurrencyUtils.formatAmount(
              totalBalance,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}