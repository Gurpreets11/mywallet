import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;

  final IconData icon;

  final String? actionText;

  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 70, color: Colors.grey.shade400),

            const SizedBox(height: 20),

            Text(
              message,

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            if (actionText != null) ...[
              const SizedBox(height: 20),

              ElevatedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
