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
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future DB migrations
  }

  static Future<void> _createExpenseTable(Database db) async {
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.tableExpenses} (
      ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DatabaseConstants.colAmount} REAL NOT NULL,
      category_id INTEGER NOT NULL,
      subcategory_id INTEGER,
      ${DatabaseConstants.colDate} TEXT NOT NULL,
      ${DatabaseConstants.colPaymentMode} TEXT,
      ${DatabaseConstants.colNotes} TEXT,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL,

      FOREIGN KEY (category_id)
      REFERENCES categories(id),

      FOREIGN KEY (subcategory_id)
      REFERENCES subcategories(id)
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

      FOREIGN KEY (category_id)
      REFERENCES categories(id),

      FOREIGN KEY (subcategory_id)
      REFERENCES subcategories(id)
    )
  ''');
  }

  static Future<void> _createInvestmentTable(Database db) async {
    await db.execute('''
CREATE TABLE investments(

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

      FOREIGN KEY (loan_id)
      REFERENCES loans(id)
    )
  ''');
  }

  static Future<void> _createTransactionTypeTable(Database db) async {
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.tableTransactionTypes} (
      ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DatabaseConstants.colTypeName} TEXT NOT NULL
    )
  ''');
  }

  static Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.tableCategories} (
      ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DatabaseConstants.colTransactionTypeId} INTEGER NOT NULL,
      ${DatabaseConstants.colCategoryName} TEXT NOT NULL,
      ${DatabaseConstants.colIconName} TEXT,
      ${DatabaseConstants.colColorCode} TEXT,
      ${DatabaseConstants.colIsActive} INTEGER DEFAULT 1,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL,
      FOREIGN KEY (${DatabaseConstants.colTransactionTypeId})
      REFERENCES ${DatabaseConstants.tableTransactionTypes}(${DatabaseConstants.colId})
    )
  ''');
  }

  static Future<void> _createSubcategoryTable(Database db) async {
    await db.execute('''
    CREATE TABLE ${DatabaseConstants.tableSubcategories} (
      ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DatabaseConstants.colCategoryId} INTEGER NOT NULL,
      ${DatabaseConstants.colSubcategoryName} TEXT NOT NULL,
      ${DatabaseConstants.colIsActive} INTEGER DEFAULT 1,
      ${DatabaseConstants.colCreatedAt} TEXT NOT NULL,
      FOREIGN KEY (${DatabaseConstants.colCategoryId})
      REFERENCES ${DatabaseConstants.tableCategories}(${DatabaseConstants.colId})
    )
  ''');
  }
}
