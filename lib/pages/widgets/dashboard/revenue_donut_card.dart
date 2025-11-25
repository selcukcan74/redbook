import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'apple_card.dart';

class RevenueDonutCard extends StatelessWidget {
  final bool isDark;
  final double monthlyRevenue;

  const RevenueDonutCard({
    super.key,
    required this.isDark,
    required this.monthlyRevenue,
  });

  @override
  Widget build(BuildContext context) {
    const target = 100000;
    final ratio = (monthlyRevenue / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appleCard(isDark),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 42,
                sections: [
                  PieChartSectionData(
                    value: ratio * 100,
                    color: const Color(0xFF2563EB),
                    radius: 18,
                  ),
                  PieChartSectionData(
                    value: 100 - ratio * 100,
                    color: const Color(0xFFD1D5DB),
                    radius: 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₺${monthlyRevenue.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Aylık Gelir (Onaylanan Teklifler)",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
