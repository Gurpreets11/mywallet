import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../../../data/providers/master_provider.dart';
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

  int? _selectedSubcategoryId;

  bool get isEditMode => widget.income != null;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<MasterProvider>().loadExpenseCategories();
    });

    if (isEditMode) {
      final income = widget.income!;

      _amountController.text = income.amount.toString();

      _notesController.text = income.notes ?? '';

      _selectedDate = DateTime.parse(income.date);

      _paymentMode = income.paymentMode;

      _selectedCategoryId = income.categoryId;

      _selectedSubcategoryId = income.subcategoryId;

      _isRecurring = income.isRecurring;

      _recurringType = income.recurringType ?? 'Monthly';

      if (_selectedCategoryId != null) {
        Future.microtask(() {
          context.read<MasterProvider>().loadSubcategories(
            _selectedCategoryId!,
          );
        });
      }
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

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final income = IncomeModel(
      id: isEditMode ? widget.income!.id : null,
      amount: double.parse(_amountController.text),
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId,
      date: _selectedDate.toIso8601String(),
      paymentMode: _paymentMode,
      notes: _notesController.text,
      isRecurring: _isRecurring,
      recurringType: _isRecurring ? _recurringType : null,
      createdAt: AppDateUtils.getCurrentTimestamp(),
    );

    final provider = context.read<IncomeProvider>();

    if (isEditMode) {
      await provider.updateIncome(income);
    } else {
      await provider.addIncome(income);
    }

    if (!mounted) {
      return;
    }

    SnackbarUtils.showSnackbar(
      context,
      isEditMode ? 'Income Updated' : 'Income Added',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Income' : 'Add Income')),
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

              const SizedBox(height: 16),

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
                      setState(() {
                        _selectedCategoryId = value;

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

              const SizedBox(height: 16),

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
                      setState(() {
                        _selectedSubcategoryId = value;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
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

              SwitchListTile(
                value: _isRecurring,
                title: const Text('Recurring Income'),
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
              ),

              if (_isRecurring)
                DropdownButtonFormField<String>(
                  value: _recurringType,
                  decoration: const InputDecoration(
                    labelText: 'Recurring Type',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurringType = value!;
                    });
                  },
                ),

              const SizedBox(height: 16),

              CommonTextField(controller: _notesController, label: 'Notes'),

              const SizedBox(height: 30),

              CommonButton(
                text: isEditMode ? 'Update Income' : 'Save Income',
                onPressed: _saveIncome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
