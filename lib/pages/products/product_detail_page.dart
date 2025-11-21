import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import 'product_edit_page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService _service = ProductService();

  Map<String, dynamic>? product;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    product = await _service.getProduct(widget.productId);
    setState(() => loading = false);
  }

  Future<void> deleteProduct() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ürünü Sil"),
        content: const Text("Bu ürünü silmek istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteProduct(widget.productId);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (product == null) {
      return const Scaffold(body: Center(child: Text("Ürün bulunamadı.")));
    }

    final p = product!;
    return Scaffold(
      appBar: AppBar(
        title: Text(p["name"]),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductEditPage(productId: p["id"]),
                ),
              );
              if (result == true) loadProduct();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: deleteProduct,
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // IMAGE
          Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
            ),
            child: p["image_url"] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(p["image_url"], fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(Icons.image_not_supported, size: 70),
                  ),
          ),

          const SizedBox(height: 20),

          Text(
            p["name"],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Satış Fiyatı: ${p["sale_price"]} ₺",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Alış Fiyatı: ${p["purchase_price"]} ₺",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text("Birim: ${p["unit"]}"),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Açıklama",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            p["description"]?.toString().isNotEmpty == true
                ? p["description"]
                : "-",
          ),
        ],
      ),
    );
  }
}
