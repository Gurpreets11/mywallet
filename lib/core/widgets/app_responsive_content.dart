import 'package:flutter/material.dart';

/// Keeps page content readable on wide screens while allowing it to use
/// the full available width on phones and smaller tablets.
class AppResponsiveContent extends StatelessWidget {
  const AppResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
