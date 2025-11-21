import 'package:flutter/material.dart';
import '../../services/customer_service.dart';

class CustomerEditPage extends StatefulWidget {
  final String customerId;
  const CustomerEditPage({super.key, required this.customerId});

  @override
  State<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends State<CustomerEditPage> {
  final _service = CustomerService();
  final _form = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final c = await _service.getCustomer(widget.customerId);

    if (c != null) {
      _name.text = c["name"] ?? "";
      _company.text = c["company"] ?? "";
      _phone.text = c["phone"] ?? "";
      _email.text = c["email"] ?? "";
      _address.text = c["address"] ?? "";
    }

    setState(() => loading = false);
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => saving = true);

    await _service.updateCustomer(
      id: widget.customerId,
      name: _name.text,
      phone: _phone.text,
      email: _email.text,
      address: _address.text,
      company: _company.text,
    );

    setState(() => saving = false);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Müşteri Düzenle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "İsim"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _company,
                decoration: const InputDecoration(labelText: "Firma"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: "Telefon"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: "Adres"),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
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
