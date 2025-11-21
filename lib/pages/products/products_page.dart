// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import 'product_add_page.dart';
import 'product_detail_page.dart';
import 'product_edit_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsPage> {
  final _service = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() => loading = true);
    _products = await _service.getProducts();
    setState(() => loading = false);
  }

  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    loadProducts();
  }

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
            // ------------------------------------------
            // BAŞLIK + ÜRÜN EKLE BUTONU
            // ------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ürünler", style: TextStyle(fontSize: 22)),

                _buildAddProductButton(context, theme),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------------------
            //   ÜRÜN LİSTESİ
            // ---------------------------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                  ? const Center(child: Text("Henüz ürün eklenmemiş"))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // ÜRÜN FOTO
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p["image_url"] != null
                                    ? Image.network(
                                        p["image_url"],
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 55,
                                        height: 55,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 28,
                                        ),
                                      ),
                              ),

                              const SizedBox(width: 16),

                              // ÜRÜN BİLGİSİ
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailPage(
                                          productId: p["id"],
                                        ),
                                      ),
                                    );

                                    if (result == true) loadProducts();
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p["name"] ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${p["sale_price"] ?? 0} ₺ — ${p["unit"] ?? "-"}",
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // DÜZENLE / SİL BUTONLARI
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductEditPage(
                                            productId: p["id"],
                                          ),
                                        ),
                                      );

                                      if (result == true) loadProducts();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => deleteProduct(p["id"]),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildAddProductButton(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductAddPage()),
        );
        if (result == true) loadProducts();
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
              "Ürün Ekle",
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
