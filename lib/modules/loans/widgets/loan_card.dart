import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/loan_model.dart';
import '../utils/loan_analytics_utils.dart';
import 'loan_status_badge.dart';

class LoanCard extends StatelessWidget {
  final LoanModel loan;

  final VoidCallback onTap;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final bool isBorrowed = loan.loanType == 'BORROWED';
    final status = loan.loanStatus.toUpperCase();
    final isClosed = status == 'CLOSED';
    final isOverdue = status == 'OVERDUE';

    final progress =
        (LoanAnalyticsUtils.calculateCompletionPercentage(
                  loanAmount: loan.principalAmount,
                  outstandingAmount: loan.outstandingAmount,
                ) /
                100)
            .clamp(0.0, 1.0);

    final nextEmi = DateTime.tryParse(loan.nextEmiDate ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isBorrowed
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isBorrowed ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 18,
                      color: isBorrowed ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loan.personName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isOverdue || isClosed) LoanStatusBadge(status: status),
                  PopupMenuButton<String>(
                    tooltip: 'Loan actions',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Icon(Icons.more_vert, size: 20, color: muted),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _stat(
                          theme,
                          'Outstanding',
                          CurrencyUtils.formatAmount(loan.outstandingAmount),
                        ),
                        _stat(
                          theme,
                          'EMI',
                          CurrencyUtils.formatAmount(loan.emiAmount),
                        ),
                        if (!isClosed && nextEmi != null)
                          _stat(
                            theme,
                            'Next EMI',
                            AppDateUtils.formatDate(nextEmi),
                            valueColor: isOverdue ? Colors.red : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% repaid',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
