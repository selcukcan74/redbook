// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final supabase = Supabase.instance.client;

  // -----------------------------------------------------------
  // Aktif şirket ID'si (companies tablosu)
  // -----------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu yok");

    final userId = user.id;

    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle();

    if (existing != null && existing["id"] != null) {
      return existing["id"].toString();
    }

    final inserted = await supabase
        .from("companies")
        .insert({
          "user_id": userId,
          "name": "Firma Adı",
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
  // GET SETTINGS — yoksa oluştur
  // -----------------------------------------------------------
  Future<Map<String, dynamic>> getSettings() async {
    final companyId = await _getCompanyId();

    final existing = await supabase
        .from("settings")
        .select()
        .eq("company_id", companyId)
        .maybeSingle();

    if (existing != null) {
      final data = Map<String, dynamic>.from(existing);

      // default_currency yoksa TRY olarak ekleyelim (güvenlik için)
      data["default_currency"] ??= "TRY";

      return data;
    }

    // İlk defa oluşturuluyor → INSERT
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
      "default_currency": "TRY", // 💰 Varsayılan para birimi
    };

    await supabase.from("settings").insert(defaultData);

    return defaultData;
  }

  // -----------------------------------------------------------
  // SAVE SETTINGS — her zaman UPDATE
  // (data içinde default_currency varsa Supabase'e gider)
  // -----------------------------------------------------------
  Future<void> saveSettings(Map<String, dynamic> data) async {
    final companyId = await _getCompanyId();

    await supabase.from("settings").update(data).eq("company_id", companyId);
  }

  // -----------------------------------------------------------
  // LOGO UPLOAD — storage + settings update
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

      await supabase
          .from("settings")
          .update({"company_logo_url": publicUrl})
          .eq("company_id", companyId);

      return publicUrl;
    } catch (e) {
      print("Logo yüklenemedi: $e");
      return null;
    }
  }
}
