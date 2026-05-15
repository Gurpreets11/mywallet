import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

import '../../../core/utils/date_utils.dart';

import '../models/loan_payment_model.dart';

class LoanPaymentHistorySection extends StatelessWidget {
  final List<LoanPaymentModel> payments;

  const LoanPaymentHistorySection({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),

          child: Center(child: Text('No EMI payments yet')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Payment History',

              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            ListView.separated(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: payments.length,

              separatorBuilder: (_, __) => const Divider(),

              itemBuilder: (context, index) {
                final payment = payments[index];

                return ListTile(
                  leading: CircleAvatar(child: Icon(Icons.payment)),

                  title: Text(
                    CurrencyUtils.formatAmount(payment.paymentAmount),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(payment.paymentMode),

                      Text(
                        AppDateUtils.formatDate(
                          DateTime.parse(payment.paymentDate),
                        ),
                      ),

                      if (payment.remarks != null) Text(payment.remarks!),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
