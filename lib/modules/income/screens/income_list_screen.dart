import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/providers/master_provider.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';
import '../widgets/income_card.dart';
import 'add_income_screen.dart';
import 'income_detail_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});
  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final _searchController = TextEditingController();
  int? _categoryId;
  String? _paymentMode;
  DateTimeRange? _dateRange;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<IncomeProvider>().loadIncomes();
      context.read<MasterProvider>().loadIncomeCategories();
    });
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _openFilters() async {
    final master = context.read<MasterProvider>();
    await master.loadIncomeCategories();
    if (!mounted) return;
    int? category = _categoryId;
    String? payment = _paymentMode;
    DateTimeRange? range = _dateRange;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Filter income', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: [const DropdownMenuItem<int?>(value: null, child: Text('All categories')), ...master.incomeCategories.map((item) => DropdownMenuItem<int?>(value: item['id'] as int, child: Text(item['category_name'].toString())))], onChanged: (v) => setSheetState(() => category = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(value: payment, decoration: const InputDecoration(labelText: 'Payment mode'), items: const [DropdownMenuItem<String?>(value: null, child: Text('All payment modes')), DropdownMenuItem(value: 'Cash', child: Text('Cash')), DropdownMenuItem(value: 'UPI', child: Text('UPI')), DropdownMenuItem(value: 'Card', child: Text('Card')), DropdownMenuItem(value: 'Bank', child: Text('Bank'))], onChanged: (v) => setSheetState(() => payment = v)),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () async { final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: range); if (picked != null) setSheetState(() => range = picked); }, icon: const Icon(Icons.calendar_month), label: Text(range == null ? 'Select date range' : '${_shortDate(range!.start)} – ${_shortDate(range!.end)}')),
          const SizedBox(height: 18),
          Row(children: [TextButton(onPressed: () => setSheetState(() { category = null; payment = null; range = null; }), child: const Text('Clear')), const Spacer(), FilledButton(onPressed: () { setState(() { _categoryId = category; _paymentMode = payment; _dateRange = range; }); Navigator.pop(sheetContext); }, child: const Text('Apply filters'))]),
        ]),
      )),
    );
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  List<IncomeModel> _visibleIncomes(List<IncomeModel> source) {
    final list = source.where((e) {
      final date = DateTime.tryParse(e.date);
      if (_categoryId != null && e.categoryId != _categoryId) return false;
      if (_paymentMode != null && e.paymentMode != _paymentMode) return false;
      if (_dateRange != null && (date == null || date.isBefore(DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day)) || date.isAfter(DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59)))) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      switch (_sort) { case 'oldest': return da.compareTo(db); case 'highest': return b.amount.compareTo(a.amount); case 'lowest': return a.amount.compareTo(b.amount); default: return db.compareTo(da); }
    });
    return list;
  }

  Future<void> _deleteIncome(IncomeProvider provider, IncomeModel income) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete income?'), content: const Text('This transaction will be permanently deleted.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirmed == true && income.id != null) await provider.deleteIncome(income.id!);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncomeProvider>();
    final incomes = _visibleIncomes(provider.filteredIncomes);
    final theme = Theme.of(context);
    final activeFilters = (_categoryId != null ? 1 : 0) + (_paymentMode != null ? 1 : 0) + (_dateRange != null ? 1 : 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Income'), actions: [IconButton(tooltip: 'Filter income', onPressed: _openFilters, icon: Badge(isLabelVisible: activeFilters > 0, label: Text('$activeFilters'), child: const Icon(Icons.tune)))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomeScreen())), icon: const Icon(Icons.add), label: const Text('Add income')),
      body: provider.isLoading ? const LoadingView() : AppResponsiveContent(maxWidth: 1050, padding: const EdgeInsets.fromLTRB(16, 8, 16, 88), child: Column(children: [
        TextField(controller: _searchController, onChanged: context.read<IncomeProvider>().searchIncome, decoration: InputDecoration(hintText: 'Search category, notes, payment mode or amount', prefixIcon: const Icon(Icons.search), suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); context.read<IncomeProvider>().searchIncome(''); }, icon: const Icon(Icons.close)), filled: true)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Received this month', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(height: 6), Text(CurrencyUtils.formatAmount(provider.monthlyIncome), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))])), Container(width: 44, height: 44, decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.south_west_rounded, color: theme.colorScheme.onPrimaryContainer))]))),
        const SizedBox(height: 8),
        Row(children: [Text('${incomes.length} transactions', style: theme.textTheme.titleSmall), const Spacer(), DropdownButton<String>(value: _sort, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'newest', child: Text('Newest')), DropdownMenuItem(value: 'oldest', child: Text('Oldest')), DropdownMenuItem(value: 'highest', child: Text('Highest amount')), DropdownMenuItem(value: 'lowest', child: Text('Lowest amount'))], onChanged: (v) => setState(() => _sort = v ?? 'newest'))]),
        if (incomes.isEmpty) Expanded(child: EmptyView(message: provider.incomes.isEmpty ? 'No income records yet' : 'No income matches your search or filters', icon: Icons.payments_outlined, actionText: provider.incomes.isEmpty ? 'Add income' : null, onAction: provider.incomes.isEmpty ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomeScreen())) : null))
        else Expanded(child: ListView.builder(itemCount: incomes.length, itemBuilder: (context, index) {
          final income = incomes[index];
          final currentDate = DateTime.tryParse(income.date);
          final previousDate = index == 0 ? null : DateTime.tryParse(incomes[index - 1].date);
          final showHeader = currentDate != null && (previousDate == null || currentDate.year != previousDate.year || currentDate.month != previousDate.month || currentDate.day != previousDate.day);
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (showHeader) Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 4), child: Text(_dateLabel(currentDate), style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700))), IncomeCard(income: income, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomeDetailScreen(income: income))), onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddIncomeScreen(income: income))), onDelete: () => _deleteIncome(provider, income))]);
        })),
      ])),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now(); final today = DateTime(now.year, now.month, now.day); final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today'; if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${day.day.toString().padLeft(2, '0')} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][day.month - 1]} ${day.year}';
  }
}
