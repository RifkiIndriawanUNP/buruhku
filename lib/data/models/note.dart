import 'package:buruhku/core/utils/json.dart';

class Note {
  String id, title, body;
  DateTime at;
  bool read;
  Note({required this.id, required this.title, required this.body, DateTime? at, this.read = false})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'ti': title, 'b': body, 't': jDateStr(at), 'r': read};
  factory Note.fromJson(Map<String, dynamic> j) =>
      Note(id: j['id'], title: j['ti'], body: j['b'], at: jDate(j['t']), read: j['r']);
}
