// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class QuotePdfService {
  // -------------------------------------------------------------
  // STATIC VERIFY BASE URL (GitHub Pages)
  // -------------------------------------------------------------
  static const String verifyBaseUrl =
      "https://selcukcan74.github.io/redbook-verify/#/verify";

  // -------------------------------------------------------------
  // ANA PDF OLUŞTURMA
  // -------------------------------------------------------------
  static Future<Uint8List> _buildPdf({
    required Map<String, dynamic> quote,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> settings,
  }) async {
    // -------------------------------------------------------------
    // FONTLAR
    // -------------------------------------------------------------
    final fontRegular =
        pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    final fontBold =
        pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"));

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
    );

    // -------------------------------------------------------------
    // ŞİRKET BİLGİLERİ
    // -------------------------------------------------------------
    final companyName = settings["company_name"] ?? "Firma Adı";
    final companyOwner = settings["company_owner"] ?? "-";
    final companyPhone = settings["company_phone"] ?? "-";
    final companyEmail = settings["company_email"] ?? "-";
    final companyAddress = settings["company_address"] ?? "-";
    final invoiceFooter = settings["invoice_footer"] ?? "";
    final logoUrl = settings["company_logo_url"];

    // -------------------------------------------------------------
    // LOGO
    // -------------------------------------------------------------
    pw.Widget logoBlock = _fallbackLogo(companyName);

    if (logoUrl != null && logoUrl.toString().isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(logoUrl));
        if (res.statusCode == 200) {
          logoBlock = pw.Image(
            pw.MemoryImage(res.bodyBytes),
            width: 150,
          );
        }
      } catch (_) {}
    }

    // -------------------------------------------------------------
    // QR + VERIFY LINK
    // -------------------------------------------------------------
    final approveUrl = "$verifyBaseUrl?quoteId=${quote["id"]}";

    final qrBlock = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.BarcodeWidget(
          data: approveUrl,
          barcode: pw.Barcode.qrCode(),
          width: 70,
          height: 70,
        ),
        pw.SizedBox(height: 6),
        pw.Text("Teklifi görüntülemek için", style: pw.TextStyle(fontSize: 9)),
        pw.UrlLink(
          destination: approveUrl,
          child: pw.Text(
            approveUrl,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blue,
              decoration: pw.TextDecoration.underline,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );

    // -------------------------------------------------------------
    // HESAPLAR
    // -------------------------------------------------------------
    final subtotal = (quote["subtotal"] ?? 0).toDouble();
    final taxAmount = (quote["tax"] ?? 0).toDouble();
    final discount = (quote["discount"] ?? 0).toDouble();
    final finalTotal =
        (quote["total_after_discount"] ?? quote["total"] ?? 0).toDouble();

    final taxPercent =
        subtotal == 0 ? 0 : (taxAmount / subtotal) * 100;

    final currency =
        (quote["currency"] ?? settings["default_currency"] ?? "TRY")
            .toString()
            .toUpperCase();

    final currencySymbol = _currencySymbol(currency);

    final issueDate = quote["issue_date"]
        ?.toString()
        .substring(0, 10) ?? "-";

    // -------------------------------------------------------------
    // PDF SAYFA
    // -------------------------------------------------------------
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        footer: (_) => pw.Center(
          child: pw.Text(invoiceFooter, style: pw.TextStyle(fontSize: 9)),
        ),
        build: (_) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              logoBlock,
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "TEKLİF",
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text("Teklif No: ${quote["quote_number"] ?? "-"}"),
                  pw.Text("Tarih: $issueDate"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // ŞİRKET + QR
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(companyName,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text(companyOwner, style: pw.TextStyle(fontSize: 10)),
                  pw.Text("Tel: $companyPhone",
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Text("E-posta: $companyEmail",
                      style: pw.TextStyle(fontSize: 10)),
                  pw.Text(companyAddress,
                      style: pw.TextStyle(fontSize: 10)),
                ],
              ),
              qrBlock,
            ],
          ),

          pw.SizedBox(height: 25),

          // MÜŞTERİ
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("MÜŞTERİ BİLGİLERİ",
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 13)),
                pw.SizedBox(height: 8),
                pw.Text("Firma: ${customer["company"] ?? "-"}"),
                pw.Text("Yetkili: ${customer["name"] ?? "-"}"),
                pw.Text("Telefon: ${customer["phone"] ?? "-"}"),
                pw.Text("E-posta: ${customer["email"] ?? "-"}"),
                pw.Text("Adres: ${customer["address"] ?? "-"}"),
              ],
            ),
          ),

          pw.SizedBox(height: 25),

          // ÜRÜNLER
          pw.Table.fromTextArray(
            headers: const [
              "Açıklama",
              "Miktar",
              "Birim",
              "Birim Fiyat",
              "Toplam"
            ],
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(color: PdfColors.grey400),
            data: items.map((item) {
              final qty = (item["quantity"] ?? 0).toString();
              final unitPrice =
                  (item["unit_price"] ?? 0).toDouble().toStringAsFixed(2);
              final total =
                  (item["total"] ?? 0).toDouble().toStringAsFixed(2);

              return [
                item["description"] ?? "",
                qty,
                item["unit"] ?? "",
                "$unitPrice $currencySymbol",
                "$total $currencySymbol",
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 25),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _modernTotalBox(
              subtotal: subtotal,
              tax: taxAmount,
              finalTotal: finalTotal,
              currencySymbol: currencySymbol,
              taxPercent: taxPercent,
              discount: discount,
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // -------------------------------------------------------------
  // TOPLAM KUTUSU
  // -------------------------------------------------------------
  static pw.Widget _modernTotalBox({
    required double subtotal,
    required double tax,
    required double finalTotal,
    required String currencySymbol,
    required double taxPercent,
    required double discount,
  }) {
    pw.Widget row(String label, double value, {bool bold = false}) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text("${value.toStringAsFixed(2)} $currencySymbol",
              style: pw.TextStyle(
                  fontSize: bold ? 13 : 11,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      );
    }

    return pw.Container(
      width: 280,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          row("Ara Toplam", subtotal),
          row("KDV (%${taxPercent.toStringAsFixed(0)})", tax),
          if (discount > 0) row("İndirim", -discount),
          pw.Divider(),
          row("Genel Toplam", finalTotal, bold: true),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // YARDIMCILAR
  // -------------------------------------------------------------
  static String _currencySymbol(String currency) {
    switch (currency) {
      case "USD":
        return "\$";
      case "EUR":
        return "€";
      case "GBP":
        return "£";
      default:
        return "₺";
    }
  }

  static pw.Widget _fallbackLogo(String name) {
    return pw.Text(
      name,
      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
    );
  }

  // -------------------------------------------------------------
  // PAYLAŞIM
  // -------------------------------------------------------------
  static Future<void> shareRevisionPdf({
    required Map<String, dynamic> snapshot,
    required Map<String, dynamic> settings,
    required int revisionNumber,
  }) async {
    final pdf = await _buildPdf(
      quote: snapshot["quote"],
      customer: snapshot["customer"],
      items: List<Map<String, dynamic>>.from(snapshot["items"] ?? []),
      settings: settings,
    );

    await Printing.sharePdf(
      bytes: pdf,
      filename: "revizyon_$revisionNumber.pdf",
    );
  }

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
    filename: "teklif_${quote["quote_number"] ?? quote["id"]}.pdf",
  );
}

}
