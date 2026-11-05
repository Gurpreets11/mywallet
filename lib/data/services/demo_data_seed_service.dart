import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';

/// Development-only sample data. main.dart calls this only when kDebugMode is true.
/// The metadata flag prevents duplicate sample records on subsequent launches.
class DemoDataSeedService {
  static const String _seedKey = 'demo_data_seeded_v1';

  static Future<void> seedIfDatabaseIsEmpty() async {
    final db = await AppDatabase.database;
    final marker = await db.query(
      'app_metadata',
      where: 'meta_key = ?',
      whereArgs: [_seedKey],
      limit: 1,
    );
    if (marker.isNotEmpty) return;

    final counts = await Future.wait([
      _count(db, 'expenses'),
      _count(db, 'incomes'),
      _count(db, 'investments'),
      _count(db, 'loans'),
      _count(db, 'loan_payments'),
      _count(db, 'budgets'),
    ]);
    // Never mix generated records into a database that already contains user data.
    if (counts.any((count) => count > 0)) {
      await db.insert('app_metadata', {
        'meta_key': _seedKey,
        'meta_value': 'skipped_existing_data',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return;
    }

    final now = DateTime.now();
    final createdAt = now.toIso8601String();
    final food = await _categoryId(db, 'Food & Dining');
    final travel = await _categoryId(db, 'Travel');
    final shopping = await _categoryId(db, 'Shopping');
    final bills = await _categoryId(db, 'Bills & Utilities');
    final salary = await _categoryId(db, 'Salary');
    final business = await _categoryId(db, 'Business');
    final otherIncome = await _categoryId(db, 'Other');

    if ([
      food,
      travel,
      shopping,
      bills,
      salary,
      business,
      otherIncome,
    ].any((id) => id == null)) {
      return;
    }

    String dateInCurrentMonth(int dayOffset) {
      final date = now.subtract(Duration(days: dayOffset));
      return DateTime(date.year, date.month, date.day, 12).toIso8601String();
    }

    await db.transaction((txn) async {
      await txn.insert('expenses', {
        'amount': 420.0,
        'category_id': food,
        'subcategory_id': await _subcategoryId(txn, food!, 'Lunch'),
        'category_name': 'Food & Dining',
        'subcategory_name': 'Lunch',
        'date': dateInCurrentMonth(1),
        'payment_mode': 'UPI',
        'notes': 'Lunch with colleagues (sample)',
        'created_at': createdAt,
      });
      await txn.insert('expenses', {
        'amount': 640.0,
        'category_id': food,
        'subcategory_id': await _subcategoryId(txn, food, 'Dinner'),
        'category_name': 'Food & Dining',
        'subcategory_name': 'Dinner',
        'date': dateInCurrentMonth(1),
        'payment_mode': 'UPI',
        'notes': 'Dinner with colleagues (sample)',
        'created_at': createdAt,
      });
      await txn.insert('expenses', {
        'amount': 1800.0,
        'category_id': travel,
        'subcategory_id': await _subcategoryId(txn, travel!, 'Fuel'),
        'category_name': 'Travel',
        'subcategory_name': 'Fuel',
        'date': dateInCurrentMonth(3),
        'payment_mode': 'UPI',
        'notes': 'Fuel refill (sample)',
        'created_at': createdAt,
      });
      await txn.insert('expenses', {
        'amount': 2499.0,
        'category_id': shopping,
        'subcategory_id': await _subcategoryId(txn, shopping!, 'Clothes'),
        'category_name': 'Shopping',
        'subcategory_name': 'Clothes',
        'date': dateInCurrentMonth(5),
        'payment_mode': 'Card',
        'notes': 'Office clothing (sample)',
        'created_at': createdAt,
      });
      await txn.insert('expenses', {
        'amount': 1250.0,
        'category_id': bills,
        'subcategory_id': await _subcategoryId(txn, bills!, 'Internet'),
        'category_name': 'Bills & Utilities',
        'subcategory_name': 'Internet',
        'date': dateInCurrentMonth(7),
        'payment_mode': 'Net Banking',
        'notes': 'Internet bill (sample)',
        'created_at': createdAt,
      });

      await txn.insert('incomes', {
        'amount': 128000.0,
        'category_id': salary,
        'subcategory_id': await _subcategoryId(txn, salary!, 'Monthly Salary'),
        'date': dateInCurrentMonth(2),
        'payment_mode': 'Bank Transfer',
        'notes': 'Monthly salary (sample)',
        'is_recurring': 1,
        'recurring_type': 'Monthly',
        'created_at': createdAt,
      });
      await txn.insert('incomes', {
        'amount': 12000.0,
        'category_id': business,
        'subcategory_id': await _subcategoryId(
          txn,
          business!,
          'Client Payment',
        ),
        'date': dateInCurrentMonth(6),
        'payment_mode': 'UPI',
        'notes': 'Freelance project payment (sample)',
        'is_recurring': 0,
        'recurring_type': null,
        'created_at': createdAt,
      });
      await txn.insert('incomes', {
        'amount': 2500.0,
        'category_id': otherIncome,
        'subcategory_id': await _subcategoryId(txn, otherIncome!, 'Other'),
        'date': dateInCurrentMonth(9),
        'payment_mode': 'Cash',
        'notes': 'Miscellaneous income (sample)',
        'is_recurring': 0,
        'recurring_type': null,
        'created_at': createdAt,
      });

      await txn.insert('investments', {
        'investment_type': 'Mutual Fund',
        'investment_name': 'Nifty 50 Index Fund',
        'investment_platform': 'Groww',
        'invested_amount': 60000.0,
        'current_value': 64200.0,
        'quantity': 120.0,
        'purchase_price': 500.0,
        'current_price': 535.0,
        'investment_date': dateInCurrentMonth(120),
        'is_sip': 1,
        'sip_amount': 5000.0,
        'sip_date': (now.day + 2).clamp(1, 28),
        'notes': 'Long-term index fund (sample)',
        'created_at': createdAt,
      });
      await txn.insert('investments', {
        'investment_type': 'Stocks',
        'investment_name': 'Reliance Industries',
        'investment_platform': 'Zerodha',
        'invested_amount': 35000.0,
        'current_value': 37250.0,
        'quantity': 10.0,
        'purchase_price': 3500.0,
        'current_price': 3725.0,
        'investment_date': dateInCurrentMonth(75),
        'is_sip': 0,
        'notes': 'Equity holding (sample)',
        'created_at': createdAt,
      });
      await txn.insert('investments', {
        'investment_type': 'Fixed Deposit',
        'investment_name': 'Bank FD',
        'investment_platform': 'HDFC Bank',
        'invested_amount': 50000.0,
        'current_value': 51500.0,
        'investment_date': dateInCurrentMonth(210),
        'maturity_date': DateTime(
          now.year + 1,
          now.month,
          now.day,
        ).toIso8601String(),
        'interest_rate': 7.1,
        'is_sip': 0,
        'notes': 'Fixed deposit (sample)',
        'created_at': createdAt,
      });

      final homeLoanId = await txn.insert('loans', {
        'loan_type': 'Home Loan',
        'person_name': 'HDFC Bank',
        'principal_amount': 3200000.0,
        'interest_rate': 7.4,
        'emi_amount': 26000.0,
        'next_emi_date': DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 5)).toIso8601String(),
        'tenure_months': 240,
        'start_date': DateTime(now.year - 2, now.month, 1).toIso8601String(),
        'total_paid': 152000.0,
        'outstanding_amount': 3048000.0,
        'loan_status': 'ACTIVE',
        'notes': 'Home loan sample record',
        'created_at': createdAt,
      });
      await txn.insert('loan_payments', {
        'loan_id': homeLoanId,
        'payment_amount': 26000.0,
        'payment_date': dateInCurrentMonth(12),
        'payment_mode': 'Auto Debit',
        'remarks': 'Monthly EMI (sample)',
        'created_at': createdAt,
      });
      await txn.insert('loans', {
        'loan_type': 'Personal Loan',
        'person_name': 'ICICI Bank',
        'principal_amount': 250000.0,
        'interest_rate': 11.5,
        'emi_amount': 8200.0,
        'next_emi_date': DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 12)).toIso8601String(),
        'tenure_months': 36,
        'start_date': DateTime(now.year - 1, now.month, 1).toIso8601String(),
        'total_paid': 98400.0,
        'outstanding_amount': 151600.0,
        'loan_status': 'ACTIVE',
        'notes': 'Personal loan sample record',
        'created_at': createdAt,
      });

      for (final item in [
        {
          'category_id': food,
          'category_name': 'Food & Dining',
          'amount': 10000.0,
        },
        {'category_id': travel, 'category_name': 'Travel', 'amount': 6000.0},
        {
          'category_id': shopping,
          'category_name': 'Shopping',
          'amount': 8000.0,
        },
        {
          'category_id': bills,
          'category_name': 'Bills & Utilities',
          'amount': 5000.0,
        },
      ]) {
        await txn.insert('budgets', {
          ...item,
          'month': now.month,
          'year': now.year,
          'alert_percentage': 80,
          'created_at': createdAt,
        });
      }
      await txn.insert('app_metadata', {
        'meta_key': _seedKey,
        'meta_value': createdAt,
      });
    });
  }

  static Future<int> _count(Database db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return (result.first['total'] as num).toInt();
  }

  static Future<int?> _categoryId(DatabaseExecutor db, String name) async {
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'category_name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  static Future<int?> _subcategoryId(
    DatabaseExecutor db,
    int categoryId,
    String name,
  ) async {
    final rows = await db.query(
      'subcategories',
      columns: ['id'],
      where: 'category_id = ? AND subcategory_name = ?',
      whereArgs: [categoryId, name],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int?;
  }
}
