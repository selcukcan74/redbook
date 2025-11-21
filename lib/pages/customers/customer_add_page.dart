import 'package:flutter/material.dart';
import '../../services/customer_service.dart';

class CustomerAddPage extends StatefulWidget {
  const CustomerAddPage({super.key});

  @override
  State<CustomerAddPage> createState() => _CustomerAddPageState();
}

class _CustomerAddPageState extends State<CustomerAddPage> {
  final _form = GlobalKey<FormState>();

  /// FORM CONTROLLERS
  final _name = TextEditingController(); // Kişi adı (zorunlu)
  final _company = TextEditingController(); // Firma adı
  final _contactName =
      TextEditingController(); // Yetkili kişi adı (contact_name)
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  final _service = CustomerService();
  bool saving = false;

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => saving = true);

    await _service.addCustomer(
      name: _name.text.trim(),
      company: _company.text.trim().isEmpty ? null : _company.text.trim(),
      contactName: _contactName.text.trim().isEmpty
          ? null
          : _contactName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
    );

    setState(() => saving = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Müşteri Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              // ----------------------------------
              // KİŞİ ADI (ZORUNLU)
              // ----------------------------------
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: "İsim / Kişi Adı *",
                ),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 10),

              // ----------------------------------
              // FİRMA ADI
              // ----------------------------------
              TextFormField(
                controller: _company,
                decoration: const InputDecoration(
                  labelText: "Firma (opsiyonel)",
                ),
              ),
              const SizedBox(height: 10),

              // ----------------------------------
              // YETKİLİ KİŞİ — CONTACT_NAME
              // ----------------------------------
              TextFormField(
                controller: _contactName,
                decoration: const InputDecoration(
                  labelText: "Yetkili (contact name)",
                ),
              ),
              const SizedBox(height: 10),

              // ----------------------------------
              // TELEFON
              // ----------------------------------
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Telefon"),
              ),
              const SizedBox(height: 10),

              // ----------------------------------
              // EMAIL
              // ----------------------------------
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "E-mail"),
              ),
              const SizedBox(height: 10),

              // ----------------------------------
              // ADRES
              // ----------------------------------
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Adres"),
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // ----------------------------------
              // KAYDET BUTONU
              // ----------------------------------
              ElevatedButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
