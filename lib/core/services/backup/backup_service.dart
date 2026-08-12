import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Handles exporting all data from the sqflite database into a single
/// JSON file. Table names are discovered at runtime from sqlite_master,
/// so you never need to update this file when you add a new table.
class BackupService {
  final Database db;
  BackupService(this.db);

  /// Returns every user-created table name (skips sqlite's own internal tables).
  Future<List<String>> _getAllTableNames() async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_metadata'",
    );
    return tables.map((row) => row['name'] as String).toList();
  }

  // Reads every row from every table into a Map<tableName, List<row>>,
  // wrapped with some metadata that restore will use later.
  Future<Map<String, dynamic>> _exportAllTablesAsMap() async {
    final tableNames = await _getAllTableNames();
    final Map<String, dynamic> backupData = {};

    for (final table in tableNames) {
      final rows = await db.query(table);
      backupData[table] = rows;
    }

    return {
      'meta': {
        'app': 'MyWallet',
        'exportedAt': DateTime.now().toIso8601String(),
        'dbVersion': await db.getVersion(),
        'tables': tableNames,
      },
      'data': backupData,
    };
  }

  String _buildFileName() {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'mywallet_backup_$stamp.json';
  }

  /// Writes the backup JSON silently into the app's own documents directory.
  /// Useful if you want an "auto backup on app close" feature, or as a
  /// staging file before sharing/exporting.
  Future<File> createBackupFileInAppStorage() async {
    final backupMap = await _exportAllTablesAsMap();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${_buildFileName()}');
    await file.writeAsString(jsonString);
    return file;
  }

  /// Opens a native "Save As" dialog so the user picks exactly where the
  /// backup file goes (Downloads, Google Drive folder, a USB stick, etc).
  /// This is almost certainly the one you want for a "Backup" button in
  /// Settings. Returns the saved file path, or null if the user cancelled.
  Future<String?> exportBackupToUserChosenLocation() async {
    final backupMap = await _exportAllTablesAsMap();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save MyWallet Backup',
      fileName: _buildFileName(),
      bytes:
          bytes, // required on Android/iOS so FilePicker can write it for you
    );

    return savedPath;
  }
}
