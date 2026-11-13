import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

enum CsvDataScope { expenses, income, both }

class CsvExportResult {
  /// Saved file path, or null when the user cancelled the save dialog.
  final String? path;
  final int recordCount;

  const CsvExportResult({required this.path, required this.recordCount});
}

/// Exports expenses and/or income to a CSV file that opens in Excel / Sheets.
class CsvExportService {
  final Database db;
  CsvExportService(this.db);

  static final DateFormat _day = DateFormat('yyyy-MM-dd');

  /// Builds the CSV and lets the user choose where to save it.
  /// [from] / [to] are inclusive; null means "no limit".
  /// When nothing matches, nothing is saved and `recordCount` is 0.
  Future<CsvExportResult> export({
    required CsvDataScope scope,
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = <List<Object?>>[];

    if (scope != CsvDataScope.income) {
      rows.addAll(await _query('expenses', 'Expense', from, to));
    }
    if (scope != CsvDataScope.expenses) {
      rows.addAll(await _query('incomes', 'Income', from, to));
    }

    if (rows.isEmpty) return const CsvExportResult(path: null, recordCount: 0);

    // Newest first (column 0 is a yyyy-MM-dd string).
    rows.sort((a, b) => (b[0] as String).compareTo(a[0] as String));

    final buffer = StringBuffer('﻿'); // BOM so Excel reads UTF-8 properly
    buffer.writeln(
      _line(['Date', 'Type', 'Category', 'Subcategory', 'Amount', 'Payment mode', 'Notes']),
    );
    for (final row in rows) {
      buffer.writeln(_line(row));
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final label = switch (scope) {
      CsvDataScope.expenses => 'expenses',
      CsvDataScope.income => 'income',
      CsvDataScope.both => 'transactions',
    };

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV export',
      fileName: 'mywallet_${label}_$stamp.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: bytes,
    );

    if (path != null &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
    }

    return CsvExportResult(path: path, recordCount: rows.length);
  }

  Future<List<List<Object?>>> _query(
    String table,
    String typeLabel,
    DateTime? from,
    DateTime? to,
  ) async {
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date(t.date) >= date(?)');
      args.add(_day.format(from));
    }
    if (to != null) {
      where.add('date(t.date) <= date(?)');
      args.add(_day.format(to));
    }

    final result = await db.rawQuery('''
      SELECT t.date, t.amount, t.payment_mode, t.notes,
             c.category_name, s.subcategory_name
      FROM $table t
      LEFT JOIN categories c ON t.category_id = c.id
      LEFT JOIN subcategories s ON t.subcategory_id = s.id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
    ''', args);

    return result.map((r) {
      final parsed = DateTime.tryParse(r['date'] as String? ?? '');
      return <Object?>[
        parsed != null ? _day.format(parsed) : (r['date'] ?? ''),
        typeLabel,
        r['category_name'] ?? '',
        r['subcategory_name'] ?? '',
        (r['amount'] as num?)?.toStringAsFixed(2) ?? '',
        r['payment_mode'] ?? '',
        r['notes'] ?? '',
      ];
    }).toList();
  }

  String _line(List<Object?> cells) => cells.map(_cell).join(',');

  /// Quotes a value for CSV and neutralises spreadsheet formulas
  /// (a note starting with = + - @ would otherwise run as a formula in Excel).
  String _cell(Object? value) {
    var text = (value ?? '').toString();
    if (text.isNotEmpty && '=+@'.contains(text[0])) text = "'$text";
    if (text.startsWith('-') && double.tryParse(text) == null) text = "'$text";
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      text = '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
