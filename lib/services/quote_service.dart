import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteService {
  final supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // TÜM TEKLİFLERİ GETİR (Müşteri bilgileri ile birlikte)
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getQuotes() async {
    final res = await supabase
        .from("quotes")
        .select("*, customers(name, company)")
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // DURUMA GÖRE TEKLİF GETİR (Filtreleme için)
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getQuotesByStatus(String status) async {
    final res = await supabase
        .from("quotes")
        .select("*, customers(name, company)")
        .eq("status", status)
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİF DETAY
  // --------------------------------------------------------
  Future<Map<String, dynamic>?> getQuoteById(String id) async {
    final res = await supabase
        .from("quotes")
        .select()
        .eq("id", id)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİF OLUŞTUR (TS-GGAAYY-0000 formatıyla)
  // --------------------------------------------------------
  Future<Map<String, dynamic>> addQuote({
    required String customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    String? notes,
  }) async {
    final dailyCount = await countQuotesToday() + 1;
    final quoteNumber = generateQuoteNumber(dailyCount);

    final payload = {
      "customer_id": customerId,
      "issue_date": (issueDate ?? DateTime.now()).toIso8601String(),
      "valid_until": validUntil?.toIso8601String(),
      "notes": notes,
      "status": "draft",
      "quote_number": quoteNumber,

      // başlangıç hesaplamaları
      "subtotal": 0,
      "tax": 0,
      "total": 0,
      "total_after_discount": 0,

      // indirim başlangıç değerleri
      "discount_type": "none",
      "discount_rate": 0,
      "discount_amount": 0,
    };

    final res = await supabase
        .from("quotes")
        .insert(payload)
        .select()
        .maybeSingle();

    if (res == null) {
      throw Exception("Teklif oluşturulamadı (null response).");
    }

    return Map<String, dynamic>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİF GÜNCELLE (Tarih – Not – Müşteri – Durum – İndirim)
  // --------------------------------------------------------
  Future<void> updateQuote({
    required String id,
    String? customerId,
    String? notes,
    DateTime? validUntil,
    String? status,

    // yeni indirim alanları
    String? discountType,
    double? discountRate,
    double? discountAmount,
  }) async {
    await supabase
        .from("quotes")
        .update({
          if (customerId != null) "customer_id": customerId,
          if (notes != null) "notes": notes,
          if (validUntil != null) "valid_until": validUntil.toIso8601String(),
          if (status != null) "status": status,

          if (discountType != null) "discount_type": discountType,
          if (discountRate != null) "discount_rate": discountRate,
          if (discountAmount != null) "discount_amount": discountAmount,
        })
        .eq("id", id);

    // hesaplamayı güncelle
    await recalcTotals(id);
  }

  // --------------------------------------------------------
  // TEKLİF SİL
  // --------------------------------------------------------
  Future<void> deleteQuote(String id) async {
    await supabase.from("quotes").delete().eq("id", id);
  }

  // --------------------------------------------------------
  // TEKLİF ÜRÜNLERİ
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getQuoteItems(String quoteId) async {
    final res = await supabase
        .from("quote_items")
        .select()
        .eq("quote_id", quoteId)
        .order("created_at");

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİFE ÜRÜN EKLE
  // --------------------------------------------------------
  Future<void> addQuoteItem({
    required String quoteId,
    required String productId,
    required String description,
    required double unitPrice,
    required double quantity,
    required String unit,
  }) async {
    final total = unitPrice * quantity;

    await supabase.from("quote_items").insert({
      "quote_id": quoteId,
      "product_id": productId,
      "description": description,
      "unit_price": unitPrice,
      "quantity": quantity,
      "unit": unit,
      "total": total,
    });

    await recalcTotals(quoteId);
  }

  // --------------------------------------------------------
  // ÜRÜN GÜNCELLE
  // --------------------------------------------------------
  Future<void> updateQuoteItem({
    required String id,
    required String quoteId,
    required String description,
    required double unitPrice,
    required double quantity,
    required String unit,
  }) async {
    final total = unitPrice * quantity;

    await supabase
        .from("quote_items")
        .update({
          "description": description,
          "unit_price": unitPrice,
          "quantity": quantity,
          "unit": unit,
          "total": total,
        })
        .eq("id", id);

    await recalcTotals(quoteId);
  }

  // --------------------------------------------------------
  // ÜRÜN SİL
  // --------------------------------------------------------
  Future<void> deleteQuoteItem(String id, String quoteId) async {
    await supabase.from("quote_items").delete().eq("id", id);
    await recalcTotals(quoteId);
  }

  // --------------------------------------------------------
  // TOPLAM – VERGİ – İNDİRİM – GENEL TOPLAM HESABI
  // --------------------------------------------------------
  Future<void> recalcTotals(String quoteId) async {
    final items = await supabase
        .from("quote_items")
        .select("total")
        .eq("quote_id", quoteId);

    double subtotal = 0;
    for (final i in items) {
      subtotal += (i["total"] as num).toDouble();
    }

    // vergi
    const taxRate = 0.20;
    final taxAmount = subtotal * taxRate;
    final totalBeforeDiscount = subtotal + taxAmount;

    // indirim bilgilerini çek
    final quote = await supabase
        .from("quotes")
        .select("discount_type, discount_rate, discount_amount")
        .eq("id", quoteId)
        .maybeSingle();

    double discount = 0;

    if (quote != null) {
      final type = quote["discount_type"];
      final rate = (quote["discount_rate"] as num).toDouble();
      final amount = (quote["discount_amount"] as num).toDouble();

      if (type == "percent") {
        discount = totalBeforeDiscount * rate;
      } else if (type == "fixed") {
        discount = amount;
      }
    }

    if (discount < 0) discount = 0;
    if (discount > totalBeforeDiscount) discount = totalBeforeDiscount;

    final finalTotal = totalBeforeDiscount - discount;

    await supabase
        .from("quotes")
        .update({
          "subtotal": subtotal,
          "tax": taxAmount,
          "total": totalBeforeDiscount,
          "discount": discount,
          "total_after_discount": finalTotal,
        })
        .eq("id", quoteId);
  }

  // --------------------------------------------------------
  // TEKLİF NUMARASI OLUŞTURMA
  // --------------------------------------------------------
  String generateQuoteNumber(int dailyCount) {
    final now = DateTime.now();
    final gg = now.day.toString().padLeft(2, '0');
    final aa = now.month.toString().padLeft(2, '0');
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final seq = dailyCount.toString().padLeft(4, '0');

    return "TS-$gg$aa$yy-$seq";
  }

  // --------------------------------------------------------
  // BUGÜN KAÇ TEKLİF OLUŞMUŞ
  // --------------------------------------------------------
  Future<int> countQuotesToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = now.toIso8601String();

    final res = await supabase
        .from("quotes")
        .select("id")
        .gte("issue_date", start)
        .lte("issue_date", end);

    return res.length;
  }

  // -------------------------------
  // TEKLİF KOPYALAMA (DUPLICATE)
  // -------------------------------
  Future<String> duplicateQuote(String quoteId) async {
    // 1) Orijinal teklifi al
    final orig = await supabase
        .from("quotes")
        .select()
        .eq("id", quoteId)
        .maybeSingle();

    if (orig == null) throw Exception("Original quote not found");

    // Yeni teklif numarası
    final dailyCount = await countQuotesToday() + 1;
    final newQuoteNumber = generateQuoteNumber(dailyCount);

    // 2) Yeni teklifi oluştur
    final newQuote = {
      "customer_id": orig["customer_id"],
      "issue_date": DateTime.now().toIso8601String(),
      "valid_until": orig["valid_until"],
      "notes": orig["notes"],
      "status": "draft",

      "quote_number": newQuoteNumber,

      // İndirim alanları
      "discount_type": orig["discount_type"],
      "discount_rate": orig["discount_rate"],
      "discount_amount": orig["discount_amount"],
      "discount": orig["discount"],
      "total_before_discount": orig["total_before_discount"],
      "total_after_discount": orig["total_after_discount"],
    };

    final inserted = await supabase
        .from("quotes")
        .insert(newQuote)
        .select()
        .maybeSingle();

    if (inserted == null) throw Exception("Duplicate creation failed");

    final newQuoteId = inserted["id"];

    // 3) Ürünleri kopyala
    final items = await supabase
        .from("quote_items")
        .select()
        .eq("quote_id", quoteId);

    for (final item in items) {
      await supabase.from("quote_items").insert({
        "quote_id": newQuoteId,
        "product_id": item["product_id"],
        "description": item["description"],
        "unit": item["unit"],
        "unit_price": item["unit_price"],
        "quantity": item["quantity"],
        "total": item["total"],
      });
    }

    // 4) Toplamları güncelle
    await recalcTotals(newQuoteId);

    return newQuoteId;
  }
}
