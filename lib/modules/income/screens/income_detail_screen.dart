import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/income_model.dart';

class IncomeDetailScreen extends StatelessWidget {
  final IncomeModel income;

  const IncomeDetailScreen({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.formatAmount(income.amount),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildRow('Category', income.categoryName ?? '-'),

                _buildRow('Subcategory', income.subcategoryName ?? '-'),

                _buildRow('Payment Mode', income.paymentMode),

                _buildRow(
                  'Date',
                  AppDateUtils.formatDate(DateTime.parse(income.date)),
                ),

                _buildRow('Recurring', income.isRecurring ? 'Yes' : 'No'),

                if (income.isRecurring)
                  _buildRow('Recurring Type', income.recurringType ?? '-'),

                _buildRow('Notes', income.notes ?? '-'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
