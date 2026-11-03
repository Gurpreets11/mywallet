import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../constant/investment_constants.dart';
import '../models/investment_model.dart';
import '../providers/investment_provider.dart';

class AddInvestmentScreen extends StatefulWidget {
  final InvestmentModel? investment;

  const AddInvestmentScreen({super.key, this.investment});

  @override
  State<AddInvestmentScreen> createState() => _AddInvestmentScreenState();
}

class _AddInvestmentScreenState extends State<AddInvestmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _platformController = TextEditingController();
  final _investedController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _notesController = TextEditingController();
  final _sipAmountController = TextEditingController();

  String _investmentType = InvestmentConstants.mutualFund;
  bool _isSip = false;
  late DateTime _investmentDate;
  int _sipDate = 1;
  bool _isSaving = false;

  bool get isEditMode => widget.investment != null;

  @override
  void initState() {
    super.initState();
    _investmentDate = DateTime.now();
    final investment = widget.investment;
    if (investment != null) {
      _investmentDate =
          DateTime.tryParse(investment.investmentDate) ?? DateTime.now();
      _nameController.text = investment.investmentName;
      _platformController.text = investment.investmentPlatform ?? '';
      _investedController.text = investment.investedAmount.toString();
      _currentValueController.text = investment.currentValue.toString();
      _notesController.text = investment.notes ?? '';
      _investmentType = investment.investmentType;
      _isSip = investment.isSip;
      _sipAmountController.text = investment.sipAmount?.toString() ?? '';
      _sipDate = investment.sipDate ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _platformController.dispose();
    _investedController.dispose();
    _currentValueController.dispose();
    _notesController.dispose();
    _sipAmountController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
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
      initialDate: _investmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _investmentDate = picked);
    }
  }

  Future<void> _saveInvestment() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final old = widget.investment;
      final investment = InvestmentModel(
        id: old?.id,
        investmentType: _investmentType,
        investmentName: _nameController.text.trim(),
        investmentPlatform: _platformController.text.trim().isEmpty
            ? null
            : _platformController.text.trim(),
        investedAmount: double.parse(_investedController.text.trim()),
        currentValue: double.parse(_currentValueController.text.trim()),
        investmentDate: _investmentDate.toIso8601String(),
        isSip: _isSip,
        createdAt: old?.createdAt ?? AppDateUtils.getCurrentTimestamp(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        sipAmount: _isSip
            ? double.parse(_sipAmountController.text.trim())
            : null,
        sipDate: _isSip ? _sipDate : null,
        // Preserve fields that are not currently editable on this form.
        quantity: old?.quantity,
        purchasePrice: old?.purchasePrice,
        currentPrice: old?.currentPrice,
        maturityDate: old?.maturityDate,
        interestRate: old?.interestRate,
      );

      final provider = context.read<InvestmentProvider>();
      if (isEditMode) {
        await provider.updateInvestment(investment);
      } else {
        await provider.addInvestment(investment);
      }

      // A reminder failure must not undo or hide a successfully saved investment.
      if (_isSip) {
        try {
          await NotificationService.instance.scheduleSipReminder(
            id: DateTime.now().millisecondsSinceEpoch,
            investmentName: investment.investmentName,
            amount: investment.sipAmount!,
            sipDate: _sipDate,
          );
        } catch (error) {
          debugPrint('Unable to schedule SIP reminder: $error');
        }
      }

      if (!mounted) return;
      await context.read<DashboardProvider>().loadDashboardData();
      if (!mounted) return;
      SnackbarUtils.showSnackbar(
        context,
        isEditMode ? 'Investment updated' : 'Investment added',
      );
      Navigator.pop(context);
    } catch (error, stackTrace) {
      debugPrint('Unable to save investment: $error\n$stackTrace');
      if (mounted) {
        SnackbarUtils.showSnackbar(
          context,
          'Unable to save investment. Please try again.',
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
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Investment' : 'Add Investment'),
      ),
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
                          isEditMode ? 'Update investment' : 'New investment',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your investment details and current valuation.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _investmentType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Investment type',
                          ),
                          items: InvestmentConstants.investmentTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _investmentType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Investment name',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          validator: _validateRequired,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _platformController,
                          decoration: const InputDecoration(
                            labelText: 'Platform / Broker (optional)',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _investedController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Invested amount',
                            prefixText: '₹ ',
                          ),
                          validator: _validateAmount,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _currentValueController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Current value',
                            prefixText: '₹ ',
                          ),
                          validator: _validateAmount,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Investment date',
                              prefixIcon:
                                  Icon(Icons.calendar_today_outlined),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppDateUtils.formatDate(_investmentDate),
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
                          value: _isSip,
                          title: const Text('This is a SIP'),
                          onChanged: (value) =>
                              setState(() => _isSip = value),
                        ),
                        if (_isSip) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _sipAmountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'SIP amount',
                              prefixText: '₹ ',
                            ),
                            validator: _isSip ? _validateAmount : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _sipDate,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'SIP date of month',
                            ),
                            items: List.generate(28, (index) {
                              final day = index + 1;
                              return DropdownMenuItem(
                                value: day,
                                child: Text('$day'),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sipDate = value);
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
                    onPressed: _isSaving ? null : _saveInvestment,
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
                              ? 'Update investment'
                              : 'Save investment',
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
