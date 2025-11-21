import 'package:flutter/material.dart';
import 'package:redbook/services/notes_service.dart';
import 'add_note_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NotesService _notesService = NotesService();
  List<Map<String, dynamic>> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    final data = await _notesService.getNotes();
    setState(() {
      notes = data;
      loading = false;
    });
  }

  Future<void> deleteNote(String id) async {
    await _notesService.deleteNote(id);
    fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notlarım")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddNotePage(onSaved: fetchNotes)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final n = notes[index];

                return ListTile(
                  title: Text(n['title']),
                  subtitle: Text(n['content']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteNote(n['id']),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddNotePage(note: n, onSaved: fetchNotes),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
