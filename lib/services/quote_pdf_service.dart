// ignore_for_file: unused_local_variable, depend_on_referenced_packages, avoid_print, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class QuotePdfService {
  /// Ana PDF oluşturma
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

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // -------------------------------------------------------------
    // ŞİRKET BİLGİLERİ
    // -------------------------------------------------------------
    final logoUrl = settings["company_logo_url"];
    final companyName = settings["company_name"] ?? "Firma Adı";
    final companyOwner = settings["company_owner"] ?? "-";
    final companyPhone = settings["company_phone"] ?? "-";
    final companyEmail = settings["company_email"] ?? "-";
    final companyAddress = settings["company_address"] ?? "-";
    final invoiceFooter = settings["invoice_footer"] ?? "";

    // -------------------------------------------------------------
    // LOGO YÜKLEME
    // -------------------------------------------------------------
    pw.Widget logoBlock;

    if (logoUrl != null && logoUrl.toString().isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(logoUrl));
        if (res.statusCode == 200) {
          final img = pw.MemoryImage(res.bodyBytes);

          logoBlock = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [pw.Image(img, width: 150)],
          );
        } else {
          logoBlock = _fallbackLogo(companyName);
        }
      } catch (_) {
        logoBlock = _fallbackLogo(companyName);
      }
    } else {
      logoBlock = _fallbackLogo(companyName);
    }

    // -------------------------------------------------------------
    // QR + LİNK
    // -------------------------------------------------------------
    const baseUrl = "https://selcukcan74.github.io/redbook/verify";
    final approveUrl = "$baseUrl/?quoteId=${quote["id"]}";

    final qrBlock = pw.Container(
      width: 210,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.BarcodeWidget(
            data: approveUrl,
            barcode: pw.Barcode.qrCode(),
            width: 70,
            height: 70,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            "Teklifi görüntülemek için:",
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.UrlLink(
            destination: approveUrl,
            child: pw.Text(
              approveUrl,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blue,
                decoration: pw.TextDecoration.underline,
              ),
              softWrap: true,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // -------------------------------------------------------------
    // HESAPLAR
    // -------------------------------------------------------------
    final subtotal = (quote["subtotal"] ?? 0).toDouble();
    final taxAmount = (quote["tax"] ?? 0).toDouble();
    final discount = (quote["discount"] ?? 0).toDouble();

    final totalBeforeDiscount = (quote["total"] ?? (subtotal + taxAmount))
        .toDouble();

    final finalTotal =
        (quote["total_after_discount"] ?? (totalBeforeDiscount - discount))
            .toDouble();

    final discountType = (quote["discount_type"] ?? "none");

    final taxPercent = subtotal == 0
        ? 0
        : ((taxAmount / subtotal) * 100).toDouble();

    // -------------------------------------------------------------
    // PARA BİRİMİ
    // -------------------------------------------------------------
    final currency =
        (quote["currency"] ?? settings["default_currency"] ?? "TRY")
            .toString()
            .toUpperCase();

    final currencySymbol = _currencySymbol(currency);

    // -------------------------------------------------------------
    // PDF SAYFA
    // -------------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(invoiceFooter, style: pw.TextStyle(fontSize: 10)),
        ),
        build: (context) => [
          // ---------------------------------------------------------
          // HEADER
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              logoBlock,
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
                  pw.SizedBox(height: 5),
                  pw.Text("Teklif No: ${quote['quote_number']}"),
                  pw.Text(
                    "Tarih: ${quote['issue_date']?.toString().substring(0, 10)}",
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ---------------------------------------------------------
          // ŞİRKET BİLGİLERİ + QR
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    companyName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(companyOwner, style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    "Tel: $companyPhone",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    "E-posta: $companyEmail",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(companyAddress, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              qrBlock,
            ],
          ),

          pw.SizedBox(height: 28),

          // ---------------------------------------------------------
          // MÜŞTERİ BİLGİLERİ
          // ---------------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.grey600),
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

          pw.SizedBox(height: 30),

          // ---------------------------------------------------------
          // TEKLİF KALEMLERİ TABLOSU
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
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headers: ["Açıklama", "Miktar", "Birim", "Birim Fiyat", "Toplam"],
            data: items.map((item) {
              final qty = (item["quantity"] ?? 0).toString();
              final unitPrice = ((item["unit_price"] ?? 0).toDouble())
                  .toStringAsFixed(2);
              final total =
                  ((item["total"] ?? item["line_total"] ?? 0).toDouble())
                      .toStringAsFixed(2);

              return [
                item["description"] ?? "",
                qty,
                item["unit"] ?? "",
                "$unitPrice $currencySymbol",
                "$total $currencySymbol",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 30),

          // ---------------------------------------------------------
          // MODERN TOPLAM KUTUSU
          // ---------------------------------------------------------
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _modernTotalBox(
              subtotal: subtotal,
              tax: taxAmount,
              finalTotal: finalTotal,
              currencySymbol: currencySymbol,
              taxPercent: taxPercent,
              discountType: discountType,
              discount: discount,
            ),
          ),

          pw.SizedBox(height: 40),

          // ---------------------------------------------------------
          // İMZA ALANLARI
          // ---------------------------------------------------------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text("Hazırlayan"),
                  pw.SizedBox(height: 35),
                  pw.Text(companyOwner),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text("Müşteri Onayı"),
                  pw.SizedBox(height: 35),
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

  // -------------------------------------------------------------
  // MODERN TOPLAM KUTUSU
  // -------------------------------------------------------------
  static pw.Widget _modernTotalBox({
    required double subtotal,
    required double tax,
    required double finalTotal,
    required String currencySymbol,
    required double taxPercent,
    required String discountType,
    required double discount,
  }) {
    return pw.Container(
      width: 300,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColors.grey500, width: 1),
        boxShadow: [
          pw.BoxShadow(
            blurRadius: 6,
            color: PdfColors.grey300,
            offset: const PdfPoint(0, 2), // ✔ DOĞRU
          ),
        ],
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _modernRow("Ara Toplam", subtotal, currencySymbol),
          pw.SizedBox(height: 8),

          _modernRow(
            "KDV (%${taxPercent.toStringAsFixed(0)})",
            tax,
            currencySymbol,
          ),
          pw.SizedBox(height: 8),

          if (discountType != "none") ...[
            _modernRow("İndirim", -discount, currencySymbol, red: true),
            pw.SizedBox(height: 10),
          ],

          pw.Container(height: 1, color: PdfColors.grey400),
          pw.SizedBox(height: 10),

          _modernRow(
            "KDV Dahil Genel Toplam",
            finalTotal,
            currencySymbol,
            big: true,
            bold: true,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MODERN SATIR
  // -------------------------------------------------------------
  static pw.Widget _modernRow(
    String label,
    double value,
    String currencySymbol, {
    bool bold = false,
    bool big = false,
    bool red = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: big ? 13 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          "${value.toStringAsFixed(2)} $currencySymbol",
          style: pw.TextStyle(
            fontSize: big ? 15 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: red ? PdfColors.red : PdfColors.black,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PARA BİRİMİ SEMBOLÜ
  // -------------------------------------------------------------
  static String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case "USD":
        return "\$";
      case "EUR":
        return "€";
      case "GBP":
        return "£";
      case "TRY":
      default:
        return "₺";
    }
  }

  // -------------------------------------------------------------
  // FALLBACK LOGO
  // -------------------------------------------------------------
  static pw.Widget _fallbackLogo(String name) {
    return pw.Text(
      name,
      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
    );
  }

  // -------------------------------------------------------------
  // PDF PAYLAŞMA
  // -------------------------------------------------------------
  static Future<void> generateAndShare({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> settings,
  }) async {
    final pdfData = await _buildPdf(
      quote: quote,
      customer: customer,
      items: items,
      settings: settings,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: "${quote['quote_number']}.pdf",
    );
  }

  static Future<Uint8List> buildRevisionPdf({
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> settings,
  }) async {
    return await _buildPdf(
      quote: snapshot["quote"],
      customer: snapshot["customer"],
      items: List<Map<String, dynamic>>.from(snapshot["items"] ?? []),
      settings: settings,
    );
  }

  static Future<void> shareRevisionPdf({
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> settings,
    required int revisionNumber,
  }) async {
    final pdf = await buildRevisionPdf(snapshot: snapshot, settings: settings);

    await Printing.sharePdf(
      bytes: pdf,
      filename: "revizyon_$revisionNumber.pdf",
    );
  }
}
