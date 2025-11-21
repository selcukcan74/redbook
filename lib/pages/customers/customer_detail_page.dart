import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import 'customer_edit_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final _service = CustomerService();
  Map<String, dynamic>? customer;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCustomer();
  }

  Future<void> loadCustomer() async {
    customer = await _service.getCustomer(widget.customerId);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (customer == null) {
      return const Scaffold(body: Center(child: Text("Müşteri bulunamadı.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(customer!["name"]),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerEditPage(customerId: customer!["id"]),
                ),
              );
              loadCustomer();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              title: const Text("Ad Soyad"),
              subtitle: Text(customer!["name"]),
            ),
            ListTile(
              title: const Text("Firma"),
              subtitle: Text(customer!["company"] ?? "-"),
            ),
            ListTile(
              title: const Text("Telefon"),
              subtitle: Text(customer!["phone"] ?? "-"),
            ),
            ListTile(
              title: const Text("E-mail"),
              subtitle: Text(customer!["email"] ?? "-"),
            ),
            ListTile(
              title: const Text("Adres"),
              subtitle: Text(customer!["address"] ?? "-"),
            ),
          ],
        ),
      ),
    );
  }
}
