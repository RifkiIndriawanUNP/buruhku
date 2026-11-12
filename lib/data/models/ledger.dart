import 'package:buruhku/core/utils/json.dart';

class Led {
  String id, role, type, note; // role: c (klien) / a (agen)
  int amount;
  DateTime at;
  Led({required this.id, required this.role, required this.type, required this.amount, this.note = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'r': role, 'ty': type, 'a': amount, 'n': note, 't': jDateStr(at)};
  factory Led.fromJson(Map<String, dynamic> j) =>
      Led(id: j['id'], role: j['r'], type: j['ty'], amount: j['a'], note: j['n'], at: jDate(j['t']));
}
