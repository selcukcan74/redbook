import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'apple_card.dart';

class TrendLineCard extends StatelessWidget {
  final bool isDark;

  const TrendLineCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = List.generate(30, (i) => sin(i / 5) * 3 + 5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appleCard(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Teklif Trendleri",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: data.length.toDouble(),
                minY: 0,
                maxY: 10,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF2563EB),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
