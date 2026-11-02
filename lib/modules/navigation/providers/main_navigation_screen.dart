import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_breakpoints.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/screens/more_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../income/screens/income_list_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),
    ExpenseListScreen(),
    IncomeListScreen(),
    MoreScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
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

  static const List<NavigationRailDestination> _railDestinations = [
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
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: Text('More'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final selectedIndex = navigation.currentIndex.clamp(0, _screens.length - 1).toInt();
        final useRail = AppBreakpoints.useNavigationRail(width);
        final extendedRail = AppBreakpoints.useExtendedNavigationRail(width);

        if (!useRail) {
          return Scaffold(
            body: IndexedStack(
              index: selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: navigation.changeIndex,
              destinations: _destinations,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: navigation.changeIndex,
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
                            Icon(Icons.account_balance_wallet_rounded,
                                color: AppColors.primary, size: 26),
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
                destinations: _railDestinations,
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: IndexedStack(
                  index: selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
