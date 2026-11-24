import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/modules/budgets/models/budget_model.dart';
import 'package:mywallet/modules/budgets/widgets/budget_progress_card.dart';
import 'package:mywallet/modules/dashboard/models/dashboard_transaction_model.dart';
import 'package:mywallet/modules/dashboard/widgets/quick_action_card.dart';
import 'package:mywallet/modules/dashboard/widgets/recent_transaction_card.dart';
import 'package:mywallet/modules/dashboard/widgets/section_title.dart';
import 'package:mywallet/modules/expenses/models/expense_model.dart';
import 'package:mywallet/modules/expenses/widgets/expense_card.dart';
import 'package:mywallet/modules/income/models/income_model.dart';
import 'package:mywallet/modules/income/widgets/income_card.dart';
import 'package:mywallet/modules/loans/models/loan_model.dart';
import 'package:mywallet/modules/loans/widgets/loan_card.dart';
import 'package:mywallet/modules/loans/widgets/loan_status_badge.dart';
import 'package:mywallet/modules/loans/widgets/loan_warning_banner.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  const ts = '2026-11-10T10:00:00.000';

  group('Loan widgets', () {
    testWidgets('status badge labels', (t) async {
      for (final entry in {
        'ACTIVE': 'Active',
        'closed': 'Closed',
        'OVERDUE': 'Overdue',
        'anything': 'Active',
      }.entries) {
        await t.pumpWidget(host(LoanStatusBadge(status: entry.key)));
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('warning banner shows its message', (t) async {
      await t.pumpWidget(host(const LoanWarningBanner(message: 'EMI overdue')));
      expect(find.text('EMI overdue'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('loan card shows the person and routes menu actions', (
      t,
    ) async {
      final loan = LoanModel(
        id: 1,
        loanType: 'TAKEN',
        personName: 'ICICI Bank',
        principalAmount: 250000,
        interestRate: 11.5,
        emiAmount: 8200,
        nextEmiDate: ts,
        tenureMonths: 36,
        startDate: ts,
        totalPaid: 0,
        outstandingAmount: 151600,
        loanStatus: 'ACTIVE',
        createdAt: ts,
      );
      var tap = 0, edit = 0, del = 0;
      await t.pumpWidget(
        host(
          LoanCard(
            loan: loan,
            onTap: () => tap++,
            onEdit: () => edit++,
            onDelete: () => del++,
          ),
        ),
      );
      expect(find.text('ICICI Bank'), findsOneWidget);
      expect(find.textContaining('1,51,600'), findsWidgets);

      await t.tap(find.text('ICICI Bank'));
      expect(tap, 1);

      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Edit'));
      await t.pumpAndSettle();
      expect(edit, 1);

      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(del, 1);
    });
  });

  group('BudgetProgressCard', () {
    BudgetModel budget(double spent) => BudgetModel(
      id: 1,
      categoryId: 1,
      categoryName: 'Food',
      amount: 1000,
      month: 11,
      year: 2026,
      spentAmount: spent,
    );

    testWidgets('shows category, amounts and a progress bar', (t) async {
      await t.pumpWidget(
        host(
          BudgetProgressCard(
            budget: budget(250),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      );
      expect(find.text('Food'), findsOneWidget);
      expect(find.textContaining('250'), findsWidgets);
      final bar = t.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.25);
    });

    testWidgets('colour follows the status', (t) async {
      Future<Color?> colorFor(double spent) async {
        await t.pumpWidget(
          host(
            BudgetProgressCard(
              budget: budget(spent),
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        );
        return t
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .color;
      }

      expect(await colorFor(900), Colors.orange);
      expect(await colorFor(1200), Colors.red);
    });

    testWidgets('edit and delete buttons call back', (t) async {
      var edit = 0, del = 0;
      await t.pumpWidget(
        host(
          BudgetProgressCard(
            budget: budget(10),
            onEdit: () => edit++,
            onDelete: () => del++,
          ),
        ),
      );
      await t.tap(find.byTooltip('Edit budget'));
      await t.tap(find.byTooltip('Delete budget'));
      expect([edit, del], [1, 1]);
    });
  });

  group('Expense / Income cards', () {
    testWidgets('ExpenseCard shows details and menu actions', (t) async {
      final e = ExpenseModel(
        id: 1,
        amount: 589,
        categoryId: 1,
        categoryName: 'Bills & Utilities',
        date: ts,
        paymentMode: 'UPI',
        createdAt: ts,
      );
      var tap = 0, edit = 0, dup = 0, del = 0;
      await t.pumpWidget(
        host(
          ExpenseCard(
            expense: e,
            onTap: () => tap++,
            onEdit: () => edit++,
            onDuplicate: () => dup++,
            onDelete: () => del++,
          ),
        ),
      );
      expect(find.text('Bills & Utilities'), findsOneWidget);
      expect(find.textContaining('589'), findsWidgets);
      expect(find.textContaining('UPI'), findsOneWidget);

      await t.tap(find.text('Bills & Utilities'));
      expect(tap, 1);

      for (final label in ['Edit', 'Duplicate', 'Delete']) {
        await t.tap(find.byType(PopupMenuButton<String>));
        await t.pumpAndSettle();
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }
      expect([edit, dup, del], [1, 1, 1]);
    });

    testWidgets('ExpenseCard hides Duplicate when no handler is given', (
      t,
    ) async {
      final e = ExpenseModel(
        id: 1,
        amount: 5,
        categoryId: 1,
        categoryName: 'X',
        date: ts,
        paymentMode: 'Cash',
        createdAt: ts,
      );
      await t.pumpWidget(
        host(
          ExpenseCard(expense: e, onTap: () {}, onEdit: () {}, onDelete: () {}),
        ),
      );
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      expect(find.text('Duplicate'), findsNothing);
    });

    testWidgets('IncomeCard shows category and recurring label', (t) async {
      final i = IncomeModel(
        id: 1,
        amount: 128000,
        categoryId: 1,
        categoryName: 'Salary',
        subcategoryName: 'Monthly Salary',
        date: ts,
        paymentMode: 'Bank Transfer',
        isRecurring: true,
        recurringType: 'Monthly',
        createdAt: ts,
      );
      var del = 0;
      await t.pumpWidget(
        host(
          IncomeCard(
            income: i,
            onTap: () {},
            onEdit: () {},
            onDelete: () => del++,
          ),
        ),
      );
      expect(find.textContaining('Salary'), findsWidgets);
      expect(find.textContaining('1,28,000'), findsWidgets);
      expect(find.text('Monthly'), findsOneWidget);

      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete'));
      await t.pumpAndSettle();
      expect(del, 1);
    });
  });

  group('Dashboard widgets', () {
    testWidgets('SectionTitle shows View all only with a handler', (t) async {
      await t.pumpWidget(host(const SectionTitle(title: 'Recent')));
      expect(find.text('Recent'), findsOneWidget);
      expect(find.textContaining('View'), findsNothing);

      var n = 0;
      await t.pumpWidget(
        host(SectionTitle(title: 'Recent', onViewAll: () => n++)),
      );
      await t.tap(find.textContaining('View'));
      expect(n, 1);
    });

    testWidgets('QuickActionCard taps', (t) async {
      var n = 0;
      await t.pumpWidget(
        host(
          QuickActionCard(
            title: 'Add expense',
            icon: Icons.add,
            onTap: () => n++,
          ),
        ),
      );
      await t.tap(find.text('Add expense'));
      expect(n, 1);
    });

    testWidgets('RecentTransactionCard picks icon by kind', (t) async {
      Future<void> pump(TransactionKind k, bool expense) => t.pumpWidget(
        host(
          RecentTransactionCard(
            title: 'Title',
            subtitle: 'Sub',
            amount: 10,
            date: ts,
            isExpense: expense,
            kind: k,
          ),
        ),
      );

      await pump(TransactionKind.investment, true);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      await pump(TransactionKind.loanEmi, true);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
      await pump(TransactionKind.expense, true);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      await pump(TransactionKind.income, false);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
    });
  });
}
