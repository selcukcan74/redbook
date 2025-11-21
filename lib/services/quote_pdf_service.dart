// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuotePdfService {
  static Future<Uint8List> _buildPdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
  }) async {
    // FONTLAR
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    final baseFont = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldData);

    final theme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);

    final doc = pw.Document(theme: theme);

    // ---- VERİLER ----
    final quoteNumber = quote['quote_number'] ?? '';
    final issueDate = (quote['issue_date'] ?? '').toString().substring(0, 10);

    final double subtotal = (quote['subtotal'] ?? 0).toDouble();
    final double tax = (quote['tax'] ?? 0).toDouble();
    final double total = (quote['total'] ?? 0).toDouble();

    final String discountType = quote['discount_type'] ?? "none";
    final double discountRate = (quote['discount_rate'] ?? 0)
        .toDouble(); // 0.10 formatı
    final double discountAmount = (quote['discount_amount'] ?? 0).toDouble();

    double discountValue = 0;

    if (discountType == "percent") {
      discountValue = subtotal * discountRate;
    } else if (discountType == "fixed") {
      discountValue = discountAmount;
    }

    final double totalAfterDiscount =
        (quote['total_after_discount'] ?? (total - discountValue)).toDouble();

    // ---- PDF SAYFA ----
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          // ----------------------------------------------------------
          // HEADER
          // ----------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                  pw.SizedBox(height: 8),
                  pw.Text("Teklif No: $quoteNumber"),
                  pw.Text("Tarih: $issueDate"),
                ],
              ),

              // sağ taraf marka bilgisi
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "REDBOOK",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text("Açıkhava Reklam / Dijital Çözümler"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),

          // ----------------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // ----------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: .8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Müşteri Bilgileri",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text("Firma: ${customer['company'] ?? '-'}"),
                pw.Text("Yetkili: ${customer['name'] ?? '-'}"),
                pw.Text("Telefon: ${customer['phone'] ?? '-'}"),
                pw.Text("Email: ${customer['email'] ?? '-'}"),
                pw.Text("Adres: ${customer['address'] ?? '-'}"),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ----------------------------------------------------------
          // ÜRÜN TABLOSU
          // ----------------------------------------------------------
          pw.Text(
            "Teklif Kalemleri",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#F3F3F3"),
            ),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: ["Açıklama", "Miktar", "Birim", "Birim Fiyat", "Toplam"],
            data: items.map((item) {
              final qty = (item['quantity'] as num).toDouble();
              final price = (item['unit_price'] as num).toDouble();
              final lineTotal = (item['total'] ?? item['line_total'] ?? 0)
                  .toDouble();

              return [
                item['description'] ?? '',
                qty.toStringAsFixed(2),
                item['unit'] ?? '',
                "${price.toStringAsFixed(2)} ₺",
                "${lineTotal.toStringAsFixed(2)} ₺",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 24),

          // ----------------------------------------------------------
          // TOPLAM HESAPLARI
          // ----------------------------------------------------------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(width: .6),
              ),
              child: pw.Column(
                children: [
                  _row("Ara Toplam", subtotal),
                  _row("KDV", tax),

                  if (discountType != "none")
                    _row(
                      discountType == "percent"
                          ? "İndirim (%${(discountRate * 100).toStringAsFixed(0)})"
                          : "İndirim",
                      -discountValue,
                      color: PdfColor.fromInt(0xFFBB0000),
                    ),

                  pw.Divider(),

                  _row("Genel Toplam", total),
                  _row(
                    "Net Ödenecek",
                    totalAfterDiscount,
                    isBold: true,
                    fontSize: 15,
                  ),
                ],
              ),
            ),
          ),

          pw.SizedBox(height: 24),

          // ----------------------------------------------------------
          // NOTLAR
          // ----------------------------------------------------------
          if ((quote['notes'] ?? '').toString().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Notlar / Açıklamalar",
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(quote['notes']),
                pw.SizedBox(height: 20),
              ],
            ),

          // ----------------------------------------------------------
          // İMZA ALANI
          // ----------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text("Hazırlayan"),
                  pw.SizedBox(height: 40),
                  pw.Text("İmza"),
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

    return doc.save();
  }

  // ----------------------------------------------------------
  // TOPLAM SATIRI WIDGETI
  // ----------------------------------------------------------
  static pw.Widget _row(
    String label,
    double value, {
    bool isBold = false,
    double fontSize = 12,
    PdfColor color = const PdfColor(0, 0, 0),
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            "${value.toStringAsFixed(2)} ₺",
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // DIŞA AKTARMA
  // ----------------------------------------------------------
  static Future<void> generateAndShare({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
  }) async {
    final bytes = await _buildPdf(
      quote: quote,
      customer: customer,
      items: items,
    );
    final number = quote['quote_number'] ?? "teklif";
    await Printing.sharePdf(bytes: bytes, filename: "$number.pdf");
  }
}
