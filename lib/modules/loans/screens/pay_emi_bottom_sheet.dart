import 'package:flutter/material.dart';

class PayEmiBottomSheet extends StatefulWidget {
  final Function({
    required double paymentAmount,

    required String paymentMode,

    String? remarks,
  })
  onSubmit;

  const PayEmiBottomSheet({super.key, required this.onSubmit});

  @override
  State<PayEmiBottomSheet> createState() => _PayEmiBottomSheetState();
}

class _PayEmiBottomSheetState extends State<PayEmiBottomSheet> {
  final _amountController = TextEditingController();

  final _remarksController = TextEditingController();

  String _paymentMode = 'UPI';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,

        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          const Text(
            'Pay EMI',

            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          /// AMOUNT
          TextField(
            controller: _amountController,

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(labelText: 'Payment Amount'),
          ),

          const SizedBox(height: 16),

          /// PAYMENT MODE
          DropdownButtonFormField<String>(
            value: _paymentMode,

            decoration: const InputDecoration(labelText: 'Payment Mode'),

            items: const [
              DropdownMenuItem(value: 'UPI', child: Text('UPI')),

              DropdownMenuItem(value: 'Cash', child: Text('Cash')),

              DropdownMenuItem(
                value: 'Bank Transfer',

                child: Text('Bank Transfer'),
              ),
            ],

            onChanged: (value) {
              setState(() {
                _paymentMode = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          /// REMARKS
          TextField(
            controller: _remarksController,

            decoration: const InputDecoration(labelText: 'Remarks'),
          ),

          const SizedBox(height: 24),

          /// BUTTON
          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () {
                widget.onSubmit(
                  paymentAmount: double.parse(_amountController.text),

                  paymentMode: _paymentMode,

                  remarks: _remarksController.text,
                );

                Navigator.pop(context);
              },

              child: const Text('Pay EMI'),
            ),
          ),
        ],
      ),
    );
  }
}
