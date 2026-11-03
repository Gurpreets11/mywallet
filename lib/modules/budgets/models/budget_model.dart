class BudgetModel {
  final int? id;
  final int categoryId;
  final String categoryName;
  final double amount;
  final int month;
  final int year;
  final int alertPercentage;
  final double spentAmount;

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.month,
    required this.year,
    this.alertPercentage = 80,
    this.spentAmount = 0,
  });
  double get remainingAmount => amount - spentAmount;
  double get progress =>
      amount <= 0 ? 0 : (spentAmount / amount).clamp(0.0, 1.0).toDouble();
  bool get isExceeded => spentAmount > amount;
  bool get isNearLimit => !isExceeded && progress * 100 >= alertPercentage;

  Map<String, dynamic> toMap() => {
    'id': id,
    'category_id': categoryId,
    'category_name': categoryName,
    'amount': amount,
    'month': month,
    'year': year,
    'alert_percentage': alertPercentage,
    'created_at': DateTime.now().toIso8601String(),
  };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
    id: map['id'] as int?,
    categoryId: map['category_id'] as int,
    categoryName: map['category_name']?.toString() ?? 'Category',
    amount: (map['amount'] as num).toDouble(),
    month: map['month'] as int,
    year: map['year'] as int,
    alertPercentage: (map['alert_percentage'] as num?)?.toInt() ?? 80,
    spentAmount: (map['spent_amount'] as num?)?.toDouble() ?? 0,
  );
}
