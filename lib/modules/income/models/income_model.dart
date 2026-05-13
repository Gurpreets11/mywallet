class IncomeModel {
  final int? id;

  final double amount;

  final int categoryId;

  final int? subcategoryId;

  final String date;

  final String paymentMode;

  final String? notes;

  final bool isRecurring;

  final String? recurringType;

  final String createdAt;

  final String? categoryName;

  final String? subcategoryName;

  IncomeModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.subcategoryId,
    required this.date,
    required this.paymentMode,
    this.notes,
    required this.isRecurring,
    this.recurringType,
    required this.createdAt,
    this.categoryName,
    this.subcategoryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'date': date,
      'payment_mode': paymentMode,
      'notes': notes,
      'is_recurring':
      isRecurring ? 1 : 0,
      'recurring_type':
      recurringType,
      'created_at': createdAt,
    };
  }

  factory IncomeModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return IncomeModel(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      subcategoryId:
      map['subcategory_id'],
      date: map['date'],
      paymentMode:
      map['payment_mode'],
      notes: map['notes'],
      isRecurring:
      map['is_recurring'] == 1,
      recurringType:
      map['recurring_type'],
      createdAt: map['created_at'],
      categoryName:
      map['category_name'],
      subcategoryName:
      map['subcategory_name'],
    );
  }
}