import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/loan_payment_model.dart';

class LoanPaymentCard extends StatelessWidget {
  final LoanPaymentModel payment;

  const LoanPaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.payments)),

        title: Text(CurrencyUtils.formatAmount(payment.paymentAmount)),

        subtitle: Text(
          AppDateUtils.formatDate(DateTime.parse(payment.paymentDate)),
        ),

        trailing: Text(payment.paymentMode),
      ),
    );
  }
}
