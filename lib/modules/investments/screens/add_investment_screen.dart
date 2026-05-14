import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/date_utils.dart';

import '../../../core/utils/snackbar_utils.dart';

import '../../../core/widgets/common_button.dart';

import '../../../core/widgets/common_text_field.dart';

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

  String _investmentType = InvestmentConstants.mutualFund;

  bool _isSip = false;

  DateTime _investmentDate = DateTime.now();

  bool get isEditMode => widget.investment != null;

  final _sipAmountController = TextEditingController();

  int _sipDate = 1;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final investment = widget.investment!;

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

  Future<void> _saveInvestment() async {
    final investment = InvestmentModel(
      id: isEditMode ? widget.investment!.id : null,

      investmentType: _investmentType,

      investmentName: _nameController.text,

      investmentPlatform: _platformController.text,

      investedAmount: double.parse(_investedController.text),

      currentValue: double.parse(_currentValueController.text),

      investmentDate: _investmentDate.toIso8601String(),

      isSip: _isSip,

      createdAt: AppDateUtils.getCurrentTimestamp(),

      sipAmount: _isSip ? double.tryParse(_sipAmountController.text) : null,

      sipDate: _isSip ? _sipDate : null,
    );

    final provider = context.read<InvestmentProvider>();

    if (isEditMode) {
      await provider.updateInvestment(investment);
    } else {
      await provider.addInvestment(investment);
    }

    if (_isSip) {
      await NotificationService.instance.scheduleSipReminder(
        id: DateTime.now().millisecondsSinceEpoch,

        investmentName: _nameController.text,

        amount: double.parse(_sipAmountController.text),

        sipDate: _sipDate,
      );
    }

    if (!mounted) {
      return;
    }

    SnackbarUtils.showSnackbar(
      context,
      isEditMode ? 'Investment Updated' : 'Investment Added',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Investment' : 'Add Investment'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _investmentType,

                decoration: const InputDecoration(labelText: 'Investment Type'),

                items: InvestmentConstants.investmentTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    _investmentType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _nameController,
                label: 'Investment Name',
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _platformController,
                label: 'Platform / Broker',
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _investedController,
                label: 'Invested Amount',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              CommonTextField(
                controller: _currentValueController,
                label: 'Current Value',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                value: _isSip,
                title: const Text('Is SIP'),
                onChanged: (value) {
                  setState(() {
                    _isSip = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              if (_isSip) ...[
                const SizedBox(height: 16),

                CommonTextField(
                  controller: _sipAmountController,

                  label: 'SIP Amount',

                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  value: _sipDate,

                  decoration: const InputDecoration(labelText: 'SIP Date'),

                  items: List.generate(28, (index) {
                    final day = index + 1;

                    return DropdownMenuItem(value: day, child: Text('$day'));
                  }),

                  onChanged: (value) {
                    setState(() {
                      _sipDate = value!;
                    });
                  },
                ),
              ],

              const SizedBox(height: 16),
              CommonTextField(controller: _notesController, label: 'Notes'),

              const SizedBox(height: 30),

              CommonButton(
                text: isEditMode ? 'Update' : 'Save',
                onPressed: _saveInvestment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
