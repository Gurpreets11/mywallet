import 'package:flutter/material.dart';

import '../models/investment_model.dart';

import '../repositories/investment_repository.dart';

class InvestmentProvider extends ChangeNotifier {
  final InvestmentRepository _repository = InvestmentRepository();

  List<InvestmentModel> _investments = [];

  bool _isLoading = false;

  List<InvestmentModel> get investments => _investments;

  bool get isLoading => _isLoading;

  Future<void> loadInvestments() async {
    _isLoading = true;

    notifyListeners();

    _investments = await _repository.getAllInvestments();

    _isLoading = false;

    notifyListeners();
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    await _repository.insertInvestment(investment);

    await loadInvestments();
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _repository.updateInvestment(investment);

    await loadInvestments();
  }

  Future<void> deleteInvestment(int id) async {
    await _repository.deleteInvestment(id);

    await loadInvestments();
  }
}
