import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../models/account_model.dart';

class AccountRepository {
  /// Makes sure at least one account exists (a restore of an older backup or
  /// a data reset can leave the table empty) and returns the default one.
  Future<AccountModel> ensureDefaultAccount() async {
    final Database db = await AppDatabase.database;

    var rows = await db.query('accounts', orderBy: 'is_default DESC, id ASC');
    if (rows.isEmpty) {
      await db.insert('accounts', {
        'name': 'Cash',
        'account_type': AccountType.cash.code,
        'opening_balance': 0,
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      rows = await db.query('accounts', orderBy: 'is_default DESC, id ASC');
    } else if (rows.first['is_default'] != 1) {
      // No account is flagged as default - promote the oldest one.
      await db.update(
        'accounts',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [rows.first['id']],
      );
      rows = await db.query('accounts', orderBy: 'is_default DESC, id ASC');
    }
    return AccountModel.fromMap(rows.first);
  }

  Future<List<AccountModel>> getAccounts() async {
    await ensureDefaultAccount();
    final Database db = await AppDatabase.database;
    final rows = await db.query('accounts', orderBy: 'is_default DESC, id ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  /// Every account with its balance.
  ///
  /// balance = opening balance
  ///         + income + EMI received (loans you gave) + transfers in
  ///         - expenses - EMI paid (loans you took) - investments
  ///         - transfers out
  ///
  /// Entries without an account (old data) and entries pointing to an
  /// account that no longer exists count towards the default account.
  Future<List<AccountBalance>> getAccountBalances() async {
    final Database db = await AppDatabase.database;
    final accounts = await getAccounts();
    final defaultId = accounts.first.id!;
    final knownIds = accounts.map((a) => a.id!).toSet();

    final inflow = <int, double>{};
    final outflow = <int, double>{};

    int resolve(Object? raw) {
      final id = raw is int ? raw : null;
      return (id != null && knownIds.contains(id)) ? id : defaultId;
    }

    void add(Map<int, double> target, List<Map<String, Object?>> rows) {
      for (final r in rows) {
        final id = resolve(r['aid']);
        target[id] =
            (target[id] ?? 0) + ((r['total'] as num?)?.toDouble() ?? 0);
      }
    }

    add(
      outflow,
      await db.rawQuery(
        'SELECT account_id AS aid, SUM(amount) AS total '
        'FROM expenses GROUP BY account_id',
      ),
    );
    add(
      inflow,
      await db.rawQuery(
        'SELECT account_id AS aid, SUM(amount) AS total '
        'FROM incomes GROUP BY account_id',
      ),
    );
    add(
      outflow,
      await db.rawQuery(
        'SELECT account_id AS aid, SUM(invested_amount) AS total '
        'FROM investments GROUP BY account_id',
      ),
    );

    // Loan EMIs: paid on a borrowed loan = out, received on a loan you gave
    // = in.
    add(
      inflow,
      await db.rawQuery('''
        SELECT lp.account_id AS aid, SUM(lp.payment_amount) AS total
        FROM loan_payments lp
        JOIN loans l ON lp.loan_id = l.id
        WHERE UPPER(l.loan_type) = 'GIVEN'
        GROUP BY lp.account_id
      '''),
    );
    add(
      outflow,
      await db.rawQuery('''
        SELECT lp.account_id AS aid, SUM(lp.payment_amount) AS total
        FROM loan_payments lp
        LEFT JOIN loans l ON lp.loan_id = l.id
        WHERE l.id IS NULL OR UPPER(l.loan_type) <> 'GIVEN'
        GROUP BY lp.account_id
      '''),
    );

    add(
      outflow,
      await db.rawQuery(
        'SELECT from_account_id AS aid, SUM(amount) AS total '
        'FROM account_transfers GROUP BY from_account_id',
      ),
    );
    add(
      inflow,
      await db.rawQuery(
        'SELECT to_account_id AS aid, SUM(amount) AS total '
        'FROM account_transfers GROUP BY to_account_id',
      ),
    );

    return [
      for (final a in accounts)
        AccountBalance(
          account: a,
          moneyIn: inflow[a.id] ?? 0,
          moneyOut: outflow[a.id] ?? 0,
        ),
    ];
  }

  Future<int> addAccount(AccountModel account) async {
    final Database db = await AppDatabase.database;
    final map = account.toMap()
      ..remove('id')
      ..['is_default'] = 0;
    return db.insert('accounts', map);
  }

  Future<void> updateAccount(AccountModel account) async {
    final Database db = await AppDatabase.database;
    await db.update(
      'accounts',
      {
        'name': account.name,
        'account_type': account.type.code,
        'opening_balance': account.openingBalance,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> setDefault(int id) async {
    final Database db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.update('accounts', {'is_default': 0});
      await txn.update(
        'accounts',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Deletes an account. Its entries move to the default account (the
  /// default account itself can't be deleted).
  Future<void> deleteAccount(int id) async {
    final Database db = await AppDatabase.database;
    final defaultAccount = await ensureDefaultAccount();
    if (defaultAccount.id == id) return;
    final defaultId = defaultAccount.id!;

    await db.transaction((txn) async {
      for (final table in [
        'expenses',
        'incomes',
        'loan_payments',
        'investments',
      ]) {
        await txn.update(
          table,
          {'account_id': defaultId},
          where: 'account_id = ?',
          whereArgs: [id],
        );
      }
      // A transfer between the deleted account and the default account would
      // become "default -> default", so it is removed.
      await txn.delete(
        'account_transfers',
        where:
            '(from_account_id = ? AND to_account_id = ?) OR '
            '(from_account_id = ? AND to_account_id = ?)',
        whereArgs: [id, defaultId, defaultId, id],
      );
      await txn.update(
        'account_transfers',
        {'from_account_id': defaultId},
        where: 'from_account_id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'account_transfers',
        {'to_account_id': defaultId},
        where: 'to_account_id = ?',
        whereArgs: [id],
      );
      await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ---- Transfers ----

  Future<List<AccountTransferModel>> getTransfers() async {
    final Database db = await AppDatabase.database;
    final rows = await db.query(
      'account_transfers',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(AccountTransferModel.fromMap).toList();
  }

  Future<int> addTransfer(AccountTransferModel transfer) async {
    final Database db = await AppDatabase.database;
    final map = transfer.toMap()..remove('id');
    return db.insert('account_transfers', map);
  }

  Future<void> updateTransfer(AccountTransferModel transfer) async {
    final Database db = await AppDatabase.database;
    final map = transfer.toMap()
      ..remove('id')
      ..remove('created_at');
    await db.update(
      'account_transfers',
      map,
      where: 'id = ?',
      whereArgs: [transfer.id],
    );
  }

  Future<void> deleteTransfer(int id) async {
    final Database db = await AppDatabase.database;
    await db.delete('account_transfers', where: 'id = ?', whereArgs: [id]);
  }
}
