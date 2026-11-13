import 'package:buruhku/utils/json.dart';

class Ord {
  String id, reqId, title, cat, address, area, status, ptype, otherId, otherName, pin, escrow, payMethod, disputeId;
  bool iAmClient, myRev, theirRev, tipped, cod;
  int unit, price, fee, extra;
  DateTime created, payBy;
  DateTime? schedAt, paidAt, startedAt, arrivedAt, finishedAt, nextAt, doneAt;
  List<String> log;
  Map<String, dynamic>? chg; // {amount, reason, by}
  Ord({required this.id, required this.reqId, required this.title, required this.cat, this.address = '',
      this.area = '', this.status = 'AWAIT_AGENT', this.ptype = 'lump', required this.otherId, required this.otherName,
      required this.pin, this.escrow = 'none', this.payMethod = '', this.disputeId = '', required this.iAmClient,
      this.myRev = false, this.theirRev = false, this.tipped = false, this.cod = false, this.unit = 0, required this.price,
      this.fee = 0, this.extra = 0, DateTime? created, DateTime? payBy, this.schedAt, this.paidAt, this.startedAt,
      this.arrivedAt, this.finishedAt, this.nextAt, this.doneAt, List<String>? log, this.chg})
      : created = created ?? DateTime.now(),
        payBy = payBy ?? DateTime.now().add(const Duration(minutes: 30)),
        log = log ?? [];
  int get total => price + extra;
  int get commission => (total * 0.1).round();
  int get net => total - commission;
  bool get active => !['COMPLETED', 'REVIEWED', 'CANCELLED', 'REFUNDED', 'RESOLVED'].contains(status);
  bool get paid => escrow != 'none' || ['COMPLETED', 'REVIEWED'].contains(status);
  void addLog(String t) => log.add('${DateTime.now().toIso8601String()}|$t');
  Map<String, dynamic> toJson() => {
        'id': id, 'rq': reqId, 'ti': title, 'ca': cat, 'ad': address, 'ar': area, 'st': status, 'pt': ptype,
        'oi': otherId, 'on': otherName, 'pin': pin, 'es': escrow, 'pm': payMethod, 'di': disputeId, 'ic': iAmClient,
        'mr': myRev, 'tr': theirRev, 'tp': tipped, 'cod': cod, 'un': unit, 'pr': price, 'fe': fee, 'ex': extra, 'cr': jDateStr(created),
        'pb': jDateStr(payBy), 'sa': jDateStr(schedAt), 'pa': jDateStr(paidAt), 'sd': jDateStr(startedAt), 'ai': jDateStr(arrivedAt),
        'fi': jDateStr(finishedAt), 'nx': jDateStr(nextAt), 'dn': jDateStr(doneAt), 'lg': log, 'chg': chg,
      };
  factory Ord.fromJson(Map<String, dynamic> j) => Ord(
        id: j['id'], reqId: j['rq'], title: j['ti'], cat: j['ca'], address: j['ad'], area: j['ar'], status: j['st'],
        ptype: j['pt'], otherId: j['oi'], otherName: j['on'], pin: j['pin'], escrow: j['es'], payMethod: j['pm'],
        disputeId: j['di'], iAmClient: j['ic'], myRev: j['mr'], theirRev: j['tr'], tipped: j['tp'], cod: j['cod'] ?? false, unit: j['un'],
        price: j['pr'], fee: j['fe'], extra: j['ex'], created: jDate(j['cr']), payBy: jDate(j['pb']), schedAt: jDate(j['sa']),
        paidAt: jDate(j['pa']), startedAt: jDate(j['sd']), arrivedAt: jDate(j['ai']), finishedAt: jDate(j['fi']),
        nextAt: jDate(j['nx']), doneAt: jDate(j['dn']), log: List<String>.from(j['lg'] ?? []),
        chg: j['chg'] == null ? null : jMap(j['chg']),
      );
}
