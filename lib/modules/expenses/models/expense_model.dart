class ExpenseModel {
  final int? id;
  final double amount;
  final int categoryId;
  final int? subcategoryId;
  final String? categoryName;

  final String? subcategoryName;
  final String date;
  final String paymentMode;
  final String? notes;
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.subcategoryId,
    this.categoryName,
    this.subcategoryName,
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
      'category_name': categoryName,
      'subcategory_name': subcategoryName,
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
      categoryName: map['category_name'],
      subcategoryName: map['subcategory_name'],
      date: map['date'],
      paymentMode: map['payment_mode'],
      notes: map['notes'],
      createdAt: map['created_at'],
    );
  }
}