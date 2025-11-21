import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/product_service.dart';

class ProductAddPage extends StatefulWidget {
  const ProductAddPage({super.key});

  @override
  State<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();

  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Uint8List? _imageBytes;
  bool _saving = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;

    _imageBytes = await file.readAsBytes();
    setState(() {});
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String? imageUrl;
    if (_imageBytes != null) {
      imageUrl = await _service.uploadImage(
        bytes: _imageBytes!,
        fileName: "${DateTime.now().millisecondsSinceEpoch}.png",
      );
    }

    await _service.addProduct(
      name: _nameCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      purchasePrice: double.parse(_purchasePriceCtrl.text.trim()),
      salePrice: double.parse(_salePriceCtrl.text.trim()),
      description: _descCtrl.text.trim(),
      imageUrl: imageUrl,
    );

    setState(() => _saving = false);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ürün")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // IMAGE PICKER
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : const Center(child: Text("Resim seçmek için dokun")),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Ürün Adı"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  labelText: "Birim (adet, metre...)",
                ),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _purchasePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Alış Fiyatı"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _salePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Satış Fiyatı"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Açıklama"),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : saveProduct,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Kaydet"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
