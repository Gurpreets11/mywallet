import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../investments/models/investment_model.dart';


class UpcomingSipCard extends StatelessWidget {
  final List<InvestmentModel> upcomingSips;

  const UpcomingSipCard({super.key, required this.upcomingSips});

  @override
  Widget build(BuildContext context) {
    if (upcomingSips.isEmpty) {
      return const SizedBox();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Row(
              children: [
                Icon(Icons.schedule),

                SizedBox(width: 8),

                Text(
                  'Upcoming SIPs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...upcomingSips.map((sip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          sip.investmentName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text(
                          'SIP Date: '
                          '${sip.sipDate}',
                        ),
                      ],
                    ),

                    Text(
                      CurrencyUtils.formatAmount(sip.sipAmount ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
