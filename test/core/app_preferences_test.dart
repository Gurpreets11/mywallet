import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:mywallet/core/database/app_database.dart';
import 'package:mywallet/core/services/settings/app_preferences.dart';

import '../helpers/test_database.dart';

void main() {
  useFreshDatabase();
  final prefs = AppPreferences.instance;

  Future<void> putRaw(String key, String value) async {
    final db = await AppDatabase.database;
    await db.insert('app_metadata', {'meta_key': key, 'meta_value': value});
  }

  group('enums', () {
    test('font sizes scale', () {
      expect(AppFontSize.small.scale, lessThan(AppFontSize.medium.scale));
      expect(AppFontSize.medium.scale, 1.0);
      expect(AppFontSize.large.scale, greaterThan(AppFontSize.medium.scale));
    });

    test('theme choices map to ThemeMode', () {
      expect(AppThemeChoice.light.mode, ThemeMode.light);
      expect(AppThemeChoice.dark.mode, ThemeMode.dark);
      expect(AppThemeChoice.system.mode, ThemeMode.system);
    });

    test('currencies have unique codes and symbols', () {
      final codes = AppCurrency.values.map((c) => c.code).toSet();
      expect(codes.length, AppCurrency.values.length);
      expect(AppCurrency.values.length, 10);
      expect(AppCurrency.inr.symbol, '₹');
    });

    test('auto backup frequencies', () {
      expect(AutoBackupFrequency.off.days, 0);
      expect(AutoBackupFrequency.daily.days, 1);
      expect(AutoBackupFrequency.weekly.days, 7);
    });

    test('lock delay options', () {
      expect(AppPreferences.lockDelayOptions, [0, 30, 60, 300]);
    });
  });

  group('defaults', () {
    test('a fresh database gives the documented defaults', () async {
      await prefs.load();
      expect(prefs.dateFormat, 'dd MMM yyyy');
      expect(prefs.dailyReminderEnabled, isTrue);
      expect(prefs.dailyReminderHour, 21);
      expect(prefs.dailyReminderMinute, 0);
      expect(prefs.emiRemindersEnabled, isTrue);
      expect(prefs.sipRemindersEnabled, isTrue);
      expect(prefs.billRemindersEnabled, isTrue);
      expect(prefs.budgetAlertsEnabled, isTrue);
      expect(prefs.fontSize, AppFontSize.medium);
      expect(prefs.fontScale, 1.0);
      expect(prefs.themeChoice, AppThemeChoice.light);
      expect(prefs.themeMode, ThemeMode.light);
      expect(prefs.currency, AppCurrency.inr);
      expect(prefs.autoBackup, AutoBackupFrequency.weekly);
      expect(prefs.lockDelaySeconds, 30);
    });
  });

  group('persistence', () {
    test('every setter survives a reload', () async {
      await prefs.load();
      await prefs.setDateFormat('yyyy-MM-dd');
      await prefs.setDailyReminderEnabled(false);
      await prefs.setDailyReminderTime(7, 5);
      await prefs.setEmiRemindersEnabled(false);
      await prefs.setSipRemindersEnabled(false);
      await prefs.setBillRemindersEnabled(false);
      await prefs.setBudgetAlertsEnabled(false);
      await prefs.setFontSize(AppFontSize.large);
      await prefs.setThemeChoice(AppThemeChoice.dark);
      await prefs.setCurrency(AppCurrency.eur);
      await prefs.setAutoBackup(AutoBackupFrequency.daily);
      await prefs.setLockDelaySeconds(300);

      await prefs.load(); // re-reads from the database

      expect(prefs.dateFormat, 'yyyy-MM-dd');
      expect(prefs.dailyReminderEnabled, isFalse);
      expect(prefs.dailyReminderHour, 7);
      expect(prefs.dailyReminderMinute, 5);
      expect(prefs.emiRemindersEnabled, isFalse);
      expect(prefs.sipRemindersEnabled, isFalse);
      expect(prefs.billRemindersEnabled, isFalse);
      expect(prefs.budgetAlertsEnabled, isFalse);
      expect(prefs.fontSize, AppFontSize.large);
      expect(prefs.fontScale, AppFontSize.large.scale);
      expect(prefs.themeChoice, AppThemeChoice.dark);
      expect(prefs.currency, AppCurrency.eur);
      expect(prefs.autoBackup, AutoBackupFrequency.daily);
      expect(prefs.lockDelaySeconds, 300);
    });

    test('an unknown date format is ignored', () async {
      await prefs.load();
      await prefs.setDateFormat('not-a-format');
      expect(prefs.dateFormat, 'dd MMM yyyy');
    });

    test('theme, currency, font and backup changes notify listeners', () async {
      await prefs.load();
      var calls = 0;
      void listener() => calls++;
      prefs.addListener(listener);
      await prefs.setThemeChoice(AppThemeChoice.system);
      await prefs.setCurrency(AppCurrency.gbp);
      await prefs.setFontSize(AppFontSize.small);
      await prefs.setAutoBackup(AutoBackupFrequency.off);
      prefs.removeListener(listener);
      expect(calls, 4);
    });

    test('corrupt stored values fall back to defaults', () async {
      await putRaw('pref_date_format', 'garbage');
      await putRaw('pref_daily_reminder_time', '99:99');
      await putRaw('pref_lock_delay_seconds', '12345');
      await putRaw('pref_theme_mode', 'neon');
      await putRaw('pref_currency', 'XYZ');
      await putRaw('pref_font_size', 'huge');
      await putRaw('pref_auto_backup', 'hourly');

      await prefs.load();

      expect(prefs.dateFormat, 'dd MMM yyyy');
      expect(prefs.dailyReminderHour, 21);
      expect(prefs.dailyReminderMinute, 0);
      expect(prefs.lockDelaySeconds, 30);
      expect(prefs.themeChoice, AppThemeChoice.light);
      expect(prefs.currency, AppCurrency.inr);
      expect(prefs.fontSize, AppFontSize.medium);
      expect(prefs.autoBackup, AutoBackupFrequency.weekly);
    });

    test(
      'values from the app_metadata table are read as 0 / 1 flags',
      () async {
        await putRaw('pref_emi_reminders_enabled', '0');
        await putRaw('pref_budget_alerts_enabled', '1');
        await prefs.load();
        expect(prefs.emiRemindersEnabled, isFalse);
        expect(prefs.budgetAlertsEnabled, isTrue);
      },
    );
  });
}
