import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyExpenseChart
    extends StatelessWidget {
  const MonthlyExpenseChart({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          borderData:
          FlBorderData(
            show: false,
          ),
          gridData:
          FlGridData(
            show: true,
          ),
          titlesData:
          FlTitlesData(
            leftTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: true,
              ),
            ),
            bottomTitles:
            const AxisTitles(
              sideTitles:
              SideTitles(
                showTitles: true,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              spots: const [
                FlSpot(0, 1000),
                FlSpot(1, 2000),
                FlSpot(2, 1500),
                FlSpot(3, 3000),
                FlSpot(4, 2800),
              ],
            ),
          ],
        ),
      ),
    );
  }
}