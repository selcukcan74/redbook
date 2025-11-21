// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // IMAGE UPLOAD (ÇALIŞAN)
  // ---------------------------------------------------------------------------
  Future<String?> uploadImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    const bucket = "products";
    final path = "images/$fileName";

    try {
      await supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = supabase.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ADD PRODUCT
  // ---------------------------------------------------------------------------
  Future<void> addProduct({
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required String description,
    String? imageUrl,
  }) async {
    await supabase.from("products").insert({
      "name": name,
      "unit": unit,
      "purchase_price": purchasePrice,
      "sale_price": salePrice,
      "description": description,
      "image_url": imageUrl,
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    });
  }

  // ---------------------------------------------------------------------------
  // UPDATE PRODUCT
  // ---------------------------------------------------------------------------
  Future<void> updateProduct({
    required String id,
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required String description,
    String? imageUrl,
  }) async {
    await supabase
        .from("products")
        .update({
          "name": name,
          "unit": unit,
          "purchase_price": purchasePrice,
          "sale_price": salePrice,
          "description": description,
          "image_url": imageUrl,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id);
  }

  // ---------------------------------------------------------------------------
  // DELETE PRODUCT
  // ---------------------------------------------------------------------------
  Future<void> deleteProduct(String id) async {
    await supabase.from("products").delete().eq("id", id);
  }

  // ---------------------------------------------------------------------------
  // GET ALL PRODUCTS
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getProducts() async {
    final res = await supabase
        .from("products")
        .select()
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE PRODUCT
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> getProduct(String id) async {
    final res = await supabase
        .from("products")
        .select()
        .eq("id", id)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }
}
