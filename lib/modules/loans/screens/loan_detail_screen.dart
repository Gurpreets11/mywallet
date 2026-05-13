import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../models/loan_model.dart';
import '../providers/loan_payment_provider.dart';
import '../widgets/loan_payment_card.dart';
import 'add_loan_payment_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.microtask(() {
      context.read<LoanPaymentProvider>().loadPayments(widget.loan.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddLoanPaymentScreen(loan: widget.loan)),
          );
        },
        label: const Text('Add EMI'),
        icon: const Icon(Icons.payments),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget. loan.personName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                _buildRow('Loan Type',widget. loan.loanType),

                _buildRow(
                  'Principal',
                  CurrencyUtils.formatAmount(widget.loan.principalAmount),
                ),

                _buildRow(
                  'Outstanding',
                  CurrencyUtils.formatAmount(widget.loan.outstandingAmount),
                ),

                _buildRow('EMI', CurrencyUtils.formatAmount(widget.loan.emiAmount)),

                _buildRow('Interest', '${widget.loan.interestRate}%'),

                _buildRow('Tenure', '${widget.loan.tenureMonths} Months'),

                _buildRow('Status',widget. loan.loanStatus),

                _buildRow('Notes', widget.loan.notes ?? '-'),


                const SizedBox(height: 24),

                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Consumer<
                    LoanPaymentProvider>(
                  builder:
                      (context, provider, _) {
                    if (provider.payments
                        .isEmpty) {
                      return const Text(
                        'No payments found',
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount:
                      provider.payments.length,
                      itemBuilder:
                          (context, index) {
                        return LoanPaymentCard(
                          payment:
                          provider
                              .payments[index],
                        );
                      },
                    );
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
