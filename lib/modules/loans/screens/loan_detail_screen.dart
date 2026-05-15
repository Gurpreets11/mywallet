import 'package:flutter/material.dart';
import 'package:mywallet/modules/loans/screens/pay_emi_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/loan_model.dart';
import '../providers/loan_payment_provider.dart';
import '../providers/loan_provider.dart';
import '../utils/loan_analytics_utils.dart';
import '../widgets/loan_analytics_card.dart';
import '../widgets/loan_payment_card.dart';
import '../widgets/loan_status_badge.dart';
import 'add_loan_payment_screen.dart';
import 'loan_payment_history_section.dart';

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LoanProvider>().loadLoanPayments(widget.loan.id!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loanProvider = context.read<LoanProvider>();

    final completionPercentage =
        LoanAnalyticsUtils.calculateCompletionPercentage(
          loanAmount: widget.loan.principalAmount,

          outstandingAmount: widget.loan.outstandingAmount,
        );

    final remainingEmis = LoanAnalyticsUtils.calculateRemainingEmiCount(
      outstandingAmount: widget.loan.outstandingAmount,

      emiAmount: widget.loan.emiAmount,
    );

    final isOverdue = LoanAnalyticsUtils.isLoanOverdue(
      widget.loan.nextEmiDate!,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddLoanPaymentScreen(loan: widget.loan),
            ),
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
                  widget.loan.personName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                LoanStatusBadge(
                  status: isOverdue ? 'Overdue' : widget.loan.loanStatus,
                ),

                _buildRow('Loan Type', widget.loan.loanType),

                _buildRow(
                  'Principal',
                  CurrencyUtils.formatAmount(widget.loan.principalAmount),
                ),

                _buildRow(
                  'Outstanding',
                  CurrencyUtils.formatAmount(widget.loan.outstandingAmount),
                ),

                _buildRow(
                  'EMI',
                  CurrencyUtils.formatAmount(widget.loan.emiAmount),
                ),

                _buildRow('Interest', '${widget.loan.interestRate}%'),

                _buildRow('Tenure', '${widget.loan.tenureMonths} Months'),

                _buildRow('Status', widget.loan.loanStatus),

                _buildRow('Notes', widget.loan.notes ?? '-'),

                const Text('Next EMI Date'),

                const SizedBox(height: 6),

                Text(
                  AppDateUtils.formatDate(DateTime.parse( widget.loan.nextEmiDate!)),

                  style: TextStyle(
                    color: isOverdue ? Colors.red : null,

                    fontWeight: isOverdue ? FontWeight.bold : null,
                  ),
                ),

                const SizedBox(height: 20),

                LinearProgressIndicator(
                  value: completionPercentage / 100,

                  minHeight: 10,

                  borderRadius: BorderRadius.circular(12),
                ),

                const SizedBox(height: 8),

                Text('${completionPercentage.toStringAsFixed(1)}% completed'),

                const SizedBox(height: 20),

                SizedBox(
                  height: 140,

                  child: ListView(
                    scrollDirection: Axis.horizontal,

                    children: [
                      SizedBox(
                        width: 200,

                        child: LoanAnalyticsCard(
                          title: 'Remaining EMIs',

                          value: '$remainingEmis EMIs',

                          icon: Icons.calendar_month,

                          color: Colors.blue,
                        ),
                      ),

                      SizedBox(
                        width: 200,

                        child: LoanAnalyticsCard(
                          title: 'Outstanding',

                          value: CurrencyUtils.formatAmount(
                            widget.loan.outstandingAmount,
                          ),

                          icon: Icons.account_balance_wallet,

                          color: Colors.red,
                        ),
                      ),

                      SizedBox(
                        width: 200,

                        child: LoanAnalyticsCard(
                          title: 'EMI Amount',

                          value: CurrencyUtils.formatAmount(
                            widget.loan.emiAmount,
                          ),

                          icon: Icons.payment,

                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Consumer<LoanPaymentProvider>(
                  builder: (context, provider, _) {
                    if (provider.payments.isEmpty) {
                      return const Text('No payments found');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.payments.length,
                      itemBuilder: (context, index) {
                        return LoanPaymentCard(
                          payment: provider.payments[index],
                        );
                      },
                    );
                  },
                ),

                if (widget.loan.loanStatus != 'Closed')
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,

                          isScrollControlled: true,

                          builder: (_) {
                            return PayEmiBottomSheet(
                              onSubmit:
                                  ({
                                    required paymentAmount,
                                    required paymentMode,
                                    remarks,
                                  }) async {
                                    await loanProvider.payEmi(
                                      loan: widget.loan,
                                      paymentAmount: paymentAmount,
                                      paymentMode: paymentMode,
                                      remarks: remarks,
                                    );

                                    await loanProvider.loadLoanPayments(
                                      widget.loan.id!,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('EMI paid successfully'),
                                      ),
                                    );
                                  },
                            );
                          },
                        );
                      },

                      icon: const Icon(Icons.payment),

                      label: const Text('Pay EMI'),
                    ),
                  ),

                const SizedBox(height: 20),

                Consumer<LoanProvider>(
                  builder: (context, provider, child) {
                    return LoanPaymentHistorySection(
                      payments: provider.loanPayments,
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
