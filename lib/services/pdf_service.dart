// ignore_for_file: unused_local_variable, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfService {
  Future<Uint8List> generateQuotePdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
  }) async {
    final fontRegular = await rootBundle.load(
      "assets/fonts/NotoSans-Regular.ttf",
    );
    final fontBold = await rootBundle.load("assets/fonts/NotoSans-Bold.ttf");

    final ttfRegular = pw.Font.ttf(fontRegular);
    final ttfBold = pw.Font.ttf(fontBold);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    // LOGO yükle
    final logoBytes = await rootBundle.load("assets/images/logo.png");
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // -----------------------------
    // HESAPLAMALAR
    // -----------------------------
    final subtotal = (quote["subtotal"] as num?)?.toDouble() ?? 0;
    final tax = (quote["tax"] as num?)?.toDouble() ?? 0;

    // indirim
    final discount = (quote["discount"] as num?)?.toDouble() ?? 0;

    // toplam
    final totalBeforeDiscount =
        (quote["total"] as num?)?.toDouble() ?? (subtotal + tax);
    final finalTotal =
        (quote["total_after_discount"] as num?)?.toDouble() ??
        (totalBeforeDiscount - discount);

    final discountType = quote["discount_type"] ?? "none";
    final discountRate = (quote["discount_rate"] as num?)?.toDouble() ?? 0;
    final discountAmount = (quote["discount_amount"] as num?)?.toDouble() ?? 0;

    // -----------------------------
    // PDF OLUŞTUR
    // -----------------------------
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // -------------------------------------------------
          // LOGO + HEADER
          // -------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(height: 70, child: pw.Image(logo)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "TEKLİF / SÖZLEŞME",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text("Teklif No: ${quote['quote_number'] ?? '-'}"),
                  pw.Text(
                    "Tarih: ${quote['issue_date'].toString().substring(0, 10)}",
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // -------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // -------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "MÜŞTERİ BİLGİLERİ",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text("Firma: ${customer['company'] ?? customer['name']}"),
                pw.Text("Yetkili: ${customer['contact_name'] ?? '-'}"),
                pw.Text("Telefon: ${customer['phone'] ?? '-'}"),
                pw.Text("E-posta: ${customer['email'] ?? '-'}"),
                pw.Text("Adres: ${customer['address'] ?? '-'}"),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // -------------------------------------------------
          // ÜRÜN TABLOSU
          // -------------------------------------------------
          pw.Text(
            "TEKLİF KALEMLERİ",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: ["Açıklama", "Miktar", "Birim", "Birim Fiyat", "Toplam"],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 11),
            data: items.map((i) {
              return [
                i['description'],
                i['quantity'].toString(),
                i['unit'],
                "${(i['unit_price'] as num).toStringAsFixed(2)} ₺",
                "${(i['total'] as num).toStringAsFixed(2)} ₺",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // -------------------------------------------------
          // TOPLAM HESAPLARI
          // -------------------------------------------------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Ara Toplam: ${subtotal.toStringAsFixed(2)} ₺"),
                pw.Text("KDV (%20): ${tax.toStringAsFixed(2)} ₺"),

                if (discountType != "none") pw.SizedBox(height: 6),

                // İNDİRİM GÖSTERİMİ
                if (discountType == "percent")
                  pw.Text(
                    "İndirim (%${(discountRate * 100).toStringAsFixed(0)}): -${discount.toStringAsFixed(2)} ₺",
                    style: pw.TextStyle(color: PdfColors.red),
                  ),

                if (discountType == "fixed")
                  pw.Text(
                    "İndirim (${discountAmount.toStringAsFixed(2)}₺): -${discount.toStringAsFixed(2)} ₺",
                    style: pw.TextStyle(color: PdfColors.red),
                  ),

                pw.SizedBox(height: 8),

                pw.Text(
                  "GENEL TOPLAM: ${finalTotal.toStringAsFixed(2)} ₺",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 30),

          // -------------------------------------------------
          // NOTLAR
          // -------------------------------------------------
          if (quote['notes'] != null && quote['notes'].toString().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "NOTLAR",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(quote['notes']),
              ],
            ),

          pw.SizedBox(height: 30),

          // -------------------------------------------------
          // İMZA / KAŞE
          // -------------------------------------------------
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "İmza / Kaşe",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 200,
                  height: 80,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
