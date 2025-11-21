// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import 'customer_add_page.dart';
import 'customer_detail_page.dart';

class CustomersListPage extends StatefulWidget {
  const CustomersListPage({Key? key}) : super(key: key);

  @override
  State<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends State<CustomersListPage> {
  final _service = CustomerService();
  List<Map<String, dynamic>> _customers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    setState(() => loading = true);
    _customers = await _service.getCustomers();
    setState(() => loading = false);
  }

  Future<void> deleteCustomer(String id) async {
    await _service.deleteCustomer(id);
    loadCustomers();
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
            // BAŞLIK + MÜŞTERİ EKLE BUTONU
            // ------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Müşteriler", style: TextStyle(fontSize: 22)),

                _buildAddButton(context, theme),
              ],
            ),

            const SizedBox(height: 16),

            // ------------------------------------------
            // MÜŞTERİ LİSTESİ
            // ------------------------------------------
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _customers.isEmpty
                  ? const Center(child: Text("Henüz müşteri yok"))
                  : ListView.builder(
                      itemCount: _customers.length,
                      itemBuilder: (_, i) {
                        final c = _customers[i];

                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white.withOpacity(0.65),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),

                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.15),
                              child: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                              ),
                            ),

                            title: Text(
                              c["company"]?.toString().isNotEmpty == true
                                  ? c["company"]
                                  : c["name"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(
                              c["phone"] ?? "-",
                              style: TextStyle(color: Colors.grey[700]),
                            ),

                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CustomerDetailPage(customerId: c["id"]),
                                ),
                              );
                              if (result == true) loadCustomers();
                            },

                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteCustomer(c["id"]),
                            ),
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

  // --------------------------------------------------
  // MODERN GLASS LOOK — MÜŞTERİ EKLE BUTONU
  // --------------------------------------------------
  Widget _buildAddButton(BuildContext context, ThemeData theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerAddPage()),
        );
        if (result == true) loadCustomers();
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
              "Müşteri Ekle",
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
