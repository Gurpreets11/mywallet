import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validator_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {

  final ExpenseModel? expense;

  const AddExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState
    extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController =
  TextEditingController();

  final _notesController =
  TextEditingController();


  DateTime _selectedDate =
  DateTime.now();

  String _paymentMode = 'Cash';

  int? _selectedCategoryId;

  int? _selectedSubcategoryId;

  bool get isEditMode =>
      widget.expense != null;


  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final expense = widget.expense!;

      _amountController.text =
          expense.amount.toString();

      _notesController.text =
          expense.notes ?? '';

      _paymentMode =
          expense.paymentMode;

      _selectedDate =
          DateTime.parse(expense.date);

      _selectedCategoryId =
          expense.categoryId;

      _selectedSubcategoryId =
          expense.subcategoryId;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate =
    await showDatePicker(
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
      appBar: AppBar(
        title: const Text('Add Expense'),

      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType:
                TextInputType.number,
                validator:
                ValidatorUtils.validateAmount,
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _notesController,
                label: 'Notes',
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _paymentMode,
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
                title: Text(
                  AppDateUtils.formatDate(
                    _selectedDate,
                  ),
                ),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CommonButton(
                text: 'Save Expense',
                onPressed: () async {
                  if (!_formKey.currentState!
                      .validate()) {
                    return;
                  }

                  final expense = ExpenseModel(
                    id: isEditMode
                        ? widget.expense!.id
                        : null,
                    amount: double.parse(
                      _amountController.text,
                    ),
                    categoryId:
                    _selectedCategoryId ?? 1,
                    subcategoryId:
                    _selectedSubcategoryId,
                    date:
                    _selectedDate.toIso8601String(),
                    paymentMode: _paymentMode,
                    notes: _notesController.text,
                    createdAt:
                    AppDateUtils
                        .getCurrentTimestamp(),
                  );

                  if (isEditMode) {
                    await context
                        .read<ExpenseProvider>()
                        .updateExpense(expense);
                  } else {
                    await context
                        .read<ExpenseProvider>()
                        .addExpense(expense);
                  }

                  if (!context.mounted) {
                    return;
                  }

                  SnackbarUtils.showSnackbar(
                    context,
                    'Expense Added',
                  );

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