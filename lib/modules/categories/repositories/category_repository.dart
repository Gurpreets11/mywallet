import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/category_item.dart';

/// Adds, renames, hides and deletes categories and subcategories.
///
/// Type ids: 0 = expense, 1 = income (same as the seed data).
class CategoryRepository {
  static const int expenseType = 0;
  static const int incomeType = 1;
  static const int maxNameLength = 40;

  // ---- Reading ----

  Future<List<CategoryItem>> getCategories(int typeId) async {
    final Database db = await AppDatabase.database;

    final categoryRows = await db.rawQuery(
      '''
      SELECT c.id, c.category_name, COALESCE(c.is_active, 1) AS is_active,
        (SELECT COUNT(*) FROM expenses e WHERE e.category_id = c.id)
        + (SELECT COUNT(*) FROM incomes i WHERE i.category_id = c.id)
        + (SELECT COUNT(*) FROM budgets b WHERE b.category_id = c.id)
        + (SELECT COUNT(*) FROM recurring_transactions r
             WHERE r.category_id = c.id) AS used
      FROM categories c
      WHERE c.transaction_type_id = ?
      ORDER BY c.id
    ''',
      [typeId],
    );

    final subRows = await db.rawQuery(
      '''
      SELECT s.id, s.category_id, s.subcategory_name,
        COALESCE(s.is_active, 1) AS is_active,
        (SELECT COUNT(*) FROM expenses e WHERE e.subcategory_id = s.id)
        + (SELECT COUNT(*) FROM incomes i WHERE i.subcategory_id = s.id) AS used
      FROM subcategories s
      WHERE s.category_id IN
        (SELECT id FROM categories WHERE transaction_type_id = ?)
      ORDER BY s.id
    ''',
      [typeId],
    );

    final byCategory = <int, List<SubcategoryItem>>{};
    for (final r in subRows) {
      final item = SubcategoryItem(
        id: r['id'] as int,
        categoryId: r['category_id'] as int,
        name: (r['subcategory_name'] ?? '').toString(),
        isActive: r['is_active'] == 1,
        usageCount: (r['used'] as num?)?.toInt() ?? 0,
      );
      byCategory.putIfAbsent(item.categoryId, () => []).add(item);
    }

    return [
      for (final r in categoryRows)
        CategoryItem(
          id: r['id'] as int,
          typeId: typeId,
          name: (r['category_name'] ?? '').toString(),
          isActive: r['is_active'] == 1,
          usageCount: (r['used'] as num?)?.toInt() ?? 0,
          subcategories: byCategory[r['id'] as int] ?? const [],
        ),
    ];
  }

  // ---- Helpers ----

  String _cleanName(String raw, String what) {
    final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) throw CategoryException('Enter a $what name');
    if (name.length > maxNameLength) {
      throw CategoryException('Name is too long (max $maxNameLength letters)');
    }
    return name;
  }

  // ---- Categories ----

  /// Adds a category and returns its id. If a hidden category with the same
  /// name already exists it is shown again instead of creating a duplicate.
  Future<int> addCategory(int typeId, String rawName) async {
    final Database db = await AppDatabase.database;
    final name = _cleanName(rawName, 'category');

    final same = await db.query(
      'categories',
      where: 'transaction_type_id = ? AND LOWER(category_name) = LOWER(?)',
      whereArgs: [typeId, name],
      limit: 1,
    );
    if (same.isNotEmpty) {
      final id = same.first['id'] as int;
      if (same.first['is_active'] == 0) {
        await setCategoryActive(id, true);
        return id;
      }
      throw CategoryException('"$name" already exists');
    }

    return db.insert('categories', {
      'transaction_type_id': typeId,
      'category_name': name,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Renames a category everywhere it is stored (entries, budgets and
  /// recurring schedules keep a copy of the name).
  Future<void> renameCategory(int id, int typeId, String rawName) async {
    final Database db = await AppDatabase.database;
    final name = _cleanName(rawName, 'category');

    final clash = await db.query(
      'categories',
      where:
          'transaction_type_id = ? AND LOWER(category_name) = LOWER(?) '
          'AND id <> ?',
      whereArgs: [typeId, name, id],
      limit: 1,
    );
    if (clash.isNotEmpty) throw CategoryException('"$name" already exists');

    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'category_name': name},
        where: 'id = ?',
        whereArgs: [id],
      );
      for (final table in ['expenses', 'budgets', 'recurring_transactions']) {
        await txn.update(
          table,
          {'category_name': name},
          where: 'category_id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> setCategoryActive(int id, bool active) async {
    final Database db = await AppDatabase.database;
    await db.update(
      'categories',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a category that nothing uses (its empty subcategories go too).
  Future<void> deleteCategory(int id) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      final used = await _categoryUsage(txn, id);
      if (used > 0) {
        throw const CategoryException(
          'This category is used by existing entries. Hide it instead.',
        );
      }
      await txn.delete(
        'subcategories',
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> _categoryUsage(DatabaseExecutor db, int id) async {
    var total = 0;
    for (final table in [
      'expenses',
      'incomes',
      'budgets',
      'recurring_transactions',
    ]) {
      final r = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM $table WHERE category_id = ?',
        [id],
      );
      total += (r.first['n'] as num).toInt();
    }
    return total;
  }

  // ---- Subcategories ----

  Future<int> addSubcategory(int categoryId, String rawName) async {
    final Database db = await AppDatabase.database;
    final name = _cleanName(rawName, 'subcategory');

    final same = await db.query(
      'subcategories',
      where: 'category_id = ? AND LOWER(subcategory_name) = LOWER(?)',
      whereArgs: [categoryId, name],
      limit: 1,
    );
    if (same.isNotEmpty) {
      final id = same.first['id'] as int;
      if (same.first['is_active'] == 0) {
        await setSubcategoryActive(id, true);
        return id;
      }
      throw CategoryException('"$name" already exists in this category');
    }

    return db.insert('subcategories', {
      'category_id': categoryId,
      'subcategory_name': name,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> renameSubcategory(int id, int categoryId, String rawName) async {
    final Database db = await AppDatabase.database;
    final name = _cleanName(rawName, 'subcategory');

    final clash = await db.query(
      'subcategories',
      where:
          'category_id = ? AND LOWER(subcategory_name) = LOWER(?) AND id <> ?',
      whereArgs: [categoryId, name, id],
      limit: 1,
    );
    if (clash.isNotEmpty) {
      throw CategoryException('"$name" already exists in this category');
    }

    await db.transaction((txn) async {
      await txn.update(
        'subcategories',
        {'subcategory_name': name},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'expenses',
        {'subcategory_name': name},
        where: 'subcategory_id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> setSubcategoryActive(int id, bool active) async {
    final Database db = await AppDatabase.database;
    await db.update(
      'subcategories',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSubcategory(int id) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      var used = 0;
      for (final table in ['expenses', 'incomes']) {
        final r = await txn.rawQuery(
          'SELECT COUNT(*) AS n FROM $table WHERE subcategory_id = ?',
          [id],
        );
        used += (r.first['n'] as num).toInt();
      }
      if (used > 0) {
        throw const CategoryException(
          'This subcategory is used by existing entries. Hide it instead.',
        );
      }
      await txn.delete('subcategories', where: 'id = ?', whereArgs: [id]);
    });
  }
}
