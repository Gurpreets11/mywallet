import 'package:sqflite/sqflite.dart';

import '../../../data/services/master_seed_service.dart';
import 'backup_service.dart';

/// Erases all user data and puts the database back to a fresh-install state
/// (default categories re-created, id counters reset).
///
/// Settings and preferences (the `app_metadata` table) are kept, except the
/// app-lock data when [removeAppLock] is true ("Forgot PIN" flow).
class DataResetService {
  final Database db;
  DataResetService(this.db);

  Future<void> resetAllData({bool removeAppLock = false}) async {
    final tablesResult = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
    );
    final tables = tablesResult.map((r) => r['name'] as String).toList();

    await db.execute('PRAGMA foreign_keys = OFF');
    await db.transaction((txn) async {
      for (final table in tables) {
        if (table == 'app_metadata') continue; // keep settings
        await txn.delete(table);
      }

      if (removeAppLock) {
        await txn.delete(
          'app_metadata',
          where: 'meta_key IN (?, ?, ?, ?)',
          whereArgs: [
            BackupMetaKeys.appLockEnabled,
            BackupMetaKeys.appLockSalt,
            BackupMetaKeys.appLockHash,
            BackupMetaKeys.appLockBiometric,
          ],
        );
      }

      // Restart AUTOINCREMENT counters so ids match a fresh install.
      try {
        await txn.delete('sqlite_sequence');
      } catch (_) {
        // sqlite_sequence does not exist when no table uses AUTOINCREMENT.
      }
    });

    // Re-create the default transaction types / categories / subcategories.
    await MasterSeedService.seedMasterData();
  }
}
