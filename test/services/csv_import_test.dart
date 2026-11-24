import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/services/import/csv_import_service.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();

  Future<CsvImportService> service() async =>
      CsvImportService(await AppDatabase.database);

  group('parse', () {
    test('reads rows with a type column', () async {
      final s = await service();
      final result = s.parse(
        'Date,Type,Category,Subcategory,Amount,Payment mode,Notes\n'
        '2026-11-02,Expense,Food,Lunch,250,Cash,office\n'
        '2026-11-03,Income,Salary,,50000,Bank Transfer,\n',
      );
      expect(result.problems, isEmpty);
      expect(result.hasTypeColumn, isTrue);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].isIncome, isFalse);
      expect(result.rows[0].amount, 250);
      expect(result.rows[0].category, 'Food');
      expect(result.rows[1].isIncome, isTrue);
    });

    test('accepts day-first dates and currency symbols', () async {
      final s = await service();
      final result = s.parse('Date,Amount\n25/12/2026,"₹1,250.50"\n');
      expect(result.rows, hasLength(1));
      expect(result.rows.first.date, DateTime(2026, 12, 25));
      expect(result.rows.first.amount, 1250.5);
      expect(result.hasTypeColumn, isFalse);
    });

    test('reports bad rows but keeps the good ones', () async {
      final s = await service();
      final result = s.parse(
        'Date,Amount\n'
        'not a date,10\n'
        '2026-11-02,abc\n'
        '2026-11-02,0\n'
        '2026-11-02,75\n',
      );
      expect(result.rows, hasLength(1));
      expect(result.problems, hasLength(3));
    });

    test('needs Date and Amount columns', () async {
      final s = await service();
      expect(
        () => s.parse('Name,Value\na,1\n'),
        throwsA(isA<CsvImportException>()),
      );
      expect(() => s.parse(''), throwsA(isA<CsvImportException>()));
    });
  });

  group('import', () {
    const csv =
        'Date,Type,Category,Subcategory,Amount,Payment mode,Notes\n'
        '2026-11-02,Expense,Zz Csv Food,Lunch,250,Cash,office\n'
        '2026-11-03,Income,Zz Csv Pay,,900,UPI,bonus\n';

    test('imports rows and creates missing categories', () async {
      final s = await service();
      final parsed = s.parse(csv);
      final result = await s.import(parsed.rows, defaultIsIncome: false);
      expect(result.imported, 2);
      expect(result.duplicates, 0);
      expect(result.newCategories, greaterThanOrEqualTo(2));

      final db = await AppDatabase.database;
      expect(await db.query('expenses'), hasLength(1));
      expect(await db.query('incomes'), hasLength(1));
    });

    test('importing the same file twice skips duplicates', () async {
      final s = await service();
      final parsed = s.parse(csv);
      await s.import(parsed.rows, defaultIsIncome: false);
      final again = await s.import(parsed.rows, defaultIsIncome: false);
      expect(again.imported, 0);
      expect(again.duplicates, 2);

      final db = await AppDatabase.database;
      expect(await db.query('expenses'), hasLength(1));
    });
  });
}
