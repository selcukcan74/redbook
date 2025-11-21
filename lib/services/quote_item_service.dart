import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteItemService {
  final supabase = Supabase.instance.client;

  // ---------------------------------------------------------
  // TÜM ÜRÜNLER (Dropdown için)
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final res = await supabase
        .from("products")
        .select()
        .order("name", ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------
  // Teklife Ait Ürünler
  // ---------------------------------------------------------
  Future<List<Map<String, dynamic>>> getItemsByQuote(String quoteId) async {
    final res = await supabase
        .from("quote_items")
        .select("*, products(name)")
        .eq("quote_id", quoteId)
        .order("created_at");

    return List<Map<String, dynamic>>.from(res);
  }

  // ---------------------------------------------------------
  // ÜRÜN EKLE
  // ---------------------------------------------------------
  Future<void> addQuoteItem(String quoteId, Map<String, dynamic> item) async {
    final payload = {
      "quote_id": quoteId,
      "product_id": item["product_id"],
      "description": item["description"],
      "unit": item["unit"],
      "unit_price": item["unit_price"],
      "quantity": item["quantity"],
      "total": item["total"],
    };

    await supabase.from("quote_items").insert(payload);
    // TRIGGER otomatik toplamlar oluşturuyor ✔︎
  }

  // ---------------------------------------------------------
  // ÜRÜN SİL
  // ---------------------------------------------------------
  Future<void> deleteQuoteItem(String id) async {
    await supabase.from("quote_items").delete().eq("id", id);
    // TRIGGER otomatik hesaplıyor ✔︎
  }
}
