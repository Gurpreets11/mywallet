import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Row of dots showing how many PIN digits have been typed.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  final int length;
  final int filled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? AppColors.error : AppColors.primary)
                : Colors.transparent,
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.primary,
              width: 1.6,
            ),
          ),
        );
      }),
    );
  }
}

/// 3x4 numeric keypad (1-9, 0, backspace).
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
    this.leading,
  });

  /// Optional key at the bottom-left (e.g. fingerprint).
  final Widget? leading;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget key(String label) => _PadKey(
      onTap: enabled ? () => onDigit(label) : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final d in row) key(d)],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              leading ?? const SizedBox(width: 72, height: 72),
              key('0'),
              _PadKey(
                onTap: enabled ? onBackspace : null,
                child: Icon(
                  Icons.backspace_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: SizedBox(width: 64, height: 64, child: Center(child: child)),
      ),
    );
  }
}
