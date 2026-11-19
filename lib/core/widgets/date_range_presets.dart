import 'package:flutter/material.dart';

/// Quick date-range chips (This month, Last month, Last 7 days, ...).
/// The "Custom" range is still chosen with the date-range picker next to it.
class DateRangePresets extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange> onSelected;

  const DateRangePresets({
    super.key,
    required this.range,
    required this.onSelected,
  });

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static List<(String, DateTimeRange)> presets() {
    final today = _day(DateTime.now());
    return [
      (
        'This month',
        DateTimeRange(start: DateTime(today.year, today.month, 1), end: today),
      ),
      (
        'Last month',
        DateTimeRange(
          start: DateTime(today.year, today.month - 1, 1),
          end: DateTime(today.year, today.month, 0),
        ),
      ),
      (
        'Last 7 days',
        DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today),
      ),
      (
        'Last 30 days',
        DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        ),
      ),
      ('This year', DateTimeRange(start: DateTime(today.year, 1, 1), end: today)),
    ];
  }

  bool _same(DateTimeRange a, DateTimeRange b) =>
      _day(a.start) == _day(b.start) && _day(a.end) == _day(b.end);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final (label, value) in presets())
          ChoiceChip(
            label: Text(label),
            selected: range != null && _same(range!, value),
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
