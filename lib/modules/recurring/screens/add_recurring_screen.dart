import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../accounts/widgets/account_dropdown.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/compact_form_theme.dart';
import '../../../data/providers/master_provider.dart';
import '../models/recurring_transaction_model.dart';
import '../providers/recurring_provider.dart';

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'EXPENSE';
  String _frequency = 'MONTHLY';
  String _paymentMode = 'Cash';
  int? _accountId;
  int _interval = 1;
  int? _categoryId;
  String _categoryName = '';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MasterProvider>().loadExpenseCategories();
      context.read<MasterProvider>().loadIncomeCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _categories(MasterProvider master) {
    return (_type == 'EXPENSE'
            ? master.expenseCategories
            : master.incomeCategories)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_categoryId == null || _categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be on or after start date.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now().toIso8601String();
      await context.read<RecurringProvider>().add(
        RecurringTransactionModel(
          title: _titleController.text.trim(),
          transactionType: _type,
          amount: double.parse(_amountController.text.trim()),
          categoryId: _categoryId!,
          categoryName: _categoryName,
          paymentMode: _paymentMode,
          accountId: _accountId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          frequency: _frequency,
          intervalValue: _interval,
          startDate: _dateOnly(_startDate),
          endDate: _endDate == null ? null : _dateOnly(_endDate!),
          nextDueDate: _dateOnly(_startDate),
          createdAt: now,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recurring schedule added')));
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Unable to add recurring schedule: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save recurring schedule.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool optional = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: optional && date != null
              ? IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : const Icon(Icons.edit_calendar_outlined),
        ),
        child: Text(date == null ? 'No end date' : _formatDate(date)),
      ),
    );
  }

  Widget _buildSaveBar(ThemeData theme) {
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Saving...' : 'Save recurring'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CompactFormTheme(
      child: Scaffold(
        appBar: AppBar(title: const Text('Add recurring')),
        bottomNavigationBar: _buildSaveBar(theme),
        body: AppResponsiveContent(
          maxWidth: 680,
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.event_repeat_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a title'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixText: '${CurrencyUtils.symbol} ',
                          ),
                          validator: (value) {
                            final amount = double.tryParse(
                              (value ?? '').trim(),
                            );
                            return amount == null || amount <= 0
                                ? 'Enter an amount greater than zero'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Transaction type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'EXPENSE',
                              child: Text('Expense'),
                            ),
                            DropdownMenuItem(
                              value: 'INCOME',
                              child: Text('Income'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _type = value;
                              _categoryId = null;
                              _categoryName = '';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Consumer<MasterProvider>(
                          builder: (context, master, _) {
                            final categories = _categories(master);
                            final selected =
                                categories.any(
                                  (item) => item['id'] == _categoryId,
                                )
                                ? _categoryId
                                : null;
                            return DropdownButtonFormField<int>(
                              initialValue: selected,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: categories.map((item) {
                                return DropdownMenuItem<int>(
                                  value: item['id'] as int,
                                  child: Text(
                                    item['category_name'].toString(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                final matches = categories.where(
                                  (item) => item['id'] == value,
                                );
                                setState(() {
                                  _categoryId = value;
                                  _categoryName = matches.isEmpty
                                      ? ''
                                      : matches.first['category_name']
                                            .toString();
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _frequency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Repeat',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'DAILY',
                              child: Text('Daily'),
                            ),
                            DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text('Weekly'),
                            ),
                            DropdownMenuItem(
                              value: 'MONTHLY',
                              child: Text('Monthly'),
                            ),
                            DropdownMenuItem(
                              value: 'YEARLY',
                              child: Text('Yearly'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _frequency = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _interval,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Every'),
                          items: List.generate(12, (index) => index + 1)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    '$value ${_frequency.toLowerCase()} interval(s)',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _interval = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AccountDropdown(
                          value: _accountId,
                          onChanged: (v) => _accountId = v,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Payment mode',
                          ),
                          items: const ['Cash', 'Card', 'UPI', 'Bank Transfer']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _paymentMode = value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        _dateField(
                          label: 'Start date',
                          date: _startDate,
                          onTap: _pickStartDate,
                        ),
                        const SizedBox(height: 12),
                        _dateField(
                          label: 'End date (optional)',
                          date: _endDate,
                          optional: true,
                          onTap: _pickEndDate,
                          onClear: () => setState(() => _endDate = null),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dateOnly(DateTime date) => DateTime(
    date.year,
    date.month,
    date.day,
  ).toIso8601String().substring(0, 10);

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
