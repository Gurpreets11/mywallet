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
    await _createLoanTable(db);
    await _createLoanPaymentTable(db);
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
      CREATE TABLE ${DatabaseConstants.tableInvestments} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colInvestmentType} TEXT NOT NULL,
        ${DatabaseConstants.colAmountInvested} REAL NOT NULL,
        ${DatabaseConstants.colCurrentValue} REAL NOT NULL,
        ${DatabaseConstants.colInvestmentDate} TEXT NOT NULL,
        ${DatabaseConstants.colNotes} TEXT
      )
    ''');
  }

  static Future<void> _createLoanTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableLoans} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colLoanName} TEXT NOT NULL,
        ${DatabaseConstants.colLenderName} TEXT,
        ${DatabaseConstants.colTotalAmount} REAL NOT NULL,
        ${DatabaseConstants.colInterestRate} REAL,
        ${DatabaseConstants.colStartDate} TEXT NOT NULL,
        ${DatabaseConstants.colEmiAmount} REAL,
        ${DatabaseConstants.colTenureMonths} INTEGER,
        ${DatabaseConstants.colOutstandingAmount} REAL,
        ${DatabaseConstants.colStatus} TEXT
      )
    ''');
  }

  static Future<void> _createLoanPaymentTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableLoanPayments} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colLoanId} INTEGER NOT NULL,
        ${DatabaseConstants.colAmountPaid} REAL NOT NULL,
        ${DatabaseConstants.colPaymentDate} TEXT NOT NULL,
        ${DatabaseConstants.colPaymentMode} TEXT,
        ${DatabaseConstants.colNotes} TEXT,
        FOREIGN KEY (${DatabaseConstants.colLoanId})
        REFERENCES ${DatabaseConstants.tableLoans}(${DatabaseConstants.colId})
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
