// ignore_for_file: unnecessary_null_comparison, unnecessary_underscores, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final service = SettingsService();

  // Form controller’ları
  final companyCtrl = TextEditingController();
  final ownerCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final taxCtrl = TextEditingController();
  final footerCtrl = TextEditingController();
  final logoUrlCtrl = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // ----------------------------------------------------------
  // AYARLARI YÜKLE
  // ----------------------------------------------------------
  Future<void> loadSettings() async {
    final data = await service.getSettings();

    if (data != null) {
      companyCtrl.text = data['company_name'] ?? '';
      ownerCtrl.text = data['company_owner'] ?? '';
      phoneCtrl.text = data['company_phone'] ?? '';
      emailCtrl.text = data['company_email'] ?? '';
      addressCtrl.text = data['company_address'] ?? '';
      taxCtrl.text = (data['default_tax_rate'] ?? 20).toString();
      footerCtrl.text = data['invoice_footer'] ?? '';
      logoUrlCtrl.text = data['company_logo_url'] ?? '';
    }

    setState(() => loading = false);
  }

  // ----------------------------------------------------------
  // FORMU KAYDET
  // ----------------------------------------------------------
  Future<void> save() async {
    setState(() => saving = true);

    final taxRateText = taxCtrl.text.replaceAll(',', '.');
    final taxRate = double.tryParse(taxRateText) ?? 20; // default %20

    await service.saveSettings({
      'company_name': companyCtrl.text.trim(),
      'company_owner': ownerCtrl.text.trim(),
      'company_phone': phoneCtrl.text.trim(),
      'company_email': emailCtrl.text.trim(),
      'company_address': addressCtrl.text.trim(),
      'default_tax_rate': taxRate,
      'invoice_footer': footerCtrl.text.trim(),
      'company_logo_url': logoUrlCtrl.text.trim().isEmpty
          ? null
          : logoUrlCtrl.text.trim(),
    });

    setState(() => saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi')));
  }

  // ----------------------------------------------------------
  // LOGO SEÇ + YÜKLE
  // ----------------------------------------------------------
  Future<void> pickAndUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => uploadingLogo = true);

    try {
      final url = await service.uploadLogo(file.bytes!);

      if (url != null) {
        setState(() {
          logoUrlCtrl.text = url;
        });

        await save(); // URL settings tablosuna kaydedilsin

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logo yüklendi')));
      } else {
        throw "Beklenmeyen bir hata oluştu.";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logo yüklenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => uploadingLogo = false);
    }
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  const Text(
                    'Firma Bilgileri',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _field('Firma Adı', companyCtrl),
                  _field('Firma Sahibi / Yetkili', ownerCtrl),
                  _field('Telefon', phoneCtrl),
                  _field('E-posta', emailCtrl),
                  _field('Adres', addressCtrl, maxLines: 2),

                  const SizedBox(height: 20),
                  const Text(
                    'Finansal Ayarlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _field('Varsayılan KDV Oranı (%)', taxCtrl),
                  _field('Teklif / Fatura Alt Notu', footerCtrl, maxLines: 3),

                  const SizedBox(height: 20),
                  const Text(
                    'Logo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: logoUrlCtrl,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: uploadingLogo ? null : pickAndUploadLogo,
                        icon: uploadingLogo
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: const Text('Yükle'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // LOGO ÖNİZLEME
                  if (logoUrlCtrl.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 80,
                        child: Image.network(
                          logoUrlCtrl.text.trim(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Text('Logo yüklenemedi'),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
