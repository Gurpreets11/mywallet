import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/screens/more_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../../income/screens/income_list_screen.dart';
import '../../investments/screens/investment_list_screen.dart';
import '../../loans/screens/loan_list_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NavigationProvider>();

    /*final screens = [
      const DashboardScreen(),
      const ExpenseListScreen(),
      const IncomeListScreen(),
      const InvestmentListScreen(),
      const LoanListScreen(),
      const Center(child: Text('Settings')),
    ];*/

    final screens = [
      const DashboardScreen(),

      const ExpenseListScreen(),

      const IncomeListScreen(),

      const MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: provider.currentIndex, children: screens),

      /* floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,*/
      bottomNavigationBar: NavigationBar(
        selectedIndex: provider.currentIndex,

        onDestinationSelected: provider.changeIndex,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),

            selectedIcon: Icon(Icons.home),

            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.money_off_outlined),

            selectedIcon: Icon(Icons.money_off),

            label: 'Expense',
          ),

          NavigationDestination(
            icon: Icon(Icons.payments_outlined),

            selectedIcon: Icon(Icons.payments),

            label: 'Income',
          ),

          NavigationDestination(
            icon: Icon(Icons.menu),

            selectedIcon: Icon(Icons.menu_open),

            label: 'More',
          ),
        ],
      ),
    );
  }
}
