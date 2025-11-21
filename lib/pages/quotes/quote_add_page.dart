// ignore_for_file: unnecessary_null_comparison, deprecated_member_use, unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/quote_service.dart';
import 'quote_detail_page.dart';

class QuoteAddPage extends StatefulWidget {
  const QuoteAddPage({super.key});

  @override
  State<QuoteAddPage> createState() => _QuoteAddPageState();
}

class _QuoteAddPageState extends State<QuoteAddPage> {
  final _formKey = GlobalKey<FormState>();

  final _customerService = CustomerService();
  final _quoteService = QuoteService();

  List<Map<String, dynamic>> customers = [];
  String? selectedCustomerId;

  final TextEditingController _notesCtrl = TextEditingController();
  DateTime? validUntil;

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    customers = await _customerService.getCustomers();
    setState(() => loading = false);
  }

  Future<void> pickValidUntil() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => validUntil = picked);
    }
  }

  Future<void> saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen müşteri seçin")));
      return;
    }

    setState(() => saving = true);

    try {
      final newQuote = await _quoteService.addQuote(
        customerId: selectedCustomerId!,
        issueDate: DateTime.now(),
        validUntil: validUntil,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (newQuote != null && newQuote["id"] != null) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteDetailPage(quoteId: newQuote["id"]),
          ),
        );
      } else {
        throw Exception("Teklif ID alınamadı.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Teklif kaydedilemedi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Teklif Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // -----------------------
              // MÜŞTERİ SEÇİMİ
              // -----------------------
              DropdownButtonFormField<String>(
                value: selectedCustomerId,
                decoration: const InputDecoration(
                  labelText: "Müşteri Seç",
                  border: OutlineInputBorder(),
                ),
                items: customers
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'],
                        child: Text(
                          (c['company'] ?? c['name'] ?? "").toString(),
                        ),
                      ),
                    )
                    .toList(),
                validator: (v) => v == null ? "Müşteri seçmek zorunlu" : null,
                onChanged: (v) => setState(() => selectedCustomerId = v),
              ),

              const SizedBox(height: 16),

              // -----------------------
              // GEÇERLİLİK TARİHİ
              // -----------------------
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Geçerlilik Tarihi"),
                subtitle: Text(
                  validUntil == null
                      ? "Seçilmedi (opsiyonel)"
                      : validUntil!.toString().substring(0, 10),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: pickValidUntil,
              ),

              const SizedBox(height: 16),

              // -----------------------
              // NOT ALANI
              // -----------------------
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Notlar (opsiyonel)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // -----------------------
              // KAYDET BUTONU
              // -----------------------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveQuote,
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Teklif Oluştur"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
