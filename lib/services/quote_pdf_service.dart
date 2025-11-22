// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class QuotePdfService {
  // --------------------------------------------------------
  // PDF OLUŞTURMA
  // --------------------------------------------------------
  static Future<Uint8List> _buildPdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
  }) async {
    // Fontlar
    final fontRegular = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // --------------------------------------------------------
    // GITHUB PAGES QR URL
    // --------------------------------------------------------
    const baseUrl = "https://selcukcan74.github.io/redbook/#/verify";

    final quoteId = quote["id"];
    final approveUrl = "$baseUrl?quoteId=$quoteId";

    print("QuotePdfService → QR URL: $approveUrl");

    // --------------------------------------------------------
    // BACKEND'DEN GELEN TOPLAMLAR (DETAIL SAYFASI İLE AYNI)
    // --------------------------------------------------------
    final subtotal = (quote["subtotal"] as num?)?.toDouble() ?? 0.0;
    final tax = (quote["tax"] as num?)?.toDouble() ?? 0.0;
    final discount = (quote["discount"] as num?)?.toDouble() ?? 0.0;

    final totalBeforeDiscount =
        (quote["total"] as num?)?.toDouble() ?? subtotal + tax;

    final finalTotal =
        (quote["total_after_discount"] as num?)?.toDouble() ??
        (totalBeforeDiscount - discount);

    final discountType = (quote["discount_type"] ?? "none") as String;
    final discountRate = (quote["discount_rate"] as num?)?.toDouble() ?? 0.0;
    final discountAmount =
        (quote["discount_amount"] as num?)?.toDouble() ?? 0.0;

    // --------------------------------------------------------
    // PDF SAYFASI
    // --------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ----------------------------------------------------
          // BAŞLIK + QR
          // ----------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "TEKLİF / SÖZLEŞME",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text("Teklif No: ${quote['quote_number'] ?? '-'}"),
                  if (quote['issue_date'] != null)
                    pw.Text(
                      "Tarih: ${quote['issue_date'].toString().substring(0, 10)}",
                    ),
                ],
              ),

              // QR KOD
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.BarcodeWidget(
                  data: approveUrl,
                  barcode: pw.Barcode.qrCode(),
                  width: 90,
                  height: 90,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ----------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // ----------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 1),
              borderRadius: pw.BorderRadius.circular(8),
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
                pw.SizedBox(height: 8),
                pw.Text("Firma: ${customer['company'] ?? '-'}"),
                pw.Text("Yetkili: ${customer['name'] ?? '-'}"),
                pw.Text("Telefon: ${customer['phone'] ?? '-'}"),
                pw.Text("E-posta: ${customer['email'] ?? '-'}"),
                pw.Text("Adres: ${customer['address'] ?? '-'}"),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ----------------------------------------------------
          // ÜRÜN TABLOSU
          // ----------------------------------------------------
          pw.Text(
            "TEKLİF KALEMLERİ",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              "Açıklama",
              "Miktar",
              "Birim",
              "Birim Fiyat",
              "Toplam",
            ],
            data: items.map((item) {
              final qty = (item["quantity"] as num?)?.toDouble() ?? 0.0;
              final unitPrice = (item["unit_price"] as num?)?.toDouble() ?? 0.0;
              final lineTotal = (item["total"] as num?)?.toDouble() ?? 0.0;

              return [
                (item["description"] ?? "").toString(),
                qty.toStringAsFixed(2),
                (item["unit"] ?? "").toString(),
                "${unitPrice.toStringAsFixed(2)} ₺",
                "${lineTotal.toStringAsFixed(2)} ₺",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // ----------------------------------------------------
          // TOPLAM ALANI
          // ----------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 260,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  children: [
                    _totalRow("Ara Toplam", subtotal),
                    _totalRow("KDV (%20)", tax),
                    if (discountType != "none")
                      _totalRow(
                        discountType == "percent"
                            ? "İndirim (%${discountRate.toStringAsFixed(0)})"
                            : "İndirim (${discountAmount.toStringAsFixed(0)}₺)",
                        -discount,
                        red: true,
                      ),
                    _totalRow("Genel Toplam", totalBeforeDiscount),
                    pw.Divider(),
                    _totalRow(
                      "Net Ödenecek Tutar",
                      finalTotal,
                      bold: true,
                      big: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ----------------------------------------------------
          // NOTLAR
          // ----------------------------------------------------
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
                pw.SizedBox(height: 8),
                pw.Text(quote["notes"].toString()),
                pw.SizedBox(height: 20),
              ],
            ),

          // ----------------------------------------------------
          // QR AÇIKLAMASI
          // ----------------------------------------------------
          pw.Text(
            "Bu teklifi onaylamak veya durumunu görüntülemek için aşağıdaki QR kodu tarayabilirsiniz.",
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 10),

          pw.Row(
            children: [
              pw.BarcodeWidget(
                data: approveUrl,
                barcode: pw.Barcode.qrCode(),
                width: 120,
                height: 120,
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Text(
                  approveUrl,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // ----------------------------------------------------
          // İMZA ALANI
          // ----------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Teklifi Hazırlayan"),
                  pw.SizedBox(height: 40),
                  pw.Text("İmza"),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
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

  // --------------------------------------------------------
  // TOPLAM SATIRI WIDGET'I
  // --------------------------------------------------------
  static pw.Widget _totalRow(
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
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: big ? 12 : 10,
              color: red ? PdfColors.red : PdfColors.black,
            ),
          ),
          pw.Text(
            "${value.toStringAsFixed(2)} ₺",
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: big ? 14 : 10,
              color: red ? PdfColors.red : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // PAYLAŞILABİLİR PDF OLUŞTURMA
  // --------------------------------------------------------
  static Future<void> generateAndShare({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdfBytes = await _buildPdf(
      quote: quote,
      customer: customer,
      items: items,
    );

    final fileName = (quote['quote_number'] ?? 'teklif').toString() + ".pdf";

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
