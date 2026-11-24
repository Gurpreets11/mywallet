import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/investments/models/investment_model.dart';
import 'package:mywallet/modules/investments/repositories/investment_repository.dart';
import 'package:mywallet/modules/recurring/models/recurring_transaction_model.dart';
import 'package:mywallet/modules/recurring/repositories/recurring_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  group('RecurringRepository', () {
    Future<RecurringTransactionModel> schedule({
      String type = 'EXPENSE',
      String? endDate,
      int? reminderDays,
    }) async {
      final cat = await CategoryRepository().addCategory(
        type == 'EXPENSE' ? 0 : 1,
        'Zz Rec ${DateTime.now().microsecondsSinceEpoch}',
      );
      return RecurringTransactionModel(
        title: 'Rent',
        transactionType: type,
        amount: 15000,
        categoryId: cat,
        categoryName: 'Rent',
        paymentMode: 'UPI',
        frequency: 'MONTHLY',
        startDate: '2026-01-15',
        endDate: endDate,
        nextDueDate: '2026-01-15',
        createdAt: iso(2026, 1, 1),
        reminderDays: reminderDays,
      );
    }

    test('creates every missed occurrence once', () async {
      final repo = RecurringRepository();
      final id = await repo.insert(await schedule());

      final made = await repo.generateDueTransactions(
        now: DateTime(2026, 3, 20),
      );
      expect(made, 3); // 15 Jan, 15 Feb, 15 Mar
      expect(await repo.occurrenceCount(id), 3);

      final all = await repo.getAll();
      expect(all.firstWhere((s) => s.id == id).nextDueDate, '2026-04-15');

      final db = await AppDatabase.database;
      final expenses = await db.query('expenses');
      expect(expenses, hasLength(3));

      // Running again the same day adds nothing.
      expect(await repo.generateDueTransactions(now: DateTime(2026, 3, 20)), 0);
    });

    test('income schedules create income', () async {
      final repo = RecurringRepository();
      await repo.insert(await schedule(type: 'INCOME'));
      await repo.generateDueTransactions(now: DateTime(2026, 1, 20));
      final db = await AppDatabase.database;
      expect(await db.query('incomes'), hasLength(1));
      expect(await db.query('expenses'), isEmpty);
    });

    test('completes after the end date', () async {
      final repo = RecurringRepository();
      final id = await repo.insert(await schedule(endDate: '2026-02-20'));
      final made = await repo.generateDueTransactions(
        now: DateTime(2026, 6, 1),
      );
      expect(made, 2);
      final s = (await repo.getAll()).firstWhere((x) => x.id == id);
      expect(s.status, 'COMPLETED');
    });

    test('paused schedules are skipped', () async {
      final repo = RecurringRepository();
      final id = await repo.insert(await schedule());
      await repo.setStatus(id, 'PAUSED');
      expect(await repo.generateDueTransactions(now: DateTime(2026, 6, 1)), 0);
      await repo.setStatus(id, 'ACTIVE');
      expect(await repo.generateDueTransactions(now: DateTime(2026, 1, 15)), 1);
    });

    test('skip next moves the due date without creating anything', () async {
      final repo = RecurringRepository();
      final id = await repo.insert(await schedule());
      await repo.skipNext(id);
      final s = (await repo.getAll()).firstWhere((x) => x.id == id);
      expect(s.nextDueDate, '2026-02-15');
      final db = await AppDatabase.database;
      expect(await db.query('expenses'), isEmpty);
    });

    test('edit keeps the reminder setting', () async {
      final repo = RecurringRepository();
      final id = await repo.insert(await schedule(reminderDays: 3));
      var s = (await repo.getAll()).firstWhere((x) => x.id == id);
      expect(s.reminderDays, 3);

      await repo.update(
        RecurringTransactionModel(
          id: id,
          title: 'Rent (edited)',
          transactionType: s.transactionType,
          amount: 16000,
          categoryId: s.categoryId,
          categoryName: s.categoryName,
          paymentMode: s.paymentMode,
          frequency: s.frequency,
          startDate: s.startDate,
          nextDueDate: s.nextDueDate,
          createdAt: s.createdAt,
          reminderDays: null,
        ),
      );
      s = (await repo.getAll()).firstWhere((x) => x.id == id);
      expect(s.title, 'Rent (edited)');
      expect(s.amount, 16000);
      expect(s.reminderDays, isNull);
    });

    test('month ends are handled (31 Jan -> 28 Feb)', () async {
      final repo = RecurringRepository();
      final cat = await CategoryRepository().addCategory(0, 'Zz Month End');
      final id = await repo.insert(
        RecurringTransactionModel(
          title: 'Month end',
          transactionType: 'EXPENSE',
          amount: 10,
          categoryId: cat,
          categoryName: 'Month End',
          paymentMode: 'Cash',
          frequency: 'MONTHLY',
          startDate: '2026-01-31',
          nextDueDate: '2026-01-31',
          createdAt: iso(2026, 1, 1),
        ),
      );
      await repo.generateDueTransactions(now: DateTime(2026, 1, 31));
      final s = (await repo.getAll()).firstWhere((x) => x.id == id);
      expect(s.nextDueDate, '2026-02-28');
    });
  });

  group('InvestmentRepository', () {
    InvestmentModel investment() => InvestmentModel(
      investmentType: 'Mutual Fund',
      investmentName: 'Index fund',
      investedAmount: 1000,
      currentValue: 1000,
      investmentDate: iso(2026, 1, 1),
      isSip: false,
      createdAt: iso(2026, 1, 1),
    );

    test('starts a value history and follows the newest value', () async {
      final repo = InvestmentRepository();
      final id = await repo.insertInvestment(investment());
      expect(await repo.getValuations(id), hasLength(1));

      await repo.addValuation(
        investmentId: id,
        value: 1500,
        date: DateTime(2026, 6, 1),
      );
      await repo.addValuation(
        investmentId: id,
        value: 1200,
        date: DateTime(2026, 3, 1),
      );
      final all = await repo.getAllInvestments();
      expect(all.firstWhere((i) => i.id == id).currentValue, 1500);
      expect(await repo.getValuations(id), hasLength(3));
    });

    test('deleting the newest value falls back to the previous one', () async {
      final repo = InvestmentRepository();
      final id = await repo.insertInvestment(investment());
      await repo.addValuation(
        investmentId: id,
        value: 1800,
        date: DateTime(2026, 6, 1),
      );
      final history = await repo.getValuations(id);
      final newest = history.firstWhere((v) => v.value == 1800);
      await repo.deleteValuation(newest.id!, id);
      final inv = (await repo.getAllInvestments()).firstWhere(
        (i) => i.id == id,
      );
      expect(inv.currentValue, 1000);
    });

    test('delete with history can be undone', () async {
      final repo = InvestmentRepository();
      final id = await repo.insertInvestment(investment());
      await repo.addValuation(
        investmentId: id,
        value: 1300,
        date: DateTime(2026, 5, 1),
      );
      final item = (await repo.getAllInvestments()).firstWhere(
        (i) => i.id == id,
      );

      final history = await repo.deleteInvestmentWithHistory(id);
      expect(history, hasLength(2));
      expect(
        (await repo.getAllInvestments()).where((i) => i.id == id),
        isEmpty,
      );
      expect(await repo.getValuations(id), isEmpty);

      await repo.restoreInvestment(item, history);
      final back = (await repo.getAllInvestments()).firstWhere(
        (i) => i.id == id,
      );
      expect(back.investmentName, 'Index fund');
      expect(back.currentValue, 1300);
      expect(await repo.getValuations(id), hasLength(2));
    });
  });
}
