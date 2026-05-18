import 'package:flutter/material.dart';
import 'package:mywallet/modules/expenses/screens/add_expense_screen.dart';
import 'package:mywallet/modules/income/screens/add_income_screen.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/greeting_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_card.dart';
import '../widgets/asset_allocation_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/loan_summary_card.dart';
import '../widgets/monthly_expense_chart.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/section_title.dart';
import '../widgets/sip_summary_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/upcoming_emi_card.dart';
import '../widgets/upcoming_sip_card.dart';
import '../widgets/wealth_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<DashboardProvider>().loadDashboardData();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          GreetingUtils.getGreeting(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'My Wallet',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',

                      onPressed: () async {
                        await context
                            .read<DashboardProvider>()
                            .loadDashboardData();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dashboard refreshed'),

                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                /* CommonButton(
              text: 'Save Expense',
              onPressed: () async {
                await NotificationService.instance.showInstantNotification(
                  id: 1,
                  title: 'Expense Reminder',
                  body: 'Don’t forget to track today’s expenses',
                );
              },
            ),*/
                const SizedBox(height: 28),

                BalanceCard(totalBalance: provider.totalSavings),

                const SizedBox(height: 28),

                Row(
                  children: [
                    SummaryCard(
                      title: 'Income',
                      amount: provider.totalIncome,
                      color: AppColors.income,
                      icon: Icons.arrow_downward,
                    ),

                    const SizedBox(width: 12),

                    SummaryCard(
                      title: 'Expense',
                      amount: provider.totalExpense,
                      color: AppColors.expense,
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const SectionTitle(title: 'Analytics'),

                const SizedBox(height: 16),

                const AnalyticsCard(
                  title: 'Monthly Expenses',
                  child: MonthlyExpenseChart(),
                ),
                const SizedBox(height: 28),
                const SectionTitle(title: 'Quick Actions'),

                const SizedBox(height: 16),

                Row(
                  children: [
                    QuickActionCard(
                      title: 'Add Expense',
                      icon: Icons.money_off,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    QuickActionCard(
                      title: 'Add Income',
                      icon: Icons.payments,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddIncomeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const SectionTitle(title: 'Loan Summary'),

                const SizedBox(height: 16),

                LoanSummaryCard(
                  totalOutstanding: provider.totalOutstandingLoan,

                  totalPaid: provider.totalLoanPaid,

                  activeLoans: provider.activeLoanCount,

                  closedLoans: provider.closedLoanCount,
                ),

                const SizedBox(height: 16),
                UpcomingEmiCard(loan: provider.upcomingLoan),

                const SizedBox(height: 28),

                WealthSummaryCard(
                  investedAmount: provider.totalInvestedAmount,

                  currentValue: provider.totalInvestmentValue,
                ),
                const SizedBox(height: 16),
                AssetAllocationCard(allocations: provider.assetAllocation),

                const SizedBox(height: 16),
                SipSummaryCard(
                  monthlySipTotal: provider.monthlySipTotal,

                  totalSipCount: provider.upcomingSips.length,
                ),
                const SizedBox(height: 16),
                UpcomingSipCard(upcomingSips: provider.upcomingSips),

                const SizedBox(height: 28),

                const SectionTitle(title: 'Recent Transactions'),

                const SizedBox(height: 16),

                Consumer<DashboardProvider>(
                  builder: (context, provider, _) {
                    if (provider.recentTransactions.isEmpty) {
                      return const EmptyView(
                        icon: Icons.receipt_long,
                        message: 'No recent transactions',
                      );
                    }

                    return Column(
                      children: provider.recentTransactions
                          .map(
                            (txn) => RecentTransactionCard(
                              title: txn.title,

                              subtitle: txn.subtitle,

                              amount: txn.amount,

                              isExpense: txn.isExpense,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
