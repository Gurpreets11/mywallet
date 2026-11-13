import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/master_provider.dart';
import '../../modules/budgets/providers/budget_provider.dart';
import '../../modules/dashboard/providers/dashboard_provider.dart';
import '../../modules/expenses/providers/expense_provider.dart';
import '../../modules/income/providers/income_provider.dart';
import '../../modules/investments/providers/investment_provider.dart';
import '../../modules/loans/providers/loan_provider.dart';
import '../../modules/recurring/providers/recurring_provider.dart';
import '../../modules/reports/providers/report_provider.dart';

/// Reloads every provider so open screens show current database content
/// (after a restore, a reset, or a display-format change).
class AppDataRefresher {
  AppDataRefresher._();

  static Future<void> refreshAll(BuildContext context) async {
    // Read providers before the first await so no context is used afterwards.
    final master = context.read<MasterProvider>();
    final expenses = context.read<ExpenseProvider>();
    final income = context.read<IncomeProvider>();
    final loans = context.read<LoanProvider>();
    final investments = context.read<InvestmentProvider>();
    final budgets = context.read<BudgetProvider>();
    final recurring = context.read<RecurringProvider>();
    final reports = context.read<ReportProvider>();
    final dashboard = context.read<DashboardProvider>();

    Future<void> safe(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        debugPrint('Data refresh failed: $e');
      }
    }

    await safe(master.loadExpenseCategories);
    await safe(master.loadIncomeCategories);
    await safe(expenses.loadExpenses);
    await safe(expenses.loadMonthlySummary);
    await safe(income.loadIncomes);
    await safe(loans.loadLoans);
    await safe(investments.loadInvestments);
    await safe(budgets.load);
    await safe(() => recurring.load(generateDue: false));
    await safe(reports.load);
    await safe(dashboard.loadDashboardData);
  }
}
