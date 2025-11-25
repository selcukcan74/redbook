// lib/services/dashboard_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // COMPANY ID (TÜM SORGULARDA ZORUNLU)
  // --------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı bulunamadı.");

    final res = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", user.id)
        .maybeSingle();

    if (res == null || res["id"] == null) {
      throw Exception("Company bulunamadı!");
    }

    return res["id"].toString();
  }

  // --------------------------------------------------------
  // TOPLAM ÜRÜNLER
  // --------------------------------------------------------
  Future<int> getTotalProducts() async {
    final cid = await _getCompanyId();
    final res = await supabase
        .from("products")
        .select("id")
        .eq("company_id", cid);
    return res.length;
  }

  // --------------------------------------------------------
  // TOPLAM MÜŞTERİLER
  // --------------------------------------------------------
  Future<int> getTotalCustomers() async {
    final cid = await _getCompanyId();
    final res = await supabase
        .from("customers")
        .select("id")
        .eq("company_id", cid);
    return res.length;
  }

  // --------------------------------------------------------
  // TOPLAM TEKLİFLER
  // --------------------------------------------------------
  Future<int> getTotalQuotes() async {
    final cid = await _getCompanyId();
    final res = await supabase
        .from("quotes")
        .select("id")
        .eq("company_id", cid);
    return res.length;
  }

  // --------------------------------------------------------
  // ONAYLANAN TEKLİFLER (approved_at IS NOT NULL)
  // --------------------------------------------------------
  Future<int> getApprovedQuotes() async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("quotes")
        .select("id")
        .eq("company_id", cid)
        .not("approved_at", "is", null); // 🔥 doğru kolon: approved_at

    return res.length;
  }

  // --------------------------------------------------------
  // AYLIK GELİR (RPC)
  // --------------------------------------------------------
  Future<double> getMonthlyRevenue() async {
    final cid = await _getCompanyId();

    final result = await supabase.rpc(
      "get_monthly_revenue",
      params: {"p_company_id": cid},
    );

    if (result == null) return 0;

    try {
      return (result as num).toDouble();
    } catch (_) {
      return 0;
    }
  }

  // --------------------------------------------------------
  // SON 30 GÜN TEKLİF SAYISI
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getLast30DaysOffers() async {
    final cid = await _getCompanyId();

    final res = await supabase.rpc(
      "get_last_30_days_quotes",
      params: {"p_company_id": cid},
    );

    if (res == null) return [];

    return List<Map<String, dynamic>>.from(res as List);
  }

  // --------------------------------------------------------
  // SON TEKLİF HAREKETLERİ
  // (Created + Approved’a göre sıralama)
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getLatestQuoteActivities() async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("quotes")
        .select(
          "id, quote_number, total, status, created_at, approved_at, customers(name)",
        )
        .eq("company_id", cid)
        .order("created_at", ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // DÖNÜŞÜM ORANI
  // --------------------------------------------------------
  Future<double> getConversionRate() async {
    final total = await getTotalQuotes();
    final approved = await getApprovedQuotes();

    if (total == 0) return 0.0;

    return approved / total;
  }
}
