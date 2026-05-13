import 'package:flutter/material.dart';

import '../models/loan_payment_model.dart';
import '../repositories/loan_payment_repository.dart';

class LoanPaymentProvider extends ChangeNotifier {
  final LoanPaymentRepository _repository = LoanPaymentRepository();

  List<LoanPaymentModel> _payments = [];

  bool _isLoading = false;

  List<LoanPaymentModel> get payments => _payments;

  bool get isLoading => _isLoading;

  Future<void> loadPayments(int loanId) async {
    _isLoading = true;

    notifyListeners();

    _payments = await _repository.getPaymentsByLoanId(loanId);

    _isLoading = false;

    notifyListeners();
  }

  Future<void> addPayment(LoanPaymentModel payment) async {
    await _repository.insertPayment(payment);

    await loadPayments(payment.loanId);
  }
}
