import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';

import '../../../core/utils/date_utils.dart';

import '../models/investment_model.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final InvestmentModel investment;

  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final double profit = investment.currentValue - investment.investedAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Detail')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  investment.investmentName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildRow('Type', investment.investmentType),

                _buildRow('Platform', investment.investmentPlatform ?? '-'),

                _buildRow(
                  'Invested',
                  CurrencyUtils.formatAmount(investment.investedAmount),
                ),

                _buildRow(
                  'Current Value',
                  CurrencyUtils.formatAmount(investment.currentValue),
                ),

                _buildRow('Profit/Loss', CurrencyUtils.formatAmount(profit)),

                _buildRow(
                  'Investment Date',
                  AppDateUtils.formatDate(
                    DateTime.parse(investment.investmentDate),
                  ),
                ),

                _buildRow('SIP', investment.isSip ? 'Yes' : 'No'),

                _buildRow('Notes', investment.notes ?? '-'),
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
        children: [
          SizedBox(
            width: 140,
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
