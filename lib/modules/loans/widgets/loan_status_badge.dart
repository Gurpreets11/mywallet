import 'package:flutter/material.dart';

class LoanStatusBadge extends StatelessWidget {
  final String status;

  const LoanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();

    final Color color;
    final String label;
    switch (upper) {
      case 'CLOSED':
        color = Colors.green;
        label = 'Closed';
        break;
      case 'OVERDUE':
        color = Colors.red;
        label = 'Overdue';
        break;
      default:
        color = Theme.of(context).colorScheme.primary;
        label = 'Active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
