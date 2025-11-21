import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/product_service.dart';

class ProductEditPage extends StatefulWidget {
  final String productId;

  const ProductEditPage({super.key, required this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _service = ProductService();

  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageUrl;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    final data = await _service.getProduct(widget.productId);

    if (data != null) {
      _nameCtrl.text = data["name"] ?? "";
      _unitCtrl.text = data["unit"] ?? "";
      _purchasePriceCtrl.text = data["purchase_price"]?.toString() ?? "";
      _salePriceCtrl.text = data["sale_price"]?.toString() ?? "";
      _descCtrl.text = data["description"] ?? "";
      _imageUrl = data["image_url"];
    }

    setState(() => _loading = false);
  }

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

    String? finalImageUrl = _imageUrl;

    // Yeni resim seçilmişse upload et
    if (_imageBytes != null) {
      finalImageUrl = await _service.uploadImage(
        bytes: _imageBytes!,
        fileName: "${DateTime.now().millisecondsSinceEpoch}.png",
      );
    }

    await _service.updateProduct(
      id: widget.productId,
      name: _nameCtrl.text.trim(),
      unit: _unitCtrl.text.trim(),
      purchasePrice: double.parse(_purchasePriceCtrl.text.trim()),
      salePrice: double.parse(_salePriceCtrl.text.trim()),
      description: _descCtrl.text.trim(),
      imageUrl: finalImageUrl,
    );

    setState(() => _saving = false);

    if (!mounted) return;
    Navigator.pop(context, true);
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Düzenle"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: deleteProduct,
          ),
        ],
      ),
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
                      : (_imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Text("Resim seçmek için dokun"),
                              )),
                ),
              ),

              const SizedBox(height: 20),

              // NAME
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Ürün Adı"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              // UNIT
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(
                  labelText: "Birim (ör: adet, metre, m²)",
                ),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              // PURCHASE PRICE
              TextFormField(
                controller: _purchasePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Satın Alma Fiyatı",
                ),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              // SALE PRICE
              TextFormField(
                controller: _salePriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Satış Fiyatı"),
                validator: (v) => v!.isEmpty ? "Zorunlu alan" : null,
              ),
              const SizedBox(height: 12),

              // DESCRIPTION
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Açıklama"),
              ),
              const SizedBox(height: 20),

              // SAVE BUTTON
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
