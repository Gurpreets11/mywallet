import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_breakpoints.dart';
import '../../accounts/screens/accounts_screen.dart';
import '../../goals/screens/savings_goals_screen.dart';
import '../../budgets/screens/budget_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/screens/more_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../income/screens/income_list_screen.dart';
import '../../investments/screens/investment_list_screen.dart';
import '../../loans/screens/loan_list_screen.dart';
import '../../settings/screens/setting_screen.dart';
import '../../recurring/screens/recurring_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  // Screen indexes are stable across mobile, tablet and desktop.
  // Index 3 is the mobile-only More screen.
  static const List<Widget> _screens = [
    DashboardScreen(),
    ExpenseListScreen(),
    IncomeListScreen(),
    MoreScreen(),
    InvestmentListScreen(),
    LoanListScreen(),
    SettingsScreen(),
    RecurringScreen(),
    ReportsScreen(),
    BudgetScreen(),
    AccountsScreen(),
    SavingsGoalsScreen(),
  ];

  static const List<NavigationDestination> _mobileDestinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.money_off_outlined),
      selectedIcon: Icon(Icons.money_off_rounded),
      label: 'Expenses',
    ),
    NavigationDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments_rounded),
      label: 'Income',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'More',
    ),
  ];

  static const List<NavigationRailDestination> _wideDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.money_off_outlined),
      selectedIcon: Icon(Icons.money_off_rounded),
      label: Text('Expenses'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.payments_outlined),
      selectedIcon: Icon(Icons.payments_rounded),
      label: Text('Income'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: Text('Accounts'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up_rounded),
      label: Text('Investments'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_outlined),
      selectedIcon: Icon(Icons.account_balance_rounded),
      label: Text('Loans'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_repeat_outlined),
      selectedIcon: Icon(Icons.event_repeat_rounded),
      label: Text('Recurring'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics_rounded),
      label: Text('Reports'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.savings_outlined),
      selectedIcon: Icon(Icons.savings_rounded),
      label: Text('Budgets'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.flag_outlined),
      selectedIcon: Icon(Icons.flag_rounded),
      label: Text('Goals'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Settings'),
    ),
  ];

  static const int _accountsScreenIndex = 10;
  static const int _goalsScreenIndex = 11;

  // Rail position -> index in _screens (order: Home, Expenses, Income,
  // Accounts, Investments, Loans, Recurring, Reports, Budgets, Goals, Settings).
  static const List<int> _railToScreen = [0, 1, 2, 10, 4, 5, 7, 8, 9, 11, 6];

  int _screenIndexForWideDestination(int destinationIndex) =>
      _railToScreen[destinationIndex.clamp(0, _railToScreen.length - 1)];

  int _wideDestinationForScreen(int screenIndex) {
    final i = _railToScreen.indexOf(screenIndex);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useRail = AppBreakpoints.useNavigationRail(width);
        final extendedRail = AppBreakpoints.useExtendedNavigationRail(width);
        final requestedIndex = navigation.currentIndex
            .clamp(0, _screens.length - 1)
            .toInt();
        // More is a mobile-only destination. If the window is resized while
        // More is selected, open Investments as the nearest wide-layout page.
        final currentIndex = requestedIndex == 3 ? 4 : requestedIndex;

        if (!useRail) {
          // On mobile, Investments, Loans and Settings are reached through More.
          final mobileIndex = currentIndex <= 2 ? currentIndex : 3;
          return Scaffold(
            body: IndexedStack(
              index: mobileIndex,
              children: _screens.take(4).toList(),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: mobileIndex,
              onDestinationSelected: navigation.changeIndex,
              destinations: _mobileDestinations,
            ),
          );
        }

        final selectedRailIndex = _wideDestinationForScreen(currentIndex);

        return Scaffold(
          body: Row(
            children: [
              // Scrollable so all 11 destinations stay reachable on short
              // tablet / landscape screens.
              LayoutBuilder(
                builder: (context, rc) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: rc.maxHeight),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: selectedRailIndex,
                        onDestinationSelected: (index) {
                          final screenIndex = _screenIndexForWideDestination(
                            index,
                          );
                          navigation.changeIndex(screenIndex);
                          // The Accounts tab stays alive in the background,
                          // so refresh its balances when it is opened.
                          if (screenIndex == _accountsScreenIndex) {
                            context.read<DashboardProvider>().loadAccounts();
                          } else if (screenIndex == _goalsScreenIndex) {
                            context.read<DashboardProvider>().loadGoals();
                          }
                        },
                        extended: extendedRail,
                        labelType: extendedRail
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        minWidth: 76,
                        minExtendedWidth: 220,
                        leading: Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 28),
                          child: extendedRail
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'myWallet',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                        ),
                        destinations: _wideDestinations,
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: IndexedStack(index: currentIndex, children: _screens),
              ),
            ],
          ),
        );
      },
    );
  }
}
