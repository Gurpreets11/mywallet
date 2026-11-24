import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/accounts/models/account_model.dart';
import 'package:mywallet/modules/accounts/repositories/account_repository.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/repositories/income_repository.dart';
import 'package:mywallet/modules/loans/models/loan_model.dart';
import 'package:mywallet/modules/loans/repositories/loan_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  group('AccountRepository', () {
    test('always has a default account', () async {
      final repo = AccountRepository();
      final def = await repo.ensureDefaultAccount();
      expect(def.isDefault, isTrue);
      expect(await repo.getAccounts(), isNotEmpty);
    });

    test('balances follow income, expenses and transfers', () async {
      final repo = AccountRepository();
      final def = await repo.ensureDefaultAccount();
      final bankId = await repo.addAccount(
        AccountModel(
          name: 'Zz Bank',
          type: AccountType.bank,
          openingBalance: 500,
          createdAt: iso(2026, 11, 1),
        ),
      );
      final expenseCat = await CategoryRepository().addCategory(0, 'Zz Acc E');
      final incomeCat = await CategoryRepository().addCategory(1, 'Zz Acc I');

      // Expense with no account counts against the default account.
      await ExpenseRepository().insertExpense(
        ExpenseModel(
          amount: 100,
          categoryId: expenseCat,
          categoryName: 'Zz Acc E',
          date: iso(2026, 11, 2),
          paymentMode: 'Cash',
          createdAt: iso(2026, 11, 2),
        ),
      );
      await IncomeRepository().insertIncome(
        IncomeModel(
          amount: 300,
          categoryId: incomeCat,
          date: iso(2026, 11, 2),
          paymentMode: 'Bank Transfer',
          isRecurring: false,
          createdAt: iso(2026, 11, 2),
          accountId: bankId,
        ),
      );
      await repo.addTransfer(
        AccountTransferModel(
          fromAccountId: def.id!,
          toAccountId: bankId,
          amount: 50,
          date: iso(2026, 11, 3),
          createdAt: iso(2026, 11, 3),
        ),
      );

      final balances = await repo.getAccountBalances();
      final d = balances.firstWhere((b) => b.account.id == def.id);
      final b = balances.firstWhere((x) => x.account.id == bankId);
      expect(d.moneyOut, 150); // expense + transfer out
      expect(d.moneyIn, 0);
      expect(b.moneyIn, 350); // income + transfer in
      expect(b.balance, 850); // 500 opening + 350
    });

    test('transfers can be edited and deleted', () async {
      final repo = AccountRepository();
      final def = await repo.ensureDefaultAccount();
      final otherId = await repo.addAccount(
        AccountModel(
          name: 'Zz Wallet',
          type: AccountType.upi,
          createdAt: iso(2026, 11, 1),
        ),
      );
      final id = await repo.addTransfer(
        AccountTransferModel(
          fromAccountId: def.id!,
          toAccountId: otherId,
          amount: 80,
          date: iso(2026, 11, 3),
          createdAt: iso(2026, 11, 3),
        ),
      );
      var list = await repo.getTransfers();
      final saved = list.firstWhere((t) => t.id == id);

      await repo.updateTransfer(
        AccountTransferModel(
          id: id,
          fromAccountId: def.id!,
          toAccountId: otherId,
          amount: 120,
          date: saved.date,
          notes: 'edited',
          createdAt: saved.createdAt,
        ),
      );
      list = await repo.getTransfers();
      final edited = list.firstWhere((t) => t.id == id);
      expect(edited.amount, 120);
      expect(edited.notes, 'edited');
      expect(edited.createdAt, saved.createdAt);

      await repo.deleteTransfer(id);
      list = await repo.getTransfers();
      expect(list.where((t) => t.id == id), isEmpty);
    });
  });

  group('LoanRepository', () {
    LoanModel loan({String type = 'BORROWED', double amount = 1000}) =>
        LoanModel(
          loanType: type,
          personName: 'Asha',
          principalAmount: amount,
          interestRate: 0,
          emiAmount: 500,
          nextEmiDate: iso(2026, 12, 1),
          tenureMonths: 2,
          startDate: iso(2026, 11, 1),
          totalPaid: 0,
          outstandingAmount: amount,
          loanStatus: 'ACTIVE',
          createdAt: iso(2026, 11, 1),
        );

    test('paying EMIs reduces the balance and closes the loan', () async {
      final repo = LoanRepository();
      final id = await repo.insertLoan(loan());

      var current = (await repo.getLoanById(id))!;
      await repo.payEmi(loan: current, paymentAmount: 500, paymentMode: 'Cash');
      current = (await repo.getLoanById(id))!;
      expect(current.outstandingAmount, 500);
      expect(current.totalPaid, 500);
      expect(current.loanStatus, 'ACTIVE');
      expect(DateTime.parse(current.nextEmiDate!).month, 1); // moved a month

      await repo.payEmi(loan: current, paymentAmount: 500, paymentMode: 'Cash');
      current = (await repo.getLoanById(id))!;
      expect(current.outstandingAmount, 0);
      expect(current.loanStatus, 'CLOSED');
      expect(await repo.getLoanPayments(id), hasLength(2));
    });

    test('an overpayment never goes below zero', () async {
      final repo = LoanRepository();
      final id = await repo.insertLoan(loan(amount: 300));
      final current = (await repo.getLoanById(id))!;
      await repo.payEmi(loan: current, paymentAmount: 900, paymentMode: 'UPI');
      expect((await repo.getLoanById(id))!.outstandingAmount, 0);
    });

    test('delete with payments can be undone', () async {
      final repo = LoanRepository();
      final id = await repo.insertLoan(loan());
      final current = (await repo.getLoanById(id))!;
      await repo.payEmi(loan: current, paymentAmount: 500, paymentMode: 'Cash');
      final before = (await repo.getLoanById(id))!;

      final payments = await repo.deleteLoanWithPayments(id);
      expect(payments, hasLength(1));
      expect(await repo.getLoanById(id), isNull);
      expect(await repo.getLoanPayments(id), isEmpty);

      await repo.restoreLoan(before, payments);
      final back = (await repo.getLoanById(id))!;
      expect(back.personName, 'Asha');
      expect(back.totalPaid, 500);
      expect(await repo.getLoanPayments(id), hasLength(1));
    });

    test('totals only count loans still owed', () async {
      final repo = LoanRepository();
      await repo.insertLoan(loan(amount: 1000));
      await repo.insertLoan(loan(amount: 400));
      expect(await repo.getTotalOutstandingLoan(), 1400);
      expect(await repo.getActiveLoanCount(), 2);
    });
  });
}
