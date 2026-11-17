import 'package:flutter/material.dart';

/// Compact header shared by the Expenses and Income lists:
/// search box, one-line monthly summary, and a count + sort row.
class TransactionListHeader extends StatelessWidget {
  const TransactionListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.summaryLabel,
    required this.summaryAmount,
    required this.summaryIcon,
    required this.summaryIconColor,
    required this.summaryIconBackground,
    required this.countText,
    required this.sortValue,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final String summaryLabel;
  final String summaryAmount;
  final IconData summaryIcon;
  final Color summaryIconColor;
  final Color summaryIconBackground;
  final String countText;
  final String sortValue;
  final ValueChanged<String> onSortChanged;

  static const Map<String, String> _sortLabels = {
    'newest': 'Newest',
    'oldest': 'Oldest',
    'highest': 'Highest amount',
    'lowest': 'Lowest amount',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) => TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search transactions',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onSearchCleared,
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // One-line summary
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: summaryIconBackground,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(summaryIcon, size: 20, color: summaryIconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summaryLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          summaryAmount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Count + sort
          Row(
            children: [
              Text(
                countText,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortValue,
                  isDense: true,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  icon: Icon(
                    Icons.unfold_more_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  items: [
                    for (final entry in _sortLabels.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (v) => onSortChanged(v ?? 'newest'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
