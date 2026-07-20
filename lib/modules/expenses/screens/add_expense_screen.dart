import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
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
  String? _selectedCategoryName;
  int? _selectedSubcategoryId;
  String? _selectedSubCategoryName;
  bool get isEditMode => widget.expense != null;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<MasterProvider>().loadExpenseCategories();
    });

    if (isEditMode) {
      final expense = widget.expense!;

      _amountController.text = expense.amount.toString();

      if (_selectedCategoryId != null) {
        Future.microtask(() {
          context.read<MasterProvider>().loadSubcategories(
            _selectedCategoryId!,
          );
        });
      }

      _notesController.text = expense.notes ?? '';
      _paymentMode = expense.paymentMode;
      _selectedDate = DateTime.parse(expense.date);
      _selectedCategoryId = expense.categoryId;
      _selectedSubcategoryId = expense.subcategoryId;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType: TextInputType.number,
                validator: ValidatorUtils.validateAmount,
              ),

              const SizedBox(height: 10),

              Consumer<MasterProvider>(
                builder: (context, master, _) {
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: master.expenseCategories.map((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text(category['category_name']),
                      );
                    }).toList(),
                    onChanged: (value) async {

                      final selectedCategory = master.expenseCategories.firstWhere(
                            (category) => category['id'] == value,
                      );

                      setState(() {
                        _selectedCategoryId = value;
                        _selectedCategoryName = selectedCategory['category_name'];

                        _selectedSubcategoryId = null;
                      });

                      if (value != null) {
                        await context.read<MasterProvider>().loadSubcategories(
                          value,
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Select category';
                      }

                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              Consumer<MasterProvider>(
                builder: (context, master, _) {
                  return DropdownButtonFormField<int>(
                    value: _selectedSubcategoryId,
                    decoration: const InputDecoration(labelText: 'Subcategory'),
                    items: master.subcategories.map((subcategory) {
                      return DropdownMenuItem<int>(
                        value: subcategory['id'],
                        child: Text(subcategory['subcategory_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final selectedSubCategory = master.subcategories.firstWhere(
                            (subcategory) => subcategory['id'] == value,
                      );

                      setState(() {
                        _selectedSubcategoryId = value;
                        _selectedSubCategoryName = selectedSubCategory['subcategory_name'];
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
              CommonTextField(controller: _notesController, label: 'Notes'),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _paymentMode,
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                ],
                onChanged: (value) {
                  setState(() {
                    _paymentMode = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppDateUtils.formatDate(_selectedDate)),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                ),
              ),
              const SizedBox(height: 20),
              CommonButton(
                text: 'Save Expense',
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final expense = ExpenseModel(
                    id: isEditMode ? widget.expense!.id : null,
                    amount: double.parse(_amountController.text),
                    categoryId: _selectedCategoryId ?? 1,
                    categoryName: _selectedCategoryName,
                    subcategoryId: _selectedSubcategoryId,
                    subcategoryName: _selectedSubCategoryName,
                    date: _selectedDate.toIso8601String(),
                    paymentMode: _paymentMode,
                    notes: _notesController.text,
                    createdAt: AppDateUtils.getCurrentTimestamp(),
                  );

                  if (isEditMode) {
                    debugPrint( 'Update Expense called..');
                    await context.read<ExpenseProvider>().updateExpense(
                      expense,
                    );
                  } else {
                    debugPrint( 'Add Expense called..');
                    await context.read<ExpenseProvider>().addExpense(expense);
                  }

                  if (!context.mounted) {
                    return;
                  }

                  await context.read<DashboardProvider>().loadDashboardData();
                  SnackbarUtils.showSnackbar(context, 'Expense Added');

                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
