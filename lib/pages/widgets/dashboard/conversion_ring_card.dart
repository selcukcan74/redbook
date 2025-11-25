// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'apple_card.dart';
import 'conversion_arc_painter.dart';

class ConversionRingCard extends StatelessWidget {
  final bool isDark;
  final int totalQuotes;
  final int approvedQuotes;

  const ConversionRingCard({
    super.key,
    required this.isDark,
    required this.totalQuotes,
    required this.approvedQuotes,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = totalQuotes == 0
        ? 0.0
        : approvedQuotes / totalQuotes.toDouble();

    final percent = (ratio * 100).clamp(0, 100);

    return Container(
      height: 230,
      padding: const EdgeInsets.all(24),
      decoration: appleCard(isDark),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percent / 100),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1F2430)
                            : const Color(0xFFF1F2F4),
                      ),
                    ),

                    CustomPaint(
                      size: const Size(160, 160),
                      painter: GradientArcPainter(progress: value),
                    ),

                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.25),
                            blurRadius: 35,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "%${percent.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dönüşüm",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 32),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Teklif → Onay Dönüşüm Oranı",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$approvedQuotes onaylandı • $totalQuotes toplam teklif",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.grey[700],
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
