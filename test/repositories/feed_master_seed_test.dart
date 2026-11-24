import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/data/repositories/master_repository.dart';
import 'package:mywallet/data/services/demo_data_seed_service.dart';
import 'package:mywallet/data/services/master_seed_service.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/dashboard/models/dashboard_transaction_model.dart';
import 'package:mywallet/modules/dashboard/repositories/transaction_feed_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/repositories/income_repository.dart';
import 'package:mywallet/modules/investments/models/investment_model.dart';
import 'package:mywallet/modules/investments/repositories/investment_repository.dart';
import 'package:mywallet/modules/loans/models/loan_model.dart';
import 'package:mywallet/modules/loans/repositories/loan_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  group('MasterSeedService', () {
    test(
      'seeds 4 types, the default categories and subcategories once',
      () async {
        await MasterSeedService.seedMasterData();
        final repo = MasterRepository();
        expect(await repo.getTransactionTypes(), hasLength(4));

        final expense = await repo.getCategoriesByType(0);
        final names = expense.map((c) => c['category_name']).toList();
        expect(
          names,
          containsAll([
            'Food & Dining',
            'Travel',
            'Shopping',
            'Bills & Utilities',
            'Health',
            'Entertainment',
          ]),
        );
        final income = await repo.getCategoriesByType(1);
        expect(
          income.map((c) => c['category_name']),
          containsAll(['Salary', 'Business']),
        );

        final food = expense.firstWhere(
          (c) => c['category_name'] == 'Food & Dining',
        );
        final subs = await repo.getSubcategoriesByCategory(food['id'] as int);
        expect(
          subs.map((s) => s['subcategory_name']),
          containsAll(['Breakfast', 'Lunch', 'Dinner', 'Snacks']),
        );

        final before = (await repo.getCategoriesByType(0)).length;
        await MasterSeedService.seedMasterData(); // idempotent
        expect(await repo.getTransactionTypes(), hasLength(4));
        expect((await repo.getCategoriesByType(0)).length, before);
      },
    );
  });

  group('MasterRepository', () {
    test('name lookups and empty fallbacks', () async {
      final catRepo = CategoryRepository();
      final cat = await catRepo.addCategory(0, 'Zz Lookup');
      final sub = await catRepo.addSubcategory(cat, 'Zz Lookup Sub');
      final repo = MasterRepository();
      expect(await repo.getCategoryName(cat), 'Zz Lookup');
      expect(await repo.getSubcategoryName(sub), 'Zz Lookup Sub');
      expect(await repo.getCategoryName(987654), '');
      expect(await repo.getSubcategoryName(987654), '');
    });

    test('hidden categories are filtered unless included', () async {
      final catRepo = CategoryRepository();
      final id = await catRepo.addCategory(0, 'Zz Hide Me');
      await catRepo.setCategoryActive(id, false);
      final repo = MasterRepository();
      ids(List<Map<String, dynamic>> l) => l.map((c) => c['id']).toList();
      expect(ids(await repo.getCategoriesByType(0)), isNot(contains(id)));
      expect(
        ids(await repo.getCategoriesByType(0, alsoIncludeId: id)),
        contains(id),
      );
      expect(
        ids(await repo.getCategoriesByType(0, includeInactive: true)),
        contains(id),
      );
    });

    test('monthly expense chart groups by month with short names', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Chart');
      Future<void> add(int month, double amount) =>
          ExpenseRepository().insertExpense(
            ExpenseModel(
              amount: amount,
              categoryId: cat,
              categoryName: 'x',
              date: DateTime(2026, month, 5).toIso8601String(),
              paymentMode: 'Cash',
              createdAt: iso(2026, month, 5),
            ),
          );
      await add(3, 10);
      await add(3, 20);
      await add(11, 5);
      final chart = await MasterRepository().getMonthlyExpenseChart();
      expect(chart.map((c) => c.month), ['Mar', 'Nov']);
      expect(chart.map((c) => c.amount), [30, 5]);
    });
  });

  group('DemoDataSeedService', () {
    test('fills an empty database once, with a marker', () async {
      await MasterSeedService.seedMasterData();
      await DemoDataSeedService.seedIfDatabaseIsEmpty();
      final db = await AppDatabase.database;
      final expenses = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expenses'),
      )!;
      expect(expenses, greaterThan(0));

      await DemoDataSeedService.seedIfDatabaseIsEmpty(); // no duplicates
      final again = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM expenses'),
      )!;
      expect(again, expenses);
    });

    test(
      'never mixes sample data into a database that already has data',
      () async {
        await MasterSeedService.seedMasterData();
        final cat = await CategoryRepository().addCategory(0, 'Zz Real');
        await ExpenseRepository().insertExpense(
          ExpenseModel(
            amount: 1,
            categoryId: cat,
            categoryName: 'x',
            date: iso(2026, 11, 1),
            paymentMode: 'Cash',
            createdAt: iso(2026, 11, 1),
          ),
        );
        await DemoDataSeedService.seedIfDatabaseIsEmpty();
        final db = await AppDatabase.database;
        final expenses = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM expenses'),
        )!;
        expect(expenses, 1);
      },
    );
  });

  group('TransactionFeedRepository', () {
    test(
      'merges expenses, income, EMIs and investments newest first',
      () async {
        final eCat = await CategoryRepository().addCategory(0, 'Zz Feed E');
        final iCat = await CategoryRepository().addCategory(1, 'Zz Feed I');
        final eSub = await CategoryRepository().addSubcategory(
          eCat,
          'Zz Feed ESub',
        );

        await ExpenseRepository().insertExpense(
          ExpenseModel(
            amount: 100,
            categoryId: eCat,
            subcategoryId: eSub,
            categoryName: 'Zz Feed E',
            date: iso(2026, 11, 1),
            paymentMode: 'UPI',
            notes: 'tea',
            createdAt: iso(2026, 11, 1),
          ),
        );
        await IncomeRepository().insertIncome(
          IncomeModel(
            amount: 5000,
            categoryId: iCat,
            date: iso(2026, 11, 3),
            paymentMode: 'Bank',
            isRecurring: false,
            createdAt: iso(2026, 11, 3),
          ),
        );
        await InvestmentRepository().insertInvestment(
          InvestmentModel(
            investmentType: 'Stocks',
            investmentName: 'Zz Stock',
            investmentPlatform: 'Zerodha',
            investedAmount: 700,
            currentValue: 700,
            investmentDate: iso(2026, 11, 2),
            isSip: false,
            createdAt: iso(2026, 11, 2),
          ),
        );

        final feed = await TransactionFeedRepository().getAll();
        expect(feed.map((t) => t.kind), [
          TransactionKind.income,
          TransactionKind.investment,
          TransactionKind.expense,
        ]);

        final expense = feed.last;
        expect(expense.title, 'Zz Feed E - Zz Feed ESub');
        expect(expense.subtitle, 'UPI');
        expect(expense.isExpense, isTrue);
        expect(expense.extra, 'tea');

        expect(feed.first.title, 'Zz Feed I');
        expect(feed.first.isExpense, isFalse);

        final inv = feed[1];
        expect(inv.title, 'Zz Stock');
        expect(inv.subtitle, 'Stocks • Zerodha');
        expect(inv.isExpense, isTrue);
      },
    );

    test('EMIs show as money out for borrowed and in for lent loans', () async {
      LoanModel loan(String type, String who) => LoanModel(
        loanType: type,
        personName: who,
        principalAmount: 1000,
        interestRate: 0,
        emiAmount: 100,
        nextEmiDate: iso(2026, 12, 1),
        tenureMonths: 10,
        startDate: iso(2026, 11, 1),
        totalPaid: 0,
        outstandingAmount: 1000,
        loanStatus: 'ACTIVE',
        createdAt: iso(2026, 11, 1),
      );
      final repo = LoanRepository();
      final takenId = await repo.insertLoan(loan('TAKEN', 'Zz Bank'));
      final givenId = await repo.insertLoan(loan('GIVEN', 'Zz Friend'));
      await repo.payEmi(
        loan: (await repo.getLoanById(takenId))!,
        paymentAmount: 100,
        paymentMode: 'UPI',
      );
      await repo.payEmi(
        loan: (await repo.getLoanById(givenId))!,
        paymentAmount: 100,
        paymentMode: 'Cash',
      );

      final feed = await TransactionFeedRepository().getAll();
      final emis = feed
          .where((t) => t.kind == TransactionKind.loanEmi)
          .toList();
      expect(emis, hasLength(2));
      final paid = emis.firstWhere((t) => t.title.startsWith('Loan EMI'));
      final received = emis.firstWhere(
        (t) => t.title.startsWith('EMI received'),
      );
      expect(paid.title, 'Loan EMI - Zz Bank');
      expect(paid.isExpense, isTrue);
      expect(paid.subtitle, 'Loan • UPI');
      expect(received.title, 'EMI received - Zz Friend');
      expect(received.isExpense, isFalse);
    });

    test('limit trims to the newest items', () async {
      final cat = await CategoryRepository().addCategory(0, 'Zz Limit');
      for (var d = 1; d <= 5; d++) {
        await ExpenseRepository().insertExpense(
          ExpenseModel(
            amount: d.toDouble(),
            categoryId: cat,
            categoryName: 'x',
            date: iso(2026, 11, d),
            paymentMode: 'Cash',
            createdAt: iso(2026, 11, d),
          ),
        );
      }
      final feed = await TransactionFeedRepository().getAll(limit: 2);
      expect(feed.map((t) => t.amount), [5, 4]);
    });

    test('an empty database gives an empty feed', () async {
      expect(await TransactionFeedRepository().getAll(), isEmpty);
    });
  });
}
