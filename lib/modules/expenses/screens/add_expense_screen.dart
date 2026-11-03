import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../data/providers/master_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;
  const AddExpenseScreen({super.key, this.expense});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentMode = 'Cash';
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryName;
  bool _isSaving = false;
  bool _isLoadingMaster = true;
  bool get isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = expense.amount.toString();
      _notesController.text = expense.notes ?? '';
      _paymentMode = expense.paymentMode;
      _selectedDate = DateTime.tryParse(expense.date) ?? DateTime.now();
      _selectedCategoryId = expense.categoryId;
      _selectedSubcategoryId = expense.subcategoryId;
      _selectedCategoryName = expense.categoryName;
      _selectedSubCategoryName = expense.subcategoryName;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasterData());
  }

  Future<void> _loadMasterData() async {
    final master = context.read<MasterProvider>();
    await master.loadExpenseCategories();
    if (_selectedCategoryId != null) {
      await master.loadSubcategories(_selectedCategoryId!);
    }
    if (!mounted) return;
    setState(() => _isLoadingMaster = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final old = widget.expense;
      final expense = ExpenseModel(
        id: old?.id,
        amount: double.parse(_amountController.text.trim()),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName,
        subcategoryId: _selectedSubcategoryId,
        subcategoryName: _selectedSubCategoryName,
        date: _selectedDate.toIso8601String(),
        paymentMode: _paymentMode,
        notes: _notesController.text.trim(),
        createdAt: old?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
      );
      final provider = context.read<ExpenseProvider>();
      if (isEditMode) {
        await provider.updateExpense(expense);
      } else {
        await provider.addExpense(expense);
      }
      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboardData();
      if (!mounted) return;
      SnackbarUtils.showSnackbar(
        context,
        isEditMode ? 'Expense updated' : 'Expense added',
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        SnackbarUtils.showSnackbar(
          context,
          'Unable to save expense. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit expense' : 'Add expense')),
      body: AppResponsiveContent(
        maxWidth: 680,
        padding: const EdgeInsets.all(20),
        child: _isLoadingMaster
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditMode
                                  ? 'Update transaction'
                                  : 'New transaction',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter the details of your expense.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                prefixText: '₹ ',
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              validator: (value) {
                                final amount = double.tryParse(
                                  (value ?? '').trim(),
                                );
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount greater than zero';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Consumer<MasterProvider>(
                              builder: (context, master, _) =>
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedCategoryId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: master.expenseCategories
                                        .map(
                                          (category) => DropdownMenuItem<int>(
                                            value: category['id'] as int,
                                            child: Text(
                                              category['category_name']
                                                  .toString(),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) async {
                                      final selected = master.expenseCategories
                                          .firstWhere(
                                            (item) => item['id'] == value,
                                          );
                                      setState(() {
                                        _selectedCategoryId = value;
                                        _selectedCategoryName =
                                            selected['category_name']
                                                .toString();
                                        _selectedSubcategoryId = null;
                                        _selectedSubCategoryName = null;
                                      });
                                      if (value != null) {
                                        await master.loadSubcategories(value);
                                      }
                                    },
                                    validator: (value) => value == null
                                        ? 'Select a category'
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Consumer<MasterProvider>(
                              builder: (context, master, _) =>
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedSubcategoryId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Subcategory (optional)',
                                      prefixIcon: Icon(
                                        Icons.subdirectory_arrow_right,
                                      ),
                                    ),
                                    items: master.subcategories
                                        .map(
                                          (item) => DropdownMenuItem<int>(
                                            value: item['id'] as int,
                                            child: Text(
                                              item['subcategory_name']
                                                  .toString(),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      final matches = master.subcategories
                                          .where((item) => item['id'] == value);
                                      setState(() {
                                        _selectedSubcategoryId = value;
                                        _selectedSubCategoryName =
                                            matches.isEmpty
                                            ? null
                                            : matches.first['subcategory_name']
                                                  .toString();
                                      });
                                    },
                                  ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _paymentMode,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Payment mode',
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Cash',
                                  child: Text('Cash'),
                                ),
                                DropdownMenuItem(
                                  value: 'UPI',
                                  child: Text('UPI'),
                                ),
                                DropdownMenuItem(
                                  value: 'Card',
                                  child: Text('Card'),
                                ),
                                DropdownMenuItem(
                                  value: 'Bank',
                                  child: Text('Bank'),
                                ),
                              ],
                              onChanged: (value) => setState(
                                () => _paymentMode = value ?? 'Cash',
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expense date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        AppDateUtils.formatDate(_selectedDate),
                                      ),
                                    ),
                                    const Icon(Icons.edit_calendar_outlined),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : isEditMode
                              ? 'Update expense'
                              : 'Save expense',
                        ),
                      ),
                    ),
                    if (isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Current amount: ${CurrencyUtils.formatAmount(widget.expense!.amount)}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
