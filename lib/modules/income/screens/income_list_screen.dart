import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
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
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<IncomeProvider>().loadIncomes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncomeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Income')),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
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
                          const Text(
                            'Monthly Income',
                            style: TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            CurrencyUtils.formatAmount(provider.monthlyIncome),
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
                  child: provider.incomes.isEmpty
                      ? const EmptyView(message: 'No income records found')
                      : ListView.builder(
                          itemCount: provider.incomes.length,
                          itemBuilder: (context, index) {
                            final income = provider.incomes[index];

                            return IncomeCard(
                              income: income,

                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        IncomeDetailScreen(income: income),
                                  ),
                                );
                              },

                              onEdit: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddIncomeScreen(income: income),
                                  ),
                                );
                              },

                              onDelete: () async {
                                await provider.deleteIncome(income.id!);
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
