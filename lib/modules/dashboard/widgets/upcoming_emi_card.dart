import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../loans/models/loan_model.dart';

class UpcomingEmiCard extends StatelessWidget {
  final LoanModel? loan;

  const UpcomingEmiCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    if (loan == null) {
      return const SizedBox();
    }

    final DateTime emiDate = DateTime.parse(loan!.nextEmiDate!);

    final int daysLeft = emiDate.difference(DateTime.now()).inDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.alarm),

                SizedBox(width: 8),

                Text(
                  'Upcoming EMI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              CurrencyUtils.formatAmount(loan!.emiAmount),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(loan!.personName, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 10),

            Text(
              'Due on '
              '${AppDateUtils.formatDate(emiDate)}',
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: daysLeft <= 3
                    ? Colors.red.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$daysLeft days remaining',
                style: TextStyle(
                  color: daysLeft <= 3 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
