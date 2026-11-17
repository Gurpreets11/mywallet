import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/app_database.dart';

/// User preferences (date format, reminders). Stored in the existing
/// `app_metadata` key/value table, so no new package or table is needed.
/// Read values anywhere with `AppPreferences.instance`.
/// App-wide text size choices (multiplies the normal text scale).
enum AppFontSize {
  small('Small', 0.9),
  medium('Medium', 1.0),
  large('Large', 1.15);

  const AppFontSize(this.label, this.scale);

  final String label;
  final double scale;
}

class AppPreferences extends ChangeNotifier {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const String _table = 'app_metadata';
  static const String _kDateFormat = 'pref_date_format';
  static const String _kDailyReminder = 'pref_daily_reminder_enabled';
  static const String _kDailyReminderTime = 'pref_daily_reminder_time';
  static const String _kEmiReminders = 'pref_emi_reminders_enabled';
  static const String _kSipReminders = 'pref_sip_reminders_enabled';
  static const String _kFontSize = 'pref_font_size';

  /// Date patterns the user can pick from (shown with a live example).
  static const List<String> dateFormatOptions = [
    'dd MMM yyyy',
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
  ];

  String _dateFormat = dateFormatOptions.first;
  bool _dailyReminderEnabled = true;
  int _dailyReminderHour = 21;
  int _dailyReminderMinute = 0;
  bool _emiRemindersEnabled = true;
  bool _sipRemindersEnabled = true;
  AppFontSize _fontSize = AppFontSize.medium;

  AppFontSize get fontSize => _fontSize;

  /// Multiplier applied to all app text (see `MaterialApp.builder` in main).
  double get fontScale => _fontSize.scale;

  String get dateFormat => _dateFormat;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  int get dailyReminderHour => _dailyReminderHour;
  int get dailyReminderMinute => _dailyReminderMinute;
  bool get emiRemindersEnabled => _emiRemindersEnabled;
  bool get sipRemindersEnabled => _sipRemindersEnabled;

  /// Loads saved preferences. Safe to call again (e.g. after a restore).
  /// Falls back to defaults for anything missing or invalid.
  Future<void> load() async {
    // Reset to defaults first so values removed by a restore don't linger.
    _dateFormat = dateFormatOptions.first;
    _dailyReminderEnabled = true;
    _dailyReminderHour = 21;
    _dailyReminderMinute = 0;
    _emiRemindersEnabled = true;
    _sipRemindersEnabled = true;
    _fontSize = AppFontSize.medium;

    try {
      final Database db = await AppDatabase.database;
      final rows = await db.query(_table, where: "meta_key LIKE 'pref_%'");
      final values = {
        for (final r in rows)
          r['meta_key'] as String: r['meta_value'] as String,
      };

      final format = values[_kDateFormat];
      if (format != null && dateFormatOptions.contains(format)) {
        _dateFormat = format;
      }
      if (values[_kDailyReminder] != null) {
        _dailyReminderEnabled = values[_kDailyReminder] == '1';
      }
      final time = values[_kDailyReminderTime];
      if (time != null) {
        final parts = time.split(':');
        final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
        final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          _dailyReminderHour = h;
          _dailyReminderMinute = m;
        }
      }
      if (values[_kEmiReminders] != null) {
        _emiRemindersEnabled = values[_kEmiReminders] == '1';
      }
      if (values[_kSipReminders] != null) {
        _sipRemindersEnabled = values[_kSipReminders] == '1';
      }
      final fontName = values[_kFontSize];
      for (final option in AppFontSize.values) {
        if (option.name == fontName) _fontSize = option;
      }
    } catch (_) {
      // Keep defaults — preferences must never block app start-up.
    }
    notifyListeners();
  }

  Future<void> _save(String key, String value) async {
    final Database db = await AppDatabase.database;
    await db.insert(_table, {
      'meta_key': key,
      'meta_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setDateFormat(String pattern) async {
    if (!dateFormatOptions.contains(pattern)) return;
    await _save(_kDateFormat, pattern);
    _dateFormat = pattern;
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    await _save(_kDailyReminder, value ? '1' : '0');
    _dailyReminderEnabled = value;
  }

  Future<void> setDailyReminderTime(int hour, int minute) async {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    await _save(_kDailyReminderTime, '$h:$m');
    _dailyReminderHour = hour;
    _dailyReminderMinute = minute;
  }

  Future<void> setEmiRemindersEnabled(bool value) async {
    await _save(_kEmiReminders, value ? '1' : '0');
    _emiRemindersEnabled = value;
  }

  Future<void> setSipRemindersEnabled(bool value) async {
    await _save(_kSipReminders, value ? '1' : '0');
    _sipRemindersEnabled = value;
  }

  Future<void> setFontSize(AppFontSize value) async {
    await _save(_kFontSize, value.name);
    _fontSize = value;
    notifyListeners();
  }
}
