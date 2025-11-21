// ignore_for_file: deprecated_member_use, unused_import, use_super_parameters

import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../services/quote_service.dart';

import '../products/products_page.dart';
import '../products/product_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final productService = ProductService();
  final customerService = CustomerService();
  final quoteService = QuoteService();

  int totalProducts = 0;
  int totalCustomers = 0;
  int totalQuotes = 0;

  List<Map<String, dynamic>> lastProducts = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    setState(() => loading = true);

    // Ürün verileri
    final products = await productService.getProducts();
    totalProducts = products.length;

    // Müşteri verileri
    final customers = await customerService.getCustomers();
    totalCustomers = customers.length;

    // Teklif verileri
    final quotes = await quoteService.getQuotes();
    totalQuotes = quotes.length;

    // Son 5 ürün
    lastProducts = products.take(5).toList();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Dashboard")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Genel Bakış",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // ---- STAT CARDS ----
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          title: "Ürünler",
                          value: totalProducts.toString(),
                          icon: Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          title: "Müşteriler",
                          value: totalCustomers.toString(),
                          icon: Icons.people,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _statCard(
                    title: "Teklifler",
                    value: totalQuotes.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),

                  const SizedBox(height: 30),

                  // ---- LAST PRODUCTS ----
                  const Text(
                    "Son Eklenen Ürünler",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (lastProducts.isEmpty) const Text("Hiç ürün yok."),

                  for (var p in lastProducts)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: p["image_url"] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  p["image_url"],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text(p["name"]),
                        subtitle: Text(
                          "${p["sale_price"]} ₺ - ${p["unit"]}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(productId: p["id"]),
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

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}
