// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:redbook/services/notes_service.dart';

class AddNotePage extends StatefulWidget {
  final Map<String, dynamic>? note;
  final VoidCallback onSaved;

  const AddNotePage({super.key, this.note, required this.onSaved});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final NotesService _notesService = NotesService();

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      titleController.text = widget.note!['title'];
      contentController.text = widget.note!['content'];
    }
  }

  Future<void> saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (widget.note == null) {
      await _notesService.addNote(title, content);
    } else {
      await _notesService.updateNote(widget.note!['id'], title, content);
    }

    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Notu Düzenle" : "Yeni Not")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Başlık"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: "İçerik"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveNote,
              child: Text(isEdit ? "Kaydet" : "Ekle"),
            ),
          ],
        ),
      ),
    );
  }
}
