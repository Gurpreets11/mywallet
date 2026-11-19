import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_responsive_content.dart';

/// App information: version, what the app does, privacy and support.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  int? _dbVersion;

  @override
  void initState() {
    super.initState();
    _loadDbVersion();
  }

  Future<void> _loadDbVersion() async {
    try {
      final db = await AppDatabase.database;
      final v = await db.getVersion();
      if (mounted) setState(() => _dbVersion = v);
    } catch (_) {}
  }

  Future<void> _copy(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant, height: 1.4);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: AppResponsiveContent(
        maxWidth: 700,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Version ${AppConstants.appVersion}', style: muted),
                    const SizedBox(height: 12),
                    Text(
                      'A personal finance manager for your expenses, income, '
                      'investments, loans, budgets, accounts and savings goals.',
                      textAlign: TextAlign.center,
                      style: muted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('App version'),
                    trailing: Text(AppConstants.appVersion),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded),
                    title: const Text('Database version'),
                    trailing: Text(_dbVersion?.toString() ?? '-'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code_rounded),
                    title: const Text('Source and support'),
                    subtitle: const Text(AppConstants.repositoryUrl),
                    trailing: const Icon(Icons.copy_rounded, size: 20),
                    onTap: () => _copy('Link', AppConstants.repositoryUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your data is stored only on this device. The app does '
                      'not need an account and does not send your financial '
                      'data anywhere. Backups are files you save yourself, and '
                      'your app-lock PIN is never included in a backup.',
                      style: muted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Need help?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report a problem or suggest a feature by opening an '
                      'issue on the project page above. Please include the '
                      'app and database version shown on this screen.',
                      style: muted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
