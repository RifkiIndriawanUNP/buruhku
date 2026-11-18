import 'package:buruhku/utils/json.dart';

class Note {
  String id, title, body;
  /// Tautan ke objek terkait: 'order', 'request', atau 'chat'. null = notifikasi sistem.
  String? refType, refId;
  DateTime at;
  bool read;
  Note({required this.id, required this.title, required this.body, this.refType, this.refId, DateTime? at, this.read = false})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'ti': title, 'b': body, 't': jDateStr(at), 'r': read, 'rt': refType, 'ri': refId};
  bool get isOrder => refType != null;
  factory Note.fromJson(Map<String, dynamic> j) =>
      Note(id: j['id'], title: j['ti'], body: j['b'], refType: j['rt'], refId: j['ri'], at: jDate(j['t']), read: j['r']);
}
