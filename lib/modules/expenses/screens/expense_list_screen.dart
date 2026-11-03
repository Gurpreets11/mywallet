import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/providers/master_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});
  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _searchController = TextEditingController();
  int? _categoryId;
  String? _paymentMode;
  DateTimeRange? _dateRange;
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    final provider = context.read<ExpenseProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadExpenses();
      provider.loadMonthlySummary();
      context.read<MasterProvider>().loadExpenseCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final master = context.read<MasterProvider>();
    await master.loadExpenseCategories();
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
                'Filter expenses',
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
                  ...master.expenseCategories.map(
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
                    onPressed: () {
                      setSheetState(() {
                        category = null;
                        payment = null;
                        range = null;
                      });
                    },
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

  String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  List<ExpenseModel> _visibleExpenses(List<ExpenseModel> source) {
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
      final dateA =
          DateTime.tryParse(a.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(b.date) ?? DateTime.fromMillisecondsSinceEpoch(0);
      switch (_sort) {
        case 'oldest':
          return dateA.compareTo(dateB);
        case 'highest':
          return b.amount.compareTo(a.amount);
        case 'lowest':
          return a.amount.compareTo(b.amount);
        default:
          return dateB.compareTo(dateA);
      }
    });
    return list;
  }

  Future<void> _deleteExpense(
    ExpenseProvider provider,
    ExpenseModel expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
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
    if (confirmed == true && expense.id != null) {
      await provider.deleteExpense(expense.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = _visibleExpenses(provider.filteredExpenses);
    final theme = Theme.of(context);
    final activeFilters =
        (_categoryId != null ? 1 : 0) +
        (_paymentMode != null ? 1 : 0) +
        (_dateRange != null ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Filter expenses',
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
        heroTag: 'expenses_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: AppResponsiveContent(
        maxWidth: 1050,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: context.read<ExpenseProvider>().searchExpense,
              decoration: InputDecoration(
                hintText: 'Search category, notes, payment mode or amount',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<ExpenseProvider>().searchExpense('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent this month',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            CurrencyUtils.formatAmount(
                              provider.monthlyExpenseTotal,
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${expenses.length} transactions',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(
                      value: 'highest',
                      child: Text('Highest amount'),
                    ),
                    DropdownMenuItem(
                      value: 'lowest',
                      child: Text('Lowest amount'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? 'newest'),
                ),
              ],
            ),
            if (provider.isLoading)
              const Expanded(child: LoadingView())
            else if (expenses.isEmpty)
              Expanded(
                child: EmptyView(
                  message: provider.expenses.isEmpty
                      ? 'No expenses yet'
                      : 'No expenses match your search or filters',
                  icon: Icons.receipt_long_outlined,
                  actionText: provider.expenses.isEmpty ? 'Add expense' : null,
                  onAction: provider.expenses.isEmpty
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen(),
                          ),
                        )
                      : null,
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final currentDate = DateTime.tryParse(expense.date);
                    final previousDate = index == 0
                        ? null
                        : DateTime.tryParse(expenses[index - 1].date);
                    final showHeader =
                        currentDate != null &&
                        (previousDate == null ||
                            currentDate.year != previousDate.year ||
                            currentDate.month != previousDate.month ||
                            currentDate.day != previousDate.day);
                    final label = currentDate == null
                        ? ''
                        : _dateLabel(currentDate);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                            child: Text(
                              label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ExpenseCard(
                          expense: expense,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseDetailScreen(expense: expense),
                            ),
                          ),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddExpenseScreen(expense: expense),
                            ),
                          ),
                          onDelete: () => _deleteExpense(provider, expense),
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
    return '${day.day.toString().padLeft(2, '0')} ${_month(day.month)} ${day.year}';
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
