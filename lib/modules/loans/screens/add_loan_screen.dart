import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../models/loan_model.dart';
import '../providers/loan_provider.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanModel? loan;

  const AddLoanScreen({super.key, this.loan});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _personController = TextEditingController();

  final _amountController = TextEditingController();

  final _interestController = TextEditingController();

  final _emiController = TextEditingController();

  final _tenureController = TextEditingController();

  final _notesController = TextEditingController();

  String _loanType = 'BORROWED';

  String _loanStatus = 'ACTIVE';

  DateTime _startDate = DateTime.now();

  bool get isEditMode => widget.loan != null;
  DateTime _nextEmiDate =
  DateTime.now();
  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final loan = widget.loan!;

      _personController.text = loan.personName;

      _amountController.text = loan.principalAmount.toString();

      _interestController.text = loan.interestRate.toString();

      _emiController.text = loan.emiAmount.toString();

      _tenureController.text = loan.tenureMonths.toString();

      _notesController.text = loan.notes ?? '';

      _loanType = loan.loanType;

      _loanStatus = loan.loanStatus;

      _startDate = DateTime.parse(loan.startDate);
    }
  }

  Future<void> _saveLoan() async {
    final amount = double.parse(_amountController.text);

    final loan = LoanModel(
      id: isEditMode ? widget.loan!.id : null,
      loanType: _loanType,
      personName: _personController.text,
      principalAmount: amount,
      interestRate: double.parse(_interestController.text),
      emiAmount: double.parse(_emiController.text),
      nextEmiDate:
      _nextEmiDate
          .toIso8601String(),
      tenureMonths: int.parse(_tenureController.text),
      startDate: _startDate.toIso8601String(),
      endDate: null,
      totalPaid: isEditMode ? widget.loan!.totalPaid : 0,
      outstandingAmount: isEditMode ? widget.loan!.outstandingAmount : amount,
      loanStatus: _loanStatus,
      notes: _notesController.text,
      createdAt: AppDateUtils.getCurrentTimestamp(),
    );

    final provider = context.read<LoanProvider>();

    if (isEditMode) {
      await provider.updateLoan(loan);
    } else {
      await provider.addLoan(loan);
    }

    if (!mounted) {
      return;
    }

    SnackbarUtils.showSnackbar(
      context,
      isEditMode ? 'Loan Updated' : 'Loan Added',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Loan' : 'Add Loan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _loanType,
                decoration: const InputDecoration(labelText: 'Loan Type'),
                items: const [
                  DropdownMenuItem(value: 'BORROWED', child: Text('Borrowed')),
                  DropdownMenuItem(value: 'GIVEN', child: Text('Given')),
                ],
                onChanged: (value) {
                  setState(() {
                    _loanType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _personController,
                label: 'Person / Bank Name',
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _amountController,
                label: 'Principal Amount',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _interestController,
                label: 'Interest Rate',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _emiController,
                label: 'EMI Amount',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              ListTile(
                contentPadding:
                EdgeInsets.zero,
                title: Text(
                  'Next EMI Date: '
                      '${AppDateUtils.formatDate(_nextEmiDate)}',
                ),
                trailing: IconButton(
                  onPressed:
                  _pickNextEmiDate,
                  icon: const Icon(
                    Icons.calendar_month,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CommonTextField(
                controller: _tenureController,
                label: 'Tenure (Months)',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _loanStatus,
                decoration: const InputDecoration(labelText: 'Loan Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                ],
                onChanged: (value) {
                  setState(() {
                    _loanStatus = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              CommonTextField(controller: _notesController, label: 'Notes'),

              const SizedBox(height: 30),

              CommonButton(
                text: isEditMode ? 'Update Loan' : 'Save Loan',
                onPressed: _saveLoan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void>
  _pickNextEmiDate() async {
    final pickedDate =
    await showDatePicker(
      context: context,
      initialDate: _nextEmiDate,
      firstDate: DateTime.now(),
      lastDate:
      DateTime.now().add(
        const Duration(days: 3650),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        _nextEmiDate =
            pickedDate;
      });
    }
  }
}
