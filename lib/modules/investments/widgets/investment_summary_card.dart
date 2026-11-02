import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../utils/investment_utils.dart';

class InvestmentSummaryCard extends StatelessWidget {
  final double investedAmount;
  final double currentValue;
  const InvestmentSummaryCard({super.key, required this.investedAmount, required this.currentValue});

  @override
  Widget build(BuildContext context) {
    final profit = InvestmentUtils.calculateProfit(investedAmount: investedAmount, currentValue: currentValue);
    final roi = InvestmentUtils.calculateRoi(investedAmount: investedAmount, currentValue: currentValue);
    final positive = profit >= 0;
    final color = positive ? Colors.green : Colors.red;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Portfolio overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text(CurrencyUtils.formatAmount(currentValue), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(children: [Icon(positive ? Icons.trending_up : Icons.trending_down, size: 18, color: color), const SizedBox(width: 5), Text('${CurrencyUtils.formatAmount(profit.abs())} (${roi.toStringAsFixed(2)}%) ${positive ? 'gain' : 'loss'}', style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _Metric(label: 'Invested amount', value: CurrencyUtils.formatAmount(investedAmount))), const SizedBox(width: 12), Expanded(child: _Metric(label: 'Current value', value: CurrencyUtils.formatAmount(currentValue)))]),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label; final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]);
}
