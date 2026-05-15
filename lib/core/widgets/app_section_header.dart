import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;

  final Widget? trailing;

  const AppSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,

          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        if (trailing != null) trailing!,
      ],
    );
  }
}
