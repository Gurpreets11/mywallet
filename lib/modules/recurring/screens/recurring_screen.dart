import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/common_delete_dialog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../models/recurring_transaction_model.dart';
import '../providers/recurring_provider.dart';
import 'add_recurring_screen.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecurringProvider>().load();
    });
  }

  Future<void> _addRecurring() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecurringScreen()),
    );
  }

  Future<void> _openForm(
    RecurringTransactionModel item, {
    bool duplicate = false,
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecurringScreen(item: item, isDuplicate: duplicate),
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    RecurringTransactionModel item,
    RecurringProvider provider,
  ) async {
    if (action == 'edit') {
      await _openForm(item);
    } else if (action == 'duplicate') {
      await _openForm(item, duplicate: true);
    } else if (action == 'pause') {
      await provider.pause(item);
    } else if (action == 'resume') {
      await provider.resume(item);
    } else if (action == 'skip') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Skip next occurrence?'),
          content: Text(
            'Nothing will be added for ${_displayDate(item.nextDueDate)}. '
            'The schedule continues from the following date.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Skip'),
            ),
          ],
        ),
      );
      if (confirmed == true) await provider.skipNext(item);
    } else if (action == 'delete') {
      final confirmed = await confirmDelete(
        context,
        title: 'Delete schedule?',
        message: 'Generated transactions will remain in your history.',
      );
      if (confirmed) await provider.delete(item);
    }
  }

  void _showDetails(RecurringTransactionModel item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.title),
        content: Text(
          '${item.transactionType} • ${item.categoryName}\n'
          'Amount: ${CurrencyUtils.simple(item.amount, decimals: 2)}\n'
          'Payment: ${item.paymentMode}\n'
          'Repeat: ${_frequencyLabel(item.frequency, item.intervalValue)}\n'
          'Start: ${_displayDate(item.startDate)}\n'
          'End: ${item.endDate == null ? 'No end date' : _displayDate(item.endDate!)}\n'
          'Next due: ${_displayDate(item.nextDueDate)}\n'
          'Reminder: ${_reminderLabel(item.reminderDays)}\n'
          'Status: ${item.status}\n'
          '${item.notes ?? ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring transactions'),
        actions: [
          IconButton(
            tooltip: 'Generate due transactions',
            icon: const Icon(Icons.sync),
            onPressed: () => context.read<RecurringProvider>().load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecurring,
        icon: const Icon(Icons.add),
        label: const Text('Add recurring'),
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return AppResponsiveContent(
            maxWidth: 1050,
            padding: EdgeInsets.zero,
            child: provider.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_repeat,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No recurring transactions yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add a schedule for bills, salary or regular savings.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: _addRecurring,
                            icon: const Icon(Icons.add),
                            label: const Text('Add recurring'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                    itemCount: provider.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      final isExpense = item.transactionType == 'EXPENSE';
                      final color = isExpense
                          ? AppColors.expense
                          : AppColors.income;
                      return Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 19,
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 19,
                              color: color,
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '${item.categoryName} • ${_frequencyLabel(item.frequency, item.intervalValue)}\n'
                              'Next: ${_displayDate(item.nextDueDate)} • ${item.status}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          isThreeLine: false,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyUtils.simple(item.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (value) =>
                                    _handleAction(value, item, provider),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Text('Duplicate'),
                                  ),
                                  if (item.status == 'ACTIVE')
                                    const PopupMenuItem(
                                      value: 'pause',
                                      child: Text('Pause'),
                                    ),
                                  if (item.status == 'ACTIVE')
                                    const PopupMenuItem(
                                      value: 'skip',
                                      child: Text('Skip next'),
                                    ),
                                  if (item.status == 'PAUSED')
                                    const PopupMenuItem(
                                      value: 'resume',
                                      child: Text('Resume'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showDetails(item),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  static String _frequencyLabel(String frequency, int interval) {
    final label = frequency.toLowerCase();
    return interval == 1 ? label : 'every $interval $label';
  }

  static String _reminderLabel(int? days) => switch (days) {
    null => 'None',
    0 => 'On the due date',
    1 => '1 day before',
    _ => '$days days before',
  };

  static String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
