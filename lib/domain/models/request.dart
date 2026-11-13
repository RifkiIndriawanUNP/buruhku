import 'package:buruhku/utils/json.dart';
import 'package:buruhku/domain/models/catalog.dart';

class Acc {
  String agentId, status, note; // accepted / declined / withdrawn / selected
  int price;
  DateTime at;
  Acc({required this.agentId, required this.price, this.status = 'accepted', this.note = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'a': agentId, 'p': price, 's': status, 'n': note, 't': jDateStr(at)};
  factory Acc.fromJson(Map<String, dynamic> j) =>
      Acc(agentId: j['a'], price: j['p'], status: j['s'], note: j['n'], at: jDate(j['t']));
}

class Req {
  String id, clientId, clientName, title, cat, desc, address, area, status, ptype, notes, sched, reason;
  int workers, price, quota, photos;
  double dur, radius, dist, lat, lng, clientRating;
  DateTime? schedAt;
  DateTime created, expires;
  List<Acc> acc;
  List<String> chosen;
  bool direct;
  Req({this.id = '', this.clientId = 'me', this.clientName = '', required this.title, required this.cat,
      this.desc = '', this.address = '', this.area = '', this.status = 'OPEN', this.ptype = 'lump', this.notes = '',
      this.sched = 'now', this.reason = '', this.workers = 1, required this.price, this.quota = 5, this.photos = 0,
      this.dur = 0, this.radius = 10, this.dist = 0, this.lat = 0.5, this.lng = 0.5, this.clientRating = 4.8,
      this.schedAt, DateTime? created, DateTime? expires, List<Acc>? acc, List<String>? chosen, this.direct = false})
      : created = created ?? DateTime.now(),
        expires = expires ?? DateTime.now().add(const Duration(minutes: 30)),
        acc = acc ?? [],
        chosen = chosen ?? [];
  bool get mine => clientId == 'me';
  int get unitTotal => totalOf(ptype, price, dur);
  Map<String, dynamic> toJson() => {
        'id': id, 'ci': clientId, 'cn': clientName, 'ti': title, 'ca': cat, 'de': desc, 'ad': address, 'ar': area,
        'st': status, 'pt': ptype, 'no': notes, 'sc': sched, 're': reason, 'wk': workers, 'pr': price, 'qu': quota,
        'ph': photos, 'du': dur, 'ra': radius, 'di': dist, 'la': lat, 'ln': lng, 'cr': clientRating,
        'sa': jDateStr(schedAt), 'c': jDateStr(created), 'e': jDateStr(expires), 'acc': acc.map((a) => a.toJson()).toList(),
        'ch': chosen, 'dr': direct,
      };
  factory Req.fromJson(Map<String, dynamic> j) => Req(
        id: j['id'], clientId: j['ci'], clientName: j['cn'], title: j['ti'], cat: j['ca'], desc: j['de'],
        address: j['ad'], area: j['ar'], status: j['st'], ptype: j['pt'], notes: j['no'], sched: j['sc'],
        reason: j['re'], workers: j['wk'], price: j['pr'], quota: j['qu'], photos: j['ph'],
        dur: (j['du'] as num).toDouble(), radius: (j['ra'] as num).toDouble(), dist: (j['di'] as num).toDouble(),
        lat: (j['la'] as num).toDouble(), lng: (j['ln'] as num).toDouble(), clientRating: (j['cr'] as num).toDouble(),
        schedAt: jDate(j['sa']), created: jDate(j['c']), expires: jDate(j['e']),
        acc: jList(j['acc'], Acc.fromJson), chosen: List<String>.from(j['ch'] ?? []), direct: j['dr'] ?? false,
      );
}
