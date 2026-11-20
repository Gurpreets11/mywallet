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
      SELECT c.id, c.category_name, c.icon_name, c.color_code,
        COALESCE(c.is_active, 1) AS is_active,
        (SELECT COUNT(*) FROM expenses e WHERE e.category_id = c.id)
        + (SELECT COUNT(*) FROM incomes i WHERE i.category_id = c.id)
        + (SELECT COUNT(*) FROM budgets b WHERE b.category_id = c.id)
        + (SELECT COUNT(*) FROM recurring_transactions r
             WHERE r.category_id = c.id) AS used
      FROM categories c
      WHERE c.transaction_type_id = ?
      ORDER BY COALESCE(c.sort_order, c.id), c.id
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
          iconName: r['icon_name'] as String?,
          colorCode: r['color_code'] as String?,
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

    final maxOrder = await db.rawQuery(
      'SELECT COALESCE(MAX(COALESCE(sort_order, id)), 0) AS m FROM categories',
    );
    return db.insert('categories', {
      'sort_order': ((maxOrder.first['m'] as num?)?.toInt() ?? 0) + 1,
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

  /// Sets the icon and colour (either may be null to go back to default).
  Future<void> setCategoryStyle(int id, String? iconName, String? colorCode) async {
    final Database db = await AppDatabase.database;
    await db.update(
      'categories',
      {'icon_name': iconName, 'color_code': colorCode},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Moves a category one step up (-1) or down (+1) within its type.
  Future<void> moveCategory(int id, int typeId, int delta) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'categories',
        columns: ['id'],
        where: 'transaction_type_id = ?',
        whereArgs: [typeId],
        orderBy: 'COALESCE(sort_order, id), id',
      );
      final ids = [for (final r in rows) r['id'] as int];
      final from = ids.indexOf(id);
      final to = from + delta;
      if (from < 0 || to < 0 || to >= ids.length) return;
      ids.insert(to, ids.removeAt(from));
      for (var i = 0; i < ids.length; i++) {
        await txn.update(
          'categories',
          {'sort_order': i + 1},
          where: 'id = ?',
          whereArgs: [ids[i]],
        );
      }
    });
  }

  Future<bool> _hasColumn(DatabaseExecutor db, String table, String col) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    return info.any((c) => c['name'] == col);
  }

  /// Moves everything from [sourceId] into [targetId] (same type) and removes
  /// the source category. Same-named subcategories are combined; budgets for
  /// the same month are added together.
  Future<void> mergeCategories(int sourceId, int targetId) async {
    if (sourceId == targetId) {
      throw const CategoryException('Pick a different category');
    }
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      final t = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [targetId],
        limit: 1,
      );
      final s = await txn.query(
        'categories',
        where: 'id = ?',
        whereArgs: [sourceId],
        limit: 1,
      );
      if (t.isEmpty || s.isEmpty) {
        throw const CategoryException('Category not found');
      }
      if (t.first['transaction_type_id'] != s.first['transaction_type_id']) {
        throw const CategoryException(
          'Only categories of the same type can be merged',
        );
      }
      final targetName = (t.first['category_name'] ?? '').toString();

      // Subcategories: reuse a same-named one in the target, else move it.
      final targetSubs = await txn.query(
        'subcategories',
        where: 'category_id = ?',
        whereArgs: [targetId],
      );
      final byName = {
        for (final r in targetSubs)
          (r['subcategory_name'] ?? '').toString().toLowerCase(): r['id'] as int,
      };
      final sourceSubs = await txn.query(
        'subcategories',
        where: 'category_id = ?',
        whereArgs: [sourceId],
      );
      for (final sub in sourceSubs) {
        final subId = sub['id'] as int;
        final name = (sub['subcategory_name'] ?? '').toString();
        final existing = byName[name.toLowerCase()];
        if (existing == null) {
          await txn.update(
            'subcategories',
            {'category_id': targetId},
            where: 'id = ?',
            whereArgs: [subId],
          );
        } else {
          for (final table in ['expenses', 'incomes']) {
            await txn.update(
              table,
              {'subcategory_id': existing},
              where: 'subcategory_id = ?',
              whereArgs: [subId],
            );
          }
          await txn.delete('subcategories', where: 'id = ?', whereArgs: [subId]);
        }
      }

      // Entries and schedules.
      for (final table in ['expenses', 'incomes', 'recurring_transactions']) {
        final values = <String, Object?>{'category_id': targetId};
        if (await _hasColumn(txn, table, 'category_name')) {
          values['category_name'] = targetName;
        }
        await txn.update(
          table,
          values,
          where: 'category_id = ?',
          whereArgs: [sourceId],
        );
      }

      // Budgets (one per category and month).
      final budgets = await txn.query(
        'budgets',
        where: 'category_id = ?',
        whereArgs: [sourceId],
      );
      for (final b in budgets) {
        final clash = await txn.query(
          'budgets',
          where: 'category_id = ? AND month = ? AND year = ?',
          whereArgs: [targetId, b['month'], b['year']],
          limit: 1,
        );
        if (clash.isEmpty) {
          await txn.update(
            'budgets',
            {'category_id': targetId, 'category_name': targetName},
            where: 'id = ?',
            whereArgs: [b['id']],
          );
        } else {
          final sum =
              ((clash.first['amount'] as num?) ?? 0).toDouble() +
              ((b['amount'] as num?) ?? 0).toDouble();
          await txn.update(
            'budgets',
            {'amount': sum},
            where: 'id = ?',
            whereArgs: [clash.first['id']],
          );
          await txn.delete('budgets', where: 'id = ?', whereArgs: [b['id']]);
        }
      }

      await txn.delete('categories', where: 'id = ?', whereArgs: [sourceId]);
    });
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

  Future<void> renameSubcategory(
    int id,
    int categoryId,
    String rawName,
  ) async {
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
