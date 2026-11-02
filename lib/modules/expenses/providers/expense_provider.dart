import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = false;
  double _monthlyExpenseTotal = 0;
  String _searchKeyword = '';

  List<ExpenseModel> get expenses => List.unmodifiable(_expenses);
  List<ExpenseModel> get filteredExpenses => List.unmodifiable(_filteredExpenses);
  bool get isLoading => _isLoading;
  double get monthlyExpenseTotal => _monthlyExpenseTotal;

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await _repository.getAllExpenses();
      _applySearch();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlySummary() async {
    _monthlyExpenseTotal = await _repository.getCurrentMonthExpenseTotal();
    notifyListeners();
  }

  void searchExpense(String keyword) {
    _searchKeyword = keyword.trim().toLowerCase();
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (_searchKeyword.isEmpty) {
      _filteredExpenses = List.of(_expenses);
      return;
    }
    _filteredExpenses = _expenses.where((expense) {
      final searchable = [
        expense.notes ?? '',
        expense.categoryName ?? '',
        expense.subcategoryName ?? '',
        expense.paymentMode,
        expense.amount.toString(),
      ].join(' ').toLowerCase();
      return searchable.contains(_searchKeyword);
    }).toList();
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.insertExpense(expense);
    await loadExpenses();
    await loadMonthlySummary();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.updateExpense(expense);
    await loadExpenses();
    await loadMonthlySummary();
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
    await loadMonthlySummary();
  }
}
