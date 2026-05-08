class ExpenseModel {
  final int? id;
  final double amount;
  final int categoryId;
  final int? subcategoryId;
  final String date;
  final String paymentMode;
  final String? notes;
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.subcategoryId,
    required this.date,
    required this.paymentMode,
    this.notes,
    required this.createdAt,
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
      'created_at': createdAt,
    };
  }

  factory ExpenseModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return ExpenseModel(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      subcategoryId: map['subcategory_id'],
      date: map['date'],
      paymentMode: map['payment_mode'],
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }
}