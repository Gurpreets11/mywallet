import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/accounts/models/account_model.dart';
import 'package:mywallet/modules/accounts/repositories/account_repository.dart';
import 'package:mywallet/modules/categories/repositories/category_repository.dart';
import 'package:mywallet/modules/dashboard/repositories/month_insights_repository.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/repositories/expense_repository.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/repositories/income_repository.dart';
import 'package:mywallet/modules/investments/models/investment_model.dart';
import 'package:mywallet/modules/investments/repositories/investment_repository.dart';
import 'package:mywallet/modules/loans/models/loan_model.dart';
import 'package:mywallet/modules/loans/repositories/loan_repository.dart';
import 'package:mywallet/modules/networth/repositories/net_worth_repository.dart';
import 'package:mywallet/modules/reports/repositories/report_repository.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  Future<void> addExpense(int cat, double amount, DateTime date) =>
      ExpenseRepository()
          .insertExpense(
            ExpenseModel(
              amount: amount,
              categoryId: cat,
              categoryName: 'Zz Rep E',
              date: date.toIso8601String(),
              paymentMode: 'Cash',
              createdAt: date.toIso8601String(),
            ),
          )
          .then((_) {});

  Future<void> addIncome(int cat, double amount, DateTime date) =>
      IncomeRepository()
          .insertIncome(
            IncomeModel(
              amount: amount,
              categoryId: cat,
              date: date.toIso8601String(),
              paymentMode: 'Cash',
              isRecurring: false,
              createdAt: date.toIso8601String(),
            ),
          )
          .then((_) {});

  group('ReportRepository', () {
    test('adds up the selected year only', () async {
      final e = await CategoryRepository().addCategory(0, 'Zz Rep E');
      final i = await CategoryRepository().addCategory(1, 'Zz Rep I');
      await addExpense(e, 100, DateTime(2026, 3, 5));
      await addExpense(e, 50, DateTime(2026, 12, 31, 23, 59));
      await addExpense(e, 999, DateTime(2025, 12, 31));
      await addExpense(e, 999, DateTime(2027, 1, 1));
      await addIncome(i, 1000, DateTime(2026, 3, 1));

      final report = await ReportRepository().getYearlyReport(2026);
      expect(report.year, 2026);
      expect(report.totalExpense, 150);
      expect(report.totalIncome, 1000);
      expect(report.netSavings, 850);
    });

    test('an empty year is all zeros, not an error', () async {
      final report = await ReportRepository().getYearlyReport(2001);
      expect(report.totalExpense, 0);
      expect(report.totalIncome, 0);
    });
  });

  group('NetWorthRepository', () {
    test('combines accounts, investments and loans', () async {
      final accounts = AccountRepository();
      final def = await accounts.ensureDefaultAccount();
      await accounts.updateAccount(
        AccountModel(
          id: def.id,
          name: def.name,
          type: def.type,
          openingBalance: 1000,
          isDefault: true,
          createdAt: def.createdAt,
        ),
      );

      await InvestmentRepository().insertInvestment(
        InvestmentModel(
          investmentType: 'Stock',
          investmentName: 'Zz Stock',
          investedAmount: 0,
          currentValue: 2000,
          investmentDate: iso(2026, 1, 1),
          isSip: false,
          createdAt: iso(2026, 1, 1),
        ),
      );

      LoanModel loan(String type, double amount) => LoanModel(
        loanType: type,
        personName: 'P',
        principalAmount: amount,
        interestRate: 0,
        emiAmount: 0,
        nextEmiDate: null,
        tenureMonths: 1,
        startDate: iso(2026, 1, 1),
        totalPaid: 0,
        outstandingAmount: amount,
        loanStatus: 'ACTIVE',
        createdAt: iso(2026, 1, 1),
      );
      await LoanRepository().insertLoan(loan('GIVEN', 300));
      await LoanRepository().insertLoan(loan('BORROWED', 500));

      final result = await NetWorthRepository().load();
      final n = result.current;
      expect(n.cash, 1000);
      expect(n.investments, 2000);
      expect(n.receivable, 300);
      expect(n.liabilities, 500);
      expect(n.netWorth, 2800);
      expect(result.trend, isNotEmpty);
      // The newest point is today's figure.
      expect(result.trend.last.snapshot.netWorth, closeTo(2800, 0.01));
    });
  });

  group('MonthInsightsRepository', () {
    test('compares this month with the same days last month', () async {
      final e = await CategoryRepository().addCategory(0, 'Zz Rep E');
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      await addExpense(e, 400, thisMonth);
      await addExpense(e, 100, lastMonth);

      final insights = await MonthInsightsRepository().load();
      expect(insights.expenseThisMonth, 400);
      expect(insights.expenseLastMonthTotal, greaterThanOrEqualTo(100));
      expect(insights.topCategories, isNotEmpty);
    });
  });
}
