import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class CsvImportException implements Exception {
  final String message;
  const CsvImportException(this.message);

  @override
  String toString() => message;
}

/// One valid row read from the CSV file.
class CsvImportRow {
  final DateTime date;
  final double amount;

  /// `true` = income, `false` = expense, `null` = file has no Type column.
  final bool? isIncome;
  final String category;
  final String subcategory;
  final String paymentMode;
  final String notes;

  const CsvImportRow({
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.subcategory,
    required this.paymentMode,
    required this.notes,
  });
}

class CsvParseResult {
  final List<CsvImportRow> rows;

  /// Human readable reasons for rows that cannot be imported ("Row 7: ...").
  final List<String> problems;
  final bool hasTypeColumn;

  const CsvParseResult({
    required this.rows,
    required this.problems,
    required this.hasTypeColumn,
  });
}

class CsvImportResult {
  final int imported;
  final int duplicates;
  final int newCategories;

  const CsvImportResult({
    required this.imported,
    required this.duplicates,
    required this.newCategories,
  });
}

/// Imports expenses / income from a CSV file. It reads the same layout the
/// app exports: Date, Type, Category, Subcategory, Amount, Payment mode, Notes.
/// Only Date and Amount are required. Rows already in the app (same date,
/// amount, category, payment mode and notes) are skipped, so importing the
/// same file twice is safe.
class CsvImportService {
  final Database db;
  CsvImportService(this.db);

  static const int maxRows = 5000;

