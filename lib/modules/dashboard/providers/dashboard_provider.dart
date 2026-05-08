import 'package:flutter/material.dart';

import '../../expenses/repositories/expense_repository.dart';

class DashboardProvider extends ChangeNotifier {
  double _totalIncome = 0;

  double _totalExpense = 0;

  double _totalSavings = 0;

  double get totalIncome =>
      _totalIncome;

  double get totalExpense =>
      _totalExpense;

  double get totalSavings =>
      _totalSavings;

  final ExpenseRepository
  _expenseRepository =
  ExpenseRepository();

  Future<void> loadDashboardData() async {
    // Later:
    // Load from repositories

    _totalExpense =
    await _expenseRepository
        .getCurrentMonthExpenseTotal();
    _totalIncome = 0;

 
    _totalSavings =
        _totalIncome - _totalExpense;

    notifyListeners();
  }
}