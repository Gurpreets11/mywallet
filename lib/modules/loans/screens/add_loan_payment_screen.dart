import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/common_button.dart';
import '../../../core/widgets/common_text_field.dart';
import '../models/loan_model.dart';
import '../models/loan_payment_model.dart';
import '../providers/loan_payment_provider.dart';
import '../providers/loan_provider.dart';
import '../repositories/loan_repository.dart';

class AddLoanPaymentScreen extends StatefulWidget {
  final LoanModel loan;

  const AddLoanPaymentScreen({super.key, required this.loan});

  @override
  State<AddLoanPaymentScreen> createState() => _AddLoanPaymentScreenState();
}

class _AddLoanPaymentScreenState extends State<AddLoanPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  final _remarksController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  String _paymentMode = 'Bank';

  final LoanRepository _loanRepository = LoanRepository();

  @override
  void initState() {
    super.initState();

    _amountController.text = widget.loan.emiAmount.toString();
  }

  Future<void> _savePayment() async {
    final double amount = double.parse(_amountController.text);

    final payment = LoanPaymentModel(
      loanId: widget.loan.id!,
      paymentAmount: amount,
      paymentDate: _paymentDate.toIso8601String(),
      paymentMode: _paymentMode,
      remarks: _remarksController.text,
      createdAt: AppDateUtils.getCurrentTimestamp(),
    );

    await context.read<LoanPaymentProvider>().addPayment(payment);

    await _loanRepository.updateLoanAfterPayment(
      loanId: widget.loan.id!,
      paymentAmount: amount,
    );

    await context.read<LoanProvider>().loadLoans();

    if (!mounted) {
      return;
    }

    SnackbarUtils.showSnackbar(context, 'EMI Payment Added');

    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _paymentDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add EMI Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CommonTextField(
                controller: _amountController,
                label: 'Payment Amount',
                keyboardType: TextInputType.number,
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
                title: Text(AppDateUtils.formatDate(_paymentDate)),
                trailing: IconButton(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                ),
              ),

              const SizedBox(height: 16),

              CommonTextField(controller: _remarksController, label: 'Remarks'),

              const SizedBox(height: 30),

              CommonButton(text: 'Save Payment', onPressed: _savePayment),
            ],
          ),
        ),
      ),
    );
  }
}
