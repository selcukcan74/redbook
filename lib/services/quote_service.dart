// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

class QuoteService {
  final supabase = Supabase.instance.client;

  // --------------------------------------------------------
  // COMPANY ID – Uygulamanın temel taşı
  // --------------------------------------------------------
  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Kullanıcı oturumu bulunamadı.");

    final existing = await supabase
        .from("companies")
        .select("id")
        .eq("user_id", user.id)
        .maybeSingle();

    if (existing != null && existing["id"] != null) {
      return existing["id"].toString();
    }

    // Zorunlu name ile company oluştur
    final inserted = await supabase
        .from("companies")
        .insert({"user_id": user.id, "name": "Firma Adı"})
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
  // TEKLİF OLUŞTUR (CURRENCY EKLENDİ)
  // --------------------------------------------------------
  Future<Map<String, dynamic>> addQuote({
    required String customerId,
    DateTime? issueDate,
    DateTime? validUntil,
    String? notes,
    String currency = "TRY",
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

      "currency": currency,

      "subtotal": 0,
      "tax": 0,
      "total": 0,
      "total_after_discount": 0,

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
  // GÜNCELLE (CURRENCY EKLENDİ)
  // --------------------------------------------------------
  Future<void> updateQuote({
    required String id,
    String? customerId,
    String? notes,
    DateTime? validUntil,
    String? status, // <-- burada accepted kontrolü var
    String? discountType,
    double? discountRate,
    double? discountAmount,
    String? currency,
  }) async {
    final updateData = <String, dynamic>{};

    if (customerId != null) updateData["customer_id"] = customerId;
    if (notes != null) updateData["notes"] = notes;
    if (validUntil != null) {
      updateData["valid_until"] = validUntil.toIso8601String();
    }

    // -----------------------------------------
    // 🔥 STATUS = ACCEPTED → accepted_at yaz!
    // -----------------------------------------
    if (status != null) {
      updateData["status"] = status;

      if (status == "accepted") {
        updateData["approved_at"] = DateTime.now().toUtc().toIso8601String();
      } else {
        // draft / rejected / sent gibi durumlarda accepted_at null olsun
        updateData["approved_at"] = null;
      }
    }

    if (discountType != null) updateData["discount_type"] = discountType;
    if (discountRate != null) updateData["discount_rate"] = discountRate;
    if (discountAmount != null) updateData["discount_amount"] = discountAmount;

    if (currency != null) updateData["currency"] = currency;

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
    // 1) Ürünleri çek
    final items = await supabase
        .from("quote_items")
        .select("total")
        .eq("quote_id", quoteId);

    double subtotal = 0;
    for (final i in items) {
      subtotal += (i["total"] as num).toDouble();
    }

    // 2) Teklif indirim bilgilerini çek
    final quote = await supabase
        .from("quotes")
        .select("discount_type, discount_rate, discount_amount")
        .eq("id", quoteId)
        .maybeSingle();

    double discount = 0;

    if (quote != null) {
      final type = quote["discount_type"];
      final rate = (quote["discount_rate"] ?? 0).toDouble();
      final fixed = (quote["discount_amount"] ?? 0).toDouble();

      if (type == "percent") {
        // YENİ DOĞRU FORMÜL: % indirim = subtotal üzerinden
        discount = subtotal * (rate / 100);
      } else if (type == "fixed") {
        discount = fixed;
      }
    }

    // İndirim asla negatife düşmesin
    if (discount < 0) discount = 0;
    if (discount > subtotal) discount = subtotal;

    // 3) İndirim sonrası net tutar
    final afterDiscount = subtotal - discount;

    // 4) KDV hesaplama (yeni formül – indirim SONRASI)
    const taxRate = 0.20; // %20
    final taxAmount = afterDiscount * taxRate;

    // 5) Genel toplam
    final total = afterDiscount + taxAmount;

    // 6) DB güncelle
    await supabase
        .from("quotes")
        .update({
          "subtotal": subtotal,
          "discount": discount,
          "tax": taxAmount,
          "total": total,
          "total_after_discount": total,
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

    if (orig == null) throw Exception("Orijinal teklif bulunamadı.");

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
      "currency": orig["currency"],
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

  // --------------------------------------------------------
  // REVİZYONDAN GERİ YÜKLE
  // --------------------------------------------------------
  Future<void> restoreFromRevision(String revisionId) async {
    final rev = await supabase
        .from("quote_revisions")
        .select()
        .eq("id", revisionId)
        .maybeSingle();

    if (rev == null) throw Exception("Revizyon bulunamadı");

    final snapshot = rev["snapshot"];
    final quote = snapshot["quote"];
    final items = List<Map<String, dynamic>>.from(snapshot["items"] ?? []);

    final quoteId = quote["id"];

    // Teklif güncelle
    await supabase
        .from("quotes")
        .update({
          "customer_id": quote["customer_id"],
          "issue_date": quote["issue_date"],
          "valid_until": quote["valid_until"],
          "notes": quote["notes"],
          "discount_type": quote["discount_type"],
          "discount_rate": quote["discount_rate"],
          "discount_amount": quote["discount_amount"],
          "subtotal": quote["subtotal"],
          "tax": quote["tax"],
          "total": quote["total"],
          "total_after_discount": quote["total_after_discount"],
        })
        .eq("id", quoteId);

    // Ürünleri sil
    await supabase.from("quote_items").delete().eq("quote_id", quoteId);

    // Eski ürünleri geri yükle
    for (final it in items) {
      await supabase.from("quote_items").insert({
        "quote_id": quoteId,
        "description": it["description"],
        "unit_price": it["unit_price"],
        "quantity": it["quantity"],
        "unit": it["unit"],
        "total": it["total"],
        "product_id": it["product_id"],
      });
    }
  }

  // --------------------------------------------------------
  // REVİZYON KAYDET
  // --------------------------------------------------------
  Future<void> saveRevision(String quoteId) async {
    final supabase = Supabase.instance.client;

    // 1) Teklif
    final quote = await supabase
        .from("quotes")
        .select()
        .eq("id", quoteId)
        .maybeSingle();

    if (quote == null) throw Exception("Teklif bulunamadı.");

    // 2) Ürünler
    final items = await supabase
        .from("quote_items")
        .select()
        .eq("quote_id", quoteId);

    // Ara toplam
    double subtotal = 0;
    for (final i in items) {
      subtotal += (i["total"] as num).toDouble();
    }

    // 3) İndirim
    final type = quote["discount_type"];
    final rate = (quote["discount_rate"] ?? 0).toDouble();
    final fixed = (quote["discount_amount"] ?? 0).toDouble();

    double discount = 0;

    if (type == "percent") {
      discount = subtotal * (rate / 100);
    } else if (type == "fixed") {
      discount = fixed;
    }

    if (discount < 0) discount = 0;
    if (discount > subtotal) discount = subtotal;

    // 4) İndirim sonrası ara toplam
    final afterDiscount = subtotal - discount;

    // 5) KDV
    const taxRate = 0.20;
    final tax = afterDiscount * taxRate;

    // 6) Genel toplam
    final finalTotal = afterDiscount + tax;

    // 7) Müşteri
    final customerId = quote["customer_id"]?.toString();
    Map<String, dynamic>? customer;

    if (customerId != null) {
      final raw = await supabase
          .from("customers")
          .select()
          .eq("id", customerId)
          .maybeSingle();

      if (raw != null) customer = Map<String, dynamic>.from(raw);
    }

    // 8) Son revizyon numarası
    final last = await supabase
        .from("quote_revisions")
        .select("revision_number")
        .eq("quote_id", quoteId)
        .order("revision_number", ascending: false)
        .limit(1)
        .maybeSingle();

    final next = last == null ? 1 : (last["revision_number"] as int) + 1;

    // 9) Snapshot
    final snapshot = {
      "quote": {
        ...quote,
        "subtotal": subtotal,
        "discount": discount,
        "tax": tax,
        "total": finalTotal,
        "total_after_discount": finalTotal,
      },
      "items": items,
      "customer": customer,
    };

    // 10) Kaydet
    await supabase.from("quote_revisions").insert({
      "company_id": quote["company_id"],
      "quote_id": quoteId,
      "revision_number": next,
      "snapshot": snapshot,
    });
  }

  // --------------------------------------------------------
  // AKTÜEL TEKLİF SNAPSHOT
  // --------------------------------------------------------
  Future<Map<String, dynamic>> getQuoteSnapshot(String quoteId) async {
    // 1) Teklif
    final quote = await supabase
        .from("quotes")
        .select()
        .eq("id", quoteId)
        .maybeSingle();

    if (quote == null) throw Exception("Teklif bulunamadı");

    // 2) Ürünler
    final items = await supabase
        .from("quote_items")
        .select()
        .eq("quote_id", quoteId);

    // 3) Müşteri
    final customerId = quote["customer_id"]?.toString();
    Map<String, dynamic>? customer;

    if (customerId != null) {
      final c = await supabase
          .from("customers")
          .select()
          .eq("id", customerId)
          .maybeSingle();

      if (c != null) customer = Map<String, dynamic>.from(c);
    }

    return {"quote": quote, "items": items, "customer": customer};
  }

  Future<int> getApprovedQuotes() async {
    final res = await supabase
        .from('quotes')
        .select('id')
        .not('approved_at', 'is', null);
    return res.length;
  }
}
