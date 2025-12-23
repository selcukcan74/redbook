// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_import, unnecessary_import, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:redbook/pages/quotes/revision_compare_page.dart';
import 'package:redbook/pages/quotes/revision_list_page.dart';
import 'package:redbook/services/quote_pdf_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/quote_item_service.dart';
import '../../services/quote_service.dart';
import '../../services/customer_service.dart';
import '../../services/settings_service.dart';

import 'quote_item_add_page.dart';
import 'quote_edit_page.dart';

class QuoteDetailPage extends StatefulWidget {
  final String quoteId;

  const QuoteDetailPage({super.key, required this.quoteId});

  @override
  State<QuoteDetailPage> createState() => _QuoteDetailPageState();
}

class _QuoteDetailPageState extends State<QuoteDetailPage> {
  static const verifyBaseUrl =
      "https://selcukcan74.github.io/redbook-verify/#/verify";

  final quoteService = QuoteService();
  final itemService = QuoteItemService();
  final customerService = CustomerService();
  final settingsService = SettingsService();

  Map<String, dynamic>? quote;
  Map<String, dynamic>? customer;
  Map<String, dynamic>? settings;
  List<Map<String, dynamic>> items = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    quote = await quoteService.getQuoteById(widget.quoteId);
    if (quote == null) {
      setState(() => loading = false);
      return;
    }

    final customerId = quote!['customer_id']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      customer = await customerService.getCustomerById(customerId);
    }

    items = await itemService.getItemsByQuote(widget.quoteId);
    settings = await settingsService.getSettings();

    setState(() => loading = false);
  }

  // ---------------------------------------------------------
  // APPBAR ACTION BUTONU
  // ---------------------------------------------------------
  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Future<void> Function() onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quote == null || customer == null) {
      return const Scaffold(body: Center(child: Text("Teklif bulunamadı")));
    }

    final quoteIdStr = quote!['id'].toString();
    final verifyUrl = "$verifyBaseUrl?quoteId=$quoteIdStr";

    final subtotal = (quote!['subtotal'] ?? 0).toDouble();
    final discount = (quote!['discount'] ?? 0).toDouble();
    final tax = (quote!['tax_amount'] ?? quote!['tax'] ?? 0).toDouble();

    final taxableBase = subtotal - discount;
    final grandTotal = taxableBase + tax;
    final netPayable =
        (quote!['total_after_discount'] ?? grandTotal).toDouble();

    final issueDate =
        quote!['issue_date']?.toString().substring(0, 10) ?? "-";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teklif Detayı"),
        actions: [
          _actionButton(
            icon: Icons.edit,
            tooltip: "Teklifi Düzenle",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteEditPage(quoteId: quoteIdStr),
                ),
              );
              await loadData();
            },
          ),

          _actionButton(
            icon: Icons.picture_as_pdf,
            tooltip: "PDF Oluştur / Paylaş",
            onTap: () async {
              if (settings == null) return;

              await QuotePdfService.generateAndShare(
                quote: quote!,
                customer: customer!,
                items: items,
                settings: settings!,
              );
            },
          ),

          _actionButton(
            icon: Icons.verified,
            tooltip: "Teklifi Doğrula",
            onTap: () async {
              final uri = Uri.parse(verifyUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),

          _actionButton(
            icon: Icons.history,
            tooltip: "Revizyonlar",
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RevisionListPage(quoteId: widget.quoteId),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final products = await itemService.getAllProducts();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuoteItemAddPage(
                products: products,
                onItemAdded: (_) async {
                  await loadData();
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Ürün Ekle"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text("Teklif No: ${quote!['quote_number'] ?? '-'}"),
              subtitle: Text("Tarih: $issueDate"),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              title: Text(customer!['company'] ?? '-'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yetkili: ${customer!['name'] ?? '-'}"),
                  Text("Telefon: ${customer!['phone'] ?? '-'}"),
                  Text("Adres: ${customer!['address'] ?? '-'}"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Ürünler",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("Ürün eklenmedi"),
            ),

          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item['description'] ?? ''),
                subtitle: Text(
                  "${item['quantity']} x ${item['unit_price']} ₺ = ${item['total']} ₺",
                ),
              ),
            ),

          const Divider(height: 32),

          _totalRow("Ara Toplam", subtotal),
          _totalRow("İndirim", -discount, red: true),
          _totalRow("Vergi Matrahı", taxableBase),
          _totalRow("KDV", tax),
          const SizedBox(height: 8),
          _totalRow("Genel Toplam", grandTotal, big: true),
          _totalRow("Net Ödenecek", netPayable, big: true),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    num value, {
    bool big = false,
    bool red = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: big ? 18 : 15,
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${value.toStringAsFixed(2)} ₺",
            style: TextStyle(
              fontSize: big ? 20 : 15,
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
              color: red ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
