// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final supabase = Supabase.instance.client;

  // -----------------------------------------------------------
  // Aktif şirket ID'si (companies tablosu) — FULL FIXED
  // -----------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu yok");

    final userId = user.id;

    // Bu kullanıcıya ait company var mı?
    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle();

    if (existing != null && existing["id"] != null) {
      return existing["id"].toString();
    }

    // -----------------------------------------------
    // Yoksa yeni şirket oluştur (NOT NULL alanlar dolu!)
    // -----------------------------------------------
    final inserted = await supabase
        .from("companies")
        .insert({
          "user_id": userId,
          "name": "Firma Adı", // NOT NULL fix
          "address": "",
          "phone": "",
          "email": "",
        })
        .select("id")
        .maybeSingle();

    if (inserted == null || inserted["id"] == null) {
      throw Exception("Company kaydı oluşturulamadı");
    }

    return inserted["id"].toString();
  }

  // -----------------------------------------------------------
  // Storage → Ürün görseli yükleme
  // -----------------------------------------------------------
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

      return supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // -----------------------------------------------------------
  // ÜRÜN EKLE
  // -----------------------------------------------------------
  Future<void> addProduct({
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required String description,
    String? imageUrl,
  }) async {
    final companyId = await _getCompanyId();

    await supabase.from("products").insert({
      "company_id": companyId,
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

  // -----------------------------------------------------------
  // ÜRÜN GÜNCELLE
  // -----------------------------------------------------------
  Future<void> updateProduct({
    required String id,
    required String name,
    required String unit,
    required double purchasePrice,
    required double salePrice,
    required String description,
    String? imageUrl,
  }) async {
    final companyId = await _getCompanyId();

    await supabase
        .from("products")
        .update({
          "name": name,
          "unit": unit,
          "purchase_price": purchasePrice,
          "sale_price": salePrice,
          "description": description,
          "image_url": imageUrl,
          "company_id": companyId,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id)
        .eq("company_id", companyId);
  }

  // -----------------------------------------------------------
  // ÜRÜN SİL
  // -----------------------------------------------------------
  Future<void> deleteProduct(String id) async {
    final companyId = await _getCompanyId();

    await supabase
        .from("products")
        .delete()
        .eq("id", id)
        .eq("company_id", companyId);
  }

  // -----------------------------------------------------------
  // TÜM ÜRÜNLER (Şirkete göre)
  // -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getProducts() async {
    final companyId = await _getCompanyId();

    final res = await supabase
        .from("products")
        .select()
        .eq("company_id", companyId)
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // -----------------------------------------------------------
  // TEK ÜRÜN GETİR
  // -----------------------------------------------------------
  Future<Map<String, dynamic>?> getProduct(String id) async {
    final companyId = await _getCompanyId();

    final res = await supabase
        .from("products")
        .select()
        .eq("id", id)
        .eq("company_id", companyId)
        .maybeSingle();

    return res == null ? null : Map<String, dynamic>.from(res);
  }
}
