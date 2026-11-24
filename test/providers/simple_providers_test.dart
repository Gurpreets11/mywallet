import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/data/providers/master_provider.dart';
import 'package:mywallet/modules/budgets/models/budget_model.dart';
import 'package:mywallet/modules/budgets/providers/budget_provider.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/providers/expense_provider.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/providers/income_provider.dart';
import 'package:mywallet/modules/navigation/providers/navigation_provider.dart';
import 'package:mywallet/modules/reports/providers/report_provider.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  ExpenseModel expense(
    int cat,
    double amount,
    String name, {
    String? notes,
    String mode = 'Cash',
  }) => ExpenseModel(
    amount: amount,
    categoryId: cat,
    categoryName: name,
    date: DateTime.now().toIso8601String(),
    paymentMode: mode,
    notes: notes,
    createdAt: DateTime.now().toIso8601String(),
  );

  group('NavigationProvider', () {
    test('starts at 0, changes index and notifies', () {
      final p = NavigationProvider();
      var n = 0;
      p.addListener(() => n++);
      expect(p.currentIndex, 0);
      p.changeIndex(3);
      expect(p.currentIndex, 3);
      expect(n, 1);
    });
  });

  group('ExpenseProvider', () {
    test(
      'add, search, update and delete keep lists and totals in sync',
      () async {
        final cat = await CategoryRepository().addCategory(0, 'Zz Prov Food');
        final p = ExpenseProvider();

        await p.addExpense(
          expense(cat, 100, 'Zz Prov Food', notes: 'lunch box'),
        );
        await p.addExpense(
          expense(cat, 50, 'Zz Prov Food', notes: 'tea', mode: 'UPI'),
        );
        expect(p.expenses, hasLength(2));
        expect(p.monthlyExpenseTotal, 150);
        expect(p.isLoading, isFalse);

        p.searchExpense('LUNCH');
        expect(p.filteredExpenses, hasLength(1));
        p.searchExpense('upi');
        expect(p.filteredExpenses.single.notes, 'tea');
        p.searchExpense('   ');
        expect(p.filteredExpenses, hasLength(2));
        p.searchExpense('nothing-matches');
        expect(p.filteredExpenses, isEmpty);
        p.searchExpense('');

        final first = p.expenses.firstWhere((e) => e.notes == 'tea');
        await p.updateExpense(
          ExpenseModel(
            id: first.id,
            amount: 500,
            categoryId: cat,
            categoryName: 'Zz Prov Food',
            date: first.date,
            paymentMode: first.paymentMode,
            createdAt: first.createdAt,
          ),
        );
        expect(p.monthlyExpenseTotal, 600);

        await p.deleteExpense(first.id!);
        expect(p.expenses, hasLength(1));
        expect(p.monthlyExpenseTotal, 100);
      },
    );

    test('lists are unmodifiable', () async {
      final p = ExpenseProvider();
      await p.loadExpenses();
      expect(() => p.expenses.add(expense(1, 1, 'x')), throwsUnsupportedError);
    });
  });

  group('IncomeProvider', () {
    test('add, search and delete', () async {
      final cat = await CategoryRepository().addCategory(1, 'Zz Prov Salary');
      final p = IncomeProvider();
      IncomeModel income(double amt, String notes) => IncomeModel(
        amount: amt,
        categoryId: cat,
        categoryName: 'Zz Prov Salary',
        date: DateTime.now().toIso8601String(),
        paymentMode: 'Bank',
        notes: notes,
        isRecurring: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      await p.addIncome(income(1000, 'april pay'));
      await p.addIncome(income(200, 'gift'));
      expect(p.incomes, hasLength(2));
      expect(p.monthlyIncome, 1200);

      p.searchIncome('GIFT');
      expect(p.filteredIncomes.single.amount, 200);
      p.searchIncome('');
      expect(p.filteredIncomes, hasLength(2));

      await p.deleteIncome(p.incomes.first.id!);
      expect(p.incomes, hasLength(1));
    });
  });

  group('BudgetProvider', () {
    test('save, totals, month navigation and delete', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Prov Budget');
      final now = DateTime.now();
      final p = BudgetProvider();
      await p.load(month: now.month, year: now.year);
      expect(p.budgets, isEmpty);
      expect(p.categories, isNotEmpty);

      await p.save(
        BudgetModel(
          categoryId: cat,
          categoryName: 'Zz Prov Budget',
          amount: 1000,
          month: now.month,
          year: now.year,
        ),
      );
      expect(p.budgets, hasLength(1));
      expect(p.totalBudget, 1000);
      expect(p.totalSpent, 0);
      expect(p.totalRemaining, 1000);

      await p.changeMonth(1);
      final next = DateTime(now.year, now.month + 1, 1);
      expect(p.month, next.month);
      expect(p.year, next.year);
      expect(p.budgets, isEmpty);

      await p.changeMonth(-1);
      expect(p.month, now.month);
      await p.delete(p.budgets.single.id!);
      expect(p.budgets, isEmpty);
    });

    test('changeMonth rolls the year', () async {
      final p = BudgetProvider();
      await p.load(month: 12, year: 2026);
      await p.changeMonth(1);
      expect([p.month, p.year], [1, 2027]);
      await p.changeMonth(-1);
      expect([p.month, p.year], [12, 2026]);
    });
  });

  group('ReportProvider', () {
    test('loads a yearly report and changes year', () async {
      final p = ReportProvider();
      expect(p.report, isNull);
      await p.load(year: 2026);
      expect(p.selectedYear, 2026);
      expect(p.report, isNotNull);
      expect(p.report!.year, 2026);
      expect(p.error, isNull);
      await p.changeYear(2025);
      expect(p.selectedYear, 2025);
      expect(p.report!.year, 2025);
      expect(p.isLoading, isFalse);
    });
  });

  group('MasterProvider', () {
    test('loads categories and subcategories by type', () async {
      final repo = CategoryRepository();
      final expCat = await repo.addCategory(0, 'Zz M Exp');
      final incCat = await repo.addCategory(1, 'Zz M Inc');
      await repo.addSubcategory(expCat, 'Zz M ExpSub');
      await repo.addSubcategory(incCat, 'Zz M IncSub');

      final p = MasterProvider();
      await p.loadExpenseCategories();
      await p.loadIncomeCategories();
      expect(
        p.expenseCategories.map((c) => c['category_name']),
        contains('Zz M Exp'),
      );
      expect(
        p.expenseCategories.map((c) => c['category_name']),
        isNot(contains('Zz M Inc')),
      );
      expect(
        p.incomeCategories.map((c) => c['category_name']),
        contains('Zz M Inc'),
      );

      await p.loadSubcategories(expCat);
      expect(p.subcategories.single['subcategory_name'], 'Zz M ExpSub');
      await p.loadIncomeSubcategories(incCat);
      expect(p.incomeSubCategories.single['subcategory_name'], 'Zz M IncSub');
    });

    test('hidden categories are left out unless asked for', () async {
      final repo = CategoryRepository();
      final id = await repo.addCategory(0, 'Zz Hidden Cat');
      await repo.setCategoryActive(id, false);

      final p = MasterProvider();
      await p.loadExpenseCategories();
      expect(p.expenseCategories.map((c) => c['id']), isNot(contains(id)));
      await p.loadExpenseCategories(alsoIncludeId: id);
      expect(p.expenseCategories.map((c) => c['id']), contains(id));
      await p.loadExpenseCategories(includeInactive: true);
      expect(p.expenseCategories.map((c) => c['id']), contains(id));
    });
  });
}
