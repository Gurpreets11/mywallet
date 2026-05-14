import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/widgets/empty_view.dart';

import '../../../core/widgets/loading_view.dart';

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

    Future.microtask(() {
      context.read<InvestmentProvider>().loadInvestments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvestmentProvider>();

    final double investedAmount = provider.investments.fold(
      0,
      (sum, item) => sum + item.investedAmount,
    );

    final double currentValue = provider.investments.fold(
      0,
      (sum, item) => sum + item.currentValue,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Investments')),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: provider.isLoading
          ? const LoadingView()
          : Column(
              children: [
                InvestmentSummaryCard(
                  investedAmount: investedAmount,

                  currentValue: currentValue,
                ),

                Expanded(
                  child: provider.investments.isEmpty
                      ? const EmptyView(message: 'No investments found')
                      : ListView.builder(
                          itemCount: provider.investments.length,

                          itemBuilder: (context, index) {
                            final investment = provider.investments[index];

                            return InvestmentCard(
                              investment: investment,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InvestmentDetailScreen(
                                      investment: investment,
                                    ),
                                  ),
                                );
                              },

                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddInvestmentScreen(
                                      investment: investment,
                                    ),
                                  ),
                                );
                              },

                              onDelete: () async {
                                await provider.deleteInvestment(investment.id!);
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
