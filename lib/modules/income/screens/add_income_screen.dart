import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../../data/providers/master_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/income_model.dart';
import '../providers/income_provider.dart';

class AddIncomeScreen extends StatefulWidget {
  final IncomeModel? income;

  const AddIncomeScreen({super.key, this.income});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _paymentMode = 'Bank';
  bool _isRecurring = false;
  String _recurringType = 'Monthly';
  int? _selectedCategoryId;
  String? _selectedCategoryName;
  int? _selectedSubcategoryId;
  String? _selectedSubCategoryName;
  bool _isSaving = false;
  bool _isLoadingCategories = true;

  bool get isEditMode => widget.income != null;

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    if (income != null) {
      _amountController.text = income.amount.toString();
      _notesController.text = income.notes ?? '';
      _selectedDate = DateTime.tryParse(income.date) ?? DateTime.now();
      _paymentMode = income.paymentMode;
      _selectedCategoryId = income.categoryId;
      _selectedCategoryName = income.categoryName;
      _selectedSubcategoryId = income.subcategoryId;
      _selectedSubCategoryName = income.subcategoryName;
      _isRecurring = income.isRecurring;
      _recurringType = income.recurringType ?? 'Monthly';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    final master = context.read<MasterProvider>();
    try {
      await master.loadIncomeCategories();
      if (_selectedCategoryId != null) {
        await master.loadIncomeSubcategories(_selectedCategoryId!);
      }
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) {
      return 'Enter an amount greater than zero';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveIncome() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;

    setState(() => _isSaving = true);
    try {
      final old = widget.income;
      final income = IncomeModel(
        id: old?.id,
        amount: double.parse(_amountController.text.trim()),
        categoryId: categoryId,
        subcategoryId: _selectedSubcategoryId,
        date: _selectedDate.toIso8601String(),
        paymentMode: _paymentMode,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isRecurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType : null,
        createdAt: old?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
        categoryName: _selectedCategoryName,
        subcategoryName: _selectedSubCategoryName,
      );

      final provider = context.read<IncomeProvider>();
      if (isEditMode) {
        await provider.updateIncome(income);
      } else {
        await provider.addIncome(income);
      }

      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboardData();
      if (!mounted) return;
      SnackbarUtils.showSnackbar(
        context,
        isEditMode ? 'Income updated' : 'Income added',
      );
      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to save income: $error\n$stackTrace');
      if (mounted) {
        SnackbarUtils.showSnackbar(
          context,
          'Unable to save income. Please try again.',
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
      appBar: AppBar(title: Text(isEditMode ? 'Edit Income' : 'Add Income')),
      body: SingleChildScrollView(
        child: AppResponsiveContent(
          maxWidth: 680,
          padding: const EdgeInsets.all(20),
          child: _isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditMode ? 'Update income' : 'New income',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter the details of your income.',
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
                                validator: _validateAmount,
                              ),
                              const SizedBox(height: 16),
                              Consumer<MasterProvider>(
                                builder: (context, master, _) {
                                  final categories = master.incomeCategories;
                                  final selectedValue =
                                      categories.any(
                                        (item) =>
                                            item['id'] == _selectedCategoryId,
                                      )
                                      ? _selectedCategoryId
                                      : null;
                                  return DropdownButtonFormField<int>(
                                    initialValue: selectedValue,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Category',
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    items: categories.map((category) {
                                      return DropdownMenuItem<int>(
                                        value: category['id'] as int,
                                        child: Text(
                                          category['category_name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (value == null) return;
                                      final selected = categories.firstWhere(
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
                                      await master.loadIncomeSubcategories(
                                        value,
                                      );
                                    },
                                    validator: (value) => value == null
                                        ? 'Select a category'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Consumer<MasterProvider>(
                                builder: (context, master, _) {
                                  final subcategories =
                                      master.incomeSubCategories;
                                  final selectedValue =
                                      subcategories.any(
                                        (item) =>
                                            item['id'] ==
                                            _selectedSubcategoryId,
                                      )
                                      ? _selectedSubcategoryId
                                      : null;
                                  return DropdownButtonFormField<int>(
                                    initialValue: selectedValue,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Subcategory (optional)',
                                      prefixIcon: Icon(
                                        Icons.subdirectory_arrow_right,
                                      ),
                                    ),
                                    items: subcategories.map((item) {
                                      return DropdownMenuItem<int>(
                                        value: item['id'] as int,
                                        child: Text(
                                          item['subcategory_name'].toString(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      final matches = subcategories.where(
                                        (item) => item['id'] == value,
                                      );
                                      setState(() {
                                        _selectedSubcategoryId = value;
                                        _selectedSubCategoryName =
                                            matches.isEmpty
                                            ? null
                                            : matches.first['subcategory_name']
                                                  .toString();
                                      });
                                    },
                                  );
                                },
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
                                    value: 'Bank',
                                    child: Text('Bank'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _paymentMode = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Income date',
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
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _isRecurring,
                                title: const Text('Recurring income'),
                                onChanged: (value) =>
                                    setState(() => _isRecurring = value),
                              ),
                              if (_isRecurring) ...[
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _recurringType,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Recurring type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Daily',
                                      child: Text('Daily'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Weekly',
                                      child: Text('Weekly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Monthly',
                                      child: Text('Monthly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Yearly',
                                      child: Text('Yearly'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _recurringType = value);
                                    }
                                  },
                                ),
                              ],
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
                          onPressed: _isSaving ? null : _saveIncome,
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
                                ? 'Update income'
                                : 'Save income',
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
