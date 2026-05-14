import 'package:flutter/material.dart';

class CommonDeleteDialog extends StatelessWidget {
  final String title;

  final String message;

  final VoidCallback onConfirm;

  const CommonDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),

          const SizedBox(width: 8),

          Expanded(child: Text(title)),
        ],
      ),

      content: Text(message),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);

            onConfirm();
          },

          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),

          child: const Text('Delete'),
        ),
      ],
    );
  }
}
