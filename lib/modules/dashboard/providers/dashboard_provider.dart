import 'package:flutter/material.dart';

import '../../expenses/repositories/expense_repository.dart';
import '../../income/repositories/income_repository.dart';

class DashboardProvider extends ChangeNotifier {
  double _totalIncome = 0;

  double _totalExpense = 0;

  double _totalSavings = 0;

  double get totalIncome => _totalIncome;

  double get totalExpense => _totalExpense;

  double get totalSavings => _totalSavings;

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final IncomeRepository _incomeRepository = IncomeRepository();

  Future<void> loadDashboardData() async {
    // Later:
    // Load from repositories

    _totalExpense = await _expenseRepository.getCurrentMonthExpenseTotal();

    _totalIncome = await _incomeRepository.getCurrentMonthIncomeTotal();
    _totalSavings = _totalIncome - _totalExpense;

    notifyListeners();
  }
}
