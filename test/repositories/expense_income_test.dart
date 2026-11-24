import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/repositories/income_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  Future<int> category(int type, String name) =>
      CategoryRepository().addCategory(type, name);

  ExpenseModel expense(int categoryId, double amount, {String? notes}) =>
      ExpenseModel(
        amount: amount,
        categoryId: categoryId,
        categoryName: 'Test',
        date: iso(2026, 11, 10),
        paymentMode: 'Cash',
        notes: notes,
        createdAt: iso(2026, 11, 10),
      );

  group('ExpenseRepository', () {
    test('insert, read, update and delete', () async {
      final repo = ExpenseRepository();
      final cat = await category(0, 'Zz Expense Cat');

      final id = await repo.insertExpense(expense(cat, 250, notes: 'lunch'));
      expect(id, greaterThan(0));

      final loaded = await repo.getExpenseById(id);
      expect(loaded, isNotNull);
      expect(loaded!.amount, 250);
      expect(loaded.notes, 'lunch');

      final all = await repo.getAllExpenses();
      expect(all.where((e) => e.id == id), hasLength(1));

      await repo.updateExpense(
        ExpenseModel(
          id: id,
          amount: 300,
          categoryId: cat,
          categoryName: 'Test',
          date: loaded.date,
          paymentMode: 'UPI',
          notes: 'dinner',
          createdAt: loaded.createdAt,
        ),
      );
      final edited = await repo.getExpenseById(id);
      expect(edited!.amount, 300);
      expect(edited.paymentMode, 'UPI');

      await repo.deleteExpense(id);
      expect(await repo.getExpenseById(id), isNull);
    });

    test('search finds entries by notes', () async {
      final repo = ExpenseRepository();
      final cat = await category(0, 'Zz Search Cat');
      await repo.insertExpense(expense(cat, 10, notes: 'pizza night'));
      await repo.insertExpense(expense(cat, 20, notes: 'bus ticket'));

      final found = await repo.searchExpenses('pizza');
      expect(found, hasLength(1));
      expect(found.first.amount, 10);
    });
  });

  group('IncomeRepository', () {
    test('insert, read, update and delete', () async {
      final repo = IncomeRepository();
      final cat = await category(1, 'Zz Income Cat');

      final id = await repo.insertIncome(
        IncomeModel(
          amount: 50000,
          categoryId: cat,
          date: iso(2026, 11, 1),
          paymentMode: 'Bank Transfer',
          isRecurring: false,
          createdAt: iso(2026, 11, 1),
        ),
      );
      var all = await repo.getAllIncomes();
      expect(all.where((i) => i.id == id), hasLength(1));
      expect(all.firstWhere((i) => i.id == id).amount, 50000);

      await repo.updateIncome(
        IncomeModel(
          id: id,
          amount: 52000,
          categoryId: cat,
          date: iso(2026, 11, 1),
          paymentMode: 'Bank Transfer',
          isRecurring: false,
          createdAt: iso(2026, 11, 1),
        ),
      );
      all = await repo.getAllIncomes();
      expect(all.firstWhere((i) => i.id == id).amount, 52000);

      await repo.deleteIncome(id);
      all = await repo.getAllIncomes();
      expect(all.where((i) => i.id == id), isEmpty);
    });
  });
}
