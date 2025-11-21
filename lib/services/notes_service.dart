import 'package:supabase_flutter/supabase_flutter.dart';

class NotesService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getNotes() async {
    final response = await supabase
        .from('notes')
        .select()
        .order('created_at', ascending: false);

    return response;
  }

  Future<void> addNote(String title, String content) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('notes').insert({
      'title': title,
      'content': content,
      'user_id': userId,
    });
  }

  Future<void> updateNote(String id, String title, String content) async {
    await supabase
        .from('notes')
        .update({'title': title, 'content': content})
        .eq('id', id);
  }

  Future<void> deleteNote(String id) async {
    await supabase.from('notes').delete().eq('id', id);
  }
}
