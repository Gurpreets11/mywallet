import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/widgets/empty_view.dart';

import '../../../core/widgets/loading_view.dart';

import '../enums/investment_sort_type.dart';
import '../models/investment_model.dart';
import '../providers/investment_provider.dart';

import '../utils/investment_utils.dart';
import '../widgets/investment_analytics_card.dart';
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

    final investmentProvider = context.read<InvestmentProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      investmentProvider.loadInvestments();
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
                // SEARCH BAR (FIXED)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search investments',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: provider.updateSearchQuery,
                  ),
                ),

                // FILTER + SORT (FIXED)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: provider.selectedFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                          ),

                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),

                            DropdownMenuItem(
                              value: 'Mutual Fund',
                              child: Text('Mutual Fund'),
                            ),

                            DropdownMenuItem(
                              value: 'Stock',
                              child: Text('Stock'),
                            ),

                            DropdownMenuItem(
                              value: 'Gold',
                              child: Text('Gold'),
                            ),

                            DropdownMenuItem(value: 'FD', child: Text('FD')),

                            DropdownMenuItem(
                              value: 'SIP',
                              child: Text('SIP Only'),
                            ),
                          ],

                          onChanged: (value) {
                            provider.updateFilter(value!);
                          },
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: DropdownButtonFormField<InvestmentSortType>(
                          initialValue: provider.sortType,

                          decoration: const InputDecoration(labelText: 'Sort'),

                          items: const [
                            DropdownMenuItem(
                              value: InvestmentSortType.latest,
                              child: Text(
                                'Latest',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),

                            DropdownMenuItem(
                              value: InvestmentSortType.highestInvestment,
                              child: Text(
                                'Highest Investment',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),

                            DropdownMenuItem(
                              value: InvestmentSortType.highestProfit,
                              child: Text(
                                'Highest Profit',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),

                            DropdownMenuItem(
                              value: InvestmentSortType.highestRoi,
                              child: Text(
                                'Highest ROI',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],

                          onChanged: (value) {
                            provider.updateSortType(value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SCROLLABLE CONTENT
                Expanded(
                  child: provider.filteredInvestments.isEmpty
                      ? EmptyView(
                          icon: Icons.trending_up,

                          message: provider.searchQuery.isNotEmpty
                              ? 'No matching investments found'
                              : 'No investments added yet.',

                          actionText: 'Add Investment',

                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddInvestmentScreen(),
                              ),
                            );
                          },
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 4),

                              // ANALYTICS
                              SizedBox(
                                height: 150,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),

                                  children: [
                                    _buildAnalyticsCard(
                                      title: 'Top Performer',
                                      investment:
                                          provider.analytics.topPerformer,
                                      icon: Icons.trending_up,
                                      color: Colors.green,
                                    ),

                                    _buildAnalyticsCard(
                                      title: 'Highest ROI',
                                      investment: provider.analytics.highestRoi,
                                      icon: Icons.show_chart,
                                      color: Colors.blue,
                                    ),

                                    _buildAnalyticsCard(
                                      title: 'Highest Investment',
                                      investment:
                                          provider.analytics.highestInvestment,
                                      icon: Icons.account_balance_wallet,
                                      color: Colors.orange,
                                    ),

                                    _buildAnalyticsCard(
                                      title: 'Worst Performer',
                                      investment:
                                          provider.analytics.worstPerformer,
                                      icon: Icons.trending_down,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // SUMMARY
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),

                                child: InvestmentSummaryCard(
                                  investedAmount: investedAmount,
                                  currentValue: currentValue,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // LIST
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),

                                itemCount: provider.filteredInvestments.length,

                                itemBuilder: (context, index) {
                                  final investment =
                                      provider.filteredInvestments[index];

                                  return InvestmentCard(
                                    investment: investment,

                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              InvestmentDetailScreen(
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

                                    onDelete: () {
                                      showDialog(
                                        context: context,

                                        builder: (_) => CommonDeleteDialog(
                                          title: 'Delete Investment',

                                          message:
                                              'Are you sure you want to delete this investment?',

                                          onConfirm: () async {
                                            await provider.deleteInvestment(
                                              investment.id!,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),

                              const SizedBox(height: 90),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required InvestmentModel? investment,
    required IconData icon,
    required Color color,
  }) {
    if (investment == null) {
      return const SizedBox();
    }

    final roi = InvestmentUtils.calculateRoi(
      investedAmount: investment.investedAmount,
      currentValue: investment.currentValue,
    );

    return SizedBox(
      width: 180,

      child: InvestmentAnalyticsCard(
        title: title,
        value:
            '${investment.investmentName}\n'
            '${roi.toStringAsFixed(1)}% ROI',

        icon: icon,

        color: color,
      ),
    );
  }
}
