class RecurringTransactionModel {
  final int? id;
  final String title;
  final String transactionType; // EXPENSE or INCOME
  final double amount;
  final int categoryId;
  final String categoryName;
  final String paymentMode;
  final String? notes;
  final String frequency; // DAILY, WEEKLY, MONTHLY, YEARLY
  final int intervalValue;
  final String startDate;
  final String? endDate;
  final String nextDueDate;
  final String status; // ACTIVE, PAUSED, COMPLETED
  final String createdAt;

  /// Account the generated entries go to (null = default account).
  final int? accountId;

  /// Days before the due date to send a reminder (0 = on the day, null = off).
  final int? reminderDays;

  const RecurringTransactionModel({
    this.id,
    required this.title,
    required this.transactionType,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.paymentMode,
    this.notes,
    required this.frequency,
    this.intervalValue = 1,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    this.status = 'ACTIVE',
    required this.createdAt,
    this.accountId,
    this.reminderDays,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'transaction_type': transactionType,
    'amount': amount,
    'category_id': categoryId,
    'category_name': categoryName,
    'payment_mode': paymentMode,
    'notes': notes,
    'frequency': frequency,
    'interval_value': intervalValue,
    'start_date': startDate,
    'end_date': endDate,
    'next_due_date': nextDueDate,
    'status': status,
    'created_at': createdAt,
    'account_id': accountId,
    'reminder_days': reminderDays,
  };

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      transactionType: map['transaction_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      paymentMode: (map['payment_mode'] as String?) ?? 'Cash',
      notes: map['notes'] as String?,
      frequency: map['frequency'] as String,
      intervalValue: (map['interval_value'] as int?) ?? 1,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      nextDueDate: map['next_due_date'] as String,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
      accountId: map['account_id'] as int?,
      reminderDays: map['reminder_days'] as int?,
    );
  }
}
