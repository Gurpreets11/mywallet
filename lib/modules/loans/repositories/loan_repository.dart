import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';

class LoanRepository {
  Future<int> insertLoan(LoanModel loan) async {
    final Database db = await AppDatabase.database;

    return await db.insert('loans', loan.toMap());
  }

  Future<List<LoanModel>> getAllLoans() async {
    final Database db = await AppDatabase.database;

    final result = await db.query('loans', orderBy: 'start_date DESC');

    return result.map((e) => LoanModel.fromMap(e)).toList();
  }

  Future<int> updateLoan(LoanModel loan) async {
    final Database db = await AppDatabase.database;

    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<int> deleteLoan(int id) async {
    final Database db = await AppDatabase.database;

    return await db.delete('loans', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalOutstandingLoan() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
      SELECT SUM(outstanding_amount)
      AS total
      FROM loans
      WHERE loan_status = 'ACTIVE'
    ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> updateLoanAfterPayment({
    required int loanId,
    required double paymentAmount,
  }) async {
    final Database db = await AppDatabase.database;

    final result = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [loanId],
    );

    if (result.isEmpty) {
      return;
    }

    final loan = LoanModel.fromMap(result.first);

    double updatedPaid = loan.totalPaid + paymentAmount;

    double updatedOutstanding = loan.outstandingAmount - paymentAmount;

    if (updatedOutstanding < 0) {
      updatedOutstanding = 0;
    }

    final String status = updatedOutstanding == 0 ? 'CLOSED' : 'ACTIVE';

    await db.update(
      'loans',
      {
        'total_paid': updatedPaid,
        'outstanding_amount': updatedOutstanding,
        'loan_status': status,
      },
      where: 'id = ?',
      whereArgs: [loanId],
    );
  }

  Future<int> getActiveLoanCount() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) as total
    FROM loans
    WHERE loan_status = 'ACTIVE'
  ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getClosedLoanCount() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT COUNT(*) as total
    FROM loans
    WHERE loan_status = 'CLOSED'
  ''');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalLoanPaid() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT SUM(total_paid)
    AS total
    FROM loans
  ''');

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<LoanModel?> getUpcomingEmiLoan() async {
    final Database db = await AppDatabase.database;

    final result = await db.rawQuery('''
    SELECT *
    FROM loans
    WHERE loan_status = 'ACTIVE'
    AND next_emi_date IS NOT NULL
    ORDER BY next_emi_date ASC
    LIMIT 1
  ''');

    if (result.isEmpty) {
      return null;
    }

    return LoanModel.fromMap(result.first);
  }

  Future<LoanModel?> getLoanById(int id) async {
    final Database db = await AppDatabase.database;

    final result = await db.query('loans', where: 'id = ?', whereArgs: [id]);

    if (result.isEmpty) {
      return null;
    }

    return LoanModel.fromMap(result.first);
  }

  Future<void> payEmi({
    required LoanModel loan,

    required double paymentAmount,

    required String paymentMode,

    String? remarks,
  }) async {
    final Database db = await AppDatabase.database;

    /// INSERT PAYMENT HISTORY

    final payment = LoanPaymentModel(
      loanId: loan.id!,

      paymentAmount: paymentAmount,

      paymentDate: DateTime.now().toIso8601String(),

      paymentMode: paymentMode,

      remarks: remarks,

      createdAt: DateTime.now().toIso8601String(),
    );

    await db.insert('loan_payments', payment.toMap());

    /// CALCULATE UPDATED VALUES

    double updatedOutstanding = loan.outstandingAmount - paymentAmount;

    if (updatedOutstanding < 0) {
      updatedOutstanding = 0;
    }

    final currentNextEmiDate = DateTime.parse(loan.nextEmiDate!);

    final updatedNextEmiDate = DateTime(
      currentNextEmiDate.year,

      currentNextEmiDate.month + 1,

      currentNextEmiDate.day,
    );

    final updatedStatus = updatedOutstanding <= 0 ? 'Closed' : 'Active';

    /// UPDATE LOAN

    await db.update(
      'loans',

      {
        'outstanding_amount': updatedOutstanding,

        'total_paid': loan.totalPaid + paymentAmount,

        'next_emi_date': updatedNextEmiDate.toIso8601String(),

        'loan_status': updatedStatus,
      },

      where: 'id = ?',

      whereArgs: [loan.id],
    );
  }

  Future<List<LoanPaymentModel>> getLoanPayments(int loanId) async {
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
