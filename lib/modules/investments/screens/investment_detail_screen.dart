import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/investment_model.dart';
import '../utils/investment_utils.dart';

class InvestmentDetailScreen extends StatelessWidget {
  final InvestmentModel investment;
  const InvestmentDetailScreen({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final profit = InvestmentUtils.calculateProfit(investedAmount: investment.investedAmount, currentValue: investment.currentValue);
    final roi = InvestmentUtils.calculateRoi(investedAmount: investment.investedAmount, currentValue: investment.currentValue);
    final positive = profit >= 0;
    final color = positive ? Colors.green : Colors.red;
    return Scaffold(appBar: AppBar(title: const Text('Investment details')), body: LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth > 760 ? 680.0 : constraints.maxWidth;
      return Center(child: SizedBox(width: width, child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(investment.investmentName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), Text(investment.investmentType.replaceAll('_', ' '), style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20), Text('Current value', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4), Text(CurrencyUtils.formatAmount(investment.currentValue), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Row(children: [Icon(positive ? Icons.trending_up : Icons.trending_down, color: color, size: 18), const SizedBox(width: 5), Text('${CurrencyUtils.formatAmount(profit.abs())} (${roi.toStringAsFixed(2)}%) ${positive ? 'gain' : 'loss'}', style: TextStyle(color: color, fontWeight: FontWeight.w600))]),
          const SizedBox(height: 18), const Divider(),
          _row(context, 'Invested amount', CurrencyUtils.formatAmount(investment.investedAmount)),
          _row(context, 'Platform / Broker', investment.investmentPlatform ?? '-'),
          _row(context, 'Investment date', _date(investment.investmentDate)),
          _row(context, 'SIP', investment.isSip ? 'Yes' : 'No'),
          if (investment.isSip) ...[_row(context, 'SIP amount', investment.sipAmount == null ? '-' : CurrencyUtils.formatAmount(investment.sipAmount!)), _row(context, 'SIP date', investment.sipDate?.toString() ?? '-')],
          if (investment.quantity != null) _row(context, 'Quantity', investment.quantity.toString()),
          if (investment.purchasePrice != null) _row(context, 'Purchase price', CurrencyUtils.formatAmount(investment.purchasePrice!)),
          if (investment.currentPrice != null) _row(context, 'Current price', CurrencyUtils.formatAmount(investment.currentPrice!)),
          if (investment.maturityDate != null) _row(context, 'Maturity date', _date(investment.maturityDate!)),
          if (investment.interestRate != null) _row(context, 'Interest rate', '${investment.interestRate}%'),
          if (investment.notes?.trim().isNotEmpty == true) _row(context, 'Notes', investment.notes!),
        ]))),
      ])));
    }));
  }
  String _date(String value) { final date = DateTime.tryParse(value); return date == null ? value : AppDateUtils.formatDate(date); }
  Widget _row(BuildContext context, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 145, child: Text(label, style: Theme.of(context).textTheme.bodySmall)), Expanded(child: Text(value, textAlign: TextAlign.end))]));
}
