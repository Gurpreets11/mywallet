import 'package:flutter/material.dart';

import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../models/category_item.dart';
import '../utils/category_style.dart';
import '../repositories/category_repository.dart';
import '../widgets/name_dialog.dart';

/// Add, rename, hide and delete categories and subcategories, separately for
/// expenses and income.
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });

  final _expenseTab = GlobalKey<_CategoryTabState>();
  final _incomeTab = GlobalKey<_CategoryTabState>();

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _tabs.index == 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => (isExpense ? _expenseTab : _incomeTab).currentState
            ?.addCategory(),
        icon: const Icon(Icons.add),
        label: Text(isExpense ? 'Expense category' : 'Income category'),
      ),
      body: AppResponsiveContent(
        maxWidth: 800,
        padding: EdgeInsets.zero,
        child: TabBarView(
          controller: _tabs,
          children: [
            _CategoryTab(
              key: _expenseTab,
              typeId: CategoryRepository.expenseType,
            ),
            _CategoryTab(
              key: _incomeTab,
              typeId: CategoryRepository.incomeType,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatefulWidget {
  final int typeId;
  const _CategoryTab({super.key, required this.typeId});

  @override
  State<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<_CategoryTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = CategoryRepository();
  List<CategoryItem>? _items;
  final Set<int> _expanded = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.getCategories(widget.typeId);
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _items = const []);
    }
  }

  /// Runs a change, shows any user-facing error, then reloads the list.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on CategoryException catch (e) {
      if (mounted) SnackbarUtils.showSnackbar(context, e.message);
    } catch (_) {
      if (mounted) SnackbarUtils.showSnackbar(context, 'Something went wrong');
    }
    await _load();
  }

  Future<void> addCategory() async {
    final name = await promptForName(
      context,
      title: widget.typeId == CategoryRepository.expenseType
          ? 'New expense category'
          : 'New income category',
      hint: 'Category name',
      confirmLabel: 'Add',
    );
    if (name == null) return;
    await _run(() => _repo.addCategory(widget.typeId, name));
  }

  Future<void> _addSubcategory(CategoryItem c) async {
    final name = await promptForName(
      context,
      title: 'New subcategory in ${c.name}',
      hint: 'Subcategory name',
      confirmLabel: 'Add',
    );
    if (name == null) return;
    setState(() => _expanded.add(c.id));
    await _run(() => _repo.addSubcategory(c.id, name));
  }

  Future<void> _renameCategory(CategoryItem c) async {
    final name = await promptForName(
      context,
      title: 'Rename category',
      initial: c.name,
    );
    if (name == null || name == c.name) return;
    await _run(() => _repo.renameCategory(c.id, c.typeId, name));
  }

  Future<void> _renameSub(CategoryItem c, SubcategoryItem s) async {
    final name = await promptForName(
      context,
      title: 'Rename subcategory',
      initial: s.name,
    );
    if (name == null || name == s.name) return;
    await _run(() => _repo.renameSubcategory(s.id, c.id, name));
  }

  Future<void> _pickStyle(CategoryItem c) async {
    final result = await showModalBottomSheet<(String?, String?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StyleSheet(icon: c.iconName, color: c.colorCode),
    );
    if (result == null) return;
    await _run(() => _repo.setCategoryStyle(c.id, result.$1, result.$2));
  }

  Future<void> _merge(CategoryItem c, List<CategoryItem> all) async {
    final others = all.where((o) => o.id != c.id).toList();
    if (others.isEmpty) {
      SnackbarUtils.showSnackbar(context, 'No other category to merge into');
      return;
    }
    final target = await showDialog<CategoryItem>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Merge "${c.name}" into…'),
        children: [
          SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView(
              children: [
                for (final o in others)
                  ListTile(
                    leading: _avatar(o, radius: 16),
                    title: Text(o.name),
                    onTap: () => Navigator.pop(ctx, o),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (target == null || !mounted) return;
    final ok = await confirmDelete(
      context,
      title: 'Merge into "${target.name}"?',
      message:
          'All entries, budgets, schedules and subcategories of "${c.name}" '
          'move to "${target.name}", and "${c.name}" is removed. '
          'This cannot be undone.',
      confirmLabel: 'Merge',
    );
    if (!ok) return;
    await _run(() => _repo.mergeCategories(c.id, target.id));
  }

  Widget _avatar(CategoryItem c, {double radius = 18}) {
    final color =
        CategoryStyle.colorFor(c.colorCode) ??
        Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(
        CategoryStyle.iconFor(c.iconName),
        size: radius * 1.1,
        color: color,
      ),
    );
  }

  Future<bool> _confirm(String title, String message) =>
      confirmDelete(context, title: title, message: message);

  Future<void> _deleteCategory(CategoryItem c) async {
    final ok = await _confirm(
      'Delete "${c.name}"?',
      c.subcategories.isEmpty
          ? 'This category is not used anywhere.'
          : 'This category and its ${c.subcategories.length} subcategories '
                'are not used anywhere and will be removed.',
    );
    if (!ok) return;
    await _run(() => _repo.deleteCategory(c.id));
  }

  Future<void> _deleteSub(SubcategoryItem s) async {
    final ok = await _confirm(
      'Delete "${s.name}"?',
      'This subcategory is not used anywhere.',
    );
    if (!ok) return;
    await _run(() => _repo.deleteSubcategory(s.id));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return const Center(child: Text('No categories yet'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        itemCount: items.length,
        itemBuilder: (context, i) => _categoryCard(items, i),
      ),
    );
  }

  Widget _categoryCard(List<CategoryItem> items, int index) {
    final c = items[index];
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final visibleSubs = c.subcategories.length;
    final summary = [
      '$visibleSubs subcategor${visibleSubs == 1 ? 'y' : 'ies'}',
      '${c.usageCount} ${c.usageCount == 1 ? 'use' : 'uses'}',
      if (!c.isActive) 'Hidden',
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('cat-${c.id}-${_expanded.contains(c.id)}'),
          initiallyExpanded: _expanded.contains(c.id),
          onExpansionChanged: (open) =>
              open ? _expanded.add(c.id) : _expanded.remove(c.id),
          leading: _avatar(c),
          tilePadding: const EdgeInsets.only(left: 14, right: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 4, 8),
          title: Text(
            c.name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: c.isActive ? null : muted,
              decoration: c.isActive ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'rename':
                      _renameCategory(c);
                    case 'style':
                      _pickStyle(c);
                    case 'up':
                      _run(() => _repo.moveCategory(c.id, c.typeId, -1));
                    case 'down':
                      _run(() => _repo.moveCategory(c.id, c.typeId, 1));
                    case 'merge':
                      _merge(c, items);
                    case 'toggle':
                      _run(() => _repo.setCategoryActive(c.id, !c.isActive));
                    case 'delete':
                      _deleteCategory(c);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(
                    value: 'style',
                    child: Text('Icon & colour'),
                  ),
                  if (index > 0)
                    const PopupMenuItem(value: 'up', child: Text('Move up')),
                  if (index < items.length - 1)
                    const PopupMenuItem(value: 'down', child: Text('Move down')),
                  const PopupMenuItem(
                    value: 'merge',
                    child: Text('Merge into…'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(c.isActive ? 'Hide' : 'Show'),
                  ),
                  if (c.usageCount == 0)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              const Icon(Icons.expand_more),
              const SizedBox(width: 6),
            ],
          ),
          children: [
            for (final s in c.subcategories) _subRow(c, s, theme, muted),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSubcategory(c),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add subcategory'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subRow(
    CategoryItem c,
    SubcategoryItem s,
    ThemeData theme,
    Color muted,
  ) {
    return Row(
      children: [
        Icon(Icons.subdirectory_arrow_right, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            s.isActive ? s.name : '${s.name}  (hidden)',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: s.isActive ? null : muted,
            ),
          ),
        ),
        Text(
          '${s.usageCount}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'rename':
                _renameSub(c, s);
              case 'toggle':
                _run(() => _repo.setSubcategoryActive(s.id, !s.isActive));
              case 'delete':
                _deleteSub(s);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(s.isActive ? 'Hide' : 'Show'),
            ),
            if (s.usageCount == 0)
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ],
    );
  }
}

/// Bottom sheet to choose an icon and a colour. Pops `(icon, colour)`.
class _StyleSheet extends StatefulWidget {
  final String? icon;
  final String? color;
  const _StyleSheet({this.icon, this.color});

  @override
  State<_StyleSheet> createState() => _StyleSheetState();
}

class _StyleSheetState extends State<_StyleSheet> {
  late String? _icon = widget.icon;
  late String? _color = widget.color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = CategoryStyle.colorFor(_color) ?? scheme.primary;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Colour', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final code in CategoryStyle.colors)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = code),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: CategoryStyle.colorFor(code),
                      child: _color == code
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Icon', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in CategoryStyle.icons.entries)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _icon = e.key),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _icon == e.key
                            ? current.withValues(alpha: 0.18)
                            : null,
                        border: Border.all(
                          color: _icon == e.key ? current : scheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        e.value,
                        color: _icon == e.key ? current : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop<(String?, String?)>(
                    context,
                    (null, null),
                  ),
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop<(String?, String?)>(
                    context,
                    (_icon, _color),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
