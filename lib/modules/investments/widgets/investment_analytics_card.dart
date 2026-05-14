import 'package:flutter/material.dart';

class InvestmentAnalyticsCard extends StatelessWidget {
  final String title;

  final String value;

  final IconData icon;

  final Color color;

  const InvestmentAnalyticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(icon, color: color, size: 28),

            const SizedBox(height: 14),

            Text(title, style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 8),

            Text(
              value,

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
