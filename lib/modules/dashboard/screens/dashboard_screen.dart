import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_button.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/analytics_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/loan_summary_card.dart';
import '../widgets/monthly_expense_chart.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_transaction_card.dart';
import '../widgets/section_title.dart';
import '../widgets/summary_card.dart';
import '../widgets/upcoming_emi_card.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 4),

              const Text(
                'My Wallet',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

          CommonButton(
            text: 'Save Expense',
            onPressed: () async {


              await NotificationService
                  .instance
                  .showInstantNotification(
                id: 1,
                title: 'Expense Reminder',
                body:
                'Don’t forget to track today’s expenses',
              );




            },
          ),


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
                    onTap: () {},
                  ),

                  const SizedBox(width: 12),

                  QuickActionCard(
                    title: 'Add Income',
                    icon: Icons.payments,
                    onTap: () {},
                  ),
                ],
              ),


              const SizedBox(height: 28),

              const SectionTitle(title: 'Loan Summary'),

              const SizedBox(height: 16),

              LoanSummaryCard(
                totalOutstanding:
                provider
                    .totalOutstandingLoan,

                totalPaid:
                provider.totalLoanPaid,

                activeLoans:
                provider.activeLoanCount,

                closedLoans:
                provider.closedLoanCount,
              ),

              const SizedBox(height: 16),
              UpcomingEmiCard(
                loan:
                provider.upcomingLoan,
              ),

              const SizedBox(height: 28),

              const SectionTitle(title: 'Recent Transactions'),

              const SizedBox(height: 16),

              const RecentTransactionCard(
                title: 'Food',
                subtitle: 'Cash Payment',
                amount: 250,
                isExpense: true,
              ),

              const RecentTransactionCard(
                title: 'Salary',
                subtitle: 'Bank Transfer',
                amount: 50000,
                isExpense: false,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
