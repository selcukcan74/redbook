// ignore_for_file: unused_local_variable, deprecated_member_use, unused_import, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/quote_service.dart';
import 'quote_add_page.dart';
import 'quote_detail_page.dart';

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  final QuoteService _quoteService = QuoteService();

  bool loading = true;

  List<Map<String, dynamic>> quotes = [];
  List<Map<String, dynamic>> filteredQuotes = [];

  String selectedStatus = "all";
  String searchQuery = "";
  String sortOption = "date_desc";

  @override
  void initState() {
    super.initState();
    loadQuotes();
  }

  // --------------------------------------------------------
  // TEKLİFLERİ SÜPERLOAD (Filtre + Arama + Sıralama)
  // --------------------------------------------------------
  Future<void> loadQuotes() async {
    setState(() => loading = true);

    if (selectedStatus == "all") {
      quotes = await _quoteService.getQuotes();
    } else {
      quotes = await _quoteService.getQuotesByStatus(selectedStatus);
    }

    applyFilters();

    setState(() => loading = false);
  }

  // --------------------------------------------------------
  // ARAMA + SIRALAMA LOGICS
  // --------------------------------------------------------
  void applyFilters() {
    List<Map<String, dynamic>> temp = [...quotes];

    // -----------------------------
    // ARAMA
    // -----------------------------
    if (searchQuery.isNotEmpty) {
      temp = temp.where((q) {
        final customer = q["customers"] ?? {};
        final name = (customer["company"] ?? customer["name"] ?? "")
            .toString()
            .toLowerCase();
        final quoteNumber = (q["quote_number"] ?? "").toString().toLowerCase();

        return name.contains(searchQuery.toLowerCase()) ||
            quoteNumber.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Net toplam
    double getTotal(Map q) {
      return (q["total_after_discount"] ?? q["total"] ?? 0).toDouble();
    }

    // -----------------------------
    // SIRALAMA
    // -----------------------------
    temp.sort((a, b) {
      switch (sortOption) {
        case "date_desc":
          return DateTime.parse(
            b["created_at"],
          ).compareTo(DateTime.parse(a["created_at"]));

        case "date_asc":
          return DateTime.parse(
            a["created_at"],
          ).compareTo(DateTime.parse(b["created_at"]));

        case "amount_desc":
          return getTotal(b).compareTo(getTotal(a));

        case "amount_asc":
          return getTotal(a).compareTo(getTotal(b));

        case "customer_asc":
          return (a["customers"]?["company"] ?? a["customers"]?["name"] ?? "")
              .toString()
              .compareTo(
                (b["customers"]?["company"] ?? b["customers"]?["name"] ?? "")
                    .toString(),
              );
      }
      return 0;
    });

    filteredQuotes = temp;
  }

  // --------------------------------------------------------
  // DURUM BADGE TASARIMI
  // --------------------------------------------------------
  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'draft':
        color = Colors.grey;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'expired':
        color = Colors.orange;
        break;
      default:
        color = Colors.black45;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // İNDİRİM BADGE
  // --------------------------------------------------------
  Widget _discountBadge(Map q) {
    final type = q["discount_type"] ?? "none";
    if (type == "none") return const SizedBox.shrink();

    final rate = ((q["discount_rate"] ?? 0) * 100).toDouble();
    final amount = (q["discount_amount"] ?? 0).toDouble();

    String text = "";

    if (type == "percent") {
      text = "%${rate.toStringAsFixed(0)} İNDİRİM";
    } else if (type == "fixed") {
      text = "${amount.toStringAsFixed(0)}₺ İNDİRİM";
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // SAYFA TASARIMI
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Teklifler", style: TextStyle(fontSize: 22)),
                _buildAddQuotesButton(context, theme),
              ],
            ),

            const SizedBox(height: 16),

            // ARAMA ALANI
            TextField(
              decoration: const InputDecoration(
                hintText: "Tekliflerde ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                searchQuery = value;
                applyFilters();
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // FİLTRE + SIRALAMA
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Duruma Göre Filtre",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("Tümü")),
                      DropdownMenuItem(value: "draft", child: Text("Taslak")),
                      DropdownMenuItem(
                        value: "sent",
                        child: Text("Gönderildi"),
                      ),
                      DropdownMenuItem(
                        value: "accepted",
                        child: Text("Kabul Edildi"),
                      ),
                      DropdownMenuItem(
                        value: "rejected",
                        child: Text("Reddedildi"),
                      ),
                      DropdownMenuItem(
                        value: "expired",
                        child: Text("Süresi Doldu"),
                      ),
                    ],
                    onChanged: (value) {
                      selectedStatus = value!;
                      loadQuotes();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                PopupMenuButton(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    sortOption = value;
                    applyFilters();
                    setState(() {});
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: "date_desc",
                      child: Text("Tarih: Yeni → Eski"),
                    ),
                    PopupMenuItem(
                      value: "date_asc",
                      child: Text("Tarih: Eski → Yeni"),
                    ),
                    PopupMenuItem(
                      value: "amount_desc",
                      child: Text("Tutar: Yüksek → Düşük"),
                    ),
                    PopupMenuItem(
                      value: "amount_asc",
                      child: Text("Tutar: Düşük → Yüksek"),
                    ),
                    PopupMenuItem(
                      value: "customer_asc",
                      child: Text("Müşteri: A → Z"),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // TEKLİF LİSTESİ
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredQuotes.isEmpty
                  ? const Center(child: Text("Hiç teklif bulunamadı."))
                  : ListView.builder(
                      itemCount: filteredQuotes.length,
                      itemBuilder: (context, index) {
                        final q = filteredQuotes[index];
                        final customer = q["customers"] ?? {};

                        final netTotal =
                            (q["total_after_discount"] ?? q["total"] ?? 0)
                                .toDouble();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              q["quote_number"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customer["company"] ??
                                      customer["name"] ??
                                      "-",
                                ),
                                Text(
                                  "Net Toplam: ${netTotal.toStringAsFixed(2)} ₺",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                _discountBadge(q),

                                const SizedBox(height: 6),
                                _statusBadge(q["status"] ?? "draft"),
                              ],
                            ),

                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      QuoteDetailPage(quoteId: q["id"]),
                                ),
                              );
                              loadQuotes();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // TEKLİF OLUŞTUR BUTONU
  // --------------------------------------------------------
  Widget _buildAddQuotesButton(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuoteAddPage()),
        );
        if (result == true) loadQuotes();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.add, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              "Teklif Oluştur",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
