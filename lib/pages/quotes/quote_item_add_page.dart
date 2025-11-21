// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';

class QuoteItemAddPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onItemAdded;

  const QuoteItemAddPage({
    super.key,
    required this.products,
    required this.onItemAdded,
  });

  @override
  State<QuoteItemAddPage> createState() => _QuoteItemAddPageState();
}

class _QuoteItemAddPageState extends State<QuoteItemAddPage> {
  String? selectedProductId;

  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _unitPriceCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: "1");

  @override
  void dispose() {
    _descCtrl.dispose();
    _unitCtrl.dispose();
    _unitPriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void fillProductInfo(String productId) {
    final product = widget.products.firstWhere(
      (p) => p["id"] == productId,
      orElse: () => {},
    );

    // Birim
    _unitCtrl.text = product["unit"]?.toString() ?? "";

    // Fiyat
    _unitPriceCtrl.text = (product["sale_price"] ?? "").toString();

    // Açıklama boşsa ürün adı yaz
    if (_descCtrl.text.trim().isEmpty) {
      _descCtrl.text = product["name"] ?? "";
    }
  }

  void saveItem() {
    if (selectedProductId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lütfen bir ürün seçin")));
      return;
    }

    final quantity = double.tryParse(_qtyCtrl.text.replaceAll(",", ".")) ?? 1;
    final price =
        double.tryParse(_unitPriceCtrl.text.replaceAll(",", ".")) ?? 0;

    final total = quantity * price;

    final item = {
      "product_id": selectedProductId,
      "description": _descCtrl.text.trim(),
      "unit": _unitCtrl.text.trim(),
      "unit_price": price,
      "quantity": quantity,
      "total": total,
    };

    widget.onItemAdded(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;

    return Scaffold(
      appBar: AppBar(title: const Text("Teklife Ürün Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // -----------------------------------
            // ÜRÜN SEÇİMİ
            // -----------------------------------
            DropdownButtonFormField<String>(
              value: selectedProductId,
              decoration: const InputDecoration(
                labelText: "Ürün",
                border: OutlineInputBorder(),
              ),
              items: products
                  .map(
                    (p) => DropdownMenuItem<String>(
                      value: p["id"] as String,
                      child: Text(p["name"] ?? ""),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedProductId = value;
                  if (value != null) fillProductInfo(value);
                });
              },
            ),

            const SizedBox(height: 16),

            // -----------------------------------
            // AÇIKLAMA
            // -----------------------------------
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Açıklama",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------
            // BİRİM
            // -----------------------------------
            TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                labelText: "Birim (m2, adet vb.)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------
            // BİRİM FİYATI
            // -----------------------------------
            TextField(
              controller: _unitPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Birim Fiyat (₺)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------
            // MİKTAR
            // -----------------------------------
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Miktar",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------
            // KAYDET
            // -----------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveItem,
                child: const Text("Ürünü Ekle"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
