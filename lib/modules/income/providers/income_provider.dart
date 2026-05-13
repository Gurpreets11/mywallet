import 'package:flutter/material.dart';

import '../models/income_model.dart';
import '../repositories/income_repository.dart';

class IncomeProvider
    extends ChangeNotifier {
  final IncomeRepository
  _repository =
  IncomeRepository();

  List<IncomeModel> _incomes = [];

  bool _isLoading = false;

  double _monthlyIncome = 0;

  List<IncomeModel> get incomes =>
      _incomes;

  bool get isLoading =>
      _isLoading;

  double get monthlyIncome =>
      _monthlyIncome;

  Future<void> loadIncomes() async {
    _isLoading = true;

    notifyListeners();

    _incomes =
    await _repository
        .getAllIncomes();

    _monthlyIncome =
    await _repository
        .getCurrentMonthIncomeTotal();

    _isLoading = false;

    notifyListeners();
  }

  Future<void> addIncome(
      IncomeModel income,
      ) async {
    await _repository.insertIncome(
      income,
    );

    await loadIncomes();
  }

  Future<void> updateIncome(
      IncomeModel income,
      ) async {
    await _repository.updateIncome(
      income,
    );

    await loadIncomes();
  }

  Future<void> deleteIncome(
      int id,
      ) async {
    await _repository.deleteIncome(
      id,
    );

    await loadIncomes();
  }
}