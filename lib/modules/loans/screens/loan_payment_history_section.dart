import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../models/loan_payment_model.dart';

class LoanPaymentHistorySection extends StatelessWidget {
  final List<LoanPaymentModel> payments;

  const LoanPaymentHistorySection({super.key, required this.payments});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Payment history',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (payments.isNotEmpty)
                  Text(
                    '${payments.length} payment${payments.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No EMI payments yet',
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ),
              )
            else
              for (var i = 0; i < payments.length; i++) ...[
                if (i > 0) const Divider(),
                _row(theme, muted, payments[i]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, Color muted, LoanPaymentModel payment) {
    final date = DateTime.tryParse(payment.paymentDate);
    final meta = [
      if (date != null) AppDateUtils.formatDate(date),
      if (payment.paymentMode.isNotEmpty) payment.paymentMode,
    ].join(' • ');
    final remarks = (payment.remarks ?? '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.check_rounded,
              size: 18,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.formatAmount(payment.paymentAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                if (remarks.isNotEmpty)
                  Text(
                    remarks,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
