import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../networth/models/net_worth_models.dart';

/// Home-screen card: net worth, change since last month, assets/liabilities.
class NetWorthCard extends StatelessWidget {
  final NetWorthResult? result;
  final VoidCallback onTap;

  const NetWorthCard({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final r = result;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: r == null
              ? Text('Calculating net worth...', style: TextStyle(color: muted))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net worth',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(r.current.netWorth),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: r.current.netWorth < 0 ? Colors.red : null,
                      ),
                    ),
                    if (r.changeSinceLastMonth != null) ...[
                      const SizedBox(height: 2),
                      _change(context, r),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _figure(
                            context,
                            'Assets',
                            r.current.assets,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _figure(
                            context,
                            'Liabilities',
                            r.current.liabilities,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _change(BuildContext context, NetWorthResult r) {
    final change = r.changeSinceLastMonth!;
    final up = change >= 0;
    final color = up ? Colors.green : Colors.red;
    final pct = r.changePercent;
    return Row(
      children: [
        Icon(
          up ? Icons.trending_up : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${up ? '+' : '-'}${CurrencyUtils.formatAmount(change.abs())}'
            '${pct == null ? '' : ' (${pct.abs().toStringAsFixed(1)}%)'}'
            ' since last month',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _figure(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          CurrencyUtils.formatAmount(value),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
