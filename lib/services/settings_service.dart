// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final supabase = Supabase.instance.client;

  // -----------------------------------------------------------
  // Aktif şirket ID'si (companies tablosu) — FULL FIXED
  // -----------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu yok");

    final userId = user.id;

    // Bu kullanıcıya ait bir company kaydı var mı?
    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle();

    if (existing != null && existing["id"] != null) {
      return existing["id"].toString();
    }

    // -----------------------------------------------
    // Yeni company oluştur (NOT NULL alanlar dolduruldu)
    // -----------------------------------------------
    final inserted = await supabase
        .from("companies")
        .insert({
          "user_id": userId,
          "name": "Firma Adı", // NOT NULL zorunluluğu giderildi
          "address": "", // NULL olmayan alan varsa doldur
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
  // GET SETTINGS (yoksa otomatik oluşturur)
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> getSettings() async {
    final companyId = await _getCompanyId();

    // Var mı?
    final existing = await supabase
        .from("settings")
        .select()
        .eq("company_id", companyId)
        .maybeSingle();

    if (existing != null) {
      return Map<String, dynamic>.from(existing);
    }

    // -----------------------------------------------
    // Yoksa default oluştur
    // -----------------------------------------------
    final defaultData = {
      "company_id": companyId,
      "company_name": "Firma Adı",
      "company_owner": "",
      "company_phone": "",
      "company_email": "",
      "company_address": "",
      "default_tax_rate": 20,
      "invoice_footer": "",
      "company_logo_url": null,
    };

    await supabase.from("settings").upsert(defaultData);

    return defaultData;
  }

  // -----------------------------------------------------------
  // SAVE SETTINGS
  // -----------------------------------------------------------
  Future<void> saveSettings(Map<String, dynamic> data) async {
    final companyId = await _getCompanyId();

    await supabase.from("settings").upsert({"company_id": companyId, ...data});
  }

  // -----------------------------------------------------------
  // LOGO UPLOAD (Storage)
  // -----------------------------------------------------------
  Future<String?> uploadLogo(Uint8List fileBytes) async {
    try {
      final companyId = await _getCompanyId();
      const bucket = "company-logos";

      final filePath = "$companyId/logo.png";

      await supabase.storage
          .from(bucket)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print("Logo yüklenemedi: $e");
      return null;
    }
  }
}
