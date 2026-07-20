import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

/// How to handle rows already present in a table when restoring.
enum RestoreMode {
  /// Deletes all existing rows in a table before inserting the backup's rows.
  /// Use this for "fresh install, bring back my old data" — the common case.
  replace,

  /// Keeps existing rows and inserts/overwrites by primary key using
  /// INSERT OR REPLACE. Use this if you want to merge two data sets
  /// instead of wiping first.
  merge,
}

class RestoreService {
  final Database db;
  RestoreService(this.db);

  /// Opens a file picker restricted to .json files, reads and decodes it.
  /// Returns null if the user cancelled the picker.
  Future<Map<String, dynamic>?> pickAndParseBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Restores data from an already-parsed backup map into the current db.
  ///
  /// Safe against schema drift between the backup and the current app version:
  /// - Tables that existed in the old backup but don't exist anymore are skipped.
  /// - Columns that existed in the old backup but don't exist anymore are dropped
  ///   from each row before insert (instead of throwing).
  /// - New tables/columns you've added since the backup was made are simply
  ///   left untouched (they weren't in the backup, so there's nothing to restore).
  Future<void> restoreFromBackupMap(
      Map<String, dynamic> backupMap, {
        RestoreMode mode = RestoreMode.replace,
      }) async {
    final data = backupMap['data'] as Map<String, dynamic>;

    final currentTablesResult = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
          "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
    );
    final currentTables =
    currentTablesResult.map((r) => r['name'] as String).toSet();

    // Your tables reference each other via foreign keys (e.g. transactions ->
    // transaction_types). Deleting/inserting in the wrong order trips a
    // FOREIGN KEY constraint failure. Since this data came from a valid
    // export of your own db, it's safe to disable FK enforcement just for
    // the restore, then turn it back on immediately after.
    // NOTE: PRAGMA statements must run *outside* any active transaction,
    // which is why these two lines sit before/after db.transaction(...).
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        for (final entry in data.entries) {
          final tableName = entry.key;

          // Table no longer exists in the new schema — skip it safely.
          if (!currentTables.contains(tableName)) continue;

          final rows = (entry.value as List).cast<Map<String, dynamic>>();
          if (rows.isEmpty) continue;

          // Find which columns actually exist in the *current* table definition.
          final columnsInfo =
          await txn.rawQuery('PRAGMA table_info($tableName)');
          final validColumns =
          columnsInfo.map((c) => c['name'] as String).toSet();

          if (mode == RestoreMode.replace) {
            await txn.delete(tableName);
          }

          for (final row in rows) {
            // Drop any keys from the backup that are no longer valid columns.
            final filteredRow = Map<String, dynamic>.from(row)
              ..removeWhere((key, _) => !validColumns.contains(key));

            if (filteredRow.isEmpty) continue;

            await txn.insert(
              tableName,
              filteredRow,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  /// Convenience wrapper: pick a file AND restore it in one call.
  /// Returns true if a restore happened, false if the user cancelled the picker.
  Future<bool> pickAndRestore({RestoreMode mode = RestoreMode.replace}) async {
    final backupMap = await pickAndParseBackupFile();
    if (backupMap == null) return false;
    await restoreFromBackupMap(backupMap, mode: mode);
    return true;
  }
}