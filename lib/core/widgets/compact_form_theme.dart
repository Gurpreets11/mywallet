import 'package:flutter/material.dart';

/// Wraps a form so its text fields and dropdowns are denser (less padding),
/// without changing the app-wide theme used by other screens.
class CompactFormTheme extends StatelessWidget {
  const CompactFormTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
      child: child,
    );
  }
}
