import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revision_compare_page.dart';
import '../../services/quote_service.dart';

class RevisionListPage extends StatefulWidget {
  final String quoteId;

  const RevisionListPage({super.key, required this.quoteId});

  @override
  State<RevisionListPage> createState() => _RevisionListPageState();
}

class _RevisionListPageState extends State<RevisionListPage> {
  final client = Supabase.instance.client;

  List<Map<String, dynamic>> revisions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRevisions();
  }

  Future<void> loadRevisions() async {
    setState(() => loading = true);

    final res = await client
        .from("quote_revisions")
        .select()
        .eq("quote_id", widget.quoteId)
        .order("revision_number", ascending: false);

    revisions = List<Map<String, dynamic>>.from(res);

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Revizyon Geçmişi")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : revisions.isEmpty
          ? const Center(child: Text("Henüz revizyon yok."))
          : ListView.builder(
              itemCount: revisions.length,
              itemBuilder: (context, i) {
                final rev = revisions[i];
                final snapshot = Map<String, dynamic>.from(
                  rev["snapshot"] ?? {},
                );
                final quote = Map<String, dynamic>.from(
                  snapshot["quote"] ?? {},
                );

                final dateStr =
                    quote["issue_date"]?.toString().substring(0, 10) ?? "";

                return Card(
                  child: ListTile(
                    title: Text("Revizyon ${rev['revision_number']}"),
                    subtitle: Text("Tarih: $dateStr"),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.compare),
                          tooltip: "Bu revizyonu güncel teklifle karşılaştır",
                          onPressed: () async {
                            final current = await QuoteService()
                                .getQuoteSnapshot(widget.quoteId);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RevisionComparePage(
                                  revision: snapshot,
                                  current: current,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.restart_alt),
                          tooltip: "Bu revizyona geri dön",
                          onPressed: () async {
                            final ok = await _confirmRestore(context);
                            if (!ok) return;

                            await QuoteService().restoreFromRevision(
                              rev["id"].toString(),
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Revizyon geri yüklendi"),
                              ),
                            );

                            Navigator.pop(context, true);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmRestore(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Revizyonu Geri Yükle"),
            content: const Text(
              "Bu revizyonu geri yüklemek istediğinize emin misiniz? "
              "Mevcut teklif ve ürünler bu revizyonun verileriyle değiştirilecek.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Evet, Geri Yükle"),
              ),
            ],
          ),
        ) ??
        false;
  }
}
