import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywallet/data/providers/master_provider.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'data/services/master_seed_service.dart';
import 'modules/expenses/providers/expense_provider.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await AppDatabase.database;
    await MasterSeedService.seedMasterData();
  }

  runApp(const FinanceManagerApp());
}

class FinanceManagerApp extends StatelessWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MasterProvider(),
         ),
        ChangeNotifierProvider(
           create: (_) => ExpenseProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Wallet',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
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
