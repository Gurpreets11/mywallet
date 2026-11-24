import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/data/models/category_model.dart';
import 'package:mywallet/data/models/subcategory_model.dart';
import 'package:mywallet/data/models/transaction_type_model.dart';
import 'package:mywallet/modules/accounts/models/account_model.dart';
import 'package:mywallet/modules/budgets/models/budget_model.dart';
import 'package:mywallet/modules/dashboard/models/dashboard_transaction_model.dart';
import 'package:mywallet/modules/dashboard/models/month_insights.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/goals/models/savings_goal_model.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/investments/models/investment_model.dart';
import 'package:mywallet/modules/investments/models/investment_valuation_model.dart';
import 'package:mywallet/modules/loans/models/loan_model.dart';
import 'package:mywallet/modules/loans/models/loan_payment_model.dart';
import 'package:mywallet/modules/networth/models/net_worth_models.dart';
import 'package:mywallet/modules/recurring/models/recurring_transaction_model.dart';
import 'package:mywallet/modules/reports/models/report_models.dart';

void main() {
  const ts = '2026-11-10T10:00:00.000';

  group('master models', () {
    test('CategoryModel', () {
      final m = CategoryModel(
        id: 3,
        transactionTypeId: 1,
        categoryName: 'Salary',
        iconName: 'work',
        colorCode: '#112233',
        createdAt: ts,
      );
      final back = CategoryModel.fromMap(m.toMap());
      expect(back.toMap(), m.toMap());
      expect(back.isActive, 1);
    });

    test('SubcategoryModel', () {
      final m = SubcategoryModel(
        id: 2,
        categoryId: 1,
        subcategoryName: 'Lunch',
        createdAt: ts,
      );
      expect(SubcategoryModel.fromMap(m.toMap()).toMap(), m.toMap());
    });

    test('TransactionTypeModel', () {
      final m = TransactionTypeModel(id: 1, typeName: 'Expense');
      expect(TransactionTypeModel.fromMap(m.toMap()).typeName, 'Expense');
    });
  });

  group('transactions', () {
    test('ExpenseModel round trip', () {
      final m = ExpenseModel(
        id: 1,
        amount: 99.5,
        categoryId: 2,
        subcategoryId: 4,
        categoryName: 'Food',
        subcategoryName: 'Lunch',
        date: ts,
        paymentMode: 'UPI',
        notes: 'n',
        createdAt: ts,
        accountId: 7,
      );
      expect(ExpenseModel.fromMap(m.toMap()).toMap(), m.toMap());
    });

    test('IncomeModel round trip keeps the recurring flag', () {
      final m = IncomeModel(
        id: 1,
        amount: 5000,
        categoryId: 1,
        date: ts,
        paymentMode: 'Bank',
        isRecurring: true,
        recurringType: 'Monthly',
        createdAt: ts,
      );
      final map = m.toMap();
      expect(map['is_recurring'], 1);
      final back = IncomeModel.fromMap(map);
      expect(back.isRecurring, isTrue);
      expect(back.recurringType, 'Monthly');
      expect(
        IncomeModel.fromMap({...map, 'is_recurring': 0}).isRecurring,
        isFalse,
      );
    });

    test('InvestmentModel round trip', () {
      final m = InvestmentModel(
        id: 1,
        investmentType: 'Mutual Fund',
        investmentName: 'Index',
        investmentPlatform: 'Groww',
        investedAmount: 1000,
        currentValue: 1200,
        quantity: 10,
        purchasePrice: 100,
        currentPrice: 120,
        investmentDate: ts,
        maturityDate: null,
        interestRate: 7.5,
        isSip: true,
        sipAmount: 500,
        sipDate: 5,
        notes: 'x',
        createdAt: ts,
        accountId: 1,
      );
      final back = InvestmentModel.fromMap(m.toMap());
      expect(back.toMap(), m.toMap());
      expect(back.isSip, isTrue);
    });

    test('InvestmentValuation round trip and day', () {
      final v = InvestmentValuation(
        id: 1,
        investmentId: 2,
        value: 10,
        date: '2026-05-06T13:45:00.000',
        createdAt: ts,
      );
      expect(InvestmentValuation.fromMap(v.toMap()).toMap(), v.toMap());
      expect(v.day, DateTime(2026, 5, 6));
    });

    test('LoanModel and LoanPaymentModel round trip', () {
      final l = LoanModel(
        id: 1,
        loanType: 'TAKEN',
        personName: 'Bank',
        principalAmount: 1000,
        interestRate: 10,
        emiAmount: 100,
        nextEmiDate: ts,
        tenureMonths: 12,
        startDate: ts,
        totalPaid: 0,
        outstandingAmount: 1000,
        loanStatus: 'ACTIVE',
        createdAt: ts,
      );
      expect(LoanModel.fromMap(l.toMap()).toMap(), l.toMap());

      final p = LoanPaymentModel(
        id: 1,
        loanId: 1,
        paymentAmount: 100,
        paymentDate: ts,
        paymentMode: 'UPI',
        remarks: 'r',
        createdAt: ts,
        accountId: 2,
      );
      expect(LoanPaymentModel.fromMap(p.toMap()).toMap(), p.toMap());
    });

    test('RecurringTransactionModel round trip', () {
      const m = RecurringTransactionModel(
        id: 1,
        title: 'Rent',
        transactionType: 'EXPENSE',
        amount: 15000,
        categoryId: 2,
        categoryName: 'Bills',
        paymentMode: 'Bank',
        frequency: 'MONTHLY',
        intervalValue: 1,
        startDate: ts,
        nextDueDate: ts,
        createdAt: ts,
        accountId: 3,
        reminderDays: 2,
      );
      final back = RecurringTransactionModel.fromMap(m.toMap());
      expect(back.toMap(), m.toMap());
      expect(back.status, 'ACTIVE');
    });
  });

  group('accounts', () {
    test('AccountType.fromCode is case-insensitive and defaults to other', () {
      expect(AccountType.fromCode('bank'), AccountType.bank);
      expect(AccountType.fromCode('UPI'), AccountType.upi);
      expect(AccountType.fromCode('???'), AccountType.other);
      expect(AccountType.fromCode(null), AccountType.other);
    });

    test('AccountModel round trip and balance maths', () {
      const a = AccountModel(
        id: 1,
        name: 'HDFC',
        type: AccountType.bank,
        openingBalance: 1000,
        isDefault: true,
        createdAt: ts,
      );
      final back = AccountModel.fromMap(a.toMap());
      expect(back.type, AccountType.bank);
      expect(back.isDefault, isTrue);
      expect(back.openingBalance, 1000);

      const b = AccountBalance(account: a, moneyIn: 500, moneyOut: 200);
      expect(b.balance, 1300);
    });

    test('AccountTransferModel round trip', () {
      const t = AccountTransferModel(
        id: 1,
        fromAccountId: 1,
        toAccountId: 2,
        amount: 50,
        date: ts,
        notes: 'rent',
        createdAt: ts,
      );
      final back = AccountTransferModel.fromMap(t.toMap());
      expect(back.toMap(), t.toMap());
    });
  });

  group('BudgetModel', () {
    BudgetModel b(double spent, {int alert = 80}) => BudgetModel(
      categoryId: 1,
      categoryName: 'Food',
      amount: 1000,
      month: 11,
      year: 2026,
      alertPercentage: alert,
      spentAmount: spent,
    );

    test('progress, remaining and clamping', () {
      expect(b(250).progress, 0.25);
      expect(b(250).remainingAmount, 750);
      expect(b(2000).progress, 1.0);
      expect(b(2000).remainingAmount, -1000);
    });

    test('status flags', () {
      expect(b(500).isNearLimit, isFalse);
      expect(b(800).isNearLimit, isTrue);
      expect(b(800).isExceeded, isFalse);
      expect(b(1000).isExceeded, isFalse); // exactly at the limit
      expect(b(1001).isExceeded, isTrue);
      expect(b(1001).isNearLimit, isFalse);
      expect(b(500, alert: 50).isNearLimit, isTrue);
    });

    test('zero budget has zero progress', () {
      const z = BudgetModel(
        categoryId: 1,
        categoryName: 'x',
        amount: 0,
        month: 1,
        year: 2026,
        spentAmount: 10,
      );
      expect(z.progress, 0);
    });

    test('fromMap reads spent_amount and defaults', () {
      final m = BudgetModel.fromMap({
        'id': 1,
        'category_id': 2,
        'category_name': null,
        'amount': 100,
        'month': 3,
        'year': 2026,
        'spent_amount': 40,
      });
      expect(m.categoryName, 'Category');
      expect(m.alertPercentage, 80);
      expect(m.spentAmount, 40);
    });
  });

  group('GoalProgress', () {
    SavingsGoalModel goal({String? date, double target = 1000}) =>
        SavingsGoalModel(
          id: 1,
          name: 'Trip',
          targetAmount: target,
          targetDate: date,
          createdAt: ts,
        );

    test('model round trip', () {
      final g = goal(date: '2030-01-01');
      expect(SavingsGoalModel.fromMap(g.toMap()).toMap(), g.toMap());
    });

    test('fraction, remaining and reached', () {
      final p = GoalProgress(goal: goal(), saved: 250);
      expect(p.fraction, 0.25);
      expect(p.remaining, 750);
      expect(p.isReached, isFalse);

      final done = GoalProgress(goal: goal(), saved: 1500);
      expect(done.fraction, 1.0);
      expect(done.remaining, 0);
      expect(done.isReached, isTrue);
    });

    test('no deadline -> no monthly figure', () {
      final p = GoalProgress(goal: goal(), saved: 0);
      expect(p.deadline, isNull);
      expect(p.monthsLeft, isNull);
      expect(p.monthlyNeeded, isNull);
      expect(p.isOverdue, isFalse);
    });

    test('future deadline gives months left and a monthly amount', () {
      final now = DateTime.now();
      final future = DateTime(now.year, now.month, now.day + 91);
      final p = GoalProgress(
        goal: goal(date: future.toIso8601String()),
        saved: 100,
      );
      expect(p.monthsLeft, 3);
      expect(p.monthlyNeeded, closeTo(300, 0.001));
      expect(p.isOverdue, isFalse);
    });

    test('past deadline is overdue unless the goal was reached', () {
      final past = DateTime.now().subtract(const Duration(days: 40));
      final late = GoalProgress(
        goal: goal(date: past.toIso8601String()),
        saved: 10,
      );
      expect(late.isOverdue, isTrue);
      expect(late.monthsLeft, isNull);

      final reached = GoalProgress(
        goal: goal(date: past.toIso8601String()),
        saved: 1000,
      );
      expect(reached.isOverdue, isFalse);
    });

    test('contribution round trip', () {
      const c = GoalContributionModel(
        id: 1,
        goalId: 2,
        amount: 10,
        date: ts,
        notes: 'n',
        createdAt: ts,
      );
      expect(GoalContributionModel.fromMap(c.toMap()).toMap(), c.toMap());
    });
  });

  group('dashboard + reports + net worth', () {
    test('DashboardTransactionModel derives its kind and date', () {
      final e = DashboardTransactionModel(
        title: 't',
        subtitle: 's',
        amount: 1,
        date: '2026-01-02T00:00:00.000',
        isExpense: true,
      );
      expect(e.kind, TransactionKind.expense);
      expect(e.dateTime, DateTime(2026, 1, 2));
      final i = DashboardTransactionModel(
        title: 't',
        subtitle: 's',
        amount: 1,
        date: 'bad date',
        isExpense: false,
      );
      expect(i.kind, TransactionKind.income);
      expect(i.dateTime, isNull);
      expect(i.extra, '');
    });

    test('MonthInsights.percentChange', () {
      expect(MonthInsights.percentChange(150, 100), 50);
      expect(MonthInsights.percentChange(50, 100), -50);
      expect(MonthInsights.percentChange(10, 0), isNull);
    });

    test('MonthInsights changes use the same-period figures', () {
      const m = MonthInsights(
        expenseThisMonth: 120,
        expenseLastMonthSamePeriod: 100,
        expenseLastMonthTotal: 400,
        incomeThisMonth: 0,
        incomeLastMonthSamePeriod: 0,
        topCategories: [],
        day: 10,
      );
      expect(m.expenseChange, 20);
      expect(m.incomeChange, isNull);
    });

    test('FinancialReport and MonthlyReport maths', () {
      const r = FinancialReport(
        year: 2026,
        totalIncome: 1000,
        totalExpense: 400,
        monthly: [MonthlyReport(month: 1, income: 100, expense: 30)],
        categories: [],
      );
      expect(r.netSavings, 600);
      expect(r.monthly.first.net, 70);
    });

    test('NetWorthSnapshot totals', () {
      const s = NetWorthSnapshot(
        cash: 100,
        investments: 200,
        receivable: 50,
        liabilities: 120,
      );
      expect(s.assets, 350);
      expect(s.netWorth, 230);
    });

    test('NetWorthResult change since last month', () {
      const prev = NetWorthSnapshot(
        cash: 100,
        investments: 0,
        receivable: 0,
        liabilities: 0,
      );
      const now = NetWorthSnapshot(
        cash: 150,
        investments: 0,
        receivable: 0,
        liabilities: 0,
      );
      final r = NetWorthResult(
        current: now,
        trend: [
          NetWorthPoint(month: DateTime(2026, 10), snapshot: prev),
          NetWorthPoint(month: DateTime(2026, 11), snapshot: now),
        ],
      );
      expect(r.changeSinceLastMonth, 50);
      expect(r.changePercent, 50);

      final single = NetWorthResult(current: now, trend: const []);
      expect(single.changeSinceLastMonth, isNull);
      expect(single.changePercent, isNull);
    });
  });
}
