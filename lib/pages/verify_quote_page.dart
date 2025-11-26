import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyQuotePage extends StatefulWidget {
  const VerifyQuotePage({super.key});

  @override
  State<VerifyQuotePage> createState() => _VerifyQuotePageState();
}

class _VerifyQuotePageState extends State<VerifyQuotePage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  Map<String, dynamic>? quote;
  String? quoteId;

  // DEBUG alanları
  String debugBase = '';
  String debugFragment = '';
  Map<String, String> debugQuery = {};
  String debugSource = '';

  @override
  void initState() {
    super.initState();
    initVerify();
  }

  // ---------------------------------------------------
  // URL'den quoteId çekme (hem fragment, hem normal query)
  // ---------------------------------------------------
  String? _extractQuoteId(Uri uri) {
    // 1) Hash içinden dene:  "#/verify?quoteId=123"
    final fragment = uri.fragment; // örn: "/verify?quoteId=123"
    if (fragment.contains("?")) {
      final parts = fragment.split("?");
      if (parts.length >= 2) {
        final queryString = parts[1]; // "quoteId=123"
        try {
          final params = Uri.splitQueryString(queryString);
          if (params["quoteId"] != null) {
            debugSource = "fragment (hash)";
            return params["quoteId"];
          }
        } catch (_) {
          // ignore
        }
      }
    }

    // 2) Normal query (localhost'ta pathUrlStrategy vb. için)
    if (uri.queryParameters["quoteId"] != null) {
      debugSource = "normal queryParameters";
      return uri.queryParameters["quoteId"];
    }

    debugSource = "bulunamadı";
    return null;
  }

  Future<void> initVerify() async {
    final uri = Uri.base;

    // DEBUG verileri kaydet
    debugBase = uri.toString();
    debugFragment = uri.fragment;
    debugQuery = uri.queryParameters;

    quoteId = _extractQuoteId(uri);

    if (quoteId == null) {
      // quoteId hiç gelmiyorsa Supabase'e gitmeye gerek yok
      setState(() => loading = false);
      return;
    }

    try {
      final res = await supabase
          .from("quotes")
          .select()
          .eq("id", quoteId!)
          .maybeSingle();

      quote = res;
    } catch (e) {
      // hata olursa yine debug için saklayabilirsin
      debugSource += " | supabase error: $e";
    }

    setState(() => loading = false);
  }

  Future<void> updateStatus(String newStatus) async {
    if (quoteId == null) return;

    await supabase
        .from("quotes")
        .update({"status": newStatus})
        .eq("id", quoteId!);

    setState(() {
      quote!["status"] = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Eğer quoteId yoksa veya kayıt bulunmadıysa
    if (quoteId == null || quote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Teklif Onay – DEBUG")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teklif bulunamadı veya quoteId alınamadı.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aşağıda debug bilgileri var. Bunlar URL’nin Flutter tarafından nasıl görüldüğünü gösteriyor:",
                ),
                const SizedBox(height: 16),
                Text("Uri.base           : $debugBase"),
                const SizedBox(height: 8),
                Text("Uri.fragment       : $debugFragment"),
                const SizedBox(height: 8),
                Text("Uri.queryParameters: $debugQuery"),
                const SizedBox(height: 8),
                Text("Parse edilen quoteId: $quoteId"),
                const SizedBox(height: 8),
                Text("quoteId kaynağı     : $debugSource"),
              ],
            ),
          ),
        ),
      );
    }

    // Buraya geldiysek, quoteId ve kayıt var
    final status = quote!["status"] ?? "unknown";

    return Scaffold(
      appBar: AppBar(title: const Text("Teklif Onay")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Teklif No: ${quote!["quote_number"]}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text("Durum: $status", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),

            if (status == "accepted")
              const Text(
                "Bu teklif zaten ONAYLANMIŞ ✔",
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),

            if (status == "rejected")
              const Text(
                "Bu teklif REDDEDİLMİŞ ✘",
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),

            if (status == "draft" || status == "sent")
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Teklifi Onayla"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(200, 48),
                    ),
                    onPressed: () => updateStatus("accepted"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Teklifi Reddet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(200, 48),
                    ),
                    onPressed: () => updateStatus("rejected"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
