import 'package:flutter/material.dart';

class QuickActionCard
    extends StatelessWidget {
  final String title;

  final IconData icon;

  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Container(
          padding:
          const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(
                  0.05,
                ),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}