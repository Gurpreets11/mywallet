import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class Migrations {
  static Future<void> onCreate(Database db, int version) async {
    await _createTransactionTypeTable(db);
    await _createCategoryTable(db);
    await _createSubcategoryTable(db);
    await _createExpenseTable(db);
    await _createIncomeTable(db);
    await _createInvestmentTable(db);
    await _createLoansTable(db);
    await _createLoanPaymentsTable(db);
    await _createBudgetTable(db);
    await _createAppMetadataTable(db);
    await _createRecurringTables(db);
    await _applyAccountsSchema(db);
    await _applyV14Schema(db);
    await _applyV15Schema(db);
    await _applyV16Schema(db);
    await _applyV17Schema(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE expenses ADD COLUMN notes TEXT');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN type_id INTEGER REFERENCES transaction_types(id)',
      );
    }
    if (oldVersion < 11) {
      await _createBudgetTable(db);
      await _createAppMetadataTable(db);
    }
    if (oldVersion < 12) {
      await _createRecurringTables(db);
    }
    if (oldVersion < 13) {
      await _applyAccountsSchema(db);
    }
    if (oldVersion < 14) {
      await _applyV14Schema(db);
    }
    if (oldVersion < 15) {
      await _applyV15Schema(db);
    }
    if (oldVersion < 16) {
      await _applyV16Schema(db);
    }
    if (oldVersion < 17) {
      await _applyV17Schema(db);
    }
  }

  /// Indexes for fast lists, filters and reports on large histories.
  /// Safe to run more than once; skips tables/columns that do not exist.
  static Future<void> _applyV17Schema(Database db) async {
    const indexes = <(String, String, List<String>)>[
      ('expenses', 'idx_expenses_date', ['date']),
      ('expenses', 'idx_expenses_category', ['category_id']),
      ('expenses', 'idx_expenses_account', ['account_id']),
      ('incomes', 'idx_incomes_date', ['date']),
      ('incomes', 'idx_incomes_account', ['account_id']),
      ('loan_payments', 'idx_loan_payments_loan', ['loan_id']),
      ('loan_payments', 'idx_loan_payments_date', ['payment_date']),
      ('account_transfers', 'idx_transfers_date', ['date']),
      ('savings_goal_contributions', 'idx_goal_contrib_goal', ['goal_id']),
    ];
    for (final (table, name, columns) in indexes) {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final existing = info.map((c) => c['name']).toSet();
      if (existing.isEmpty || !columns.every(existing.contains)) continue;
      await db.execute(
        'CREATE INDEX IF NOT EXISTS $name ON $table (${columns.join(', ')})',
      );
    }
  }

  /// Bill reminders: days before the due date to remind (NULL = no reminder).
  /// Safe to run more than once.
  static Future<void> _applyV16Schema(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(recurring_transactions)');
    if (info.isNotEmpty && !info.any((c) => c['name'] == 'reminder_days')) {
      await db.execute(
        'ALTER TABLE recurring_transactions ADD COLUMN reminder_days INTEGER',
      );
    }
  }

  /// Investment valuation history. Safe to run more than once.
  /// Every investment that has no history yet gets one opening entry with its
  /// current value, so existing data keeps showing the same numbers.
  static Future<void> _applyV15Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS investment_valuations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        investment_id INTEGER NOT NULL,
        value REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_investment_valuations_investment '
      'ON investment_valuations (investment_id, date)',
    );
    await db.execute('''
      INSERT INTO investment_valuations
        (investment_id, value, date, notes, created_at)
      SELECT i.id, i.current_value, date('now'), 'Opening value',
             datetime('now')
      FROM investments i
      WHERE NOT EXISTS (
        SELECT 1 FROM investment_valuations v WHERE v.investment_id = i.id
      )
    ''');
  }

  /// Savings goals, budget-alert state and the account on recurring items.
  /// Safe to run more than once.
  static Future<void> _applyV14Schema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        target_date TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goal_contributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    Future<void> addColumn(String table, String column, String type) async {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      if (info.isNotEmpty && !info.any((c) => c['name'] == column)) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      }
    }

    // 0 = no alert sent yet, 1 = "near limit" sent, 2 = "limit reached" sent
    await addColumn('budgets', 'last_alert_level', 'INTEGER NOT NULL DEFAULT 0');
    await addColumn('recurring_transactions', 'account_id', 'INTEGER');
  }

  /// Accounts / wallets. Safe to run more than once.
  /// - `accounts` and `account_transfers` tables
  /// - `account_id` on expenses, incomes, loan_payments and investments
  ///   (NULL = belongs to the default account, so old data keeps working)
  /// - one default "Cash" account
  static Future<void> _applyAccountsSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableAccounts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        account_type TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableAccountTransfers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_account_id INTEGER NOT NULL,
        to_account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    for (final table in ['expenses', 'incomes', 'loan_payments', 'investments']) {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final hasColumn = info.any((c) => c['name'] == 'account_id');
      if (!hasColumn && info.isNotEmpty) {
        await db.execute('ALTER TABLE $table ADD COLUMN account_id INTEGER');
      }
    }

    final existing = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM ${DatabaseConstants.tableAccounts}',
    );
    if (((existing.first['total'] as num?) ?? 0) == 0) {
      await db.insert(DatabaseConstants.tableAccounts, {
        'name': 'Cash',
        'account_type': 'CASH',
        'opening_balance': 0,
        'is_default': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> _createRecurringTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableRecurringTransactions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        payment_mode TEXT,
        notes TEXT,
        frequency TEXT NOT NULL,
        interval_value INTEGER NOT NULL DEFAULT 1,
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_due_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableRecurringOccurrences} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recurring_transaction_id INTEGER NOT NULL,
        occurrence_date TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        generated_transaction_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(recurring_transaction_id, occurrence_date),
        FOREIGN KEY(recurring_transaction_id)
          REFERENCES ${DatabaseConstants.tableRecurringTransactions}(id)
          ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createExpenseTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        subcategory_id INTEGER,
        category_name TEXT NOT NULL,
        subcategory_name TEXT,
        date TEXT NOT NULL,
        payment_mode TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(subcategory_id) REFERENCES subcategories(id)
      )
    ''');
  }

  static Future<void> _createIncomeTable(Database db) async {
    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        subcategory_id INTEGER,
        date TEXT NOT NULL,
        payment_mode TEXT,
        notes TEXT,
        is_recurring INTEGER DEFAULT 0,
        recurring_type TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(subcategory_id) REFERENCES subcategories(id)
      )
    ''');
  }

  static Future<void> _createInvestmentTable(Database db) async {
    await db.execute('''
      CREATE TABLE investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        investment_type TEXT NOT NULL,
        investment_name TEXT NOT NULL,
        investment_platform TEXT,
        invested_amount REAL NOT NULL,
        current_value REAL NOT NULL,
        quantity REAL,
        purchase_price REAL,
        current_price REAL,
        investment_date TEXT NOT NULL,
        maturity_date TEXT,
        interest_rate REAL,
        is_sip INTEGER DEFAULT 0,
        sip_amount REAL,
        sip_date INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createLoansTable(Database db) async {
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_type TEXT NOT NULL,
        person_name TEXT NOT NULL,
        principal_amount REAL NOT NULL,
        interest_rate REAL,
        emi_amount REAL,
        next_emi_date TEXT,
        tenure_months INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT,
        total_paid REAL DEFAULT 0,
        outstanding_amount REAL NOT NULL,
        loan_status TEXT DEFAULT 'ACTIVE',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createLoanPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE loan_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        payment_amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_mode TEXT,
        remarks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(loan_id) REFERENCES loans(id)
      )
    ''');
  }

  static Future<void> _createBudgetTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        alert_percentage INTEGER NOT NULL DEFAULT 80,
        created_at TEXT NOT NULL,
        UNIQUE(category_id, month, year)
      )
    ''');
  }

  static Future<void> _createAppMetadataTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        meta_key TEXT PRIMARY KEY,
        meta_value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createTransactionTypeTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTransactionTypes} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableCategories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        icon_name TEXT,
        color_code TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY(transaction_type_id)
          REFERENCES ${DatabaseConstants.tableTransactionTypes}(id)
      )
    ''');
  }

  static Future<void> _createSubcategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableSubcategories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        subcategory_name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES ${DatabaseConstants.tableCategories}(id)
      )
    ''');
  }
}
