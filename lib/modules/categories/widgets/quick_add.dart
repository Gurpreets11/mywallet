import 'package:flutter/material.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../models/category_item.dart';
import '../repositories/category_repository.dart';
import 'name_dialog.dart';

/// Result of adding a category / subcategory from a form.
typedef QuickAddResult = ({int id, String name});

/// Asks for a name and creates a category of [typeId] (0 expense, 1 income).
/// Returns null if cancelled or if saving failed (the error is shown).
Future<QuickAddResult?> showQuickAddCategory(
  BuildContext context, {
  required int typeId,
}) async {
  final name = await promptForName(
    context,
    title: typeId == CategoryRepository.expenseType
        ? 'New expense category'
        : 'New income category',
    hint: 'e.g. Pets',
    confirmLabel: 'Add',
  );
  if (name == null || !context.mounted) return null;

  try {
    final id = await CategoryRepository().addCategory(typeId, name);
    return (id: id, name: name.trim().replaceAll(RegExp(r'\s+'), ' '));
  } on CategoryException catch (e) {
    if (context.mounted) SnackbarUtils.showSnackbar(context, e.message);
  } catch (_) {
    if (context.mounted) {
      SnackbarUtils.showSnackbar(context, 'Could not add category');
    }
  }
  return null;
}

/// Asks for a name and creates a subcategory under [categoryId].
Future<QuickAddResult?> showQuickAddSubcategory(
  BuildContext context, {
  required int categoryId,
}) async {
  final name = await promptForName(
    context,
    title: 'New subcategory',
    hint: 'e.g. Vet',
    confirmLabel: 'Add',
  );
  if (name == null || !context.mounted) return null;

  try {
    final id = await CategoryRepository().addSubcategory(categoryId, name);
    return (id: id, name: name.trim().replaceAll(RegExp(r'\s+'), ' '));
  } on CategoryException catch (e) {
    if (context.mounted) SnackbarUtils.showSnackbar(context, e.message);
  } catch (_) {
    if (context.mounted) {
      SnackbarUtils.showSnackbar(context, 'Could not add subcategory');
    }
  }
  return null;
}

/// Compact "New category / New subcategory" links shown under the category
/// fields on the add forms.
class QuickAddLinks extends StatelessWidget {
  final VoidCallback onAddCategory;

  /// Null hides the subcategory link (no category picked yet).
  final VoidCallback? onAddSubcategory;

  const QuickAddLinks({
    super.key,
    required this.onAddCategory,
    this.onAddSubcategory,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 32),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        children: [
          TextButton.icon(
            style: style,
            onPressed: onAddCategory,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New category'),
          ),
          if (onAddSubcategory != null)
            TextButton.icon(
              style: style,
              onPressed: onAddSubcategory,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New subcategory'),
            ),
        ],
      ),
    );
  }
}
