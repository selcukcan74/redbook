// ignore_for_file: unnecessary_non_null_assertion

import 'package:flutter/material.dart';
import 'package:redbook/pages/quotes/revision_compare_page.dart';
import 'package:redbook/services/quote_pdf_service.dart';
import 'package:redbook/services/quote_service.dart';
import 'package:redbook/services/settings_service.dart';

class RevisionDetailPage extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final int revisionNumber;

  const RevisionDetailPage({
    super.key,
    required this.snapshot,
    required this.revisionNumber,
  });

  @override
  Widget build(BuildContext context) {
    final quote = snapshot["quote"] ?? {};
    final items = List<Map<String, dynamic>>.from(snapshot["items"] ?? []);
    final customer = snapshot["customer"] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text("Revizyon $revisionNumber"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final settings = await SettingsService().getSettings();
              await QuotePdfService.shareRevisionPdf(
                snapshot: snapshot,
                settings: settings!,
                revisionNumber: revisionNumber,
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.compare),
            onPressed: () async {
              final current = await QuoteService().getQuoteSnapshot(
                snapshot["quote"]["id"],
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RevisionComparePage(revision: snapshot, current: current),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () async {
              await QuoteService().restoreFromRevision(snapshot["quote"]["id"]);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Revizyon geri yüklendi")),
              );
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------
          // TEKLİF BİLGİLERİ
          // -------------------------
          Card(
            child: ListTile(
              title: Text("Teklif No: ${quote['quote_number']}"),
              subtitle: Text(
                "Tarih: ${quote['issue_date']?.toString().substring(0, 10) ?? '-'}",
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -------------------------
          // MÜŞTERİ BİLGİLERİ
          // -------------------------
          Card(
            child: ListTile(
              title: Text((customer['company'] ?? '-').toString()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yetkili: ${customer['name'] ?? '-'}"),
                  Text("Telefon: ${customer['phone'] ?? '-'}"),
                  Text("E-posta: ${customer['email'] ?? '-'}"),
                  Text("Adres: ${customer['address'] ?? '-'}"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -------------------------
          // ÜRÜN LİSTESİ
          // -------------------------
          const Text(
            "Ürünler",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          if (items.isEmpty) const Text("Ürün yok"),

          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item["description"] ?? "-"),
                subtitle: Text(
                  "${item['quantity']} x ${item['unit_price']} ₺ = ${item['total']} ₺",
                ),
              ),
            ),
        ],
      ),
    );
  }
}
