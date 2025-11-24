import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revision_detail_page.dart';

class QuoteRevisionsPage extends StatelessWidget {
  final String quoteId;

  const QuoteRevisionsPage({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text("Revizyon Geçmişi")),
      body: FutureBuilder(
        future: supabase
            .from("quote_revisions")
            .select()
            .eq("quote_id", quoteId)
            .order("revision_number", ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = List<Map<String, dynamic>>.from(snapshot.data as List);

          if (list.isEmpty) {
            return const Center(child: Text("Henüz revizyon bulunmuyor."));
          }

          return ListView(
            children: list.map((rev) {
              return ListTile(
                title: Text("Revizyon ${rev['revision_number']}"),
                subtitle: Text(rev["created_at"]),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RevisionDetailPage(
                        snapshot: rev["snapshot"],
                        revisionNumber: rev["revision_number"],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
