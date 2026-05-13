import 'package:flutter/material.dart';

import '../../expenses/repositories/expense_repository.dart';
import '../../income/repositories/income_repository.dart';
import '../../loans/models/loan_model.dart';
import '../../loans/repositories/loan_repository.dart';

class DashboardProvider extends ChangeNotifier {
  double _totalIncome = 0;

  double _totalExpense = 0;

  double _totalSavings = 0;

  double get totalIncome => _totalIncome;

  double get totalExpense => _totalExpense;

  double get totalSavings => _totalSavings;

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final IncomeRepository _incomeRepository = IncomeRepository();

  final LoanRepository _loanRepository = LoanRepository();

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

  Future<void> loadDashboardData() async {
    // Later:
    // Load from repositories

    _totalExpense = await _expenseRepository.getCurrentMonthExpenseTotal();

    _totalIncome = await _incomeRepository.getCurrentMonthIncomeTotal();
    _totalSavings = _totalIncome - _totalExpense;

    _totalOutstandingLoan = await _loanRepository.getTotalOutstandingLoan();

    _totalLoanPaid = await _loanRepository.getTotalLoanPaid();

    _activeLoanCount = await _loanRepository.getActiveLoanCount();

    _closedLoanCount = await _loanRepository.getClosedLoanCount();

    _upcomingLoan = await _loanRepository.getUpcomingEmiLoan();

    notifyListeners();
  }
}
