class LoanPaymentModel {
  final int? id;

  final int loanId;

  final double paymentAmount;

  final String paymentDate;

  final String paymentMode;

  final String? remarks;

  final String createdAt;

  /// Account this belongs to (null = default account).
  final int? accountId;

  LoanPaymentModel({
    this.id,
    required this.loanId,
    required this.paymentAmount,
    required this.paymentDate,
    required this.paymentMode,
    this.remarks,
    required this.createdAt,
    this.accountId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate,
      'payment_mode': paymentMode,
      'remarks': remarks,
      'created_at': createdAt,
      'account_id': accountId,
    };
  }

  factory LoanPaymentModel.fromMap(Map<String, dynamic> map) {
    return LoanPaymentModel(
      id: map['id'],
      loanId: map['loan_id'],
      paymentAmount: map['payment_amount'],
      paymentDate: map['payment_date'],
      paymentMode: map['payment_mode'],
      remarks: map['remarks'],
      createdAt: map['created_at'],
      accountId: map['account_id'],
    );
  }
}
