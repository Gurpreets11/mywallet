class CategoryModel {
  final int? id;
  final int transactionTypeId;
  final String categoryName;
  final String? iconName;
  final String? colorCode;
  final int isActive;
  final String createdAt;

  CategoryModel({
    this.id,
    required this.transactionTypeId,
    required this.categoryName,
    this.iconName,
    this.colorCode,
    this.isActive = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_type_id': transactionTypeId,
      'category_name': categoryName,
      'icon_name': iconName,
      'color_code': colorCode,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      transactionTypeId: map['transaction_type_id'],
      categoryName: map['category_name'],
      iconName: map['icon_name'],
      colorCode: map['color_code'],
      isActive: map['is_active'],
      createdAt: map['created_at'],
    );
  }
}
