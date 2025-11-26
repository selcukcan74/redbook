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

  @override
  void initState() {
    super.initState();
    initVerify();
  }

  // ------------------------------------------------
  // URL’den quoteId okuma (hem normal query hem hash)
  // ------------------------------------------------
  String? _extractQuoteIdFromUrl() {
    // 1) Normal query:  /?quoteId=123
    final q1 = Uri.base.queryParameters['quoteId'];
    if (q1 != null && q1.isNotEmpty) return q1;

    // 2) Hash router:  #/verify?quoteId=123
    final fragment = Uri.base.fragment; // "/verify?quoteId=TEST123" gibi
    if (fragment.isEmpty || !fragment.contains('?')) return null;

    // "?quoteId=TEST123" kısmını al
    final fragQuery = fragment.split('?').last;

    try {
      final map = Uri.splitQueryString(fragQuery);
      return map['quoteId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> initVerify() async {
    final id = _extractQuoteIdFromUrl();
    quoteId = id;

    if (quoteId == null || quoteId!.isEmpty) {
      setState(() {
        loading = false;
        quote = null;
      });
      return;
    }

    try {
      final res = await supabase
          .from("quotes")
          .select()
          .eq("id", quoteId!)
          .maybeSingle();

      setState(() {
        quote = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        quote = null;
      });
    }
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

    if (quoteId == null) {
      return const Scaffold(
        body: Center(child: Text("Geçersiz bağlantı (quoteId bulunamadı).")),
      );
    }

    if (quote == null) {
      return const Scaffold(body: Center(child: Text("Teklif bulunamadı.")));
    }

    final status = (quote!["status"] ?? "unknown") as String;

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
