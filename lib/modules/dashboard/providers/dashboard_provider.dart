import 'package:flutter/material.dart';

import '../../../data/repositories/master_repository.dart';
import '../../expenses/repositories/expense_repository.dart';
import '../../income/repositories/income_repository.dart';
import '../../investments/models/investment_model.dart';
import '../../investments/repositories/investment_repository.dart';
import '../../loans/models/loan_model.dart';
import '../../loans/repositories/loan_repository.dart';
import '../models/dashboard_chart_model.dart';
import '../models/dashboard_transaction_model.dart';

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

    notifyListeners();
  }

  Future<void> loadRecentTransactions() async {
    final List<DashboardTransactionModel> transactions = [];

    // EXPENSES
    final expenses = await _expenseRepository.getAllExpenses();

    for (final e in expenses.take(5)) {
      transactions.add(
        DashboardTransactionModel(
          title: '${e.categoryName} - ${e.subcategoryName}' ?? 'Expense',
          subtitle: e.paymentMode,
          amount: e.amount,
          date: e.date,
          isExpense: true,
        ),
      );
    }

    // INCOME
    final incomes = await _incomeRepository.getAllIncomes();

    for (final i in incomes.take(5)) {
      transactions.add(
        DashboardTransactionModel(
          title: i.categoryName ?? 'Income',

          subtitle: i.paymentMode,

          amount: i.amount,

          date: i.date,

          isExpense: false,
        ),
      );
    }

    // SORT BY DATE
    transactions.sort(
      (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
    );

    recentTransactions = transactions.take(5).toList();
  }




}
