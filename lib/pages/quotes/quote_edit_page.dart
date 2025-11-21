// ignore_for_file: unused_local_variable, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/quote_service.dart';

class QuoteEditPage extends StatefulWidget {
  final String quoteId;

  const QuoteEditPage({super.key, required this.quoteId});

  @override
  State<QuoteEditPage> createState() => _QuoteEditPageState();
}

class _QuoteEditPageState extends State<QuoteEditPage> {
  final customerService = CustomerService();
  final quoteService = QuoteService();

  List<Map<String, dynamic>> customers = [];
  Map<String, dynamic>? quote;

  String? selectedCustomerId;
  DateTime? selectedValidDate;
  final notesController = TextEditingController();

  // İndirim alanları
  String discountType = "none"; // none / percent / fixed
  final discountRateController = TextEditingController(); // Yüzde
  final discountAmountController = TextEditingController(); // Sabit tutar

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    // Müşteriler
    customers = await customerService.getCustomers();

    // Teklif bilgileri
    quote = await quoteService.getQuoteById(widget.quoteId);

    if (quote == null) return;

    // Form doldur
    selectedCustomerId = quote!["customer_id"];
    notesController.text = quote!["notes"] ?? "";

    if (quote!["valid_until"] != null) {
      selectedValidDate = DateTime.parse(quote!["valid_until"]);
    }

    // İndirimi forma yükle
    discountType = quote!["discount_type"] ?? "none";
    discountRateController.text = (quote!["discount_rate"] ?? 0).toString();
    discountAmountController.text = (quote!["discount_amount"] ?? 0).toString();

    setState(() => loading = false);
  }

  Future<void> save() async {
    final double parsedRate = double.tryParse(discountRateController.text) ?? 0;

    final double parsedAmount =
        double.tryParse(discountAmountController.text) ?? 0;

    await quoteService.updateQuote(
      id: widget.quoteId,
      customerId: selectedCustomerId,
      notes: notesController.text.isEmpty ? null : notesController.text,
      validUntil: selectedValidDate,
      status: quote!["status"],

      // İndirim ile ilgili parametreler
      discountType: discountType,
      discountRate: discountType == "percent"
          ? (double.tryParse(discountRateController.text) ?? 0) / 100
          : 0,

      discountAmount: discountType == "fixed"
          ? double.tryParse(discountAmountController.text) ?? 0
          : 0,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Teklif Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // -----------------------------
            // Müşteri
            // -----------------------------
            const Text(
              "Müşteri",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCustomerId,
              decoration: const InputDecoration(
                labelText: "Müşteri Seç",
                border: OutlineInputBorder(),
              ),
              items: customers.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem<String>(
                  value: c["id"].toString(),
                  child: Text((c["company"] ?? c["name"] ?? "-").toString()),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => selectedCustomerId = v);
              },
            ),

            const SizedBox(height: 20),

            // -----------------------------
            // Geçerlilik Tarihi
            // -----------------------------
            const Text(
              "Geçerlilik Tarihi",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                  initialDate: selectedValidDate ?? DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedValidDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedValidDate == null
                      ? "Tarih Seç"
                      : selectedValidDate.toString().substring(0, 10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------
            // Notlar
            // -----------------------------
            const Text("Notlar", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Not ekleyebilirsiniz (opsiyonel)",
              ),
            ),

            const SizedBox(height: 32),

            // -----------------------------
            // İNDİRİM ALANLARI
            // -----------------------------
            const Divider(),
            const Text(
              "İndirim",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // İndirim Tipi
            DropdownButtonFormField<String>(
              value: discountType,
              decoration: const InputDecoration(
                labelText: "İndirim Türü",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "none", child: Text("İndirim Yok")),
                DropdownMenuItem(value: "percent", child: Text("% İndirim")),
                DropdownMenuItem(value: "fixed", child: Text("Sabit İndirim")),
              ],
              onChanged: (v) {
                setState(() => discountType = v!);
              },
            ),

            const SizedBox(height: 16),

            if (discountType == "percent")
              TextField(
                controller: discountRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "% İndirim Oranı (örn: 10)",
                  border: OutlineInputBorder(),
                ),
              ),

            if (discountType == "percent") const SizedBox(height: 16),

            if (discountType == "fixed")
              TextField(
                controller: discountAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "İndirim Tutarı (₺)",
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 32),

            // -----------------------------
            // Kaydet
            // -----------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: save,
                child: const Text("Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
