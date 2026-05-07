class SubcategoryModel {
  final int? id;
  final int categoryId;
  final String subcategoryName;
  final int isActive;
  final String createdAt;

  SubcategoryModel({
    this.id,
    required this.categoryId,
    required this.subcategoryName,
    this.isActive = 1,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'subcategory_name': subcategoryName,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  factory SubcategoryModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return SubcategoryModel(
      id: map['id'],
      categoryId: map['category_id'],
      subcategoryName: map['subcategory_name'],
      isActive: map['is_active'],
      createdAt: map['created_at'],
    );
  }
}