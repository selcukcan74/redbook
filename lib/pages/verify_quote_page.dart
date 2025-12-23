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
  // URL’den quoteId okuma (query + hash uyumlu)
  // ------------------------------------------------
  String? _extractQuoteIdFromUrl() {
    // 1) Normal query: ?quoteId=123
    final direct = Uri.base.queryParameters['quoteId'];
    if (direct != null && direct.isNotEmpty) return direct;

    // 2) Hash router: #/verify?quoteId=123
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty || !fragment.contains('?')) return null;

    final cleanFragment = fragment.startsWith('/')
        ? fragment.substring(1)
        : fragment;

    final queryPart = cleanFragment.split('?').last;

    try {
      final params = Uri.splitQueryString(queryPart);
      return params['quoteId'];
    } catch (_) {
      return null;
    }
  }

  Future<void> initVerify() async {
    final id = _extractQuoteIdFromUrl();
    quoteId = id;

    if (quoteId == null || quoteId!.isEmpty) {
      if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        quote = res;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
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

    if (!mounted) return;
    setState(() {
      quote!["status"] = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quoteId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Geçersiz doğrulama bağlantısı.\nLütfen QR kodu tekrar okutun.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (quote == null) {
      return const Scaffold(
        body: Center(child: Text("Teklif bulunamadı.")),
      );
    }

    final status = (quote!["status"] ?? "unknown") as String;

    return Scaffold(
      appBar: AppBar(title: const Text("Teklif Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Teklif No: ${quote!["quote_number"]}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Text("Durum: $status",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 30),

            if (status == "accepted")
              const Text(
                "Bu teklif ONAYLANMIŞ ✔",
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
                      minimumSize: const Size(220, 48),
                    ),
                    onPressed: () => updateStatus("accepted"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Teklifi Reddet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(220, 48),
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
