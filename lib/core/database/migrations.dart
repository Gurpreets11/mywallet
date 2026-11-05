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
