// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../services/pdf_service.dart';
import '../../services/quote_item_service.dart';
import '../../services/quote_service.dart';
import '../../services/customer_service.dart';
import 'quote_item_add_page.dart';
import 'quote_edit_page.dart';

class QuoteDetailPage extends StatefulWidget {
  final String quoteId;

  const QuoteDetailPage({super.key, required this.quoteId});

  @override
  State<QuoteDetailPage> createState() => _QuoteDetailPageState();
}

class _QuoteDetailPageState extends State<QuoteDetailPage> {
  final quoteService = QuoteService();
  final itemService = QuoteItemService();
  final customerService = CustomerService();

  Map<String, dynamic>? quote;
  Map<String, dynamic>? customer;
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
    if (quote == null) return;

    customer = await customerService.getCustomerById(quote!["customer_id"]);
    items = await itemService.getItemsByQuote(widget.quoteId);

    setState(() => loading = false);
  }

  void addItem() async {
    final products = await itemService.getAllProducts();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuoteItemAddPage(
          products: products,
          onItemAdded: (item) async {
            await itemService.addQuoteItem(widget.quoteId, item);
          },
        ),
      ),
    );

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ------------------------------
    // HESAPLAR
    // ------------------------------
    final subtotal = (quote!["subtotal"] ?? 0).toDouble();
    final tax = (quote!["tax"] ?? 0).toDouble();
    final discount = (quote!["discount"] ?? 0).toDouble();
    final totalBeforeDiscount = (quote!["total"] ?? 0).toDouble();
    final finalTotal = (quote!["total_after_discount"] ?? totalBeforeDiscount)
        .toDouble();

    final discountType = quote!["discount_type"] ?? "none";
    final discountRate = ((quote!["discount_rate"] ?? 0) * 100).toDouble();
    final discountAmount = (quote!["discount_amount"] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teklif Detayı"),
        actions: [
          // ----------------------
          // ✏️ Teklifi Düzenle
          // ----------------------
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Teklifi Düzenle",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteEditPage(quoteId: quote!['id']),
                ),
              );
              loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Teklifi Kopyala",
            onPressed: () async {
              final newId = await quoteService.duplicateQuote(quote!["id"]);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Teklif başarıyla kopyalandı")),
              );

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuoteDetailPage(quoteId: newId),
                ),
              );
            },
          ),

          // ----------------------
          // PDF OLUŞTUR
          // ----------------------
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pdfService = PdfService();
              final pdfBytes = await pdfService.generateQuotePdf(
                quote: quote!,
                customer: customer!,
                items: items,
              );
              await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addItem,
        icon: const Icon(Icons.add),
        label: const Text("Ürün Ekle"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------
          // DURUM
          // -------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Durum",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: quote!['status'],
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text("Taslak")),
                      DropdownMenuItem(
                        value: 'sent',
                        child: Text("Gönderildi"),
                      ),
                      DropdownMenuItem(
                        value: 'accepted',
                        child: Text("Kabul Edildi"),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text("Reddedildi"),
                      ),
                      DropdownMenuItem(
                        value: 'expired',
                        child: Text("Süresi Doldu"),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;

                      await quoteService.updateQuote(
                        id: quote!['id'],
                        status: v,
                        notes: quote!['notes'],
                        validUntil: quote!['valid_until'] != null
                            ? DateTime.parse(quote!['valid_until'])
                            : null,
                        customerId: quote!['customer_id'],
                      );

                      loadData();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // -------------------------
          // TEKLİF NO / TARİH
          // -------------------------
          Card(
            child: ListTile(
              title: Text("Teklif No: ${quote!['quote_number'] ?? '-'}"),
              subtitle: Text(
                "Tarih: ${quote!['issue_date'].toString().substring(0, 10)}",
              ),
            ),
          ),

          const SizedBox(height: 16),

          // -------------------------
          // MÜŞTERİ BİLGİLERİ
          // -------------------------
          Card(
            child: ListTile(
              title: Text(customer?['company'] ?? customer?['name'] ?? "-"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Yetkili: ${customer?['contact_name'] ?? '-'}"),
                  Text("Telefon: ${customer?['phone'] ?? '-'}"),
                  Text("Adres: ${customer?['address'] ?? '-'}"),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (items.isEmpty) const Text("Bu teklife henüz ürün eklenmedi."),

          for (var item in items)
            Card(
              child: ListTile(
                title: Text(item['description']),
                subtitle: Text(
                  "${item['quantity']} x ${item['unit_price']} ₺ = ${item['total']} ₺",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await itemService.deleteQuoteItem(item["id"]);
                    loadData();
                  },
                ),
              ),
            ),

          const Divider(height: 32),

          // -------------------------
          // TOPLAM SATIRLARI
          // -------------------------
          _totalRow("Ara Toplam", subtotal),
          _totalRow("KDV (%20)", tax),

          if (discountType != "none")
            _totalRow(
              discountType == "percent"
                  ? "İndirim (%${discountRate.toStringAsFixed(0)})"
                  : "İndirim (${discountAmount.toStringAsFixed(0)}₺)",
              -discount,
              red: true,
            ),

          _totalRow("Genel Toplam", totalBeforeDiscount),

          _totalRow("Net Ödenecek", finalTotal, big: true),
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
    final v = value.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: big ? 18 : 16,
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${v.toStringAsFixed(2)} ₺",
            style: TextStyle(
              fontSize: big ? 20 : 16,
              fontWeight: big ? FontWeight.bold : FontWeight.normal,
              color: red ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
