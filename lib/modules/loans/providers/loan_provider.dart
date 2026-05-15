import 'package:flutter/material.dart';

import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';
import '../repositories/loan_repository.dart';
import '../utils/loan_analytics_utils.dart';

class LoanProvider extends ChangeNotifier {
  final LoanRepository _repository = LoanRepository();

  List<LoanModel> _loans = [];

  bool _isLoading = false;

  double _totalOutstanding = 0;

  List<LoanModel> get loans => _loans;

  bool get isLoading => _isLoading;

  double get totalOutstanding => _totalOutstanding;

  List<LoanPaymentModel> _loanPayments = [];

  List<LoanPaymentModel> get loanPayments => _loanPayments;

  Future<void> loadLoans() async {
    _isLoading = true;

    notifyListeners();

    _loans = await _repository.getAllLoans();

    _totalOutstanding = await _repository.getTotalOutstandingLoan();

    for (final loan in _loans) {
      if (loan.loanStatus != 'Closed') {
        final isOverdue = LoanAnalyticsUtils.isLoanOverdue(loan.nextEmiDate!);

        if (isOverdue) {
          loan.loanStatus = 'Overdue';
        }
      }
    }

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

  Future<void> payEmi({
    required LoanModel loan,

    required double paymentAmount,

    required String paymentMode,

    String? remarks,
  }) async {
    await _repository.payEmi(
      loan: loan,

      paymentAmount: paymentAmount,

      paymentMode: paymentMode,

      remarks: remarks,
    );

    await loadLoans();
  }

  Future<void> loadLoanPayments(int loanId) async {
    _loanPayments = await _repository.getLoanPayments(loanId);

    notifyListeners();
  }
}
