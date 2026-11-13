import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Destructive-action dialog: the confirm button stays disabled until the user
/// types [keyword] (case-insensitive). Returns true when confirmed.
class TypeToConfirmDialog extends StatefulWidget {
  const TypeToConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.keyword = 'DELETE',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String keyword;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String keyword = 'DELETE',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TypeToConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        keyword: keyword,
      ),
    );
    return result == true;
  }

  @override
  State<TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<TypeToConfirmDialog> {
  final TextEditingController _controller = TextEditingController();

  bool get _matches =>
      _controller.text.trim().toUpperCase() == widget.keyword.toUpperCase();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            Text('Type ${widget.keyword} to confirm:'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
          ),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
