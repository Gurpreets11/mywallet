import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Keys stored in the `app_metadata` table that describe THIS device only.
/// They are never exported and never overwritten by a restore.
class BackupMetaKeys {
  BackupMetaKeys._();

  static const String lastBackupAt = 'last_backup_at';
  static const String lastRestoreAt = 'last_restore_at';

  /// App-lock data. Must never leave the device inside a backup file.
  static const String appLockEnabled = 'app_lock_enabled';
  static const String appLockSalt = 'app_lock_salt';
  static const String appLockHash = 'app_lock_hash';

  static const Set<String> deviceLocal = {
    lastBackupAt,
    lastRestoreAt,
    appLockEnabled,
    appLockSalt,
    appLockHash,
  };
}

/// Handles exporting all data from the sqflite database into a single
/// JSON file. Table names are discovered at runtime from sqlite_master,
/// so you never need to update this file when you add a new table.
class BackupService {
  final Database db;
  BackupService(this.db);

  static const String _metadataTable = 'app_metadata';
  static const int _keepSafetyBackups = 5;

  /// Returns every user-created table name (skips sqlite's own internal tables).
  Future<List<String>> _getAllTableNames() async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
    );
    return tables.map((row) => row['name'] as String).toList();
  }

  /// Number of rows in every user table, e.g. {'expenses': 120, 'loans': 3}.
  Future<Map<String, int>> getRecordCounts() async {
    final counts = <String, int>{};
    for (final table in await _getAllTableNames()) {
      final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
      counts[table] = (result.first['total'] as num).toInt();
    }
    return counts;
  }

  /// When the user last saved a backup file from this device (null = never).
  Future<DateTime?> getLastBackupAt() async {
    try {
      final rows = await db.query(
        _metadataTable,
        columns: ['meta_value'],
        where: 'meta_key = ?',
        whereArgs: [BackupMetaKeys.lastBackupAt],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return DateTime.tryParse(rows.first['meta_value'] as String);
    } catch (_) {
      return null;
    }
  }

  Future<void> _markBackupDone() async {
    try {
      await db.insert(_metadataTable, {
        'meta_key': BackupMetaKeys.lastBackupAt,
        'meta_value': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      // Bookkeeping only — never fail a successful backup because of it.
    }
  }

  // Reads every row from every table into a Map<tableName, List<row>>,
  // wrapped with some metadata that restore will use later.
  Future<Map<String, dynamic>> _exportAllTablesAsMap() async {
    final tableNames = await _getAllTableNames();
    final Map<String, dynamic> backupData = {};
    final Map<String, int> counts = {};

    for (final table in tableNames) {
      var rows = await db.query(table);
      if (table == _metadataTable) {
        rows = rows
            .where((r) => !BackupMetaKeys.deviceLocal.contains(r['meta_key']))
            .toList();
      }
      backupData[table] = rows;
      counts[table] = rows.length;
    }

    return {
      'meta': {
        'app': 'MyWallet',
        'exportedAt': DateTime.now().toIso8601String(),
        'dbVersion': await db.getVersion(),
        'tables': tableNames,
        'counts': counts,
      },
      'data': backupData,
    };
  }

  String _buildFileName([String prefix = 'mywallet_backup']) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$stamp.json';
  }

  Future<String> _buildJson() async {
    final backupMap = await _exportAllTablesAsMap();
    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Writes the backup JSON silently into the app's own documents directory.
  /// Useful if you want an "auto backup on app close" feature, or as a
  /// staging file before sharing/exporting.
  Future<File> createBackupFileInAppStorage() async {
    final jsonString = await _buildJson();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_buildFileName()}');
    await file.writeAsString(jsonString);
    return file;
  }

  /// Automatic safety copy taken right before a restore or a reset, so the
  /// action can always be undone from Settings > "Restore from safety copy".
  /// Stored in the app's private documents directory (`auto_backups/`); only
  /// the newest few copies are kept.
  Future<File> createSafetyBackup({String reason = 'restore'}) async {
    final jsonString = await _buildJson();

    final dir = await _safetyDir(create: true);
    final file = File('${dir.path}/${_buildFileName('mywallet_before_$reason')}');
    await file.writeAsString(jsonString, flush: true);

    // Prune old safety copies (newest first, keep a handful).
    final all = await listSafetyBackups();
    for (final f in all.skip(_keepSafetyBackups)) {
      try {
        await f.delete();
      } catch (_) {}
    }
    return file;
  }

  Future<Directory> _safetyDir({bool create = false}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/auto_backups');
    if (create && !await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Automatic safety copies, newest first (empty list if there are none).
  Future<List<File>> listSafetyBackups() async {
    final dir = await _safetyDir();
    if (!await dir.exists()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('mywallet_before_'))
        .toList()
      // Sort by the timestamp at the end of the name (the reason part differs).
      ..sort((a, b) => _stampOf(b).compareTo(_stampOf(a)));
    return files;
  }

  /// `yyyyMMdd_HHmmss` part of a safety copy's file name ('' if unparseable).
  static String _stampOf(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final m = RegExp(r'(\d{8}_\d{6})\.json$').firstMatch(name);
    return m?.group(1) ?? '';
  }

  /// Reads "what" and "when" from a safety copy's file name, e.g.
  /// `mywallet_before_reset_20261113_152600.json` -> ('reset', 13 Nov 2026 ...).
  static ({String reason, DateTime? time}) describeSafetyBackup(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    final match = RegExp(
      r'mywallet_before_(.+)_(\d{8})_(\d{6})\.json$',
    ).firstMatch(name);
    if (match == null) return (reason: 'restore', time: null);
    final d = match.group(2)!;
    final t = match.group(3)!;
    final time = DateTime.tryParse(
      '${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6, 8)} '
      '${t.substring(0, 2)}:${t.substring(2, 4)}:${t.substring(4, 6)}',
    );
    return (reason: match.group(1)!, time: time);
  }

  /// Opens a native "Save As" dialog so the user picks exactly where the
  /// backup file goes (Downloads, Google Drive folder, a USB stick, etc).
  /// This is almost certainly the one you want for a "Backup" button in
  /// Settings. Returns the saved file path, or null if the user cancelled.
  Future<String?> exportBackupToUserChosenLocation() async {
    final jsonString = await _buildJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save MyWallet Backup',
      fileName: _buildFileName(),
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes:
          bytes, // required on Android/iOS so FilePicker can write it for you
    );

    if (savedPath == null) return null; // user cancelled

    // On desktop, older file_picker versions only return the chosen path and
    // do not write the bytes — make sure the file really has content.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final file = File(savedPath);
      if (!await file.exists() || await file.length() == 0) {
        await file.writeAsBytes(bytes);
      }
    }

    await _markBackupDone();
    return savedPath;
  }
}
