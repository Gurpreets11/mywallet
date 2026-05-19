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
      // Expense Categories
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Food & Dining',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Travel',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Shopping',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Bills & Utilities',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Health',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Entertainment',
        createdAt: now,
      ),

      // Income Categories
      CategoryModel(
        transactionTypeId: 1,
        categoryName: 'Salary',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 1,
        categoryName: 'Business',
        createdAt: now,
      ),
      CategoryModel(
        transactionTypeId: 1,
        categoryName: 'Investment',
        createdAt: now,
      ),

      // Finance / Loan
      CategoryModel(
        transactionTypeId: 0,
        categoryName: 'Loan & EMI',
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

      // Food & Dining (1)
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Breakfast',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Lunch',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Dinner',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 1,
        subcategoryName: 'Snacks',
        createdAt: now,
      ),

      // Travel (2)
      SubcategoryModel(
        categoryId: 2,
        subcategoryName: 'Fuel',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 2,
        subcategoryName: 'Taxi',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 2,
        subcategoryName: 'Bus',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 2,
        subcategoryName: 'Flight',
        createdAt: now,
      ),

      // Shopping (3)
      SubcategoryModel(
        categoryId: 3,
        subcategoryName: 'Clothes',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 3,
        subcategoryName: 'Electronics',
        createdAt: now,
      ),

      // Bills & Utilities (4)
      SubcategoryModel(
        categoryId: 4,
        subcategoryName: 'Electricity',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 4,
        subcategoryName: 'Internet',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 4,
        subcategoryName: 'Mobile Recharge',
        createdAt: now,
      ),

      // Health (5)
      SubcategoryModel(
        categoryId: 5,
        subcategoryName: 'Medicine',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 5,
        subcategoryName: 'Doctor',
        createdAt: now,
      ),

      // Entertainment (6)
      SubcategoryModel(
        categoryId: 6,
        subcategoryName: 'Movies',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 6,
        subcategoryName: 'OTT Subscription',
        createdAt: now,
      ),

      // Salary (7)
      SubcategoryModel(
        categoryId: 7,
        subcategoryName: 'Monthly Salary',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 7,
        subcategoryName: 'Bonus',
        createdAt: now,
      ),

      // Business (8)
      SubcategoryModel(
        categoryId: 8,
        subcategoryName: 'Client Payment',
        createdAt: now,
      ),

      // Investment (9)
      SubcategoryModel(
        categoryId: 9,
        subcategoryName: 'Stocks',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 9,
        subcategoryName: 'Mutual Funds',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 9,
        subcategoryName: 'Interest',
        createdAt: now,
      ),

      // Loan & EMI (10)
      SubcategoryModel(
        categoryId: 10,
        subcategoryName: 'Personal Loan',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 10,
        subcategoryName: 'Home Loan',
        createdAt: now,
      ),
      SubcategoryModel(
        categoryId: 10,
        subcategoryName: 'EMI Payment',
        createdAt: now,
      ),
    ];

    for (final item in subcategories) {
      await _repository.insertSubcategory(item.toMap());
    }
  }
}
