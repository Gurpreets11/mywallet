import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/transaction_list_header.dart';
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final master = context.read<MasterProvider>();
    await master.loadIncomeCategories();
    if (!mounted) return;
    int? category = _categoryId;
    String? payment = _paymentMode;
    DateTimeRange? range = _dateRange;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter income',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...master.incomeCategories.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item['id'] as int,
                      child: Text(item['category_name'].toString()),
                    ),
                  ),
                ],
                onChanged: (v) => setSheetState(() => category = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: payment,
                decoration: const InputDecoration(labelText: 'Payment mode'),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All payment modes'),
                  ),
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                ],
                onChanged: (v) => setSheetState(() => payment = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: range,
                  );
                  if (picked != null) setSheetState(() => range = picked);
                },
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  range == null
                      ? 'Select date range'
                      : '${_shortDate(range!.start)} – ${_shortDate(range!.end)}',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setSheetState(() {
                      category = null;
                      payment = null;
                      range = null;
                    }),
                    child: const Text('Clear'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _categoryId = category;
                        _paymentMode = payment;
                        _dateRange = range;
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  List<IncomeModel> _visibleIncomes(List<IncomeModel> source) {
    final list = source.where((e) {
      final date = DateTime.tryParse(e.date);
      if (_categoryId != null && e.categoryId != _categoryId) return false;
      if (_paymentMode != null && e.paymentMode != _paymentMode) return false;
      if (_dateRange != null &&
          (date == null ||
              date.isBefore(
                DateTime(
                  _dateRange!.start.year,
                  _dateRange!.start.month,
                  _dateRange!.start.day,
                ),
              ) ||
              date.isAfter(
                DateTime(
                  _dateRange!.end.year,
                  _dateRange!.end.month,
                  _dateRange!.end.day,
                  23,
                  59,
                  59,
                ),
              ))) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      final da =
          DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      switch (_sort) {
        case 'oldest':
          return da.compareTo(db);
        case 'highest':
          return b.amount.compareTo(a.amount);
        case 'lowest':
          return a.amount.compareTo(b.amount);
        default:
          return db.compareTo(da);
      }
    });
    return list;
  }

  Future<void> _deleteIncome(
    IncomeProvider provider,
    IncomeModel income,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete income?'),
        content: const Text('This transaction will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && income.id != null) {
      await provider.deleteIncome(income.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncomeProvider>();
    final incomes = _visibleIncomes(provider.filteredIncomes);
    final theme = Theme.of(context);
    final activeFilters =
        (_categoryId != null ? 1 : 0) +
        (_paymentMode != null ? 1 : 0) +
        (_dateRange != null ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
            tooltip: 'Filter income',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'income_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add income'),
      ),
      body: AppResponsiveContent(
        maxWidth: 1050,
        // Horizontal padding only: vertical padding outside a scroll view
        // clips the list, so spacing is applied inside the scroll view.
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TransactionListHeader(
                searchController: _searchController,
                onSearchChanged: context.read<IncomeProvider>().searchIncome,
                onSearchCleared: () {
                  _searchController.clear();
                  context.read<IncomeProvider>().searchIncome('');
                },
                summaryLabel: 'Received this month',
                summaryAmount: CurrencyUtils.formatAmount(provider.monthlyIncome),
                summaryIcon: Icons.south_west_rounded,
                summaryIconColor: theme.colorScheme.onPrimaryContainer,
                summaryIconBackground: theme.colorScheme.primaryContainer,
                countText: '${incomes.length} transactions',
                sortValue: _sort,
                onSortChanged: (v) => setState(() => _sort = v),
              ),
            ),
            if (provider.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingView(),
              )
            else if (incomes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyView(
                  message: provider.incomes.isEmpty
                      ? 'No income records yet'
                      : 'No income matches your search or filters',
                  icon: Icons.payments_outlined,
                  actionText: provider.incomes.isEmpty ? 'Add income' : null,
                  onAction: provider.incomes.isEmpty
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddIncomeScreen(),
                          ),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                // Room for the floating button under the last item.
                padding: const EdgeInsets.only(bottom: 88),
                sliver: SliverList.builder(
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    // Date headings only make sense when sorted by date.
                    final groupByDate = _sort == 'newest' || _sort == 'oldest';
                    final currentDate = DateTime.tryParse(income.date);
                    final previousDate = index == 0
                        ? null
                        : DateTime.tryParse(incomes[index - 1].date);
                    final showHeader =
                        groupByDate &&
                        currentDate != null &&
                        (previousDate == null ||
                            currentDate.year != previousDate.year ||
                            currentDate.month != previousDate.month ||
                            currentDate.day != previousDate.day);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                            child: Text(
                              _dateLabel(currentDate!),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        IncomeCard(
                          income: income,
                          showDate: !groupByDate,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncomeDetailScreen(income: income),
                            ),
                          ),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddIncomeScreen(income: income),
                            ),
                          ),
                          onDelete: () => _deleteIncome(provider, income),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${day.day.toString().padLeft(2, '0')} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][day.month - 1]} ${day.year}';
  }
}
