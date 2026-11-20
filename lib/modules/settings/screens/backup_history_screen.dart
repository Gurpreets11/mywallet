import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/backup/backup_service.dart';
import '../../../core/services/settings/app_preferences.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/common_delete_dialog.dart';

/// Automatic backup settings and the list of backup copies kept on this
/// device. Pop result: a [File] when the user taps Restore on a copy, so the
/// Settings screen can run its normal confirm-and-restore flow.
class BackupHistoryScreen extends StatefulWidget {
  const BackupHistoryScreen({super.key});

  @override
  State<BackupHistoryScreen> createState() => _BackupHistoryScreenState();
}

class _BackupHistoryScreenState extends State<BackupHistoryScreen> {
  final AppPreferences _prefs = AppPreferences.instance;

  bool _loading = true;
  bool _working = false;
  DateTime? _lastAuto;
  List<({File file, String label, DateTime? time})> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = await AppDatabase.database;
      final service = BackupService(db);
      final items = await service.listAllPrivateBackups();
      final last = await service.getLastAutoBackupAt();
      if (!mounted) return;
      setState(() {
        _items = items;
        _lastAuto = last;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _backupNow() async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final db = await AppDatabase.database;
      await BackupService(db).createAutoBackup();
      _snack('Backup saved on this device');
      await _load();
    } catch (e) {
      _snack('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete(File file) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete this backup?',
      message: 'The backup copy will be removed from this device.',
    );
    if (!ok) return;
    try {
      await file.delete();
    } catch (_) {}
    await _load();
  }

  String _size(File file) {
    try {
      final kb = file.lengthSync() / 1024;
      return kb < 1024
          ? '${kb.toStringAsFixed(0)} KB'
          : '${(kb / 1024).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(
      fontSize: 12,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Automatic backup')),
      body: AppResponsiveContent(
        maxWidth: 700,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How often',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AutoBackupFrequency>(
                        showSelectedIcon: false,
                        segments: [
                          for (final f in AutoBackupFrequency.values)
                            ButtonSegment(value: f, label: Text(f.label)),
                        ],
                        selected: {_prefs.autoBackup},
                        onSelectionChanged: (s) async {
                          await _prefs.setAutoBackup(s.first);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _lastAuto == null
                          ? 'No automatic backup yet.'
                          : 'Last automatic backup: '
                                '${DateFormat('dd MMM yyyy, hh:mm a').format(_lastAuto!)}',
                      style: muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A copy is saved when you open the app and one is due. '
                      'The newest 7 are kept. These copies stay on this '
                      'device and are removed if the app is uninstalled, so '
                      'also use "Backup Data" to keep a copy elsewhere.',
                      style: muted,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _working ? null : _backupNow,
                        icon: const Icon(Icons.backup_outlined),
                        label: const Text('Back up now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'Backup history',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No backup copies on this device yet.', style: muted),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          _items[i].label == 'Automatic backup'
                              ? Icons.schedule_rounded
                              : Icons.history_rounded,
                        ),
                        title: Text(_items[i].label),
                        subtitle: Text(
                          [
                            if (_items[i].time != null)
                              DateFormat(
                                'dd MMM yyyy, hh:mm a',
                              ).format(_items[i].time!),
                            _size(_items[i].file),
                          ].where((e) => e.isNotEmpty).join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'restore') {
                              Navigator.pop(context, _items[i].file);
                            } else if (v == 'delete') {
                              _delete(_items[i].file);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'restore',
                              child: Text('Restore'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
