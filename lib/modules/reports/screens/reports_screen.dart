import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../models/report_models.dart';
import '../providers/report_provider.dart';
import '../services/report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _export = ReportExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReportProvider>().load(),
    );
  }

  Future<void> _exportFile(
    Future<String?> Function(FinancialReport) action,
    FinancialReport report,
  ) async {
    try {
      final path = await action(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Export cancelled' : 'Report saved successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReportProvider>();
    final report = p.report;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => p.load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AppResponsiveContent(
        maxWidth: 1100,
        padding: EdgeInsets.zero,
        child: p.isLoading && report == null
            ? const Center(child: CircularProgressIndicator())
            : p.error != null && report == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 44,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Could not load the report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please try again. If it keeps happening, restart the app.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: () => p.load(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : report == null
            ? const Center(child: Text('No report data available'))
            : RefreshIndicator(
                onRefresh: () => p.load(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Financial year',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value: p.selectedYear,
                          items:
                              List.generate(8, (i) => DateTime.now().year - i)
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (y) {
                            if (y != null) p.changeYear(y);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _summaryCards(report),
                    const SizedBox(height: 14),
                    _sectionTitle('Income vs Expenses'),
                    const SizedBox(height: 8),
                    _monthlyChart(report),
                    const SizedBox(height: 14),
                    _sectionTitle('Category-wise Expenses'),
                    const SizedBox(height: 8),
                    _categoryChart(report),
                    const SizedBox(height: 14),
                    _sectionTitle('Monthly Breakdown'),
                    const SizedBox(height: 8),
                    _monthlyTable(report),
                    const SizedBox(height: 14),
                    _sectionTitle('Export Report'),
                    const SizedBox(height: 8),
                    if (report.totalIncome == 0 && report.totalExpense == 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Nothing to export for ${p.selectedYear}. '
                          'Pick another year or add transactions.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                report.totalIncome == 0 &&
                                    report.totalExpense == 0
                                ? null
                                : () => _exportFile(_export.exportPdf, report),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                report.totalIncome == 0 &&
                                    report.totalExpense == 0
                                ? null
                                : () => _exportFile(_export.exportCsv, report),
                            icon: const Icon(Icons.table_view_outlined),
                            label: const Text('Excel / CSV'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summaryCards(FinancialReport r) => LayoutBuilder(
    builder: (context, c) {
      final wide = c.maxWidth > 650;
      final cards = [
        _summary('Income', r.totalIncome, AppColors.income, Icons.south_west),
        _summary(
          'Expenses',
          r.totalExpense,
          AppColors.expense,
          Icons.north_east,
        ),
        _summary(
          'Net Savings',
          r.netSavings,
          r.netSavings >= 0 ? AppColors.success : AppColors.error,
          Icons.savings_outlined,
        ),
      ];
      return wide
          ? Row(
              children: cards
                  .map(
                    (w) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: w,
                      ),
                    ),
                  )
                  .toList(),
            )
          : Column(
              children: cards
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: w,
                    ),
                  )
                  .toList(),
            );
    },
  );

  Widget _summary(String title, double amount, Color color, IconData icon) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyUtils.formatAmount(amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );

  Widget _monthlyChart(FinancialReport r) {
    final maxValue = [
      ...r.monthly.map((x) => x.income),
      ...r.monthly.map((x) => x.expense),
    ].fold<double>(0, (a, b) => a > b ? a : b);
    if (maxValue == 0) return const _EmptyChart();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 12, 10),
        child: SizedBox(
          height: 230,
          child: BarChart(
            BarChartData(
              maxY: maxValue * 1.2,
              barGroups: r.monthly
                  .map(
                    (x) => BarChartGroupData(
                      x: x.month,
                      barRods: [
                        BarChartRodData(
                          toY: x.income,
                          color: AppColors.income,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: x.expense,
                          color: AppColors.expense,
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                      barsSpace: 3,
                    ),
                  )
                  .toList(),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, _) =>
                        Text(_axis(v), style: const TextStyle(fontSize: 9)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _monthShort(v.toInt()),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  String _axis(double v) => v >= 100000
      ? '${(v / 100000).toStringAsFixed(1)}L'
      : v >= 1000
      ? '${(v / 1000).toStringAsFixed(0)}k'
      : v.toStringAsFixed(0);

  String _monthShort(int m) => m >= 1 && m <= 12
      ? const ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'][m -
            1]
      : '';

  Widget _categoryChart(FinancialReport r) {
    if (r.categories.isEmpty) return const _EmptyChart();
    final colors = [
      AppColors.primary,
      AppColors.income,
      AppColors.warning,
      AppColors.savings,
      AppColors.error,
      Colors.teal,
      Colors.deepPurple,
      Colors.orange,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SizedBox(
              height: 190,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  sections: r.categories
                      .asMap()
                      .entries
                      .map(
                        (e) => PieChartSectionData(
                          value: e.value.amount,
                          title:
                              '${(e.value.amount / r.totalExpense * 100).toStringAsFixed(0)}%',
                          color: colors[e.key % colors.length],
                          radius: 55,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...r.categories
                .take(8)
                .toList()
                .asMap()
                .entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          CurrencyUtils.formatAmount(e.value.amount),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            if (r.categories.length > 8)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing top 8 categories',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyTable(FinancialReport r) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: 12,
          columnSpacing: 18,
          dataRowMinHeight: 42,
          dataRowMaxHeight: 48,
          headingRowHeight: 42,
          columns: const [
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Income'), numeric: true),
            DataColumn(label: Text('Expense'), numeric: true),
            DataColumn(label: Text('Net'), numeric: true),
          ],
          rows: r.monthly
              .map(
                (x) => DataRow(
                  cells: [
                    DataCell(Text(names[x.month - 1])),
                    DataCell(Text(CurrencyUtils.formatAmount(x.income))),
                    DataCell(Text(CurrencyUtils.formatAmount(x.expense))),
                    DataCell(
                      Text(
                        CurrencyUtils.formatAmount(x.net),
                        style: TextStyle(
                          color: x.net >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => Card(
    child: SizedBox(
      height: 150,
      child: Center(
        child: Text(
          'No transactions found for this year',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}
