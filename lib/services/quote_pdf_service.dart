// ignore_for_file: unused_local_variable, depend_on_referenced_packages, avoid_print, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class QuotePdfService {
  /// Ana PDF oluşturma metodu
  static Future<Uint8List> _buildPdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> settings,
  }) async {
    // -------------------------------------------------------------
    // FONTLAR
    // -------------------------------------------------------------
    final fontRegular = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
    );

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(theme: theme);

    // -------------------------------------------------------------
    // LOGO YÜKLEME (URL → MemoryImage, yoksa firma adı)
    // -------------------------------------------------------------
    pw.Widget logoWidget;
    final logoUrl = settings["company_logo_url"];
    final companyName = (settings["company_name"] ?? "Firma Adı").toString();

    if (logoUrl != null && logoUrl.toString().isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl.toString()));
        if (response.statusCode == 200) {
          final logo = pw.MemoryImage(response.bodyBytes);
          logoWidget = pw.Image(logo, width: 90);
        } else {
          logoWidget = pw.Text(
            companyName,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          );
        }
      } catch (e) {
        logoWidget = pw.Text(
          companyName,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        );
      }
    } else {
      logoWidget = pw.Text(
        companyName,
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      );
    }

    // -------------------------------------------------------------
    // QR CODE URL
    // -------------------------------------------------------------
    const baseUrl = "https://selcukcan74.github.io/redbook/#/verify";
    final quoteId = quote["id"];
    final approveUrl = "$baseUrl?quoteId=$quoteId";

    // -------------------------------------------------------------
    // HESAPLAR — DB İLE BİREBİR UYUMLU
    // -------------------------------------------------------------
    // Toplamlar mümkün olduğunca quotes tablosundan alınır.
    final subtotal = (quote["subtotal"] ?? 0).toDouble();
    final taxAmount = (quote["tax"] ?? 0).toDouble();
    final discountValue = (quote["discount"] ?? 0).toDouble();

    final totalBeforeDiscount = (quote["total"] ?? (subtotal + taxAmount))
        .toDouble();

    final finalTotal =
        (quote["total_after_discount"] ?? (totalBeforeDiscount - discountValue))
            .toDouble();

    // İndirim alanları (oran / tutar)
    final discountType = (quote["discount_type"] ?? "none").toString();
    final discountRate = (quote["discount_rate"] ?? 0).toDouble(); // 10 => %10
    final discountAmount = (quote["discount_amount"] ?? 0).toDouble();

    // KDV yüzdesini subtotal + tax üzerinden geri hesaplayalım
    final taxPercent = subtotal == 0
        ? 0
        : (taxAmount / subtotal * 100).toDouble();

    // -------------------------------------------------------------
    // PDF SAYFASI
    // -------------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ---------------------------------------------------------
          // HEADER → Logo + Teklif Bilgileri + QR
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  logoWidget,
                  pw.SizedBox(height: 14),
                  pw.Text(
                    "TEKLİF / SÖZLEŞME",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text("Teklif No: ${quote['quote_number'] ?? '-'}"),
                  pw.Text(
                    "Tarih: ${quote['issue_date'] != null ? quote['issue_date'].toString().substring(0, 10) : '-'}",
                  ),
                ],
              ),

              pw.Column(
                children: [
                  pw.BarcodeWidget(
                    data: approveUrl,
                    barcode: pw.Barcode.qrCode(),
                    width: 110,
                    height: 110,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "QR Kodunu okutarak\nteklifi görüntüleyebilirsiniz",
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // ---------------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // ---------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey600, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "MÜŞTERİ BİLGİLERİ",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Firma: ${customer['company'] ?? '-'}"),
                pw.Text("Yetkili: ${customer['name'] ?? '-'}"),
                pw.Text("Telefon: ${customer['phone'] ?? '-'}"),
                pw.Text("E-posta: ${customer['email'] ?? '-'}"),
                pw.Text("Adres: ${customer['address'] ?? '-'}"),
              ],
            ),
          ),

          pw.SizedBox(height: 28),

          // ---------------------------------------------------------
          // ÜRÜN TABLOSU
          // ---------------------------------------------------------
          pw.Text(
            "TEKLİF KALEMLERİ",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15),
          ),
          pw.SizedBox(height: 12),

          pw.Table.fromTextArray(
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#F2F2F2"),
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: pw.TextStyle(fontSize: 10),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headers: ["Açıklama", "Miktar", "Birim", "Birim Fiyat", "Toplam"],
            data: items.map((item) {
              final qty = (item["quantity"] ?? 0).toString();
              final unitPrice = ((item["unit_price"] ?? 0).toDouble())
                  .toStringAsFixed(2);
              final total =
                  ((item["line_total"] ?? item["total"] ?? 0).toDouble())
                      .toStringAsFixed(2);

              return [
                item["description"] ?? "",
                qty,
                item["unit"] ?? "",
                "$unitPrice ₺",
                "$total ₺",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          // ---------------------------------------------------------
          // TOPLAM BİLGİLERİ (quotes tablosundaki değerler)
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 280,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColors.grey600, width: 1),
                ),
                child: pw.Column(
                  children: [
                    _row("Ara Toplam", subtotal),
                    _row("KDV (%${taxPercent.toStringAsFixed(0)})", taxAmount),

                    if (discountType != "none")
                      _row(
                        discountType == "percent"
                            ? "%${discountRate.toStringAsFixed(0)} İndirim"
                            : "İndirim",
                        -discountValue,
                        red: true,
                      ),

                    pw.Divider(),
                    _row(
                      "KDV Dahil Genel Toplam",
                      finalTotal,
                      bold: true,
                      big: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // ---------------------------------------------------------
          // FOOTER (firma alt yazısı)
          // ---------------------------------------------------------
          if ((settings["invoice_footer"] ?? "").toString().isNotEmpty)
            pw.Text(
              settings["invoice_footer"],
              style: const pw.TextStyle(fontSize: 10),
            ),

          pw.SizedBox(height: 30),

          // ---------------------------------------------------------
          // İMZA ALANLARI
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text("Hazırlayan"),
                  pw.SizedBox(height: 40),
                  pw.Text(settings["company_owner"] ?? "İmza"),
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
        ],
      ),
    );

    return pdf.save();
  }

  /// -------------------------------------------------------------
  /// Toplam satır widget
  /// -------------------------------------------------------------
  static pw.Widget _row(
    String label,
    double value, {
    bool bold = false,
    bool big = false,
    bool red = false,
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

  /// -------------------------------------------------------------
  /// PDF OLUŞTURMA & PAYLAŞMA
  /// -------------------------------------------------------------
  static Future<void> generateAndShare({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> settings,
  }) async {
    final pdfBytes = await _buildPdf(
      quote: quote,
      customer: customer,
      items: items,
      settings: settings,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: "${quote['quote_number']}.pdf",
    );
  }
}
