import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/services/backup/backup_service.dart';
import '../../core/services/backup/restore_service.dart';
import '../../core/widgets/common_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _backupData() async {
    final Database db = await AppDatabase.database;
    final backupService = BackupService(db); // pass your existing Database
    final path = await backupService.exportBackupToUserChosenLocation();
    if (!mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup saved to $path')));
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> _restoreData() async {
    final Database db = await AppDatabase.database;
    final restoreService = RestoreService(db);
    final didRestore = await restoreService.pickAndRestore(
      mode: RestoreMode.replace,
    );
    if (!mounted) return;
    if (didRestore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data restored successfully')),
      );
      // you'll likely want to refresh any in-memory state / providers here
    }

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setting')),
      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const SizedBox(height: 20),

            Text(
              "Data Backup and Restore",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            CommonButton(text: 'Backup Data', onPressed: _backupData),
            const SizedBox(height: 20),
            CommonButton(text: 'Restore Data', onPressed: _restoreData),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
