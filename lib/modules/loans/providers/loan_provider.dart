import 'package:flutter/material.dart';

import '../models/loan_model.dart';
import '../repositories/loan_repository.dart';

class LoanProvider extends ChangeNotifier {
  final LoanRepository _repository = LoanRepository();

  List<LoanModel> _loans = [];

  bool _isLoading = false;

  double _totalOutstanding = 0;

  List<LoanModel> get loans => _loans;

  bool get isLoading => _isLoading;

  double get totalOutstanding => _totalOutstanding;

  Future<void> loadLoans() async {
    _isLoading = true;

    notifyListeners();

    _loans = await _repository.getAllLoans();

    _totalOutstanding = await _repository.getTotalOutstandingLoan();

    _isLoading = false;

    notifyListeners();
  }

  Future<void> addLoan(LoanModel loan) async {
    await _repository.insertLoan(loan);

    await loadLoans();
  }

  Future<void> updateLoan(LoanModel loan) async {
    await _repository.updateLoan(loan);

    await loadLoans();
  }

  Future<void> deleteLoan(int id) async {
    await _repository.deleteLoan(id);

    await loadLoans();
  }
}
