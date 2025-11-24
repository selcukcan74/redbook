// ignore_for_file: depend_on_referenced_packages, unused_local_variable, deprecated_member_use, avoid_print

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

class PdfService {
  // ------------------------------------------------------------
  // NETWORK LOGO YÜKLEYİCİ + FALLBACK METİN LOGO
  // ------------------------------------------------------------
  Future<pw.Widget> buildLogo({
    required String? logoUrl,
    required String companyName,
  }) async {
    try {
      if (logoUrl != null && logoUrl.trim().isNotEmpty) {
        final response = await http.get(Uri.parse(logoUrl));

        if (response.statusCode == 200) {
          final img = pw.MemoryImage(response.bodyBytes);
          return pw.Image(img, height: 70, fit: pw.BoxFit.contain);
        }
      }
    } catch (e) {
      print("LOGO yüklenemedi: $e");
    }

    // FALLBACK → Firma adı ile premium text-logo
    return pw.Container(
      height: 70,
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        companyName,
        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ------------------------------------------------------------
  // PDF OLUŞTURMA
  // ------------------------------------------------------------
  Future<Uint8List> generateQuotePdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? settings,
  }) async {
    // FONTLAR
    final fontRegular = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // ------------------------------------------------------------
    // Firma Ayarları (Settings)
    // ------------------------------------------------------------
    final companyName = settings?["company_name"] ?? "FİRMA ADI";
    final companyOwner = settings?["company_owner"] ?? "-";
    final companyPhone = settings?["company_phone"] ?? "-";
    final companyEmail = settings?["company_email"] ?? "-";
    final companyAddress = settings?["company_address"] ?? "-";
    final invoiceFooter = settings?["invoice_footer"] ?? "";
    final companyLogoUrl = settings?["company_logo_url"];

    // LOGO
    final logoWidget = await buildLogo(
      logoUrl: companyLogoUrl,
      companyName: companyName,
    );

    // ------------------------------------------------------------
    // Hesaplamalar
    // ------------------------------------------------------------
    final subtotal = (quote["subtotal"] ?? 0).toDouble();
    final tax = (quote["tax"] ?? 0).toDouble();
    final discount = (quote["discount"] ?? 0).toDouble();

    final totalBeforeDiscount = (quote["total"] ?? (subtotal + tax)).toDouble();

    final finalTotal =
        (quote["total_after_discount"] ?? (totalBeforeDiscount - discount))
            .toDouble();

    final discountType = quote["discount_type"] ?? "none";
    final discountRate = (quote["discount_rate"] ?? 0).toDouble();
    final discountAmount = (quote["discount_amount"] ?? 0).toDouble();

    // ------------------------------------------------------------
    // PDF SAYFA İÇERİĞİ
    // ------------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ------------------------------------------------------------
          // HEADER — LOGO + TEKLİF BİLGİLERİ
          // ------------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logoWidget,
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

          // ------------------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // ------------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "MÜŞTERİ BİLGİLERİ",
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text("Firma: ${customer['company'] ?? customer['name']}"),
                pw.Text("Yetkili: ${customer['contact_name'] ?? '-'}"),
                pw.Text("Telefon: ${customer['phone'] ?? '-'}"),
                pw.Text("E-posta: ${customer['email'] ?? '-'}"),
                pw.Text("Adres: ${customer['address'] ?? '-'}"),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ------------------------------------------------------------
          // ÜRÜN TABLOSU
          // ------------------------------------------------------------
          pw.Text(
            "TEKLİF KALEMLERİ",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: ["Açıklama", "Miktar", "Birim", "Birim Fiyat", "Toplam"],
            data: items.map((item) {
              return [
                item["description"] ?? "",
                "${item["quantity"] ?? 0}",
                "${item["unit"] ?? ""}",
                "${((item["unit_price"] ?? 0).toDouble()).toStringAsFixed(2)} ₺",
                "${((item["total"] ?? 0).toDouble()).toStringAsFixed(2)} ₺",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 25),

          // ------------------------------------------------------------
          // TOPLAM ALANI
          // ------------------------------------------------------------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _totalRow("Ara Toplam", subtotal),
                  _totalRow("KDV (%20)", tax),

                  if (discountType != "none") pw.SizedBox(height: 6),

                  if (discountType == "percent")
                    _totalRow(
                      "İndirim (%${discountRate.toStringAsFixed(0)})",
                      -discount,
                      red: true,
                    ),

                  if (discountType == "fixed")
                    _totalRow(
                      "İndirim (${discountAmount.toStringAsFixed(0)}₺)",
                      -discount,
                      red: true,
                    ),

                  pw.Divider(),

                  _totalRow(
                    "KDV Dahil Genel Toplam",
                    finalTotal,
                    big: true,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // ------------------------------------------------------------
          // NOTLAR
          // ------------------------------------------------------------
          if ((quote["notes"] ?? "").toString().trim().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "NOTLAR",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(quote["notes"]),
              ],
            ),

          pw.SizedBox(height: 40),

          // ------------------------------------------------------------
          // İMZA ALANLARI
          // ------------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text("Hazırlayan"),
                  pw.SizedBox(height: 40),
                  pw.Text(companyOwner),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text("Müşteri Onayı"),
                  pw.SizedBox(height: 40),
                  pw.Text("İmza / Kaşe"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          // ------------------------------------------------------------
          // FOOTER (Firma alt bilgisi)
          // ------------------------------------------------------------
          pw.Text(invoiceFooter, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return pdf.save();
  }

  // ------------------------------------------------------------
  // TOPLAM SATIR WIDGET
  // ------------------------------------------------------------
  pw.Widget _totalRow(
    String label,
    double value, {
    bool red = false,
    bool big = false,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: big ? 12 : 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: red ? PdfColors.red : PdfColors.black,
            ),
          ),
          pw.Text(
            "${value.toStringAsFixed(2)} ₺",
            style: pw.TextStyle(
              fontSize: big ? 14 : 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: red ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
