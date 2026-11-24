import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/settings/app_preferences.dart';
import '../models/report_models.dart';

class ReportExportService {
  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static String get _code => AppPreferences.instance.currency.code;

  Future<String?> exportCsv(FinancialReport r) async {
    final rows = <List<String>>[
      ['MyWallet Financial Report', r.year.toString()],
      ['Currency', _code],
      ['Total Income', r.totalIncome.toStringAsFixed(2)],
      ['Total Expenses', r.totalExpense.toStringAsFixed(2)],
      ['Net Savings', r.netSavings.toStringAsFixed(2)],
      [],
      ['Month', 'Income', 'Expenses', 'Net Savings'],
      ...r.monthly.map(
        (x) => [
          months[x.month - 1],
          x.income.toStringAsFixed(2),
          x.expense.toStringAsFixed(2),
          x.net.toStringAsFixed(2),
        ],
      ),
      [],
      ['Expense Category', 'Amount'],
      ...r.categories.map((x) => [x.categoryName, x.amount.toStringAsFixed(2)]),
    ];
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final csv = rows.map((x) => x.map(q).join(',')).join('\r\n');
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Export report',
      fileName: 'mywallet_report_${r.year}.csv',
      bytes: bytes,
    );
  }

  Future<String?> exportPdf(FinancialReport r) async {
    final lines = <String>[
      'MYWALLET FINANCIAL REPORT',
      'Year: ${r.year}',
      '',
      'TOTAL INCOME: $_code ${r.totalIncome.toStringAsFixed(2)}',
      'TOTAL EXPENSES: $_code ${r.totalExpense.toStringAsFixed(2)}',
      'NET SAVINGS: $_code ${r.netSavings.toStringAsFixed(2)}',
      '',
      'MONTHLY SUMMARY',
      ...r.monthly.map(
        (x) =>
            '${months[x.month - 1]} | Income ${x.income.toStringAsFixed(2)} | Expense ${x.expense.toStringAsFixed(2)} | Net ${x.net.toStringAsFixed(2)}',
      ),
      '',
      'CATEGORY-WISE EXPENSES',
      ...r.categories.map(
        (x) => '${x.categoryName}: $_code ${x.amount.toStringAsFixed(2)}',
      ),
    ];
    // 50 lines per A4 page; as many pages as the report needs.
    const perPage = 50;
    final streams = <String>[];
    for (var start = 0; start < lines.length; start += perPage) {
      final end = start + perPage > lines.length
          ? lines.length
          : start + perPage;
      final c = StringBuffer('BT\n/F1 10 Tf\n50 790 Td\n14 TL\n');
      for (var i = start; i < end; i++) {
        if (i > start) c.write('T*\n');
        c.write('(${_escape(lines[i])}) Tj\n');
      }
      c.write('ET');
      streams.add(c.toString());
    }
    // Objects: 1 catalog, 2 pages, 3 font, then (page, content) per page.
    final pageCount = streams.length;
    final kids = [for (var i = 0; i < pageCount; i++) '${4 + i * 2} 0 R'];
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [${kids.join(' ')}] /Count $pageCount >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      for (var i = 0; i < pageCount; i++) ...[
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
            '/Resources << /Font << /F1 3 0 R >> >> /Contents ${5 + i * 2} 0 R >>',
        '<< /Length ${latin1.encode(streams[i]).length} >>\n'
            'stream\n${streams[i]}\nendstream',
      ],
    ];
    final out = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(latin1.encode(out.toString()).length);
      out.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final xref = latin1.encode(out.toString()).length;
    final size = objects.length + 1;
    out.write('xref\n0 $size\n0000000000 65535 f \n');
    for (var i = 1; i < offsets.length; i++) {
      out.write('${offsets[i].toString().padLeft(10, '0')} 00000 n \n');
    }
    out.write(
      'trailer\n<< /Size $size /Root 1 0 R >>\nstartxref\n$xref\n%%EOF',
    );
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF report',
      fileName: 'mywallet_report_${r.year}.pdf',
      bytes: Uint8List.fromList(latin1.encode(out.toString())),
    );
  }

  String _escape(String s) {
    final slash = String.fromCharCode(92);
    return s
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '?')
        .replaceAll(slash, '$slash$slash')
        .replaceAll('(', '$slash(')
        .replaceAll(')', '$slash)');
  }
}
