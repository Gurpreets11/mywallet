import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await AppDatabase.database;
  }

  runApp(const FinanceManagerApp());
}

class FinanceManagerApp extends StatelessWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finance Manager',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Manager'),
      ),
      body: const Center(
        child: Text(
          'Finance Manager App Initialized',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
