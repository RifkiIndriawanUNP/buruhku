import 'package:buruhku/core/utils/json.dart';

class Rep {
  String id, no, cat, desc, target, orderId, status, action, police;
  int evid;
  DateTime at;
  Rep({required this.id, required this.no, required this.cat, required this.desc, this.target = '', this.orderId = '',
      this.status = 'Diterima', this.action = '', this.police = '', this.evid = 0, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'no': no, 'c': cat, 'd': desc, 'tg': target, 'o': orderId, 's': status,
        'ac': action, 'po': police, 'ev': evid, 't': jDateStr(at)};
  factory Rep.fromJson(Map<String, dynamic> j) => Rep(id: j['id'], no: j['no'], cat: j['c'], desc: j['d'],
      target: j['tg'], orderId: j['o'], status: j['s'], action: j['ac'], police: j['po'], evid: j['ev'], at: jDate(j['t']));
}

class Sos {
  String id, orderId, info;
  bool resolved;
  DateTime at;
  Sos({required this.id, this.orderId = '', this.info = '', this.resolved = false, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'i': info, 'r': resolved, 't': jDateStr(at)};
  factory Sos.fromJson(Map<String, dynamic> j) =>
      Sos(id: j['id'], orderId: j['o'], info: j['i'], resolved: j['r'], at: jDate(j['t']));
}

class Tix {
  String id, no, subject, body, status, reply;
  DateTime at;
  Tix({required this.id, required this.no, required this.subject, required this.body, this.status = 'Dibuka',
      this.reply = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'no': no, 's': subject, 'b': body, 'st': status, 'r': reply, 't': jDateStr(at)};
  factory Tix.fromJson(Map<String, dynamic> j) => Tix(id: j['id'], no: j['no'], subject: j['s'], body: j['b'],
      status: j['st'], reply: j['r'], at: jDate(j['t']));
}

class Disp {
  String id, orderId, type, desc, status, response, decision, prev; // status: open / responded / resolved / cancelled
  int evid;
  DateTime at;
  Disp({required this.id, required this.orderId, required this.type, required this.desc, this.status = 'open',
      this.response = '', this.decision = '', this.prev = 'PENDING_CONFIRM', this.evid = 0, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'ty': type, 'd': desc, 's': status, 'r': response,
        'de': decision, 'pv': prev, 'ev': evid, 't': jDateStr(at)};
  factory Disp.fromJson(Map<String, dynamic> j) => Disp(id: j['id'], orderId: j['o'], type: j['ty'], desc: j['d'],
      status: j['s'], response: j['r'], decision: j['de'], prev: j['pv'] ?? 'PENDING_CONFIRM', evid: j['ev'], at: jDate(j['t']));
}
