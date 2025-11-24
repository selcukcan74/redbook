// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteService {
  final supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // COMPANY ID – Uygulamanın temel taşı
  // --------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu bulunamadı.");

    final userId = user.id;

    // Kullanıcıya ait company var mı?
    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", userId)
        .maybeSingle();

    if (existing != null && existing["id"] != null) {
      return existing["id"].toString();
    }

    // Yoksa zorunlu 'name' alanı ile company oluştur
    final inserted = await supabase
        .from("companies")
        .insert({"user_id": userId, "name": "Firma Adı"})
        .select("id")
        .maybeSingle();

    if (inserted == null || inserted["id"] == null) {
      throw Exception("Company oluşturulamadı!");
    }

    return inserted["id"].toString();
  }

  // --------------------------------------------------------
  // TÜM TEKLİFLER
  // --------------------------------------------------------
  Future<List<Map<String, dynamic>>> getQuotes() async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("quotes")
        .select("*, customers(name, company)")
        .eq("company_id", cid)
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getQuotesByStatus(String status) async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("quotes")
        .select("*, customers(name, company)")
        .eq("company_id", cid)
        .eq("status", status)
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİF DETAY
  // --------------------------------------------------------
  Future<Map<String, dynamic>?> getQuoteById(String id) async {
    final cid = await _getCompanyId();

    final res = await supabase
        .from("quotes")
        .select()
        .eq("id", id)
        .eq("company_id", cid)
        .maybeSingle();

    return res == null ? null : Map<String, dynamic>.from(res);
  }

  // --------------------------------------------------------
  // TEKLİF OLUŞTUR
  // --------------------------------------------------------
  Future<Map<String, dynamic>> addQuote({
    required String customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    String? notes,
  }) async {
    final cid = await _getCompanyId();

    final dailyCount = await countQuotesToday() + 1;
    final quoteNumber = generateQuoteNumber(dailyCount);

    final payload = {
      "company_id": cid,
      "customer_id": customerId,
      "issue_date": (issueDate ?? DateTime.now()).toIso8601String(),
      "valid_until": validUntil?.toIso8601String(),
      "notes": notes,
      "status": "draft",
      "quote_number": quoteNumber,

      // Hesaplamalar
      "subtotal": 0,
      "tax": 0,
      "total": 0,
      "total_after_discount": 0,

      // İndirim
      "discount_type": "none",
      "discount_rate": 0,
      "discount_amount": 0,
      "discount": 0,
    };

    final res = await supabase
        .from("quotes")
        .insert(payload)
        .select()
        .maybeSingle();

    if (res == null) throw Exception("Teklif oluşturulamadı.");

    return Map<String, dynamic>.from(res);
  }

  // --------------------------------------------------------
  // GÜNCELLE
  // --------------------------------------------------------
  Future<void> updateQuote({
    required String id,
    String? customerId,
    String? notes,
    DateTime? validUntil,
    String? status,
    String? discountType,
    double? discountRate,
    double? discountAmount,
  }) async {
    final updateData = <String, dynamic>{};

    if (customerId != null) updateData["customer_id"] = customerId;
    if (notes != null) updateData["notes"] = notes;

    if (validUntil != null) {
      updateData["valid_until"] = validUntil.toIso8601String();
    }

    if (status != null) updateData["status"] = status;

    if (discountType != null) updateData["discount_type"] = discountType;
    if (discountRate != null) updateData["discount_rate"] = discountRate;
    if (discountAmount != null) updateData["discount_amount"] = discountAmount;

    if (updateData.isNotEmpty) {
      await supabase.from("quotes").update(updateData).eq("id", id);
      await recalcTotals(id);
    }
  }

  // --------------------------------------------------------
  // TEKLİF SİL
  // --------------------------------------------------------
  Future<void> deleteQuote(String id) async {
    final cid = await _getCompanyId();
    await supabase.from("quotes").delete().eq("id", id).eq("company_id", cid);
  }

  // --------------------------------------------------------
  // TOPLAM HESAPLAMA
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

    const taxRate = 0.20;
    final taxAmount = subtotal * taxRate;
    final totalBefore = subtotal + taxAmount;

    // Mevcut indirim bilgileri
    final quote = await supabase
        .from("quotes")
        .select("discount_type, discount_rate, discount_amount")
        .eq("id", quoteId)
        .maybeSingle();

    double discount = 0;

    if (quote != null) {
      final type = quote["discount_type"];
      final rate = (quote["discount_rate"] as num?)?.toDouble() ?? 0;
      final amount = (quote["discount_amount"] as num?)?.toDouble() ?? 0;

      if (type == "percent") {
        discount = totalBefore * (rate / 100.0);
      } else if (type == "fixed") {
        discount = amount;
      }
    }

    if (discount < 0) discount = 0;
    if (discount > totalBefore) discount = totalBefore;

    final finalTotal = totalBefore - discount;

    await supabase
        .from("quotes")
        .update({
          "subtotal": subtotal,
          "tax": taxAmount,
          "total": totalBefore,
          "discount": discount,
          "total_after_discount": finalTotal,
        })
        .eq("id", quoteId);
  }

  // --------------------------------------------------------
  // TEKLİF NUMARASI
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
  // BUGÜN KAÇ TEKLİF VAR?
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

  // --------------------------------------------------------
  // TEKLİF KOPYALA
  // --------------------------------------------------------
  Future<String> duplicateQuote(String quoteId) async {
    final orig = await supabase
        .from("quotes")
        .select()
        .eq("id", quoteId)
        .maybeSingle();

    if (orig == null) {
      throw Exception("Orijinal teklif bulunamadı.");
    }

    final dailyCount = await countQuotesToday() + 1;
    final newNumber = generateQuoteNumber(dailyCount);

    final newQuote = {
      "company_id": orig["company_id"],
      "customer_id": orig["customer_id"],
      "issue_date": DateTime.now().toIso8601String(),
      "valid_until": orig["valid_until"],
      "notes": orig["notes"],
      "status": "draft",
      "quote_number": newNumber,
      "discount_type": orig["discount_type"],
      "discount_rate": orig["discount_rate"],
      "discount_amount": orig["discount_amount"],
    };

    final inserted = await supabase
        .from("quotes")
        .insert(newQuote)
        .select()
        .maybeSingle();

    if (inserted == null) throw Exception("Teklif kopyalanamadı.");

    final newId = inserted["id"].toString();

    // Ürünleri kopyala
    final items = await supabase
        .from("quote_items")
        .select()
        .eq("quote_id", quoteId);

    for (final item in items) {
      await supabase.from("quote_items").insert({
        "quote_id": newId,
        "product_id": item["product_id"],
        "description": item["description"],
        "unit": item["unit"],
        "unit_price": item["unit_price"],
        "quantity": item["quantity"],
        "total": item["total"],
      });
    }

    await recalcTotals(newId);

    return newId;
  }
}
