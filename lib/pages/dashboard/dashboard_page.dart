// lib/pages/dashboard/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:redbook/pages/dashboard/dashboard_service.dart';

// Widgets
import 'package:redbook/pages/widgets/dashboard/build_analytics_grid.dart';
import 'package:redbook/pages/widgets/dashboard/build_stat_grid.dart';
import 'package:redbook/pages/widgets/dashboard/conversion_ring_card.dart';
import 'package:redbook/pages/widgets/dashboard/latest_activities_table.dart';
import 'package:redbook/pages/widgets/dashboard/offer_30day_chart.dart';
import 'package:redbook/pages/widgets/dashboard/revenue_donut_card.dart';
import 'package:redbook/pages/widgets/dashboard/stat_card.dart';
import 'package:redbook/pages/widgets/dashboard/trend_line_card.dart';

class DashboardPage extends StatefulWidget {
  final bool isDark;
  const DashboardPage({super.key, required this.isDark});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool get isDark => widget.isDark;

  final dashboardService = DashboardService();

  int totalProducts = 0;
  int totalCustomers = 0;
  int totalQuotes = 0;
  int approvedQuotes = 0;

  double monthlyRevenue = 0.0;

  List<Map<String, dynamic>> last30days = [];
  List<Map<String, dynamic>> latestActivities = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      setState(() => loading = true);

      totalProducts = await dashboardService.getTotalProducts();
      totalCustomers = await dashboardService.getTotalCustomers();
      totalQuotes = await dashboardService.getTotalQuotes();
      approvedQuotes = await dashboardService.getApprovedQuotes();
      monthlyRevenue = await dashboardService.getMonthlyRevenue();
      last30days = await dashboardService.getLast30DaysOffers();
      latestActivities = await dashboardService.getLatestQuoteActivities();
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // HEADER
            // ---------------------------------------------------------
            Text(
              "Genel Bakış",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------------------------------------------------
            // STAT CARDS
            // ---------------------------------------------------------
            BuildStatGrid(
              children: [
                StatCard(
                  title: "Ürünler",
                  value: totalProducts.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                  isDark: isDark,
                ),
                StatCard(
                  title: "Müşteriler",
                  value: totalCustomers.toString(),
                  icon: Icons.people,
                  color: Colors.green,
                  isDark: isDark,
                ),
                StatCard(
                  title: "Tüm Teklifler",
                  value: totalQuotes.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                  isDark: isDark,
                ),
                StatCard(
                  title: "Onaylanan Teklifler",
                  value: approvedQuotes.toString(),
                  icon: Icons.verified,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ---------------------------------------------------------
            // ANALYTICS
            // ---------------------------------------------------------
            BuildAnalyticsGrid(
              children: [
                RevenueDonutCard(
                  isDark: isDark,
                  monthlyRevenue: monthlyRevenue,
                ),
                TrendLineCard(isDark: isDark),
                Offer30DayChart(isDark: isDark, last30days: last30days),
                ConversionRingCard(
                  isDark: isDark,
                  totalQuotes: totalQuotes,
                  approvedQuotes: approvedQuotes,
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ---------------------------------------------------------
            // LATEST ACTIVITIES HEADER
            // ---------------------------------------------------------
            Text(
              "Son Teklif Hareketleri",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------------------------------------------------
            // LATEST ACTIVITIES TABLE
            // ---------------------------------------------------------
            LatestActivitiesTable(isDark: isDark, activities: latestActivities),
          ],
        ),
      ),
    );
  }
}
