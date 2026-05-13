import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
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

    Future.microtask(() {
      context.read<LoanProvider>().loadLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoanProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Loans')),

      floatingActionButton: FloatingActionButton(
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outstanding'),

                          const SizedBox(height: 8),

                          Text(
                            CurrencyUtils.formatAmount(
                              provider.totalOutstanding,
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: provider.loans.isEmpty
                      ? const EmptyView(message: 'No loans found')
                      : ListView.builder(
                          itemCount: provider.loans.length,
                          itemBuilder: (context, index) {
                            final loan = provider.loans[index];

                            return LoanCard(
                              loan: loan,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LoanDetailScreen(loan: loan),
                                  ),
                                );
                              },

                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddLoanScreen(loan: loan),
                                  ),
                                );
                              },

                              onDelete: () async {
                                await provider.deleteLoan(loan.id!);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
