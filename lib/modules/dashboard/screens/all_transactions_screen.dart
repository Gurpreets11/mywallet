import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/dashboard_transaction_model.dart';
import '../repositories/transaction_feed_repository.dart';
import '../widgets/recent_transaction_card.dart';

/// Every transaction (expenses, income, loan EMIs, investments) grouped by
/// day, newest first, with a type filter.
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _DayHeader {
  final String label;
  final int count;
  const _DayHeader(this.label, this.count);
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _repository = TransactionFeedRepository();

  List<DashboardTransactionModel> _all = [];
  TransactionKind? _filter; // null = all
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repository.getAll();
      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load transactions';
      });
    }
  }

  static const _filters = <(String, TransactionKind?)>[
    ('All', null),
    ('Expenses', TransactionKind.expense),
    ('Income', TransactionKind.income),
    ('Loan EMI', TransactionKind.loanEmi),
    ('Investments', TransactionKind.investment),
  ];

  String _dayLabel(DateTime? d) {
    if (d == null) return 'Unknown date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return AppDateUtils.formatDate(d);
  }

  /// Flattens the (already newest-first) list into day headers + rows.
  List<Object> _buildItems(List<DashboardTransactionModel> txns) {
    final items = <Object>[];
    var i = 0;
    while (i < txns.length) {
      final label = _dayLabel(txns[i].dateTime);
      var j = i;
      while (j < txns.length && _dayLabel(txns[j].dateTime) == label) {
        j++;
      }
      items.add(_DayHeader(label, j - i));
      items.addAll(txns.sublist(i, j));
      i = j;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filter == null
        ? _all
        : _all.where((t) => t.kind == _filter).toList();
    final items = _buildItems(filtered);

    var moneyIn = 0.0;
    var moneyOut = 0.0;
    for (final t in filtered) {
      if (t.isExpense) {
        moneyOut += t.amount;
      } else {
        moneyIn += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: AppResponsiveContent(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, kind) = _filters[i];
                  return ChoiceChip(
                    label: Text(label),
                    selected: _filter == kind,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _filter = kind),
                  );
                },
              ),
            ),
            if (!_loading && _error == null && filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} transactions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'In ${CurrencyUtils.formatAmount(moneyIn)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Out ${CurrencyUtils.formatAmount(moneyOut)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildBody(theme, items, filtered.isEmpty)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, List<Object> items, bool empty) {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return EmptyView(
        icon: Icons.error_outline,
        message: _error!,
        actionText: 'Retry',
        onAction: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }
    if (empty) {
      return const EmptyView(
        icon: Icons.receipt_long,
        message: 'No transactions found',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (item is _DayHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.count}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          final txn = item as DashboardTransactionModel;
          return RecentTransactionCard(
            title: txn.title,
            subtitle: txn.subtitle,
            amount: txn.amount,
            date: txn.date,
            isExpense: txn.isExpense,
            kind: txn.kind,
          );
        },
      ),
    );
  }
}
