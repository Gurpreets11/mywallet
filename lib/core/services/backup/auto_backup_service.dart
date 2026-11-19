import 'package:flutter/foundation.dart';

import '../../database/app_database.dart';
import '../settings/app_preferences.dart';
import 'backup_service.dart';

/// Saves a scheduled backup copy when one is due. Runs when the app starts
/// (no background service or extra package is needed). The copy is kept in the
/// app's private storage; use "Backup Data" in Settings to save a copy
/// somewhere else such as Google Drive.
class AutoBackupService {
  AutoBackupService._();

  /// Never throws - a failed automatic backup must not affect the app.
  static Future<void> runIfDue() async {
    try {
      final frequency = AppPreferences.instance.autoBackup;
      if (frequency == AutoBackupFrequency.off) return;

      final db = await AppDatabase.database;
      final service = BackupService(db);

      // Nothing to protect yet.
      final counts = await service.getRecordCounts();
      const dataTables = ['expenses', 'incomes', 'investments', 'loans'];
      final hasData = dataTables.any((t) => (counts[t] ?? 0) > 0);
      if (!hasData) return;

      final last = await service.getLastAutoBackupAt();
      if (last != null &&
          DateTime.now().difference(last) < Duration(days: frequency.days)) {
        return;
      }
      await service.createAutoBackup();
    } catch (e) {
      debugPrint('Automatic backup skipped: $e');
    }
  }
}
