import 'package:flutter/material.dart';

import '../../../core/widgets/app_section_header.dart';

class PayEmiBottomSheet extends StatefulWidget {
  final Function({
    required double paymentAmount,

    required String paymentMode,

    String? remarks,
  })
  onSubmit;

  /// Pre-filled amount (normally the loan's EMI).
  final double? initialAmount;

  const PayEmiBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialAmount,
  });

  @override
  State<PayEmiBottomSheet> createState() => _PayEmiBottomSheetState();
}

class _PayEmiBottomSheetState extends State<PayEmiBottomSheet> {
  late final TextEditingController _amountController;

  final _remarksController = TextEditingController();

  String _paymentMode = 'UPI';
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAmount;
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : (initial == initial.roundToDouble()
                ? initial.toStringAsFixed(0)
                : initial.toString()),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter an amount greater than zero');
      return;
    }

    widget.onSubmit(
      paymentAmount: amount,
      paymentMode: _paymentMode,
      remarks: _remarksController.text,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSectionHeader(title: 'Pay EMI'),

          const SizedBox(height: 14),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
            decoration: InputDecoration(
              labelText: 'Payment amount',
              prefixText: '₹ ',
              errorText: _amountError,
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(labelText: 'Payment mode'),
            items: const [
              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(
                value: 'Bank Transfer',
                child: Text('Bank Transfer'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _paymentMode = value);
            },
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Pay EMI'),
            ),
          ),
        ],
      ),
    );
  }
}
