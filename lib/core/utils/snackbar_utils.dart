import 'package:flutter/material.dart';

class SnackbarUtils {
  static void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows a message with an UNDO action. [onUndo] runs when tapped.
  static void showUndo(
    BuildContext context,
    String message,
    Future<void> Function() onUndo,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'UNDO', onPressed: () => onUndo()),
      ),
    );
  }
}
