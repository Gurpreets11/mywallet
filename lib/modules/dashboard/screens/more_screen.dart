import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../investments/screens/investment_list_screen.dart';
import '../../loans/screens/loan_list_screen.dart';
import '../../settings/setting_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1100
              ? 4
              : width >= 700
              ? 3
              : 2;

          return AppResponsiveContent(
            maxWidth: 1200,
            padding: const EdgeInsets.all(16),
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                // Give each card enough vertical space for its icon, title,
                // subtitle and padding on narrow mobile screens.
                mainAxisExtent: width < 400
                    ? 150
                    : width < 700
                    ? 160
                    : 170,
              ),
              children: [
                _MoreMenuCard(
                  title: 'Investments',
                  subtitle: 'Portfolio and returns',
                  icon: Icons.trending_up_rounded,
                  iconColor: AppColors.savings,
                  screen: const InvestmentListScreen(),
                ),
                _MoreMenuCard(
                  title: 'Loans',
                  subtitle: 'Loans and EMI history',
                  icon: Icons.account_balance_rounded,
                  iconColor: AppColors.warning,
                  screen: const LoanListScreen(),
                ),
                _MoreMenuCard(
                  title: 'Settings',
                  subtitle: 'App preferences and backup',
                  icon: Icons.settings_rounded,
                  iconColor: AppColors.textSecondary,
                  screen: const SettingsScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  const _MoreMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
