import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';

/// How to handle rows already present in a table when restoring.
enum RestoreMode {
  /// Makes the database match the backup exactly: every current table is
  /// emptied first (even tables that are empty in the backup), then the
  /// backup's rows are inserted. This is what the Settings screen uses.
  replace,

  /// Keeps existing rows and inserts/overwrites by primary key using
  /// INSERT OR REPLACE. NOTE: rows with the same id are overwritten by the
  /// backup's row, so this is not a true "merge". Not used by the UI.
  merge,
}

/// Thrown when the chosen file is not a usable MyWallet backup.
/// [message] is written for the end user and can be shown as-is.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

/// Summary of a backup file, shown to the user before they confirm a restore.
class BackupInfo {
  final DateTime? exportedAt;
  final int? dbVersion;

  /// Rows per table that exist in the backup AND in the current database.
  final Map<String, int> counts;

  const BackupInfo({
    required this.exportedAt,
    required this.dbVersion,
    required this.counts,
  });

  int get totalRecords => counts.values.fold(0, (sum, c) => sum + c);
}

class RestoreService {
  final Database db;
  RestoreService(this.db);

  static const String _metadataTable = 'app_metadata';

  Future<Set<String>> _currentTables() async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
    );
    return result.map((r) => r['name'] as String).toSet();
  }

  /// Opens a file picker restricted to .json files, reads and decodes it.
  /// Returns null if the user cancelled the picker.
  /// Throws [BackupFormatException] if the file cannot be read as JSON.
  Future<Map<String, dynamic>?> pickAndParseBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return null;

    final path = result.files.single.path;
    if (path == null) {
      throw const BackupFormatException('Could not read the selected file.');
    }
    return parseBackupFile(path);
  }

  /// Reads and decodes the backup file at [path] (no database changes).
  /// Throws [BackupFormatException] if it cannot be read as a backup.
  Future<Map<String, dynamic>> parseBackupFile(String path) async {
    final String jsonString;
    try {
      jsonString = await File(path).readAsString();
    } on FileSystemException {
      throw const BackupFormatException('Could not read the selected file.');
    } on FormatException {
      throw const BackupFormatException(
        'This file is not a valid MyWallet backup.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupFormatException(
        'This file is not a valid MyWallet backup (it is not proper JSON).',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupFormatException(
        'This file is not a valid MyWallet backup.',
      );
    }
    return decoded;
  }

  /// Validates a parsed backup WITHOUT touching the database and returns a
  /// summary of what it contains. Throws [BackupFormatException] when the
  /// backup must not be restored.
  Future<BackupInfo> inspectBackup(Map<String, dynamic> backupMap) async {
    final data = backupMap['data'];
    if (data is! Map) {
      throw const BackupFormatException(
        'This file is not a MyWallet backup (no data section found).',
      );
    }

    DateTime? exportedAt;
    int? dbVersion;
    final meta = backupMap['meta'];
    if (meta is Map) {
      final app = meta['app'];
      if (app != null && app != 'MyWallet') {
        throw const BackupFormatException(
          'This backup was created by a different app.',
        );
      }
      final exported = meta['exportedAt'];
      if (exported is String) exportedAt = DateTime.tryParse(exported);
      final version = meta['dbVersion'];
      if (version is int) dbVersion = version;
    }

    final currentVersion = await db.getVersion();
    if (dbVersion != null && dbVersion > currentVersion) {
      throw const BackupFormatException(
        'This backup was created by a newer version of the app. '
        'Please update the app and try again.',
      );
    }

    final currentTables = await _currentTables();
    final counts = <String, int>{};
    for (final entry in data.entries) {
      final rows = entry.value;
      if (rows is! List) {
        throw BackupFormatException(
          'The backup is damaged (table "${entry.key}" is unreadable).',
        );
      }
      if (rows.any((r) => r is! Map)) {
        throw BackupFormatException(
          'The backup is damaged (table "${entry.key}" has invalid rows).',
        );
      }
      if (currentTables.contains(entry.key)) {
        counts[entry.key.toString()] = rows.length;
      }
    }

    if (counts.isEmpty) {
      throw const BackupFormatException(
        'This backup does not contain any data this app can restore.',
      );
    }

    return BackupInfo(
      exportedAt: exportedAt,
      dbVersion: dbVersion,
      counts: counts,
    );
  }

  /// Restores data from an already-parsed backup map into the current db and
  /// returns the number of records restored.
  ///
  /// Everything runs in ONE transaction: if anything fails (including the
  /// final row-count verification), the transaction is rolled back and the
  /// existing data stays exactly as it was.
  ///
  /// Safe against schema drift between the backup and the current app version:
  /// - Tables that existed in the old backup but don't exist anymore are skipped.
  /// - Columns that existed in the old backup but don't exist anymore are dropped
  ///   from each row before insert (instead of throwing).
  /// - Tables added since the backup was made are emptied in replace mode
  ///   (they were empty at backup time).
  Future<int> restoreFromBackupMap(
    Map<String, dynamic> backupMap, {
    RestoreMode mode = RestoreMode.replace,
  }) async {
    // Validate first — never wipe anything for a file we cannot trust.
    await inspectBackup(backupMap);

    final data = backupMap['data'] as Map<String, dynamic>;
    final currentTables = await _currentTables();
    final localKeys = BackupMetaKeys.deviceLocal.toList();

    // Foreign keys are switched off while rows are re-inserted (parents and
    // children arrive in arbitrary order). The app opens the database with
    // foreign_keys OFF, so put back whatever the setting was before — do not
    // force it ON, or app behaviour would change until the next launch.
    // NOTE: PRAGMA statements must run *outside* any active transaction.
    final fkRows = await db.rawQuery('PRAGMA foreign_keys');
    final fkWasOn = fkRows.isNotEmpty && fkRows.first.values.first == 1;

    var restoredRows = 0;
    await db.execute('PRAGMA foreign_keys = OFF');
    try {
      await db.transaction((txn) async {
        // 1. REPLACE = make the database match the backup. Empty every
        //    current table, including tables that are empty in the backup.
        if (mode == RestoreMode.replace) {
          for (final table in currentTables) {
            if (table == _metadataTable) {
              final marks = List.filled(localKeys.length, '?').join(', ');
              await txn.delete(
                table,
                where: 'meta_key NOT IN ($marks)',
                whereArgs: localKeys,
              );
            } else {
              await txn.delete(table);
            }
          }
        }

        // 2. Insert the backup rows.
        final expected = <String, int>{};
        for (final entry in data.entries) {
          final tableName = entry.key;

          // Table no longer exists in the new schema — skip it safely.
          if (!currentTables.contains(tableName)) continue;

          final rows = (entry.value as List)
              .map((r) => Map<String, dynamic>.from(r as Map))
              .toList();
          if (rows.isEmpty) continue;

          // Find which columns actually exist in the *current* table definition.
          final columnsInfo = await txn.rawQuery(
            'PRAGMA table_info($tableName)',
          );
          final validColumns = columnsInfo
              .map((c) => c['name'] as String)
              .toSet();

          final batch = txn.batch();
          var queued = 0;
          for (final row in rows) {
            // Drop any keys from the backup that are no longer valid columns.
            final filteredRow = Map<String, dynamic>.from(row)
              ..removeWhere((key, _) => !validColumns.contains(key));

            if (filteredRow.isEmpty) continue;

            // Never import device-local bookkeeping from another device.
            if (tableName == _metadataTable &&
                BackupMetaKeys.deviceLocal.contains(filteredRow['meta_key'])) {
              continue;
            }

            batch.insert(
              tableName,
              filteredRow,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            queued++;
          }
          await batch.commit(noResult: true);

          restoredRows += queued;
          if (mode == RestoreMode.replace && tableName != _metadataTable) {
            expected[tableName] = queued;
          }
        }

        // 3. Verify: every table must now hold exactly the rows the backup
        //    had. A mismatch (e.g. duplicate ids inside a damaged file)
        //    throws, which rolls the whole restore back.
        for (final entry in expected.entries) {
          final result = await txn.rawQuery(
            'SELECT COUNT(*) AS total FROM ${entry.key}',
          );
          final actual = (result.first['total'] as num).toInt();
          if (actual != entry.value) {
            throw BackupFormatException(
              'Restore verification failed for "${entry.key}" '
              '(expected ${entry.value} records, found $actual). '
              'The backup file may be damaged.',
            );
          }
        }
      });
    } finally {
      if (fkWasOn) await db.execute('PRAGMA foreign_keys = ON');
    }

    try {
      await db.insert(_metadataTable, {
        'meta_key': BackupMetaKeys.lastRestoreAt,
        'meta_value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Bookkeeping only.
    }

    return restoredRows;
  }

  /// Convenience wrapper: pick a file AND restore it in one call.
  /// Returns true if a restore happened, false if the user cancelled the picker.
  /// (The Settings screen uses the individual steps so it can ask for
  /// confirmation in between.)
  Future<bool> pickAndRestore({RestoreMode mode = RestoreMode.replace}) async {
    final backupMap = await pickAndParseBackupFile();
    if (backupMap == null) return false;
    await restoreFromBackupMap(backupMap, mode: mode);
    return true;
  }
}
