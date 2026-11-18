import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/dashboard_transaction_model.dart';

/// Combines expenses, income, loan EMI payments and investments into one
/// list, newest first. Used by the dashboard's "Recent Transactions" and the
/// "All Transactions" screen.
class TransactionFeedRepository {
  /// Every transaction, newest first. Pass [limit] to keep only the newest N.
  Future<List<DashboardTransactionModel>> getAll({int? limit}) async {
    final Database db = await AppDatabase.database;
    final items = <DashboardTransactionModel>[];

    // EXPENSES
    final expenses = await db.rawQuery('''
      SELECT e.amount, e.date, e.payment_mode,
             c.category_name, s.subcategory_name
      FROM expenses e
      LEFT JOIN categories c ON e.category_id = c.id
      LEFT JOIN subcategories s ON e.subcategory_id = s.id
    ''');
    for (final r in expenses) {
      items.add(
        DashboardTransactionModel(
          title: _join([r['category_name'], r['subcategory_name']], 'Expense'),
          subtitle: _text(r['payment_mode']),
          amount: _amount(r['amount']),
          date: _text(r['date']),
          isExpense: true,
          kind: TransactionKind.expense,
        ),
      );
    }

    // INCOME
    final incomes = await db.rawQuery('''
      SELECT i.amount, i.date, i.payment_mode,
             c.category_name, s.subcategory_name
      FROM incomes i
      LEFT JOIN categories c ON i.category_id = c.id
      LEFT JOIN subcategories s ON i.subcategory_id = s.id
    ''');
    for (final r in incomes) {
      items.add(
        DashboardTransactionModel(
          title: _join([r['category_name'], r['subcategory_name']], 'Income'),
          subtitle: _text(r['payment_mode']),
          amount: _amount(r['amount']),
          date: _text(r['date']),
          isExpense: false,
          kind: TransactionKind.income,
        ),
      );
    }

    // LOAN EMI PAYMENTS (paid on a borrowed loan = out, received on a loan
    // you gave = in)
    final emis = await db.rawQuery('''
      SELECT lp.payment_amount, lp.payment_date, lp.payment_mode,
             l.person_name, l.loan_type
      FROM loan_payments lp
      LEFT JOIN loans l ON lp.loan_id = l.id
    ''');
    for (final r in emis) {
      final given = _text(r['loan_type']).toUpperCase() == 'GIVEN';
      final person = _text(r['person_name']);
      final mode = _text(r['payment_mode']);
      items.add(
        DashboardTransactionModel(
          title: given
              ? 'EMI received${person.isEmpty ? '' : ' - $person'}'
              : 'Loan EMI${person.isEmpty ? '' : ' - $person'}',
          subtitle: mode.isEmpty ? 'Loan' : 'Loan • $mode',
          amount: _amount(r['payment_amount']),
          date: _text(r['payment_date']),
          isExpense: !given,
          kind: TransactionKind.loanEmi,
        ),
      );
    }

    // INVESTMENTS (money put in)
    final investments = await db.rawQuery('''
      SELECT investment_name, investment_type, investment_platform,
             invested_amount, investment_date
      FROM investments
    ''');
    for (final r in investments) {
      items.add(
        DashboardTransactionModel(
          title: _text(r['investment_name']).isEmpty
              ? 'Investment'
              : _text(r['investment_name']),
          subtitle: _join(
            [r['investment_type'], r['investment_platform']],
            'Investment',
            separator: ' • ',
          ),
          amount: _amount(r['invested_amount']),
          date: _text(r['investment_date']),
          isExpense: true,
          kind: TransactionKind.investment,
        ),
      );
    }

    // Newest first. Rows whose date cannot be read go to the end.
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    items.sort((a, b) => (b.dateTime ?? epoch).compareTo(a.dateTime ?? epoch));

    if (limit != null && items.length > limit) {
      return items.sublist(0, limit);
    }
    return items;
  }

  static String _text(Object? v) => v == null ? '' : v.toString().trim();

  static double _amount(Object? v) => v is num ? v.toDouble() : 0;

  static String _join(
    List<Object?> parts,
    String fallback, {
    String separator = ' - ',
  }) {
    final cleaned = parts.map(_text).where((p) => p.isNotEmpty).toList();
    return cleaned.isEmpty ? fallback : cleaned.join(separator);
  }
}
