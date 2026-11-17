import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';
import '../widgets/loan_card.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  @override
  void initState() {
    super.initState();

    final loanProvider = context.read<LoanProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loanProvider.loadLoans();
    });
  }

  Future<void> _confirmDelete(LoanProvider provider, LoanModel loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text(
          '"${loan.personName}" and its details will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && loan.id != null) {
      await provider.deleteLoan(loan.id!);
    }
  }

  Widget _summaryCard(LoanProvider provider) {
    final theme = Theme.of(context);
    final loans = provider.loans;
    final active = loans
        .where((l) => l.loanStatus.toUpperCase() != 'CLOSED')
        .toList();
    final overdue = loans
        .where((l) => l.loanStatus.toUpperCase() == 'OVERDUE')
        .length;
    final monthlyEmi = active.fold<double>(0, (sum, l) => sum + l.emiAmount);

    Widget mini(String label, String value, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total outstanding',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              CurrencyUtils.formatAmount(provider.totalOutstanding),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              children: [
                mini('Active loans', '${active.length}'),
                mini('Monthly EMI', CurrencyUtils.formatAmount(monthlyEmi)),
                mini(
                  'Overdue',
                  '$overdue',
                  color: overdue > 0 ? Colors.red : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoanProvider>();
    final loans = provider.loans;

    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),

      floatingActionButton: FloatingActionButton(
        heroTag: 'loans_fab',
        tooltip: 'Add loan',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLoanScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: provider.isLoading
          ? const LoadingView()
          : loans.isEmpty
          ? EmptyView(
              message: 'No loans found',
              icon: Icons.account_balance_outlined,
              actionText: 'Add loan',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddLoanScreen()),
              ),
            )
          : AppResponsiveContent(
              maxWidth: 1050,
              // Padding is applied inside the list so it never clips content.
              padding: EdgeInsets.zero,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                itemCount: loans.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _summaryCard(provider),
                    );
                  }
                  final loan = loans[index - 1];
                  return LoanCard(
                    loan: loan,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoanDetailScreen(loan: loan),
                      ),
                    ),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddLoanScreen(loan: loan),
                      ),
                    ),
                    onDelete: () => _confirmDelete(provider, loan),
                  );
                },
              ),
            ),
    );
  }
}
