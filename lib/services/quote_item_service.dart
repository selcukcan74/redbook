import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteItemService {
  final supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // AKTİF ŞİRKET (COMPANY) ID
  // --------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı yok");

    final record = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", user.id)
        .maybeSingle();

    if (record == null || record["id"] == null) {
      throw Exception("Company bulunamadı!");
    }

    return record["id"];
  }

  // --------------------------------------------------------
  // TÜM ÜRÜNLER (Sadece aktif şirketin)
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("products")
        .select()
        .eq("company_id", cid)
        .order("name", ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİFİN ÜRÜNLERİ
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getItemsByQuote(String quoteId) async {
    final res = await supabase
        .from("quote_items")
        .select("*, products(name)")
        .eq("quote_id", quoteId)
        .order("created_at");

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // ÜRÜN EKLEME
  // --------------------------------------------------------
  Future<void> addQuoteItem(String quoteId, Map<String, dynamic> item) async {
    final insertData = {
      "quote_id": quoteId,
      "product_id": item["product_id"],
      "description": item["description"],
      "unit": item["unit"],
      "unit_price": item["unit_price"],
      "quantity": item["quantity"],
      "total": (item["unit_price"] * item["quantity"]),
    };

    await supabase.from("quote_items").insert(insertData);

    // Toplamları güncelle
    await supabase.rpc("recalc_quote_totals", params: {"qid": quoteId});
  }

  // --------------------------------------------------------
  // ÜRÜN SİLME
  // --------------------------------------------------------
  Future<void> deleteQuoteItem(String id) async {
    await supabase.from("quote_items").delete().eq("id", id);
  }
}
