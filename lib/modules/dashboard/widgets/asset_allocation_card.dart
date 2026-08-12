import 'package:flutter/material.dart';
import 'package:mywallet/core/widgets/vertical_spacing.dart';

import '../../../core/utils/currency_utils.dart';

class AssetAllocationCard extends StatelessWidget {
  final List<Map<String, dynamic>> allocations;

  const AssetAllocationCard({super.key, required this.allocations});

  @override
  Widget build(BuildContext context) {
    final double total = allocations.fold(
      0,
      (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0),
    );

    return Column(
      children: [
        const Row(
          children: [
            Icon(Icons.pie_chart),
            SizedBox(width: 8),
            Text(
              'Asset Allocation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        VerticalSpacing(height: 14),
        Card(
          color: Colors.white,

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...allocations.map((item) {
                  final double value =
                      ((item['total'] as num?)?.toDouble() ?? 0);
                  final double percent = total == 0 ? 0 : (value / total) * 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['investment_type']),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: percent / 100),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(CurrencyUtils.formatAmount(value)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
