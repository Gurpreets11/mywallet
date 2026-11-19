import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/repositories/account_repository.dart';
import '../models/net_worth_models.dart';

/// Net worth = cash in accounts + investments + money lent - money owed.
///
/// The current figures come straight from the app (account balances,
/// investment current values, loan outstanding amounts). Past months are
/// worked out backwards from today: cash is today's cash minus the money that
/// came in or went out since then, investments use the latest recorded value
/// on or before that month end, and loans add back the payments made since.
/// So the trend always ends exactly at today's net worth.
class NetWorthRepository {
  static const int months = 12;

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;

  static double _num(Object? raw) => (raw as num?)?.toDouble() ?? 0;

  Future<NetWorthResult> load() async {
    final Database db = await AppDatabase.database;

    final balances = await AccountRepository().getAccountBalances();
    final cashNow = balances.fold<double>(0, (s, a) => s + a.balance);

    final investments = await db.query('investments');
    final valuations = await db.query(
      'investment_valuations',
      orderBy: 'date(date) ASC, id ASC',
    );
    final loans = await db.query('loans');
    final payments = await db.rawQuery('''
      SELECT lp.loan_id AS loan_id, lp.payment_amount AS amount,
             lp.payment_date AS date, UPPER(COALESCE(l.loan_type, '')) AS type
      FROM loan_payments lp
      LEFT JOIN loans l ON lp.loan_id = l.id
    ''');
    final incomes = await db.rawQuery('SELECT date, amount FROM incomes');
    final expenses = await db.rawQuery('SELECT date, amount FROM expenses');

    // ---- today ----
    var investmentsNow = 0.0;
    for (final i in investments) {
      investmentsNow += _num(i['current_value']);
    }
    var receivableNow = 0.0;
    var liabilitiesNow = 0.0;
    for (final l in loans) {
      if ((l['loan_status'] as String?)?.toUpperCase() == 'CLOSED') continue;
      final out = _num(l['outstanding_amount']);
      if ((l['loan_type'] as String?)?.toUpperCase() == 'GIVEN') {
        receivableNow += out;
      } else {
        liabilitiesNow += out;
      }
    }
    final current = NetWorthSnapshot(
      cash: cashNow,
      investments: investmentsNow,
      receivable: receivableNow,
      liabilities: liabilitiesNow,
    );

    // Valuations per investment (already oldest first).
    final valuationsBy = <int, List<Map<String, Object?>>>{};
    for (final v in valuations) {
      valuationsBy.putIfAbsent(v['investment_id'] as int, () => []).add(v);
    }

    // ---- previous month ends ----
    final now = DateTime.now();
    final trend = <NetWorthPoint>[];

    for (var back = months - 1; back >= 1; back--) {
      final monthStart = DateTime(now.year, now.month - back, 1);
      // Exclusive upper bound: first moment of the next month.
      final end = DateTime(monthStart.year, monthStart.month + 1, 1);

      // Cash: undo everything that happened on/after [end].
      var flowAfter = 0.0;
      for (final r in incomes) {
        final d = _date(r['date']);
        if (d != null && !d.isBefore(end)) flowAfter += _num(r['amount']);
      }
      for (final r in expenses) {
        final d = _date(r['date']);
        if (d != null && !d.isBefore(end)) flowAfter -= _num(r['amount']);
      }
      for (final i in investments) {
        final d = _date(i['investment_date']);
        if (d != null && !d.isBefore(end)) {
          flowAfter -= _num(i['invested_amount']);
        }
      }
      for (final p in payments) {
        final d = _date(p['date']);
        if (d == null || d.isBefore(end)) continue;
        flowAfter += p['type'] == 'GIVEN' ? _num(p['amount']) : -_num(p['amount']);
      }
      final cash = cashNow - flowAfter;

      // Investments: latest value before [end]; invested amount if none.
      var inv = 0.0;
      for (final i in investments) {
        final bought = _date(i['investment_date']);
        if (bought == null || !bought.isBefore(end)) continue;
        double? value;
        for (final v in valuationsBy[i['id'] as int] ?? const []) {
          final vd = _date(v['date']);
          if (vd != null && vd.isBefore(end)) value = _num(v['value']);
        }
        inv += value ?? _num(i['invested_amount']);
      }

      // Loans: outstanding today + payments made since.
      var receivable = 0.0;
      var liabilities = 0.0;
      for (final l in loans) {
        final started = _date(l['start_date']);
        if (started != null && !started.isBefore(end)) continue;
        final closed =
            (l['loan_status'] as String?)?.toUpperCase() == 'CLOSED';
        var out = closed ? 0.0 : _num(l['outstanding_amount']);
        for (final p in payments) {
          if (p['loan_id'] != l['id']) continue;
          final d = _date(p['date']);
          if (d != null && !d.isBefore(end)) out += _num(p['amount']);
        }
        if (out < 0) out = 0;
        if ((l['loan_type'] as String?)?.toUpperCase() == 'GIVEN') {
          receivable += out;
        } else {
          liabilities += out;
        }
      }

      trend.add(
        NetWorthPoint(
          month: monthStart,
          snapshot: NetWorthSnapshot(
            cash: cash,
            investments: inv,
            receivable: receivable,
            liabilities: liabilities,
          ),
        ),
      );
    }

    trend.add(
      NetWorthPoint(
        month: DateTime(now.year, now.month, 1),
        snapshot: current,
      ),
    );

    return NetWorthResult(current: current, trend: trend);
  }
}
