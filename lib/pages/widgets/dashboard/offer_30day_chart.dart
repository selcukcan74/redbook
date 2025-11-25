import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'apple_card.dart';

class Offer30DayChart extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> last30days;

  const Offer30DayChart({
    super.key,
    required this.isDark,
    required this.last30days,
  });

  @override
  Widget build(BuildContext context) {
    if (last30days.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: appleCard(isDark),
        child: Text(
          "Son 30 gün için teklif bulunmuyor.",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    int maxCount = 0;

    for (int i = 0; i < last30days.length; i++) {
      final count = (last30days[i]["count"] as num).toDouble();
      maxCount = max(maxCount, count.toInt());
      spots.add(FlSpot(i.toDouble(), count));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appleCard(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Oluşturulan Teklifler (Son 30 Gün)",
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
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: (maxCount * 1.3).toDouble(),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
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
