import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../models/investment_model.dart';
import '../utils/investment_utils.dart';

class InvestmentCard extends StatelessWidget {
  final InvestmentModel investment;
  final VoidCallback onTap, onEdit, onDelete;
  const InvestmentCard({super.key, required this.investment, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final profit = InvestmentUtils.calculateProfit(investedAmount: investment.investedAmount, currentValue: investment.currentValue);
    final roi = InvestmentUtils.calculateRoi(investedAmount: investment.investedAmount, currentValue: investment.currentValue);
    final positive = profit >= 0;
    final color = positive ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(_typeIcon(investment.investmentType), color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(investment.investmentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 3), Text('${_typeLabel(investment.investmentType)}${investment.investmentPlatform?.isNotEmpty == true ? ' • ${investment.investmentPlatform}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)])),
          if (investment.isSip) const Padding(padding: EdgeInsets.only(right: 4), child: Chip(label: Text('SIP'), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero)),
          PopupMenuButton<String>(tooltip: 'Investment actions', onSelected: (v) => v == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]),
        ]),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _Value(label: 'Current value', value: CurrencyUtils.formatAmount(investment.currentValue))), Expanded(child: _Value(label: 'Invested', value: CurrencyUtils.formatAmount(investment.investedAmount)))]),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(positive ? Icons.trending_up : Icons.trending_down, size: 17, color: color), const SizedBox(width: 6), Text('${CurrencyUtils.formatAmount(profit.abs())} ${positive ? 'gain' : 'loss'}', style: TextStyle(color: color, fontWeight: FontWeight.w600)), const Spacer(), Text('${roi.toStringAsFixed(2)}% ROI', style: TextStyle(color: color, fontWeight: FontWeight.w600))])),
      ]))),
    );
  }
  IconData _typeIcon(String type) { switch (type) { case 'MUTUAL_FUND': return Icons.pie_chart_outline; case 'STOCK': return Icons.show_chart; case 'GOLD': return Icons.monetization_on_outlined; case 'FD': return Icons.account_balance_outlined; case 'CRYPTO': return Icons.currency_bitcoin; default: return Icons.savings_outlined; } }
  String _typeLabel(String type) => type.replaceAll('_', ' ').toLowerCase().split(' ').map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}').join(' ');
}
class _Value extends StatelessWidget {
  final String label, value;
  const _Value({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))]);
}
