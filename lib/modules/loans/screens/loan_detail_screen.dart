import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/loan_model.dart';
import '../providers/loan_payment_provider.dart';
import '../providers/loan_provider.dart';
import '../utils/loan_analytics_utils.dart';
import '../widgets/loan_analytics_card.dart';
import '../widgets/loan_status_badge.dart';
import '../widgets/loan_warning_banner.dart';
import 'add_loan_payment_screen.dart';
import 'loan_payment_history_section.dart';
import 'pay_emi_bottom_sheet.dart';

class LoanDetailScreen extends StatefulWidget {
  final LoanModel loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  @override
  void initState() {
    super.initState();
    final loanPaymentProvider = context.read<LoanPaymentProvider>();
    final loanProvider = context.read<LoanProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loanPaymentProvider.loadPayments(widget.loan.id!);
      loanProvider.loadLoanPayments(widget.loan.id!);
    });
  }

  /// The loan as it is NOW. The object passed to this screen goes stale after
  /// a payment, so always prefer the provider's up-to-date copy.
  LoanModel _currentLoan(LoanProvider provider) {
    return provider.loans.firstWhere(
      (l) => l.id == widget.loan.id,
      orElse: () => widget.loan,
    );
  }

  void _openPaySheet(LoanModel loan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PayEmiBottomSheet(
        initialAmount: loan.emiAmount,
        accountLabel: loan.loanType.toUpperCase() == 'GIVEN'
            ? 'Received in account'
            : 'Paid from account',
        onSubmit:
            ({
              required double paymentAmount,
              required String paymentMode,
              String? remarks,
              int? accountId,
            }) => _recordEmi(
              loan,
              paymentAmount,
              paymentMode,
              remarks,
              accountId,
            ),
      ),
    );
  }

  Future<void> _recordEmi(
    LoanModel loan,
    double amount,
    String mode,
    String? remarks,
    int? accountId,
  ) async {
    final loanProvider = context.read<LoanProvider>();
    final payments = context.read<LoanPaymentProvider>();
    final dashboard = context.read<DashboardProvider>();
    try {
      await loanProvider.payEmi(
        loan: loan,
        paymentAmount: amount,
        paymentMode: mode,
        accountId: accountId,
        remarks: (remarks == null || remarks.trim().isEmpty)
            ? null
            : remarks.trim(),
      );
      await payments.loadPayments(loan.id!);
      await loanProvider.loadLoanPayments(loan.id!);
      await dashboard.loadDashboardData();
      if (!mounted) return;
      SnackbarUtils.showSnackbar(context, 'EMI payment recorded successfully');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showSnackbar(context, 'Could not record payment: $e');
    }
  }

  Future<void> _openAddPayment(LoanModel loan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLoanPaymentScreen(loan: loan)),
    );
    if (!mounted) return;
    context.read<LoanPaymentProvider>().loadPayments(loan.id!);
    context.read<LoanProvider>().loadLoanPayments(loan.id!);
  }

  String _prettyType(String type) {
    switch (type.toUpperCase()) {
      case 'BORROWED':
        return 'Borrowed loan';
      case 'GIVEN':
        return 'Given loan';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final loan = _currentLoan(context.watch<LoanProvider>());

    final isClosed = loan.loanStatus.toUpperCase() == 'CLOSED';
    final nextEmi = DateTime.tryParse(loan.nextEmiDate ?? '');
    final isOverdue =
        !isClosed &&
        loan.nextEmiDate != null &&
        LoanAnalyticsUtils.isLoanOverdue(loan.nextEmiDate!);

    final completion = LoanAnalyticsUtils.calculateCompletionPercentage(
      loanAmount: loan.principalAmount,
      outstandingAmount: loan.outstandingAmount,
    ).clamp(0.0, 100.0);

    final remainingEmis = LoanAnalyticsUtils.calculateRemainingEmiCount(
      outstandingAmount: loan.outstandingAmount,
      emiAmount: loan.emiAmount,
    );

    final started = DateTime.tryParse(loan.startDate);
    final hasNotes = (loan.notes ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),
      bottomNavigationBar: _buildActionBar(loan, isClosed),
      body: AppResponsiveContent(
        maxWidth: 800,
        // Padding is applied inside the list so it never clips content.
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          children: [
            // ---- Header: name, status, outstanding, progress, next EMI ----
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.personName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _prettyType(loan.loanType),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LoanStatusBadge(
                          status: isClosed
                              ? 'CLOSED'
                              : isOverdue
                              ? 'OVERDUE'
                              : 'ACTIVE',
                        ),
                      ],
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 12),
                      const LoanWarningBanner(
                        message: 'EMI overdue. Please pay immediately.',
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Outstanding',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(loan.outstandingAmount),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${completion.toStringAsFixed(1)}% repaid',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'of ${CurrencyUtils.formatAmount(loan.principalAmount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    if (isClosed)
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loan fully repaid',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 20,
                            color: isOverdue ? Colors.red : muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Next EMI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            nextEmi == null
                                ? '-'
                                : AppDateUtils.formatDate(nextEmi),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ---- Key numbers ----
            Row(
              children: [
                Expanded(
                  child: LoanAnalyticsCard(
                    title: 'EMI amount',
                    value: CurrencyUtils.formatAmount(loan.emiAmount),
                    icon: Icons.payment,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LoanAnalyticsCard(
                    title: 'Remaining EMIs',
                    value: '$remainingEmis',
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LoanAnalyticsCard(
                    title: 'Interest rate',
                    value: '${loan.interestRate}%',
                    icon: Icons.percent,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LoanAnalyticsCard(
                    title: 'Tenure',
                    value: '${loan.tenureMonths} months',
                    icon: Icons.timelapse,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ---- Other details ----
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _infoRow(
                      'Started',
                      started == null ? '-' : AppDateUtils.formatDate(started),
                    ),
                    if (hasNotes) ...[
                      const Divider(),
                      _infoRow('Notes', loan.notes!.trim()),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---- Payment history (single list) ----
            Consumer<LoanPaymentProvider>(
              builder: (context, provider, _) =>
                  LoanPaymentHistorySection(payments: provider.payments),
            ),
          ],
        ),
      ),
    );
  }

  /// Both payment actions pinned at the bottom (no floating button covering
  /// the content).
  Widget _buildActionBar(LoanModel loan, bool isClosed) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              if (!isClosed) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => _openPaySheet(loan),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pay EMI'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddPayment(loan),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Add payment'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
