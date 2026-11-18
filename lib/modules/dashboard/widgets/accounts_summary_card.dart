import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../accounts/models/account_model.dart';

/// Home-screen card: total across accounts and the balance of each one.
class AccountsSummaryCard extends StatelessWidget {
  final List<AccountBalance> accounts;
  final double total;

  const AccountsSummaryCard({
    super.key,
    required this.accounts,
    required this.total,
  });

  static const int _maxRows = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final shown = accounts.take(_maxRows).toList();
    final hidden = accounts.length - shown.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total across accounts',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            Text(
              CurrencyUtils.formatAmount(total),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (shown.isNotEmpty) const Divider(height: 20),
            for (final a in shown)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(a.account.type.icon, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.account.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(a.balance),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: a.balance < 0 ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            if (hidden > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+ $hidden more',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
