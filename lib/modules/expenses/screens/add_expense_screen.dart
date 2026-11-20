import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../categories/widgets/quick_add.dart';
import '../../accounts/widgets/account_dropdown.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../core/widgets/compact_form_theme.dart';
import '../../../data/providers/master_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../budgets/services/budget_alert_service.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;

  /// When true, [expense] only pre-fills the form and a new entry is saved.
  final bool isDuplicate;
  const AddExpenseScreen({super.key, this.expense, this.isDuplicate = false});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentMode = 'Cash';
  int? _accountId;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String? _selectedCategoryName;
  String? _selectedSubCategoryName;
  bool _isSaving = false;
  bool _isLoadingMaster = true;
  bool get isEditMode => widget.expense != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _amountController.text = expense.amount.toString();
      _notesController.text = expense.notes ?? '';
      _paymentMode = expense.paymentMode;
      _accountId = expense.accountId;
      _selectedDate = widget.isDuplicate
          ? DateTime.now()
          : (DateTime.tryParse(expense.date) ?? DateTime.now());
      _selectedCategoryId = expense.categoryId;
      _selectedSubcategoryId = expense.subcategoryId;
      _selectedCategoryName = expense.categoryName;
      _selectedSubCategoryName = expense.subcategoryName;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasterData());
  }

  Future<void> _loadMasterData() async {
    final master = context.read<MasterProvider>();
    await master.loadExpenseCategories(alsoIncludeId: _selectedCategoryId);
    if (_selectedCategoryId != null) {
      await master.loadSubcategories(
        _selectedCategoryId!,
        alsoIncludeId: _selectedSubcategoryId,
      );
    }
    if (!mounted) return;
    setState(() => _isLoadingMaster = false);
  }

  Future<void> _addCategory() async {
    final created = await showQuickAddCategory(context, typeId: 0);
    if (created == null || !mounted) return;
    final master = context.read<MasterProvider>();
    await master.loadExpenseCategories(alsoIncludeId: created.id);
    await master.loadSubcategories(created.id);
    if (!mounted) return;
    setState(() {
      _selectedCategoryId = created.id;
      _selectedCategoryName = created.name;
      _selectedSubcategoryId = null;
      _selectedSubCategoryName = null;
    });
  }

  Future<void> _addSubcategory() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;
    final created = await showQuickAddSubcategory(
      context,
      categoryId: categoryId,
    );
    if (created == null || !mounted) return;
    await context.read<MasterProvider>().loadSubcategories(
      categoryId,
      alsoIncludeId: created.id,
    );
    if (!mounted) return;
    setState(() {
      _selectedSubcategoryId = created.id;
      _selectedSubCategoryName = created.name;
    });
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
      final old = widget.isDuplicate ? null : widget.expense;
      final expense = ExpenseModel(
        id: old?.id,
        amount: double.parse(_amountController.text.trim()),
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName,
        subcategoryId: _selectedSubcategoryId,
        subcategoryName: _selectedSubCategoryName,
        date: _selectedDate.toIso8601String(),
        paymentMode: _paymentMode,
        accountId: _accountId,
        notes: _notesController.text.trim(),
        createdAt: old?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
      );
      final provider = context.read<ExpenseProvider>();
      if (isEditMode) {
        await provider.updateExpense(expense);
      } else {
        await provider.addExpense(expense);
      }
      await BudgetAlertService().checkAfterExpense(
        categoryId: expense.categoryId,
        dateIso: expense.date,
      );
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

  /// Save button pinned to the bottom so it is always visible.
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
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : isEditMode
                    ? 'Update expense'
                    : 'Save expense',
              ),
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
        appBar: AppBar(
          title: Text(isEditMode ? 'Edit expense' : 'Add expense'),
        ),
        bottomNavigationBar: _isLoadingMaster ? null : _buildSaveBar(theme),
        body: AppResponsiveContent(
          maxWidth: 680,
          // Padding lives inside the scroll view (below), otherwise it clips
          // the content at the edges.
          padding: EdgeInsets.zero,
          child: _isLoadingMaster
              ? const Center(child: CircularProgressIndicator())
              : Form(
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
                              TextFormField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  prefixText: '${CurrencyUtils.symbol} ',
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
                              const SizedBox(height: 12),
                              Consumer<MasterProvider>(
                                builder: (context, master, _) =>
                                    DropdownButtonFormField<int>(
                                      key: ValueKey('cat-$_selectedCategoryId'),
                                      initialValue: _selectedCategoryId,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        prefixIcon: Icon(
                                          Icons.category_outlined,
                                        ),
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
                                        final selected = master
                                            .expenseCategories
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
                              const SizedBox(height: 12),
                              Consumer<MasterProvider>(
                                builder: (context, master, _) =>
                                    DropdownButtonFormField<int>(
                                      key: ValueKey(
                                        'sub-$_selectedCategoryId-$_selectedSubcategoryId',
                                      ),
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
                                            .where(
                                              (item) => item['id'] == value,
                                            );
                                        setState(() {
                                          _selectedSubcategoryId = value;
                                          _selectedSubCategoryName =
                                              matches.isEmpty
                                              ? null
                                              : matches
                                                    .first['subcategory_name']
                                                    .toString();
                                        });
                                      },
                                    ),
                              ),
                              QuickAddLinks(
                                onAddCategory: _addCategory,
                                onAddSubcategory: _selectedCategoryId == null
                                    ? null
                                    : _addSubcategory,
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
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                items: [
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
                                  if (!const [
                                    'Cash',
                                    'UPI',
                                    'Card',
                                    'Bank',
                                  ].contains(_paymentMode))
                                    DropdownMenuItem(
                                      value: _paymentMode,
                                      child: Text(_paymentMode),
                                    ),
                                ],
                                onChanged: (value) => setState(
                                  () => _paymentMode = value ?? 'Cash',
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                          AppDateUtils.formatDate(
                                            _selectedDate,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.edit_calendar_outlined),
                                    ],
                                  ),
                                ),
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
}
