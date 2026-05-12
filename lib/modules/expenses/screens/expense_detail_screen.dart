import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/expense_model.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.formatAmount(expense.amount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Text('Payment Mode: ${expense.paymentMode}'),

                const SizedBox(height: 8),
                Text(
                  'Category'
                  ' • '
                  '${expense.categoryName ?? ''}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Subcategory'
                  ' • '
                  '${expense.subcategoryName ?? ''}',
                ),
                const SizedBox(height: 8),
                Text('Date: ${AppDateUtils.formatDate(DateTime.parse(expense.date))}',),

                const SizedBox(height: 8),

                Text('Notes: ${expense.notes ?? '-'}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
