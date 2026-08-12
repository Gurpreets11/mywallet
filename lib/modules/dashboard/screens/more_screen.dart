import 'package:flutter/material.dart';

import '../../investments/screens/investment_list_screen.dart';
import '../../loans/screens/loan_list_screen.dart';
import '../../settings/setting_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),

      body: GridView.count(
        padding: const EdgeInsets.all(16),

        crossAxisCount: 2,

        crossAxisSpacing: 16,

        mainAxisSpacing: 16,

        children: [
          _card(
            context,

            title: 'Loans',

            icon: Icons.account_balance,

            screen: const LoanListScreen(),
          ),

          _card(
            context,

            title: 'Investments',

            icon: Icons.trending_up,

            screen: const InvestmentListScreen(),
          ),

          _card(
            context,

            title: 'Settings',

            icon: Icons.settings,

            screen: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {

    required String title,

    required IconData icon,

    required Widget screen,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },

      child: Card(
        elevation: 2,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 42),

            const SizedBox(height: 12),

            Text(
              title,

              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
