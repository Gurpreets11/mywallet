import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_responsive_content.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/net_worth_models.dart';

/// Net worth: what you own minus what you owe, with a 12-month trend.
class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().loadNetWorth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = context.watch<DashboardProvider>().netWorth;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Net worth')),
      body: AppResponsiveContent(
        maxWidth: 700,
        padding: EdgeInsets.zero,
        child: result == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () =>
                    context.read<DashboardProvider>().loadNetWorth(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headline(context, result),
                    const SizedBox(height: 12),
                    _trendCard(context, result, scheme),
                    const SizedBox(height: 12),
                    _breakdown(context, result.current),
                    const SizedBox(height: 12),
                    Text(
                      'Net worth = money in your accounts + investments + '
                      'money you lent - money you owe. Earlier months are '
                      'worked out from your recorded transactions, investment '
                      'values and loan payments, so they are estimates. '
                      'Savings goals are not added because that money is '
                      'already inside your accounts.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _headline(BuildContext context, NetWorthResult r) {
    final theme = Theme.of(context);
    final change = r.changeSinceLastMonth;
    final up = (change ?? 0) >= 0;
    final color = up ? Colors.green : Colors.red;
    final pct = r.changePercent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your net worth',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyUtils.formatAmount(r.current.netWorth),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: r.current.netWorth < 0 ? Colors.red : null,
              ),
            ),
            if (change != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    up ? Icons.trending_up : Icons.trending_down,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${up ? '+' : '-'}${CurrencyUtils.formatAmount(change.abs())}'
                      '${pct == null ? '' : ' (${pct.abs().toStringAsFixed(1)}%)'}'
                      ' since last month',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _trendCard(
    BuildContext context,
    NetWorthResult r,
    ColorScheme scheme,
  ) {
    final points = r.trend;
    final values = [for (final p in points) p.snapshot.netWorth];
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final pad = math.max((maxV - minV) * 0.15, math.max(maxV.abs(), 1) * 0.02);
    final fmt = DateFormat('MMM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 12 months',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: points.length < 2
                  ? Center(
                      child: Text(
                        'Not enough data yet.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (points.length - 1).toDouble(),
                        minY: minV - pad,
                        maxY: maxV + pad,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: scheme.outlineVariant,
                            strokeWidth: 0.6,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.round();
                                if (i < 0 ||
                                    i >= points.length ||
                                    (points.length > 8 && i.isOdd)) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    fmt.format(points[i].month),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => [
                              for (final s in spots)
                                LineTooltipItem(
                                  '${DateFormat('MMM yyyy').format(points[s.x.round()].month)}\n'
                                  '${CurrencyUtils.formatAmount(s.y)}',
                                  const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < points.length; i++)
                                FlSpot(i.toDouble(), values[i]),
                            ],
                            isCurved: false,
                            barWidth: 2.5,
                            color: scheme.primary,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: scheme.primary.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breakdown(BuildContext context, NetWorthSnapshot s) {
    final theme = Theme.of(context);

    Widget row(IconData icon, String label, double value, {Color? color}) =>
        ListTile(
          dense: true,
          leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          title: Text(label),
          trailing: Text(
            CurrencyUtils.formatAmount(value),
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        );

    Widget header(String title, double total, Color color) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            CurrencyUtils.formatAmount(total),
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );

    return Card(
      child: Column(
        children: [
          header('Assets', s.assets, Colors.green),
          row(
            Icons.account_balance_wallet_outlined,
            'Cash and accounts',
            s.cash,
            color: s.cash < 0 ? Colors.red : null,
          ),
          row(Icons.trending_up_rounded, 'Investments', s.investments),
          row(
            Icons.arrow_circle_up_outlined,
            'Money lent to others',
            s.receivable,
          ),
          const Divider(height: 1),
          header('Liabilities', s.liabilities, Colors.red),
          row(Icons.arrow_circle_down_outlined, 'Loans you owe', s.liabilities),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
