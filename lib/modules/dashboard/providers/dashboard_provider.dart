import 'package:flutter/material.dart';

import '../../../data/repositories/master_repository.dart';
import '../../accounts/models/account_model.dart';
import '../../accounts/repositories/account_repository.dart';
import '../../expenses/repositories/expense_repository.dart';
import '../../goals/models/savings_goal_model.dart';
import '../../goals/repositories/goal_repository.dart';
import '../../income/repositories/income_repository.dart';
import '../../investments/models/investment_model.dart';
import '../../investments/repositories/investment_repository.dart';
import '../../loans/models/loan_model.dart';
import '../../loans/repositories/loan_repository.dart';
import '../../networth/models/net_worth_models.dart';
import '../../networth/repositories/net_worth_repository.dart';
import '../models/dashboard_chart_model.dart';
import '../models/month_insights.dart';
import '../repositories/month_insights_repository.dart';
import '../models/dashboard_transaction_model.dart';
import '../repositories/transaction_feed_repository.dart';

class DashboardProvider extends ChangeNotifier {
  double _totalIncome = 0;

  double _totalExpense = 0;

  double _totalSavings = 0;

  double get totalIncome => _totalIncome;

  double get totalExpense => _totalExpense;

  double get totalSavings => _totalSavings;

  final MasterRepository _masterRepository = MasterRepository();

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final IncomeRepository _incomeRepository = IncomeRepository();
  final TransactionFeedRepository _transactionFeed =
      TransactionFeedRepository();

  final LoanRepository _loanRepository = LoanRepository();

  final InvestmentRepository _investmentRepository = InvestmentRepository();

  List<DashboardChartModel> _monthlyExpense = [];
  List<DashboardChartModel> get monthlyExpense => _monthlyExpense;

  double _totalOutstandingLoan = 0;

  double _totalLoanPaid = 0;

  int _activeLoanCount = 0;

  int _closedLoanCount = 0;

  double get totalOutstandingLoan => _totalOutstandingLoan;

  double get totalLoanPaid => _totalLoanPaid;

  int get activeLoanCount => _activeLoanCount;

  int get closedLoanCount => _closedLoanCount;

  LoanModel? _upcomingLoan;

  LoanModel? get upcomingLoan => _upcomingLoan;

  double _totalInvestedAmount = 0;

  double _totalInvestmentValue = 0;

  List<Map<String, dynamic>> _assetAllocation = [];

  double get totalInvestedAmount => _totalInvestedAmount;

  double get totalInvestmentValue => _totalInvestmentValue;

  List<Map<String, dynamic>> get assetAllocation => _assetAllocation;

  List<InvestmentModel> _upcomingSips = [];

  double _monthlySipTotal = 0;

  List<InvestmentModel> get upcomingSips => _upcomingSips;

  double get monthlySipTotal => _monthlySipTotal;

  List<DashboardTransactionModel> recentTransactions = [];

  // ---- Savings goals ----
  final GoalRepository _goalRepository = GoalRepository();

  List<GoalProgress> goalProgress = [];

  Future<void> loadGoals() async {
    try {
      goalProgress = await _goalRepository.getGoals();
    } catch (e) {
      debugPrint('Loading goals failed: $e');
    }
    notifyListeners();
  }

  // ---- Net worth and this-month insights ----
  NetWorthResult? netWorth;
  MonthInsights? insights;

  Future<void> loadNetWorth() async {
    try {
      netWorth = await NetWorthRepository().load();
    } catch (e) {
      debugPrint('Loading net worth failed: $e');
    }
    notifyListeners();
  }

  Future<void> loadInsights() async {
    try {
      insights = await MonthInsightsRepository().load();
    } catch (e) {
      debugPrint('Loading insights failed: $e');
    }
    notifyListeners();
  }

  // ---- Accounts ----
  final AccountRepository _accountRepository = AccountRepository();

  List<AccountBalance> accountBalances = [];
  List<AccountTransferModel> accountTransfers = [];

  /// Sum of every account's balance.
  double get totalAccountBalance =>
      accountBalances.fold(0.0, (sum, a) => sum + a.balance);

  Future<void> loadAccounts() async {
    try {
      accountBalances = await _accountRepository.getAccountBalances();
      accountTransfers = await _accountRepository.getTransfers();
    } catch (e) {
      debugPrint('Loading accounts failed: $e');
    }
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    // Later:
    // Load from repositories

    _totalExpense = await _expenseRepository.getCurrentMonthExpenseTotal();

    debugPrint("_totalExpense :: $_totalExpense");
    _totalIncome = await _incomeRepository.getCurrentMonthIncomeTotal();
    _totalSavings = _totalIncome - _totalExpense;
    debugPrint("_totalIncome :: $_totalIncome");
    debugPrint("_totalSavings :: $_totalSavings");
    _totalOutstandingLoan = await _loanRepository.getTotalOutstandingLoan();

    _totalLoanPaid = await _loanRepository.getTotalLoanPaid();

    _activeLoanCount = await _loanRepository.getActiveLoanCount();

    _closedLoanCount = await _loanRepository.getClosedLoanCount();

    _upcomingLoan = await _loanRepository.getUpcomingEmiLoan();

    _totalInvestedAmount = await _investmentRepository.getTotalInvestedAmount();

    _totalInvestmentValue = await _investmentRepository.getTotalCurrentValue();

    _assetAllocation = await _investmentRepository.getAssetAllocation();

    _upcomingSips = await _investmentRepository.getUpcomingSips();

    _monthlySipTotal = await _investmentRepository.getMonthlySipTotal();
    notifyListeners();

    _monthlyExpense = await _masterRepository.getMonthlyExpenseChart();

    notifyListeners();

    await loadRecentTransactions();

    await loadAccounts();

    await loadGoals();

    await loadInsights();

    await loadNetWorth();
  }

  Future<void> loadRecentTransactions() async {
    // Newest 5 across expenses, income, loan EMIs and investments.
    recentTransactions = await _transactionFeed.getAll(limit: 5);
  }
}
