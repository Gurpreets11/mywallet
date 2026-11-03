import 'package:flutter/material.dart';

import '../models/income_model.dart';
import '../repositories/income_repository.dart';

class IncomeProvider extends ChangeNotifier {
  final IncomeRepository _repository = IncomeRepository();
  List<IncomeModel> _incomes = [];
  List<IncomeModel> _filteredIncomes = [];
  bool _isLoading = false;
  double _monthlyIncome = 0;

  List<IncomeModel> get incomes => List.unmodifiable(_incomes);
  List<IncomeModel> get filteredIncomes => List.unmodifiable(_filteredIncomes);
  bool get isLoading => _isLoading;
  double get monthlyIncome => _monthlyIncome;

  Future<void> loadIncomes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _incomes = await _repository.getAllIncomes();
      _filteredIncomes = List.of(_incomes);
      _monthlyIncome = await _repository.getCurrentMonthIncomeTotal();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchIncome(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      _filteredIncomes = List.of(_incomes);
    } else {
      _filteredIncomes = _incomes.where((income) {
        final fields = [
          income.amount.toString(),
          income.categoryName ?? '',
          income.subcategoryName ?? '',
          income.paymentMode,
          income.notes ?? '',
          income.recurringType ?? '',
        ];
        return fields.any((field) => field.toLowerCase().contains(value));
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addIncome(IncomeModel income) async {
    await _repository.insertIncome(income);
    await loadIncomes();
  }

  Future<void> updateIncome(IncomeModel income) async {
    await _repository.updateIncome(income);
    await loadIncomes();
  }

  Future<void> deleteIncome(int id) async {
    await _repository.deleteIncome(id);
    await loadIncomes();
  }
}
