import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/common_delete_dialog.dart';
import '../models/investment_model.dart';
import '../models/investment_valuation_model.dart';
import '../providers/investment_provider.dart';
import '../utils/investment_utils.dart';

/// Value history and performance of one investment: a chart, summary figures
/// and the list of recorded valuations (add / delete).
class InvestmentValuationScreen extends StatefulWidget {
  final InvestmentModel investment;
  const InvestmentValuationScreen({super.key, required this.investment});

  @override
  State<InvestmentValuationScreen> createState() =>
      _InvestmentValuationScreenState();
}

class _InvestmentValuationScreenState extends State<InvestmentValuationScreen> {
  List<InvestmentValuation> _valuations = [];
  bool _loading = true;

  int get _id => widget.investment.id!;

  /// Latest copy of the investment (current value changes with each entry).
  InvestmentModel _current(BuildContext context) {
    final list = context.watch<InvestmentProvider>().investments;
    return list.firstWhere((i) => i.id == _id, orElse: () => widget.investment);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await context.read<InvestmentProvider>().getValuations(_id);
    if (!mounted) return;
    setState(() {
      _valuations = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final result = await showModalBottomSheet<_ValuationInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ValuationSheet(
        minDate: DateTime.tryParse(widget.investment.investmentDate),
        lastValue: _valuations.isEmpty ? null : _valuations.last.value,
      ),
    );
    if (result == null || !mounted) return;
    final provider = context.read<InvestmentProvider>();
    await provider.addValuation(
      investmentId: _id,
      value: result.value,
      date: result.date,
      notes: result.notes,
    );
    await _load();
    if (mounted) SnackbarUtils.showSnackbar(context, 'Value recorded');
  }

  Future<void> _delete(InvestmentValuation v) async {
    if (_valuations.length <= 1) {
      SnackbarUtils.showSnackbar(
        context,
        'The only entry cannot be deleted. Add a new value first.',
      );
      return;
    }
    final ok = await confirmDelete(
      context,
      title: 'Delete this value?',
      message:
          'The entry for ${AppDateUtils.formatDate(v.day)} will be removed. '
          'The current value follows the latest remaining entry.',
    );
    if (!ok || !mounted) return;
    await context.read<InvestmentProvider>().deleteValuation(v.id!, _id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final inv = _current(context);
    final scheme = Theme.of(context).colorScheme;
    final profit = InvestmentUtils.calculateProfit(
      investedAmount: inv.investedAmount,
      currentValue: inv.currentValue,
    );
    final roi = InvestmentUtils.calculateRoi(
      investedAmount: inv.investedAmount,
      currentValue: inv.currentValue,
    );
    final gain = profit >= 0;
    final gainColor = gain ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Value history')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Add value'),
      ),
      body: AppResponsiveContent(
        maxWidth: 700,
        padding: EdgeInsets.zero,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.investmentName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyUtils.formatAmount(inv.currentValue),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                gain ? Icons.trending_up : Icons.trending_down,
                                color: gainColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${CurrencyUtils.formatAmount(profit.abs())} '
                                  '(${roi.toStringAsFixed(2)}%) '
                                  '${gain ? 'gain' : 'loss'}',
                                  style: TextStyle(
                                    color: gainColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(height: 200, child: _chart(inv, scheme)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 14,
                                height: 3,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Value',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 14,
                                height: 3,
                                color: scheme.outline,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Invested',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _performanceCard(inv),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Recorded values',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = _valuations.length - 1; i >= 0; i--) ...[
                          if (i != _valuations.length - 1)
                            const Divider(height: 1),
                          _valuationTile(i),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _valuationTile(int index) {
    final v = _valuations[index];
    final prev = index > 0 ? _valuations[index - 1].value : null;
    Widget? change;
    if (prev != null && prev != 0) {
      final pct = (v.value - prev) / prev * 100;
      final up = pct >= 0;
      change = Text(
        '${up ? '+' : ''}${pct.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: up ? Colors.green : Colors.red,
        ),
      );
    }
    return ListTile(
      title: Text(CurrencyUtils.formatAmount(v.value)),
      subtitle: Text(
        [
          AppDateUtils.formatDate(v.day),
          if (v.notes != null && v.notes!.isNotEmpty) v.notes!,
        ].join(' • '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?change,
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(v),
          ),
        ],
      ),
    );
  }

  Widget _performanceCard(InvestmentModel inv) {
    final values = _valuations.map((v) => v.value).toList();
    final high = values.isEmpty ? inv.currentValue : values.reduce(math.max);
    final low = values.isEmpty ? inv.currentValue : values.reduce(math.min);

    final start = DateTime.tryParse(inv.investmentDate);
    final days = start == null ? 0 : DateTime.now().difference(start).inDays;
    String annualised = '-';
    if (days >= 30 && inv.investedAmount > 0 && inv.currentValue > 0) {
      final cagr =
          (math.pow(inv.currentValue / inv.investedAmount, 365 / days) - 1) *
          100;
      annualised = '${cagr.toStringAsFixed(2)}% a year';
    }

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            row('Invested', CurrencyUtils.formatAmount(inv.investedAmount)),
            row('Highest value', CurrencyUtils.formatAmount(high)),
            row('Lowest value', CurrencyUtils.formatAmount(low)),
            row('Time held', days <= 0 ? '-' : _heldLabel(days)),
            row('Annualised return', annualised),
          ],
        ),
      ),
    );
  }

  static String _heldLabel(int days) {
    if (days < 31) return '$days days';
    final months = (days / 30.44).floor();
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final rest = months % 12;
    return rest == 0 ? '$years yr' : '$years yr $rest mo';
  }

  Widget _chart(InvestmentModel inv, ColorScheme scheme) {
    final start = DateTime.tryParse(inv.investmentDate);
    final points = <({DateTime day, double value})>[
      if (start != null)
        (
          day: DateTime(start.year, start.month, start.day),
          value: inv.investedAmount,
        ),
      for (final v in _valuations) (day: v.day, value: v.value),
    ]..sort((a, b) => a.day.compareTo(b.day));

    if (points.length < 2) {
      return Center(
        child: Text(
          'Add more values to see the trend.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final first = points.first.day;
    double x(DateTime d) => d.difference(first).inDays.toDouble();
    final maxX = math.max(1.0, x(points.last.day));
    final ys = [...points.map((p) => p.value), inv.investedAmount];
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final pad = math.max((maxY - minY) * 0.15, maxY * 0.02);
    final dateFmt = DateFormat('dd MMM yy');

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: math.max(0, minY - pad),
        maxY: maxY + pad,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 0.6),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: maxX,
              getTitlesWidget: (value, meta) {
                if (value != 0 && value != maxX) return const SizedBox.shrink();
                final d = first.add(Duration(days: value.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFmt.format(d),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: inv.investedAmount,
              color: scheme.outline,
              strokeWidth: 1,
              dashArray: [6, 4],
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${CurrencyUtils.formatAmount(s.y)}\n'
                  '${dateFmt.format(first.add(Duration(days: s.x.round())))}',
                  const TextStyle(fontSize: 11, color: Colors.white),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final p in points) FlSpot(x(p.day), p.value)],
            isCurved: false,
            barWidth: 2.5,
            color: scheme.primary,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuationInput {
  final double value;
  final DateTime date;
  final String? notes;
  const _ValuationInput(this.value, this.date, this.notes);
}

class _ValuationSheet extends StatefulWidget {
  final DateTime? minDate;
  final double? lastValue;
  const _ValuationSheet({this.minDate, this.lastValue});

  @override
  State<_ValuationSheet> createState() => _ValuationSheetState();
}

class _ValuationSheetState extends State<_ValuationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _value = TextEditingController(
    text: widget.lastValue?.toStringAsFixed(2) ?? '',
  );
  final TextEditingController _notes = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.minDate ?? DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ValuationInput(
        double.parse(_value.text.trim()),
        _date,
        _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record current value',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Value on this date',
                prefixText: '${CurrencyUtils.symbol} ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n < 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(AppDateUtils.formatDate(_date)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
