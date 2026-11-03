import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../constant/investment_constants.dart';
import '../enums/investment_sort_type.dart';
import '../models/investment_model.dart';
import '../providers/investment_provider.dart';
import '../widgets/investment_card.dart';
import '../widgets/investment_summary_card.dart';
import 'add_investment_screen.dart';
import 'investment_detail_screen.dart';

class InvestmentListScreen extends StatefulWidget {
  const InvestmentListScreen({super.key});
  @override
  State<InvestmentListScreen> createState() => _InvestmentListScreenState();
}

class _InvestmentListScreenState extends State<InvestmentListScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<InvestmentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) => provider.loadInvestments());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();
    final invested = provider.investments.fold<double>(0, (sum, e) => sum + e.investedAmount);
    final current = provider.investments.fold<double>(0, (sum, e) => sum + e.currentValue);
    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),
      floatingActionButton: FloatingActionButton.extended(
          heroTag: 'investment_fab',
          onPressed: _addInvestment, icon: const Icon(Icons.add), label: const Text('Add')),
      body: provider.isLoading ? const LoadingView() : LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final contentWidth = constraints.maxWidth > 1200 ? 1120.0 : constraints.maxWidth;
        return Center(child: SizedBox(width: contentWidth, child: RefreshIndicator(
          onRefresh: provider.loadInvestments,
          child: ListView(padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 100), children: [
            InvestmentSummaryCard(investedAmount: invested, currentValue: current),
            const SizedBox(height: 18),
            _allocationSection(provider.investments),
            const SizedBox(height: 18),
            TextField(onChanged: provider.updateSearchQuery, decoration: const InputDecoration(hintText: 'Search name or platform', prefixIcon: Icon(Icons.search), isDense: true)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 8, children: [
              SizedBox(width: wide ? 220 : (constraints.maxWidth - 42) / 2, child: DropdownButtonFormField<String>(value: provider.selectedFilter, isExpanded: true, decoration: const InputDecoration(labelText: 'Investment type', isDense: true), items: const [DropdownMenuItem(value: 'All', child: Text('All types')), DropdownMenuItem(value: InvestmentConstants.mutualFund, child: Text('Mutual Fund')), DropdownMenuItem(value: InvestmentConstants.stock, child: Text('Stock')), DropdownMenuItem(value: InvestmentConstants.gold, child: Text('Gold')), DropdownMenuItem(value: InvestmentConstants.fd, child: Text('Fixed Deposit')), DropdownMenuItem(value: InvestmentConstants.crypto, child: Text('Crypto')), DropdownMenuItem(value: 'SIP', child: Text('SIP only'))], onChanged: (v) { if (v != null) provider.updateFilter(v); })),
              SizedBox(width: wide ? 220 : (constraints.maxWidth - 42) / 2, child: DropdownButtonFormField<InvestmentSortType>(value: provider.sortType, isExpanded: true, decoration: const InputDecoration(labelText: 'Sort by', isDense: true), items: const [DropdownMenuItem(value: InvestmentSortType.latest, child: Text('Latest')), DropdownMenuItem(value: InvestmentSortType.highestInvestment, child: Text('Highest invested')), DropdownMenuItem(value: InvestmentSortType.highestProfit, child: Text('Highest profit')), DropdownMenuItem(value: InvestmentSortType.highestRoi, child: Text('Highest ROI'))], onChanged: (v) { if (v != null) provider.updateSortType(v); }))
            ]),
            const SizedBox(height: 18),
            Row(children: [Text('Your investments', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)), const Spacer(), Text('${provider.filteredInvestments.length} records', style: Theme.of(context).textTheme.bodySmall)]),
            const SizedBox(height: 8),
            if (provider.filteredInvestments.isEmpty) SizedBox(height: 260, child: EmptyView(icon: Icons.trending_up, message: provider.searchQuery.isNotEmpty || provider.selectedFilter != 'All' ? 'No matching investments found' : 'No investments added yet.', actionText: 'Add Investment', onAction: _addInvestment))
            else if (wide) _wideList(provider.filteredInvestments, provider)
            else ...provider.filteredInvestments.map((investment) => InvestmentCard(investment: investment, onTap: () => _openDetails(investment), onEdit: () => _editInvestment(investment), onDelete: () => _deleteInvestment(investment, provider))),
          ]),
        )));
      }),
    );
  }

  Widget _allocationSection(List<InvestmentModel> investments) {
    if (investments.isEmpty) return const SizedBox.shrink();
    final totals = <String, double>{};
    for (final item in investments) { totals[item.investmentType] = (totals[item.investmentType] ?? 0) + item.currentValue; }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    return Card(margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      const Text('Portfolio allocation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),

      const SizedBox(height: 12),

      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 10,
          child: Row(
            children: <Widget>[
              for (final e in entries)
                Expanded(
                  flex: (e.value * 1000 / (total == 0 ? 1 : total))
                      .round()
                      .clamp(1, 1000),
                  child: Container(
                    color: _typeColor(e.key),
                  ),
                ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 12),
      Wrap(spacing: 14, runSpacing: 8, children: entries.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: _typeColor(e.key), shape: BoxShape.circle)), const SizedBox(width: 5), Text('${_typeName(e.key)} ${(e.value * 100 / (total == 0 ? 1 : total)).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12))])).toList()),
    ])));
  }

  Widget _wideList(List<InvestmentModel> items, InvestmentProvider provider) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 460, mainAxisExtent: 190, crossAxisSpacing: 12, mainAxisSpacing: 4), itemBuilder: (_, i) { final item = items[i]; return InvestmentCard(investment: item, onTap: () => _openDetails(item), onEdit: () => _editInvestment(item), onDelete: () => _deleteInvestment(item, provider)); });

  Color _typeColor(String type) { switch (type) { case InvestmentConstants.mutualFund: return Colors.indigo; case InvestmentConstants.stock: return Colors.blue; case InvestmentConstants.gold: return Colors.amber.shade700; case InvestmentConstants.fd: return Colors.teal; case InvestmentConstants.crypto: return Colors.deepPurple; default: return Colors.grey; } }
  String _typeName(String type) => type.replaceAll('_', ' ');
  void _addInvestment() => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen()));
  void _editInvestment(InvestmentModel item) => Navigator.push(context, MaterialPageRoute(builder: (_) => AddInvestmentScreen(investment: item)));
  void _openDetails(InvestmentModel item) => Navigator.push(context, MaterialPageRoute(builder: (_) => InvestmentDetailScreen(investment: item)));
  void _deleteInvestment(InvestmentModel item, InvestmentProvider provider) => showDialog(context: context, builder: (_) => CommonDeleteDialog(title: 'Delete Investment', message: 'Are you sure you want to delete this investment?', onConfirm: () async { if (item.id != null) await provider.deleteInvestment(item.id!); }));
}
