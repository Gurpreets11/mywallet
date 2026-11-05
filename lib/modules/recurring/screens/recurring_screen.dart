import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../data/providers/master_provider.dart';
import '../models/recurring_transaction_model.dart';
import '../providers/recurring_provider.dart';

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
      context.read<RecurringProvider>().load();
      context.read<MasterProvider>().loadExpenseCategories();
      context.read<MasterProvider>().loadIncomeCategories();
    });
  }

  Future<void> _showAddDialog() async {
    final provider = context.read<RecurringProvider>();
    final master = context.read<MasterProvider>();
    String type = 'EXPENSE';
    String frequency = 'MONTHLY';
    String paymentMode = 'Cash';
    int interval = 1;
    int? categoryId;
    String categoryName = '';
    DateTime start = DateTime.now();
    DateTime? end;
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories = type == 'EXPENSE'
              ? master.expenseCategories
              : master.incomeCategories;
          if (categoryId != null &&
              !categories.any((item) => item['id'] == categoryId)) {
            categoryId = null;
            categoryName = '';
          }
          return AlertDialog(
            title: const Text('Add recurring transaction'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Transaction type'),
                      items: const [
                        DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                        DropdownMenuItem(value: 'INCOME', child: Text('Income')),
                      ],
                      onChanged: (value) => setDialogState(() {
                        type = value!;
                        categoryId = null;
                        categoryName = '';
                      }),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(item['category_name'].toString()),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() {
                        categoryId = value;
                        final selected = categories.firstWhere(
                          (item) => item['id'] == value,
                        );
                        categoryName = selected['category_name'].toString();
                      }),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Repeat'),
                      items: const [
                        DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                        DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                        DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
                      ],
                      onChanged: (value) => setDialogState(() => frequency = value!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: interval,
                      decoration: const InputDecoration(labelText: 'Every'),
                      items: List.generate(12, (index) => index + 1)
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value ${frequency.toLowerCase()} interval(s)'),
                              ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => interval = value!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: paymentMode,
                      decoration: const InputDecoration(labelText: 'Payment mode'),
                      items: const ['Cash', 'Card', 'UPI', 'Bank Transfer']
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => paymentMode = value!),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(_formatDate(start)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: start,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setDialogState(() => start = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End date (optional)'),
                      subtitle: Text(end == null ? 'No end date' : _formatDate(end!)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (end != null)
                            IconButton(
                              tooltip: 'Clear end date',
                              icon: const Icon(Icons.clear),
                              onPressed: () => setDialogState(() => end = null),
                            ),
                          const Icon(Icons.event),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: end ?? start,
                          firstDate: start,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setDialogState(() => end = picked);
                      },
                    ),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text.trim());
                  if (title.isEmpty || amount == null || amount <= 0 ||
                      categoryId == null || categoryName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter title, valid amount and category.')),
                    );
                    return;
                  }
                  if (end != null && end!.isBefore(start)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('End date must be on or after start date.')),
                    );
                    return;
                  }
                  final now = DateTime.now().toIso8601String();
                  await provider.add(RecurringTransactionModel(
                    title: title,
                    transactionType: type,
                    amount: amount,
                    categoryId: categoryId!,
                    categoryName: categoryName,
                    paymentMode: paymentMode,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    frequency: frequency,
                    intervalValue: interval,
                    startDate: _dateOnly(start),
                    endDate: end == null ? null : _dateOnly(end!),
                    nextDueDate: _dateOnly(start),
                    createdAt: now,
                  ));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
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
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add recurring'),
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return AppResponsiveContent(
            maxWidth: 900,
            child: provider.items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_repeat, size: 52, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text('No recurring transactions yet',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          SizedBox(height: 6),
                          Text('Add a schedule for bills, salary or regular savings.'),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: provider.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      final isExpense = item.transactionType == 'EXPENSE';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isExpense ? AppColors.expense : AppColors.income)
                                .withValues(alpha: 0.12),
                            child: Icon(
                              isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                          ),
                          title: Text(item.title,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              '${item.categoryName} • ${item.frequency.toLowerCase()}'
                              '${item.intervalValue > 1 ? ' (every ${item.intervalValue})' : ''}\n'
                              'Next: ${item.nextDueDate} • ${item.status}',
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'pause') await provider.pause(item);
                              if (value == 'resume') await provider.resume(item);
                              if (value == 'delete') {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete schedule?'),
                                    content: const Text(
                                      'Generated transactions will remain in your history.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) await provider.delete(item);
                              }
                            },
                            itemBuilder: (_) => [
                              if (item.status == 'ACTIVE')
                                const PopupMenuItem(value: 'pause', child: Text('Pause')),
                              if (item.status == 'PAUSED')
                                const PopupMenuItem(value: 'resume', child: Text('Resume')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(item.title),
                              content: Text(
                                '${item.transactionType} • ${item.categoryName}\n'
                                'Amount: ${item.amount.toStringAsFixed(2)}\n'
                                'Payment: ${item.paymentMode}\n'
                                'Start: ${item.startDate}\n'
                                'End: ${item.endDate ?? 'No end date'}\n'
                                'Next due: ${item.nextDueDate}\n'
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
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  static String _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day).toIso8601String().substring(0, 10);

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
