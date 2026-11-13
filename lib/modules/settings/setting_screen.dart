import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/services/app_data_refresher.dart';
import '../../core/services/backup/backup_service.dart';
import '../../core/services/backup/data_reset_service.dart';
import '../../core/services/backup/restore_service.dart';
import '../../core/services/export/csv_export_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/security/app_lock_service.dart';
import '../../core/services/settings/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/widgets/app_responsive_content.dart';
import '../../core/widgets/type_to_confirm_dialog.dart';
import 'screens/pin_setup_screen.dart';
import 'widgets/export_options_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Tables shown in the "Your data" card: table name -> label.
  static const Map<String, String> _overviewTables = {
    'expenses': 'Expenses',
    'incomes': 'Income',
    'investments': 'Investments',
    'loans': 'Loans',
    'loan_payments': 'EMI payments',
    'budgets': 'Budgets',
    'recurring_transactions': 'Recurring',
  };

  final AppPreferences _prefs = AppPreferences.instance;
  final AppLockService _lock = AppLockService.instance;

  bool _busy = false;
  bool _loadingOverview = true;
  Map<String, int> _counts = {};
  DateTime? _lastBackupAt;
  int _safetyCopyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  void _snack(String message) {
    if (!mounted) return;
    SnackbarUtils.showSnackbar(context, message);
  }

  Future<void> _loadOverview() async {
    try {
      final Database db = await AppDatabase.database;
      final service = BackupService(db);
      final counts = await service.getRecordCounts();
      final lastBackup = await service.getLastBackupAt();
      final safety = await service.listSafetyBackups();
      if (!mounted) return;
      setState(() {
        _counts = counts;
        _lastBackupAt = lastBackup;
        _safetyCopyCount = safety.length;
        _loadingOverview = false;
      });
    } catch (e) {
      debugPrint('Settings overview failed: $e');
      if (!mounted) return;
      setState(() => _loadingOverview = false);
    }
  }

  /// Rebuilds reminders for the current data/preferences. Never throws
  /// (notification permission may be denied).
  Future<void> _rescheduleReminders() async {
    try {
      await NotificationService.instance.rescheduleAll();
    } catch (e) {
      debugPrint('Reminder rescheduling failed: $e');
    }
  }

  /// Everything that must happen after the database content was replaced.
  Future<void> _afterDataChanged() async {
    await _prefs.load();
    await _rescheduleReminders();
    if (mounted) await AppDataRefresher.refreshAll(context);
    await _loadOverview();
  }

  // ---------------------------------------------------------------------------
  // Backup
  // ---------------------------------------------------------------------------

  Future<void> _backupData() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final Database db = await AppDatabase.database;
      final path = await _lock.runWithoutLock(
        () => BackupService(db).exportBackupToUserChosenLocation(),
      );
      if (!mounted) return;
      if (path == null) {
        _snack('Backup cancelled');
      } else {
        _snack('Backup saved to $path');
        await _loadOverview();
      }
    } catch (e) {
      _snack('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Restore
  // ---------------------------------------------------------------------------

  /// Restore from a file the user picks.
  Future<void> _restoreData() async {
    if (_busy) return;
    try {
      final Database db = await AppDatabase.database;
      final backupMap = await _lock.runWithoutLock(
        () => RestoreService(db).pickAndParseBackupFile(),
      );
      if (backupMap == null) return; // user cancelled the picker
      await _runRestore(backupMap);
    } on BackupFormatException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Restore failed: $e. Your existing data was not changed.');
    }
  }

  /// Restore from one of the automatic safety copies kept by the app.
  Future<void> _restoreFromSafetyCopy() async {
    if (_busy) return;
    try {
      final Database db = await AppDatabase.database;
      final files = await BackupService(db).listSafetyBackups();
      if (files.isEmpty) {
        _snack('No safety copies found.');
        await _loadOverview();
        return;
      }
      if (!mounted) return;
      final chosen = await showDialog<File>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Restore from safety copy'),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Copies are saved automatically before every restore or '
                'reset. Pick the state you want to go back to.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            for (final f in files)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, f),
                child: Text(_describeSafetyCopy(f)),
              ),
          ],
        ),
      );
      if (chosen == null) return;
      final backupMap = await RestoreService(db).parseBackupFile(chosen.path);
      await _runRestore(backupMap);
    } on BackupFormatException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Restore failed: $e. Your existing data was not changed.');
    }
  }

  String _describeSafetyCopy(File file) {
    final info = BackupService.describeSafetyBackup(file);
    final what = info.reason == 'reset' ? 'Before reset' : 'Before restore';
    final when = info.time == null
        ? ''
        : ' • ${DateFormat('dd MMM yyyy, hh:mm a').format(info.time!)}';
    return '$what$when';
  }

  /// Validate -> confirm -> safety copy -> restore -> refresh the app.
  Future<void> _runRestore(Map<String, dynamic> backupMap) async {
    try {
      final Database db = await AppDatabase.database;
      final restoreService = RestoreService(db);
      final info = await restoreService.inspectBackup(backupMap);

      if (!mounted) return;
      final confirmed = await _confirmRestore(info);
      if (confirmed != true || !mounted) return;

      setState(() => _busy = true);

      await BackupService(db).createSafetyBackup(reason: 'restore');
      final restored = await restoreService.restoreFromBackupMap(
        backupMap,
        mode: RestoreMode.replace,
      );

      await _afterDataChanged();
      _snack('Data restored successfully ($restored records)');
    } on BackupFormatException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Restore failed: $e. Your existing data was not changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmRestore(BackupInfo info) {
    final exported = info.exportedAt == null
        ? 'Unknown date'
        : DateFormat('dd MMM yyyy, hh:mm a').format(info.exportedAt!);

    final lines = <String>[];
    _overviewTables.forEach((table, label) {
      final count = info.counts[table];
      if (count != null && count > 0) lines.add('$label: $count');
    });

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(child: Text('Restore data?')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup created: $exported'),
              const SizedBox(height: 8),
              if (lines.isEmpty)
                const Text('This backup contains no transactions.')
              else
                Text(lines.join('\n')),
              const SizedBox(height: 16),
              const Text(
                'This will REPLACE all data currently in the app with the '
                'data from this backup. A safety copy of your current data '
                'is saved automatically before restoring.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CSV export
  // ---------------------------------------------------------------------------

  Future<void> _exportCsv() async {
    if (_busy) return;
    final options = await ExportOptionsSheet.show(context);
    if (options == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final Database db = await AppDatabase.database;
      final result = await _lock.runWithoutLock(
        () => CsvExportService(
          db,
        ).export(scope: options.scope, from: options.from, to: options.to),
      );
      if (result.recordCount == 0) {
        _snack('No records found for the selected period.');
      } else if (result.path == null) {
        _snack('Export cancelled');
      } else {
        _snack('Exported ${result.recordCount} records to ${result.path}');
      }
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Preferences & reminders
  // ---------------------------------------------------------------------------

  Future<void> _changeDateFormat(String? pattern) async {
    if (pattern == null || pattern == _prefs.dateFormat) return;
    await _prefs.setDateFormat(pattern);
    if (!mounted) return;
    setState(() {});
    // Providers notify their listeners, so open screens redraw their dates.
    await AppDataRefresher.refreshAll(context);
  }

  Future<void> _toggleDailyReminder(bool value) async {
    await _prefs.setDailyReminderEnabled(value);
    if (!mounted) return;
    setState(() {});
    await _applyReminderChange(
      () => NotificationService.instance.scheduleDailyReminder(),
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _prefs.dailyReminderHour,
        minute: _prefs.dailyReminderMinute,
      ),
    );
    if (picked == null || !mounted) return;
    await _prefs.setDailyReminderTime(picked.hour, picked.minute);
    if (!mounted) return;
    setState(() {});
    await _applyReminderChange(
      () => NotificationService.instance.scheduleDailyReminder(),
    );
  }

  Future<void> _toggleEmiReminders(bool value) async {
    await _prefs.setEmiRemindersEnabled(value);
    if (!mounted) return;
    setState(() {});
    await _applyReminderChange(
      () => value
          ? NotificationService.instance.rescheduleAll()
          : NotificationService.instance.cancelByType('loan'),
    );
  }

  Future<void> _toggleSipReminders(bool value) async {
    await _prefs.setSipRemindersEnabled(value);
    if (!mounted) return;
    setState(() {});
    await _applyReminderChange(
      () => value
          ? NotificationService.instance.rescheduleAll()
          : NotificationService.instance.cancelByType('investment'),
    );
  }

  Future<void> _applyReminderChange(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Reminder update failed: $e');
      _snack('Saved, but reminders could not be updated. Check notification permission.');
    }
  }

  // ---------------------------------------------------------------------------
  // Security
  // ---------------------------------------------------------------------------

  Future<void> _toggleAppLock(bool value) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PinSetupScreen(flow: value ? PinFlow.enable : PinFlow.disable),
      ),
    );
    if (!mounted) return;
    setState(() {});
    if (done == true) {
      _snack(value ? 'App lock turned on' : 'App lock turned off');
    }
  }

  Future<void> _changePin() async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinSetupScreen(flow: PinFlow.change),
      ),
    );
    if (done == true) _snack('PIN changed');
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  Future<void> _resetAllData() async {
    if (_busy) return;
    final confirmed = await TypeToConfirmDialog.show(
      context,
      title: 'Erase all data?',
      message:
          'This permanently deletes all expenses, income, investments, loans, '
          'budgets and recurring items and restores the default categories. '
          'A safety copy is saved first, so you can undo this from '
          '"Restore from safety copy".',
      confirmLabel: 'Erase everything',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final Database db = await AppDatabase.database;
      await BackupService(db).createSafetyBackup(reason: 'reset');
      await DataResetService(db).resetAllData();
      await _afterDataChanged();
      _snack('All data erased');
    } catch (e) {
      _snack('Reset failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  String _lastBackupLabel() {
    final last = _lastBackupAt;
    if (last == null) return 'No backup saved yet';
    final when = DateFormat('dd MMM yyyy, hh:mm a').format(last);
    final days = DateTime.now().difference(last).inDays;
    if (days >= 30) return 'Last backup: $when ($days days ago)';
    return 'Last backup: $when';
  }

  bool get _backupIsStale {
    final last = _lastBackupAt;
    return last == null || DateTime.now().difference(last).inDays >= 30;
  }

  @override
  Widget build(BuildContext context) {
    final reminderTime = TimeOfDay(
      hour: _prefs.dailyReminderHour,
      minute: _prefs.dailyReminderMinute,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: AppResponsiveContent(
              maxWidth: 700,
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Your data'),
                  _buildOverviewCard(),
                  const SizedBox(height: 24),

                  _sectionTitle('Backup & restore'),
                  _buildBackupCard(),
                  const SizedBox(height: 24),

                  _sectionTitle('Export'),
                  _groupCard([
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Export to CSV'),
                      subtitle: const Text(
                        'Expenses and income for Excel / Google Sheets',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      enabled: !_busy,
                      onTap: _exportCsv,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _sectionTitle('Preferences'),
                  _groupCard([
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Date format'),
                      trailing: DropdownButton<String>(
                        value: _prefs.dateFormat,
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final p in AppPreferences.dateFormatOptions)
                            DropdownMenuItem(
                              value: p,
                              child: Text(DateFormat(p).format(DateTime.now())),
                            ),
                        ],
                        onChanged: _changeDateFormat,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _sectionTitle('Reminders'),
                  _groupCard([
                    SwitchListTile(
                      secondary: const Icon(Icons.edit_calendar_outlined),
                      title: const Text('Daily expense reminder'),
                      subtitle: const Text('Reminds you to log your expenses'),
                      value: _prefs.dailyReminderEnabled,
                      onChanged: _toggleDailyReminder,
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule_rounded),
                      title: const Text('Reminder time'),
                      trailing: Text(
                        reminderTime.format(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      enabled: _prefs.dailyReminderEnabled,
                      onTap: _prefs.dailyReminderEnabled
                          ? _pickReminderTime
                          : null,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.account_balance_outlined),
                      title: const Text('EMI reminders'),
                      subtitle: const Text('A day before each EMI is due'),
                      value: _prefs.emiRemindersEnabled,
                      onChanged: _toggleEmiReminders,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.trending_up_rounded),
                      title: const Text('SIP reminders'),
                      subtitle: const Text('On the SIP date of each investment'),
                      value: _prefs.sipRemindersEnabled,
                      onChanged: _toggleSipReminders,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  _sectionTitle('Security'),
                  _groupCard([
                    SwitchListTile(
                      secondary: const Icon(Icons.lock_outline_rounded),
                      title: const Text('App lock (PIN)'),
                      subtitle: const Text(
                        'Ask for a PIN when the app opens or returns from the '
                        'background',
                      ),
                      value: _lock.isEnabled,
                      onChanged: _toggleAppLock,
                    ),
                    if (_lock.isEnabled)
                      ListTile(
                        leading: const Icon(Icons.password_rounded),
                        title: const Text('Change PIN'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _changePin,
                      ),
                  ]),
                  const SizedBox(height: 24),

                  _sectionTitle('Danger zone'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_forever_outlined,
                        color: AppColors.error,
                      ),
                      title: const Text(
                        'Erase all data',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Deletes everything and starts fresh. A safety copy is '
                        'saved first.',
                      ),
                      enabled: !_busy,
                      onTap: _resetAllData,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Card holding several tiles separated by thin dividers.
  Widget _groupCard(List<Widget> children) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingOverview
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in _overviewTables.entries)
                    _StatTile(
                      label: entry.value,
                      value: _counts[entry.key] ?? 0,
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _backupIsStale
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  size: 20,
                  color: _backupIsStale ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastBackupLabel(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _backupData,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Backup Data'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _restoreData,
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: const Text('Restore Data'),
              ),
            ),
            if (_safetyCopyCount > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy ? null : _restoreFromSafetyCopy,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text('Restore from safety copy ($_safetyCopyCount)'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Backup saves all your expenses, income, investments, loans, '
              'budgets and recurring items into one file. Keep it somewhere '
              'safe, such as Google Drive.\n\n'
              'Restore replaces everything currently in the app with the '
              'contents of a backup file. Your app-lock PIN is never stored '
              'in backup files.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
