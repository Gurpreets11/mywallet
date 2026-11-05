import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_breakpoints.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/screens/more_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../income/screens/income_list_screen.dart';
import '../../investments/screens/investment_list_screen.dart';
import '../../loans/screens/loan_list_screen.dart';
import '../../settings/setting_screen.dart';
import '../../recurring/screens/recurring_screen.dart';
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
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Settings'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.event_repeat_outlined),
      selectedIcon: Icon(Icons.event_repeat_rounded),
      label: Text('Recurring'),
    ),
  ];

  int _screenIndexForWideDestination(int destinationIndex) {
    // Skip index 3, which is the mobile-only More screen.
    return destinationIndex < 3 ? destinationIndex : destinationIndex + 1;
  }

  int _wideDestinationForScreen(int screenIndex) {
    if (screenIndex <= 2) return screenIndex;
    return (screenIndex - 1).clamp(0, 6);
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
              NavigationRail(
                selectedIndex: selectedRailIndex,
                onDestinationSelected: (index) => navigation.changeIndex(
                  _screenIndexForWideDestination(index),
                ),
                extended: extendedRail,
                labelType: extendedRail
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                minWidth: 76,
                minExtendedWidth: 220,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 28),
                  child: extendedRail
                      ? const Row(
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
                                color: AppColors.textPrimary,
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
