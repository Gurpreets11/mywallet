import 'package:flutter/material.dart';

class LoanStatusBadge extends StatelessWidget {
  final String status;

  const LoanStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (status) {
      case 'Closed':
        color = Colors.green;
        break;

      case 'Overdue':
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
