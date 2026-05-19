import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_chart_model.dart';

class MonthlyExpenseChart extends StatelessWidget {
  final List<DashboardChartModel> data;

  const MonthlyExpenseChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(
            data.length,
                (index) {
              final item = data[index];

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.amount,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
