// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final res = await supabase
          .from("customers")
          .select()
          .order("created_at", ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print("Customer get error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCustomer(String id) async {
    try {
      final res = await supabase
          .from("customers")
          .select()
          .eq("id", id)
          .maybeSingle();

      return res;
    } catch (e) {
      print("Customer detail error: $e");
      return null;
    }
  }

  Future<void> addCustomer({
    required String name,
    String? company,
    String? contactName,
    required String phone,
    required String email,
    required String address,
  }) async {
    await supabase.from("customers").insert({
      "name": name,
      "company": company,
      "contact_name": contactName,
      "phone": phone,
      "email": email,
      "address": address,
    });
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String company,
  }) async {
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
        .eq("id", id);
  }

  Future<void> deleteCustomer(String id) async {
    await supabase.from("customers").delete().eq("id", id);
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    final res = await supabase
        .from("customers")
        .select()
        .eq("id", id)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }
}
