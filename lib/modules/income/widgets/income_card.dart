import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/income_model.dart';

class IncomeCard extends StatelessWidget {
  final IncomeModel income;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Show the date on the card. The list hides it when transactions are
  /// already grouped under date headings.
  final bool showDate;

  const IncomeCard({
    super.key,
    required this.income,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final title = [income.categoryName, income.subcategoryName]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(' • ');

    final date = DateTime.tryParse(income.date);
    final meta = <String>[
      if (income.paymentMode.isNotEmpty) income.paymentMode,
      if (showDate && date != null) AppDateUtils.formatDate(date),
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.south_west_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isEmpty ? 'Income' : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyUtils.formatAmount(income.amount),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (meta.isNotEmpty || income.isRecurring) ...[
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (meta.isNotEmpty)
                            Text(
                              meta,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          if (income.isRecurring)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 13,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  income.recurringType ?? 'Recurring',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                    if ((income.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        income.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Income actions',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.more_vert, size: 20, color: muted),
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
