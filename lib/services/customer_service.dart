// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final supabase = Supabase.instance.client;

  // -------------------------------------------------
  // AKTİF ŞİRKET ID'Sİ
  // -------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu yok");

    final userId = user.id;

    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle();

    if (existing == null || existing["id"] == null) {
      throw Exception("Company kaydı bulunamadı (trigger çalışmamış olabilir)");
    }

    return existing["id"];
  }

  // -------------------------------------------------
  // TÜM MÜŞTERİLER
  // -------------------------------------------------
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final companyId = await _getCompanyId();

      final res = await supabase
          .from("customers")
          .select()
          .eq("company_id", companyId)
          .order("created_at", ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Customer get error: $e");
      return [];
    }
  }

  // -------------------------------------------------
  // MÜŞTERİ DETAY
  // -------------------------------------------------
  Future<Map<String, dynamic>?> getCustomer(String id) async {
    try {
      final companyId = await _getCompanyId();

      final res = await supabase
          .from("customers")
          .select()
          .eq("id", id)
          .eq("company_id", companyId)
          .maybeSingle();

      return res;
    } catch (e) {
      print("Customer detail error: $e");
      return null;
    }
  }

  // -------------------------------------------------
  // MÜŞTERİ EKLE
  // -------------------------------------------------
  Future<void> addCustomer({
    required String name,
    String? company,
    String? contactName,
    required String phone,
    required String email,
    required String address,
  }) async {
    final companyId = await _getCompanyId();

    await supabase.from("customers").insert({
      "company_id": companyId,
      "name": name,
      "company": company,
      "contact_name": contactName,
      "phone": phone,
      "email": email,
      "address": address,
    });
  }

  // -------------------------------------------------
  // MÜŞTERİ GÜNCELLE
  // -------------------------------------------------
  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String company,
  }) async {
    final companyId = await _getCompanyId();

    await supabase
        .from("customers")
        .update({
          "name": name,
          "phone": phone,
          "email": email,
          "address": address,
          "company": company,
          "updated_at": DateTime.now().toIso8601String(),
        })
        .eq("id", id)
        .eq("company_id", companyId);
  }

  // -------------------------------------------------
  // MÜŞTERİ SİL
  // -------------------------------------------------
  Future<void> deleteCustomer(String id) async {
    final companyId = await _getCompanyId();

    await supabase
        .from("customers")
        .delete()
        .eq("id", id)
        .eq("company_id", companyId);
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) {
    return getCustomer(id);
  }
}