  /// Lets the user pick a .csv file and returns its text (null = cancelled).
  Future<String?> pickFileText() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    List<int>? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) throw const CsvImportException('Could not read the file.');
    return utf8.decode(bytes, allowMalformed: true);
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Splits CSV text into rows of cells (handles quotes, commas and line
  /// breaks inside quotes, and a leading BOM).
  static List<List<String>> _splitCsv(String text) {
    if (text.startsWith('﻿')) text = text.substring(1);
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    void endCell() {
      row.add(cell.toString());
      cell.clear();
    }

    void endRow() {
      endCell();
      if (!(row.length == 1 && row.first.trim().isEmpty)) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        endCell();
      } else if (c == '\n') {
        endRow();
      } else if (c == '\r') {
        // ignore (handled by \n)
      } else {
        cell.write(c);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  /// Removes the apostrophe the exporter adds in front of =, +, @ and -.
  static String _clean(String value) {
    var v = value.trim();
    if (v.length > 1 && v[0] == "'" && '=+@-'.contains(v[1])) v = v.substring(1);
    return v;
  }

  static DateTime? _parseDate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    final iso = DateTime.tryParse(v);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    for (final pattern in const [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd MMM yyyy',
      'd/M/yyyy',
      'MM/dd/yyyy',
    ]) {
      try {
        final d = DateFormat(pattern).parseStrict(v);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }
    return null;
  }

  static double? _parseAmount(String raw) {
    final v = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final n = double.tryParse(v);
    if (n == null) return null;
    return n.abs();
  }

  CsvParseResult parse(String text) {
    final table = _splitCsv(text);
    if (table.isEmpty) throw const CsvImportException('The file is empty.');

    final header = table.first.map((h) => h.trim().toLowerCase()).toList();
    int col(List<String> names) {
      for (final n in names) {
        final i = header.indexOf(n);
        if (i != -1) return i;
      }
      return -1;
    }

    final dateCol = col(['date']);
    final amountCol = col(['amount']);
    if (dateCol == -1 || amountCol == -1) {
      throw const CsvImportException(
        'The first row must be a header with at least "Date" and "Amount" '
        'columns. Export a file from this app to see the expected layout.',
      );
    }
    final typeCol = col(['type']);
    final categoryCol = col(['category']);
    final subCol = col(['subcategory', 'sub category']);
    final modeCol = col(['payment mode', 'payment_mode', 'payment']);
    final notesCol = col(['notes', 'note', 'description', 'remarks']);

    String cellAt(List<String> r, int i) =>
        (i >= 0 && i < r.length) ? _clean(r[i]) : '';

    final rows = <CsvImportRow>[];
    final problems = <String>[];

    if (table.length - 1 > maxRows) {
      throw CsvImportException(
        'The file has more than $maxRows rows. Split it into smaller files.',
      );
    }

    for (var i = 1; i < table.length; i++) {
      final r = table[i];
      final line = i + 1;
      final date = _parseDate(cellAt(r, dateCol));
      if (date == null) {
        problems.add('Row $line: unreadable date');
        continue;
      }
      final amount = _parseAmount(cellAt(r, amountCol));
      if (amount == null || amount <= 0) {
        problems.add('Row $line: amount is missing or not positive');
        continue;
      }
      bool? isIncome;
      if (typeCol != -1) {
        final t = cellAt(r, typeCol).toLowerCase();
        if (t == 'income') {
          isIncome = true;
        } else if (t == 'expense') {
          isIncome = false;
        } else {
          problems.add('Row $line: Type must be Expense or Income');
          continue;
        }
      }
      rows.add(
        CsvImportRow(
          date: date,
          amount: amount,
          isIncome: isIncome,
          category: cellAt(r, categoryCol),
          subcategory: cellAt(r, subCol),
          paymentMode: cellAt(r, modeCol),
          notes: cellAt(r, notesCol),
        ),
      );
    }

    return CsvParseResult(
      rows: rows,
      problems: problems,
      hasTypeColumn: typeCol != -1,
    );
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  static String _cut(String v, int max) =>
      v.length > max ? v.substring(0, max) : v;

  /// Imports [rows] in one transaction. Rows whose Type is unknown use
  /// [defaultIsIncome].
  Future<CsvImportResult> import(
    List<CsvImportRow> rows, {
    required bool defaultIsIncome,
  }) async {
    var imported = 0;
    var duplicates = 0;
    var newCategories = 0;

    await db.transaction((txn) async {
      final categoryCache = <String, ({int id, String name})>{};
      final subCache = <String, ({int id, String name})>{};
      final seen = <String>{};

      Future<({int id, String name})> categoryFor(
        int typeId,
        String rawName,
      ) async {
        final name = _cut(rawName.isEmpty ? 'Uncategorized' : rawName, 40);
        final key = '$typeId|${name.toLowerCase()}';
        final cached = categoryCache[key];
        if (cached != null) return cached;

        final found = await txn.query(
          'categories',
          where: 'transaction_type_id = ? AND LOWER(category_name) = LOWER(?)',
          whereArgs: [typeId, name],
          limit: 1,
        );
        late final ({int id, String name}) result;
        if (found.isNotEmpty) {
          final id = found.first['id'] as int;
          if (found.first['is_active'] == 0) {
            await txn.update(
              'categories',
              {'is_active': 1},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          result = (id: id, name: found.first['category_name'] as String);
        } else {
          final id = await txn.insert('categories', {
            'transaction_type_id': typeId,
            'category_name': name,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
          newCategories++;
          result = (id: id, name: name);
        }
        categoryCache[key] = result;
        return result;
      }

      Future<({int id, String name})?> subFor(
        int categoryId,
        String rawName,
      ) async {
        if (rawName.isEmpty) return null;
        final name = _cut(rawName, 40);
        final key = '$categoryId|${name.toLowerCase()}';
        final cached = subCache[key];
        if (cached != null) return cached;

        final found = await txn.query(
          'subcategories',
          where: 'category_id = ? AND LOWER(subcategory_name) = LOWER(?)',
          whereArgs: [categoryId, name],
          limit: 1,
        );
        late final ({int id, String name}) result;
        if (found.isNotEmpty) {
          final id = found.first['id'] as int;
          if (found.first['is_active'] == 0) {
            await txn.update(
              'subcategories',
              {'is_active': 1},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          result = (id: id, name: found.first['subcategory_name'] as String);
        } else {
          final id = await txn.insert('subcategories', {
            'category_id': categoryId,
            'subcategory_name': name,
            'is_active': 1,
            'created_at': DateTime.now().toIso8601String(),
          });
          result = (id: id, name: name);
        }
        subCache[key] = result;
        return result;
      }

      for (final row in rows) {
        final income = row.isIncome ?? defaultIsIncome;
        final table = income ? 'incomes' : 'expenses';
        final category = await categoryFor(income ? 1 : 0, row.category);
        final sub = await subFor(category.id, row.subcategory);
        final dateText = DateFormat('yyyy-MM-dd').format(row.date);
        final mode = row.paymentMode.isEmpty ? 'Cash' : row.paymentMode;

        final key =
            '$table|$dateText|${row.amount.toStringAsFixed(2)}|${category.id}|'
            '$mode|${row.notes}';
        var exists = seen.contains(key);
        if (!exists) {
          final match = await txn.rawQuery(
            'SELECT 1 FROM $table WHERE date(date) = date(?) '
            'AND ROUND(amount, 2) = ? AND category_id = ? '
            'AND COALESCE(payment_mode, \'\') = ? '
            'AND COALESCE(notes, \'\') = ? LIMIT 1',
            [
              dateText,
              double.parse(row.amount.toStringAsFixed(2)),
              category.id,
              mode,
              row.notes,
            ],
          );
          exists = match.isNotEmpty;
        }
        if (exists) {
          duplicates++;
          continue;
        }
        seen.add(key);

        final values = <String, Object?>{
          'amount': row.amount,
          'category_id': category.id,
          'subcategory_id': sub?.id,
          'date': DateTime(
            row.date.year,
            row.date.month,
            row.date.day,
          ).toIso8601String(),
          'payment_mode': mode,
          'notes': row.notes.isEmpty ? null : row.notes,
          'created_at': DateTime.now().toIso8601String(),
        };
        if (income) {
          values['is_recurring'] = 0;
        } else {
          values['category_name'] = category.name;
          values['subcategory_name'] = sub?.name;
        }
        await txn.insert(table, values);
        imported++;
      }
    });

    return CsvImportResult(
      imported: imported,
      duplicates: duplicates,
      newCategories: newCategories,
    );
  }
}
