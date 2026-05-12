import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../expenses/screens/expense_list_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NavigationProvider>();

    final screens = [
      const DashboardScreen(),
      const ExpenseListScreen(),
      const Center(child: Text('Income')),
      const Center(child: Text('Investments')),
      const Center(child: Text('Settings')),
    ];

    return Scaffold(
      body: IndexedStack(index: provider.currentIndex, children: screens),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: BottomNavigationBar(
          currentIndex: provider.currentIndex,
          onTap: provider.changeIndex,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.money_off),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments),
              label: 'Income',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Investments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
