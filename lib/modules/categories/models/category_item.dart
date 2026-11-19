/// A subcategory as shown on the Manage Categories screen.
class SubcategoryItem {
  final int id;
  final int categoryId;
  final String name;
  final bool isActive;

  /// Number of expenses / income entries that use it.
  final int usageCount;

  const SubcategoryItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.isActive,
    required this.usageCount,
  });
}

/// A category with its subcategories and how much it is used.
class CategoryItem {
  final int id;
  final int typeId; // 0 = expense, 1 = income
  final String name;
  final bool isActive;

  /// Entries + budgets + recurring schedules that use it. A category that is
  /// in use can be hidden but not deleted.
  final int usageCount;
  final List<SubcategoryItem> subcategories;

  const CategoryItem({
    required this.id,
    required this.typeId,
    required this.name,
    required this.isActive,
    required this.usageCount,
    required this.subcategories,
  });
}

/// Thrown with a message that can be shown to the user as-is.
class CategoryException implements Exception {
  final String message;
  const CategoryException(this.message);

  @override
  String toString() => message;
}
