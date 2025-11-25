import 'package:flutter/material.dart';
import 'status_label.dart';

class LatestActivitiesTable extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> activities;

  const LatestActivitiesTable({
    super.key,
    required this.isDark,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF1C1F27) : const Color(0xFFE5E7EB);

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13161C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Text(
          "Henüz teklif hareketi yok.",
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13161C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Teklif")),
          DataColumn(label: Text("Müşteri")),
          DataColumn(label: Text("Tutar")),
          DataColumn(label: Text("Durum")),
        ],
        rows: activities.map((q) {
          final quote = q["quote_number"] ?? "-";
          final total = q["total"] ?? 0;
          final status = q["status"] ?? "-";
          final customer = q["customers"]?["name"] ?? "-";

          return DataRow(
            cells: [
              DataCell(Text(quote.toString())),
              DataCell(Text(customer.toString())),
              DataCell(Text("₺${(total as num).toStringAsFixed(0)}")),
              DataCell(Text(statusLabel(status))),
            ],
          );
        }).toList(),
      ),
    );
  }
}
