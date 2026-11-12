import 'package:buruhku/core/utils/json.dart';

class Msg {
  String id, from, type, body; // from: me / other / system ; type: text image location offer order_offer contact ewallet system
  Map<String, dynamic> data;
  DateTime at;
  bool flagged;
  Msg({required this.id, required this.from, this.type = 'text', this.body = '', Map<String, dynamic>? data,
      DateTime? at, this.flagged = false})
      : data = data ?? {},
        at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'f': from, 'ty': type, 'b': body, 'd': data, 't': jDateStr(at), 'fl': flagged};
  factory Msg.fromJson(Map<String, dynamic> j) => Msg(id: j['id'], from: j['f'], type: j['ty'], body: j['b'],
      data: jMap(j['d']), at: jDate(j['t']), flagged: j['fl']);
}

class Chat {
  String id, type, refId, otherId, otherName, title; // type: order / direct
  bool otherAgent, closed;
  int unread;
  List<Msg> msgs;
  Chat({required this.id, required this.type, this.refId = '', required this.otherId, required this.otherName,
      this.title = '', required this.otherAgent, this.closed = false, this.unread = 0, List<Msg>? msgs})
      : msgs = msgs ?? [];
  Map<String, dynamic> toJson() => {'id': id, 'ty': type, 'rf': refId, 'oi': otherId, 'on': otherName, 'ti': title,
        'oa': otherAgent, 'cl': closed, 'un': unread, 'ms': msgs.map((m) => m.toJson()).toList()};
  factory Chat.fromJson(Map<String, dynamic> j) => Chat(id: j['id'], type: j['ty'], refId: j['rf'], otherId: j['oi'],
      otherName: j['on'], title: j['ti'], otherAgent: j['oa'], closed: j['cl'], unread: j['un'],
      msgs: jList(j['ms'], Msg.fromJson));
}
