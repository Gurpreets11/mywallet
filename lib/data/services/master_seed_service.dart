import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../models/transaction_type_model.dart';
import '../repositories/master_repository.dart';

class MasterSeedService {
  static final MasterRepository _repository = MasterRepository();

  static Future<void> seedMasterData() async {
    final existingTypes = await _repository.getTransactionTypes();

    if (existingTypes.isNotEmpty) {
      return;
    }

    await _seedTransactionTypes();
    await _seedCategories();
    await _seedSubcategories();
  }

  static Future<void> _seedTransactionTypes() async {
    final transactionTypes = [
      TransactionTypeModel(typeName: 'Expense'),
      TransactionTypeModel(typeName: 'Income'),
      TransactionTypeModel(typeName: 'Investment'),
      TransactionTypeModel(typeName: 'Loan'),
    ];

    for (final item in transactionTypes) {
      await _repository.insertTransactionType(item.toMap());
    }
  }

  static Future<void> _seedCategories() async {
    final now = DateTime.now().toIso8601String();

    final categories = [
      CategoryModel(transactionTypeId: 0, categoryName: 'Food', createdAt: now),
      CategoryModel(
        transactionTypeId: 1,
        categoryName: 'Travel',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 2,
        categoryName: 'Salary',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 3,
        categoryName: 'Stocks',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 4,
        categoryName: 'Personal Loan',
        createdAt: now,
      ),
    ];

    for (final item in categories) {
      await _repository.insertCategory(item.toMap());
    }
  }

  static Future<void> _seedSubcategories() async {
    final now = DateTime.now().toIso8601String();

    final subcategories = [
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Breakfast',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Dinner',
        createdAt: now,
      ),
      SubcategoryModel(categoryId: 2, subcategoryName: 'Fuel', createdAt: now),
      SubcategoryModel(
        categoryId: 3,
        subcategoryName: 'Monthly Salary',
        createdAt: now,
      ),
    ];

    for (final item in subcategories) {
      await _repository.insertSubcategory(item.toMap());
    }
  }
}
