import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/modules/budgets/models/budget_model.dart';
import 'package:mywallet/modules/budgets/repositories/budget_repository.dart';
import 'package:mywallet/modules/categories/models/category_item.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();
  final repo = CategoryRepository();

  Future<CategoryItem?> find(int id) async {
    final list = await repo.getCategories(CategoryRepository.expenseType);
    for (final c in list) {
      if (c.id == id) return c;
    }
    return null;
  }

  group('add / rename / hide / delete', () {
    test('adds a category and rejects a duplicate name', () async {
      final id = await repo.addCategory(0, 'Zz Hobbies');
      expect((await find(id))!.name, 'Zz Hobbies');
      expect(
        () => repo.addCategory(0, 'zz hobbies'),
        throwsA(isA<CategoryException>()),
      );
    });

    test('rejects empty and very long names', () async {
      expect(
        () => repo.addCategory(0, '   '),
        throwsA(isA<CategoryException>()),
      );
      expect(
        () => repo.addCategory(0, 'x' * 100),
        throwsA(isA<CategoryException>()),
      );
    });

    test('rename updates the name stored on existing entries', () async {
      final id = await repo.addCategory(0, 'Zz Old Name');
      final expenseId = await ExpenseRepository().insertExpense(
        ExpenseModel(
          amount: 5,
          categoryId: id,
          categoryName: 'Zz Old Name',
          date: iso(2026, 11, 2),
          paymentMode: 'Cash',
          createdAt: iso(2026, 11, 2),
        ),
      );
      await repo.renameCategory(id, 0, 'Zz New Name');

      expect((await find(id))!.name, 'Zz New Name');
      final e = await ExpenseRepository().getExpenseById(expenseId);
      expect(e!.categoryName, 'Zz New Name');
    });

    test('hiding keeps the category but marks it inactive', () async {
      final id = await repo.addCategory(0, 'Zz Hide Me');
      await repo.setCategoryActive(id, false);
      expect((await find(id))!.isActive, isFalse);
      await repo.setCategoryActive(id, true);
      expect((await find(id))!.isActive, isTrue);
    });

    test('a used category cannot be deleted, an unused one can', () async {
      final used = await repo.addCategory(0, 'Zz Used');
      await ExpenseRepository().insertExpense(
        ExpenseModel(
          amount: 5,
          categoryId: used,
          categoryName: 'Zz Used',
          date: iso(2026, 11, 2),
          paymentMode: 'Cash',
          createdAt: iso(2026, 11, 2),
        ),
      );
      expect(
        () => repo.deleteCategory(used),
        throwsA(isA<CategoryException>()),
      );

      final unused = await repo.addCategory(0, 'Zz Unused');
      await repo.deleteCategory(unused);
      expect(await find(unused), isNull);
    });
  });

  group('style and order', () {
    test('saves and clears icon and colour', () async {
      final id = await repo.addCategory(0, 'Zz Styled');
      await repo.setCategoryStyle(id, 'food', '#E53935');
      var c = (await find(id))!;
      expect(c.iconName, 'food');
      expect(c.colorCode, '#E53935');

      await repo.setCategoryStyle(id, null, null);
      c = (await find(id))!;
      expect(c.iconName, isNull);
      expect(c.colorCode, isNull);
    });

    test('new categories go last and can be moved up and down', () async {
      final a = await repo.addCategory(0, 'Zz Order A');
      final b = await repo.addCategory(0, 'Zz Order B');
      final c = await repo.addCategory(0, 'Zz Order C');

      Future<List<int>> order() async {
        final list = await repo.getCategories(0);
        return [
          for (final x in list)
            if ([a, b, c].contains(x.id)) x.id,
        ];
      }

      expect(await order(), [a, b, c]);
      await repo.moveCategory(c, 0, -1);
      expect(await order(), [a, c, b]);
      await repo.moveCategory(a, 0, 1);
      expect(await order(), [c, a, b]);
    });

    test('moving the first item up does nothing', () async {
      // Arrange: Create a category.
      final firstId = await repo.addCategory(0, 'Zz First Category');

      // Act: Try moving the first category up.
      await repo.moveCategory(firstId, 0, -1);

      // Assert: Its position should remain unchanged.
      final list = await repo.getCategories(0);

      expect(list.first.id, firstId);
    });
  });

  group('merge', () {
    test('moves entries, combines subcategories and adds budgets', () async {
      final src = await repo.addCategory(0, 'Zz Merge Source');
      final dst = await repo.addCategory(0, 'Zz Merge Target');
      final srcLunch = await repo.addSubcategory(src, 'Lunch');
      final srcTea = await repo.addSubcategory(src, 'Tea');
      final dstLunch = await repo.addSubcategory(dst, 'lunch');

      final expenses = ExpenseRepository();
      final e1 = await expenses.insertExpense(
        ExpenseModel(
          amount: 100,
          categoryId: src,
          categoryName: 'Zz Merge Source',
          subcategoryId: srcLunch,
          subcategoryName: 'Lunch',
          date: iso(2026, 11, 3),
          paymentMode: 'Cash',
          createdAt: iso(2026, 11, 3),
        ),
      );

      final budgets = BudgetRepository();
      await budgets.saveBudget(
        BudgetModel(
          categoryId: src,
          categoryName: 'Zz Merge Source',
          amount: 1000,
          month: 11,
          year: 2026,
        ),
      );
      await budgets.saveBudget(
        BudgetModel(
          categoryId: dst,
          categoryName: 'Zz Merge Target',
          amount: 500,
          month: 11,
          year: 2026,
        ),
      );

      await repo.mergeCategories(src, dst);

      expect(await find(src), isNull);

      final moved = await expenses.getExpenseById(e1);
      expect(moved!.categoryId, dst);
      expect(moved.categoryName, 'Zz Merge Target');
      expect(moved.subcategoryId, dstLunch);

      final target = (await find(dst))!;
      final subNames = target.subcategories.map((s) => s.name).toSet();
      expect(subNames, containsAll(['lunch', 'Tea']));
      expect(target.subcategories.where((s) => s.id == srcTea), hasLength(1));
      expect(target.subcategories.where((s) => s.id == srcLunch), isEmpty);

      final list = await budgets.getBudgets(month: 11, year: 2026);
      final mine = list.where((b) => b.categoryId == dst).toList();
      expect(mine, hasLength(1));
      expect(mine.first.amount, 1500);
      expect(list.where((b) => b.categoryId == src), isEmpty);
    });

    test('refuses to merge a category into itself or across types', () async {
      final expenseCat = await repo.addCategory(0, 'Zz Same Type');
      final incomeCat = await repo.addCategory(1, 'Zz Other Type');
      expect(
        () => repo.mergeCategories(expenseCat, expenseCat),
        throwsA(isA<CategoryException>()),
      );
      expect(
        () => repo.mergeCategories(expenseCat, incomeCat),
        throwsA(isA<CategoryException>()),
      );
      // Nothing was lost.
      final db = await AppDatabase.database;
      final rows = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [expenseCat],
      );
      expect(rows, hasLength(1));
    });
  });
}
