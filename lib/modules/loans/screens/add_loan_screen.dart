import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
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
  DateTime _nextEmiDate = DateTime.now();
  bool _isSaving = false;

  bool get isEditMode => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    if (loan != null) {
      _personController.text = loan.personName;
      _amountController.text = loan.principalAmount.toString();
      _interestController.text = loan.interestRate.toString();
      _emiController.text = loan.emiAmount.toString();
      _tenureController.text = loan.tenureMonths.toString();
      _notesController.text = loan.notes ?? '';
      _loanType = loan.loanType;
      _loanStatus = loan.loanStatus.toUpperCase() == 'CLOSED' ? 'CLOSED' : 'ACTIVE';
      _startDate = DateTime.tryParse(loan.startDate) ?? DateTime.now();
      _nextEmiDate =
          DateTime.tryParse(loan.nextEmiDate ?? '') ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _emiController.dispose();
    _tenureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePositiveAmount(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || amount <= 0) {
      return 'Enter a value greater than zero';
    }
    return null;
  }

  String? _validateInterest(String? value) {
    final rate = double.tryParse((value ?? '').trim());
    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a valid rate between 0 and 100';
    }
    return null;
  }

  String? _validateTenure(String? value) {
    final months = int.tryParse((value ?? '').trim());
    if (months == null || months <= 0) {
      return 'Enter tenure in months';
    }
    return null;
  }

  Future<void> _pickDate({required bool isNextEmiDate}) async {
    final current = isNextEmiDate ? _nextEmiDate : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isNextEmiDate) {
        _nextEmiDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  Future<void> _saveLoan() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final old = widget.loan;
      final loan = LoanModel(
        id: old?.id,
        loanType: _loanType,
        personName: _personController.text.trim(),
        principalAmount: double.parse(_amountController.text.trim()),
        interestRate: double.parse(_interestController.text.trim()),
        emiAmount: double.parse(_emiController.text.trim()),
        nextEmiDate: _nextEmiDate.toIso8601String(),
        tenureMonths: int.parse(_tenureController.text.trim()),
        startDate: _startDate.toIso8601String(),
        endDate: old?.endDate,
        totalPaid: old?.totalPaid ?? 0,
        outstandingAmount: old?.outstandingAmount ??
            double.parse(_amountController.text.trim()),
        loanStatus: _loanStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: old?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
      );

      final provider = context.read<LoanProvider>();
      if (isEditMode) {
        await provider.updateLoan(loan);
      } else {
        await provider.addLoan(loan);
      }

      // Do not fail the loan save if Android notification permission is unavailable.
      try {
        await NotificationService.instance.scheduleNotification(
          id: old?.id ?? DateTime.now().millisecondsSinceEpoch,
          title: 'EMI Reminder',
          body: 'EMI payment due for ${loan.personName}',
          scheduledDate: _nextEmiDate.subtract(const Duration(days: 1)),
          payload: jsonEncode({'type': 'loan', 'loanId': loan.id}),
        );
      } catch (error) {
        debugPrint('Unable to schedule EMI reminder: $error');
      }

      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboardData();
      if (!mounted) return;
      SnackbarUtils.showSnackbar(
        context,
        isEditMode ? 'Loan updated' : 'Loan added',
      );
      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to save loan: $error\n$stackTrace');
      if (mounted) {
        SnackbarUtils.showSnackbar(
          context,
          'Unable to save loan. Please try again.',
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
      appBar: AppBar(title: Text(isEditMode ? 'Edit Loan' : 'Add Loan')),
      body: SingleChildScrollView(
        child: AppResponsiveContent(
          maxWidth: 680,
          padding: const EdgeInsets.all(20),
          child: Form(
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
                          isEditMode ? 'Update loan' : 'New loan',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the loan and repayment details.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _loanType,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Loan type'),
                          items: const [
                            DropdownMenuItem(
                              value: 'BORROWED',
                              child: Text('Borrowed'),
                            ),
                            DropdownMenuItem(
                              value: 'GIVEN',
                              child: Text('Given'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _loanType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _personController,
                          decoration: const InputDecoration(
                            labelText: 'Person / Bank name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Principal amount',
                            prefixText: '₹ ',
                          ),
                          validator: _validatePositiveAmount,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _interestController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Interest rate (%)',
                            suffixText: '%',
                          ),
                          validator: _validateInterest,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emiController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'EMI amount',
                            prefixText: '₹ ',
                          ),
                          validator: _validatePositiveAmount,
                        ),
                        const SizedBox(height: 16),
                        _dateField(
                          label: 'Loan start date',
                          date: _startDate,
                          onTap: () => _pickDate(isNextEmiDate: false),
                        ),
                        const SizedBox(height: 12),
                        _dateField(
                          label: 'Next EMI date',
                          date: _nextEmiDate,
                          onTap: () => _pickDate(isNextEmiDate: true),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tenureController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tenure (months)',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          validator: _validateTenure,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _loanStatus,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Loan status'),
                          items: const [
                            DropdownMenuItem(
                              value: 'ACTIVE',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'CLOSED',
                              child: Text('Closed'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _loanStatus = value);
                            }
                          },
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
                    onPressed: _isSaving ? null : _saveLoan,
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
                              ? 'Update loan'
                              : 'Save loan',
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

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Row(
          children: [
            Expanded(child: Text(AppDateUtils.formatDate(date))),
            const Icon(Icons.edit_calendar_outlined),
          ],
        ),
      ),
    );
  }
}
