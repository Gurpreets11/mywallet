import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/database/database_constants.dart';
import 'package:mywallet/core/database/migrations.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  Future<Set<String>> names(String type) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ?',
      [type],
    );
    return {for (final r in rows) r['name'] as String};
  }

  Future<Set<String>> columns(String table) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return {for (final r in rows) r['name'] as String};
  }

  group('fresh database', () {
    test('is created at the current schema version', () async {
      final db = await AppDatabase.database;
      expect(await db.getVersion(), DatabaseConstants.databaseVersion);
    });

    test('has every table the app uses', () async {
      await AppDatabase.database;
      final tables = await names('table');
      for (final t in [
        'expenses',
        'incomes',
        'categories',
        'subcategories',
        'loans',
        'loan_payments',
        'investments',
        'investment_valuations',
        'budgets',
        'accounts',
        'account_transfers',
        'recurring_transactions',
        'savings_goals',
        'savings_goal_contributions',
        'app_metadata',
      ]) {
        expect(tables, contains(t), reason: 'missing table $t');
      }
    });

    test('has the performance indexes', () async {
      await AppDatabase.database;
      final indexes = await names('index');
      for (final i in [
        'idx_expenses_date',
        'idx_expenses_category',
        'idx_incomes_date',
        'idx_loan_payments_loan',
        'idx_transfers_date',
      ]) {
        expect(indexes, contains(i), reason: 'missing index $i');
      }
    });

    test('has the columns added by later versions', () async {
      await AppDatabase.database;
      expect(
        await columns('recurring_transactions'),
        contains('reminder_days'),
      );
      expect(await columns('categories'), contains('sort_order'));
      expect(await columns('expenses'), contains('account_id'));
      expect(await columns('budgets'), contains('last_alert_level'));
    });
  });

  group('upgrade', () {
    test('re-running the newest migrations is harmless', () async {
      final db = await AppDatabase.database;
      await Migrations.onUpgrade(db, 16, DatabaseConstants.databaseVersion);
      await Migrations.onUpgrade(db, 16, DatabaseConstants.databaseVersion);
      expect(await columns('categories'), contains('sort_order'));
      expect(await names('index'), contains('idx_expenses_date'));
    });
  });
}
