import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywallet/data/providers/master_provider.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/services/navigation_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/security/app_lock_service.dart';
import 'core/services/settings/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_lock_gate.dart';
import 'data/services/master_seed_service.dart';
import 'data/services/demo_data_seed_service.dart';
import 'modules/budgets/providers/budget_provider.dart';
import 'modules/dashboard/providers/dashboard_provider.dart';
import 'modules/expenses/providers/expense_provider.dart';
import 'modules/income/providers/income_provider.dart';
import 'modules/investments/providers/investment_provider.dart';
import 'modules/loans/providers/loan_payment_provider.dart';
import 'modules/loans/providers/loan_provider.dart';
import 'modules/navigation/providers/main_navigation_screen.dart';
import 'modules/navigation/providers/navigation_provider.dart';
import 'modules/recurring/providers/recurring_provider.dart';
import 'modules/recurring/repositories/recurring_repository.dart';
import 'modules/reports/providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await AppDatabase.database;
    await MasterSeedService.seedMasterData();
    // User preferences and app-lock state live in the database.
    await AppPreferences.instance.load();
    await AppLockService.instance.load();
    // Development preview data only. kDebugMode is false in production builds.
    if (kDebugMode) {
      try {
        await DemoDataSeedService.seedIfDatabaseIsEmpty();
      } catch (error) {
        debugPrint('Demo data seeding failed: $error');
      }
    }
  }
  // final database = AppDatabase();
  // Generate due recurring entries at app launch. Generation is idempotent.
  if (!kIsWeb) {
    try {
      await RecurringRepository().generateDueTransactions();
    } catch (error) {
      debugPrint('Recurring transaction generation failed: $error');
    }
  }

  await NotificationService.instance.initialize();
  await NotificationService.instance.handleInitialNotification();
  //await NotificationService.instance.scheduleDailyReminder();
  try {
    await NotificationService.instance.scheduleDailyReminder();
  } catch (e) {
    debugPrint('Daily reminder scheduling failed: $e');
  }

  runApp(const FinanceManagerApp());
}

class FinanceManagerApp extends StatelessWidget {
  const FinanceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MasterProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),

        ChangeNotifierProvider(create: (_) => LoanProvider()),

        ChangeNotifierProvider(create: (_) => LoanPaymentProvider()),

        ChangeNotifierProvider(create: (_) => InvestmentProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My Wallet',

        themeMode: ThemeMode.light,

        theme: AppTheme.lightTheme,

        darkTheme: AppTheme.darkTheme,
        // App-wide text size (Settings > Preferences) + PIN lock overlay.
        builder: (context, child) => ListenableBuilder(
          listenable: AppPreferences.instance,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            // Multiply the user's choice with the phone's own text setting.
            final scale =
                media.textScaler.scale(1.0) * AppPreferences.instance.fontScale;
            return MediaQuery(
              data: media.copyWith(textScaler: TextScaler.linear(scale)),
              child: AppLockGate(child: child ?? const SizedBox.shrink()),
            );
          },
        ),
        home: const MainNavigationScreen(),
        navigatorKey: NavigationService.instance.navigatorKey,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Manager')),
      body: const Center(
        child: Text(
          'Finance Manager App Initialized',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
