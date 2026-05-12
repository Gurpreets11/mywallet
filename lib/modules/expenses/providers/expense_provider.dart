import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();

  List<ExpenseModel> _expenses = [];

  bool _isLoading = false;

  List<ExpenseModel> get expenses => _expenses;

  bool get isLoading => _isLoading;

  double _monthlyExpenseTotal = 0;

  List<ExpenseModel> _filteredExpenses = [];

  double get monthlyExpenseTotal => _monthlyExpenseTotal;

  List<ExpenseModel> get filteredExpenses => _filteredExpenses;

  Future<void> loadExpenses() async {
    _isLoading = true;

    notifyListeners();

    /*_expenses = await _repository.getAllExpenses();*/

    _expenses = await _repository.getAllExpenses();

    _filteredExpenses = _expenses;

    _isLoading = false;

    notifyListeners();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.insertExpense(expense);

    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);

    await loadExpenses();
  }

  Future<void> loadMonthlySummary() async {
    _monthlyExpenseTotal = await _repository.getCurrentMonthExpenseTotal();

    notifyListeners();
  }

  Future<void> searchExpense(String keyword) async {
    if (keyword.trim().isEmpty) {
      _filteredExpenses = _expenses;
    } else {
      _filteredExpenses = await _repository.searchExpenses(keyword);
    }

    notifyListeners();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.updateExpense(expense);

    await loadExpenses();
  }
}
