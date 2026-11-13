part of 'app_state.dart';

/// Notifikasi dalam aplikasi (daftar, toast, jumlah belum dibaca).
class NotificationRepository extends RepoBase {
  NotificationRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  bool get agentMode => hub.agentMode;
  set agentMode(bool v) => hub.agentMode = v;
  List<Chat> get chats => hub.chats;
  set chats(List<Chat> v) => hub.chats = v;
  List<Note> get notes => hub.notes;
  set notes(List<Note> v) => hub.notes = v;
  Note? get toastNote => hub.toastNote;
  set toastNote(Note? v) => hub.toastNote = v;
  String nid(String p) => hub.nid(p);

  // ================= notifikasi =================
  void notify(String t, String b) {
    final n = Note(id: nid('N'), title: t, body: b);
    notes.insert(0, n);
    toastNote = n;
  }

  int get unreadNotes => notes.where((n) => !n.read).length;
  int get unreadChats => chats.where((c) => c.otherAgent != agentMode).fold(0, (a, c) => a + c.unread);
  void readAllNotes() {
    for (final n in notes) {
      n.read = true;
    }
    notifyListeners();
  }
}
