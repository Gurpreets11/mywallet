import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/loan_payment_model.dart';

class LoanPaymentRepository {
  Future<int> insertPayment(LoanPaymentModel payment) async {
    final Database db = await AppDatabase.database;

    return await db.insert('loan_payments', payment.toMap());
  }

  Future<List<LoanPaymentModel>> getPaymentsByLoanId(int loanId) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      'loan_payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'payment_date DESC',
    );

    return result.map((e) => LoanPaymentModel.fromMap(e)).toList();
  }
}
