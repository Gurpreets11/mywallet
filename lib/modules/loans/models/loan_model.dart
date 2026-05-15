class LoanModel {
  final int? id;

  final String loanType;

  final String personName;

  final double principalAmount;

  final double interestRate;

  final double emiAmount;
  final String? nextEmiDate;
  final int tenureMonths;

  final String startDate;

  final String? endDate;

  final double totalPaid;

  final double outstandingAmount;

    String loanStatus;

  final String? notes;

  final String createdAt;

  LoanModel({
    this.id,
    required this.loanType,
    required this.personName,
    required this.principalAmount,
    required this.interestRate,
    required this.emiAmount,
    required this.nextEmiDate,
    required this.tenureMonths,
    required this.startDate,
    this.endDate,
    required this.totalPaid,
    required this.outstandingAmount,
    required this.loanStatus,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_type': loanType,
      'person_name': personName,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'emi_amount': emiAmount,
      'next_emi_date': nextEmiDate,
      'tenure_months': tenureMonths,
      'start_date': startDate,
      'end_date': endDate,
      'total_paid': totalPaid,
      'outstanding_amount': outstandingAmount,
      'loan_status': loanStatus,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map['id'],
      loanType: map['loan_type'],
      personName: map['person_name'],
      principalAmount: map['principal_amount'],
      interestRate: map['interest_rate'],
      emiAmount: map['emi_amount'],
      nextEmiDate: map['next_emi_date'],
      tenureMonths: map['tenure_months'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      totalPaid: map['total_paid'],
      outstandingAmount: map['outstanding_amount'],
      loanStatus: map['loan_status'],
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }
}
