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

  Future<void> initVerify() async {
    final params = Uri.base.queryParameters;
    quoteId = params["quoteId"];

    if (quoteId == null) {
      setState(() => loading = false);
      return;
    }

    final res = await supabase
        .from("quotes")
        .select()
        .eq("id", quoteId!)
        .maybeSingle();

    setState(() {
      quote = res;
      loading = false;
    });
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

    if (quoteId == null || quote == null) {
      return const Scaffold(body: Center(child: Text("Teklif bulunamadı.")));
    }

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
