import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/export/csv_export_service.dart';

/// The choices made in the "Export to CSV" sheet.
class ExportOptions {
  final CsvDataScope scope;
  final DateTime? from;
  final DateTime? to;

  const ExportOptions({required this.scope, this.from, this.to});
}

enum _Period { allTime, thisMonth, last3Months, thisYear, custom }

/// Bottom sheet that asks what to export and for which period.
/// Returns [ExportOptions], or null if dismissed.
class ExportOptionsSheet extends StatefulWidget {
  const ExportOptionsSheet({super.key});

  static Future<ExportOptions?> show(BuildContext context) {
    return showModalBottomSheet<ExportOptions>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ExportOptionsSheet(),
    );
  }

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  CsvDataScope _scope = CsvDataScope.both;
  _Period _period = _Period.thisMonth;
  DateTimeRange? _custom;

  static final DateFormat _fmt = DateFormat('dd MMM yyyy');

  static const Map<_Period, String> _periodLabels = {
    _Period.allTime: 'All time',
    _Period.thisMonth: 'This month',
    _Period.last3Months: 'Last 3 months',
    _Period.thisYear: 'This year',
    _Period.custom: 'Custom range',
  };

  Future<void> _selectPeriod(_Period period) async {
    if (period == _Period.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 1, 12, 31),
        initialDateRange:
            _custom ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      );
      if (picked == null) return; // keep the previous choice
      setState(() {
        _custom = picked;
        _period = _Period.custom;
      });
      return;
    }
    setState(() => _period = period);
  }

  ExportOptions _build() {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (_period) {
      case _Period.allTime:
        break;
      case _Period.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;
      case _Period.last3Months:
        from = DateTime(now.year, now.month - 2, 1);
        to = now;
        break;
      case _Period.thisYear:
        from = DateTime(now.year, 1, 1);
        to = now;
        break;
      case _Period.custom:
        from = _custom?.start;
        to = _custom?.end;
        break;
    }
    return ExportOptions(scope: _scope, from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export to CSV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const Text('What to export'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CsvDataScope>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: CsvDataScope.expenses,
                    label: Text('Expenses'),
                  ),
                  ButtonSegment(
                    value: CsvDataScope.income,
                    label: Text('Income'),
                  ),
                  ButtonSegment(value: CsvDataScope.both, label: Text('Both')),
                ],
                selected: {_scope},
                onSelectionChanged: (s) => setState(() => _scope = s.first),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Period'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in _periodLabels.entries)
                  ChoiceChip(
                    label: Text(
                      entry.key == _Period.custom && _custom != null
                          ? '${_fmt.format(_custom!.start)} – ${_fmt.format(_custom!.end)}'
                          : entry.value,
                    ),
                    selected: _period == entry.key,
                    onSelected: (_) => _selectPeriod(entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _build()),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
