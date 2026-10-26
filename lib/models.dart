import 'package:flutter/material.dart';

// ---------- helper JSON ----------
Map<String, dynamic> _m(dynamic x) => Map<String, dynamic>.from(x as Map);
List<T> _lm<T>(dynamic x, T Function(Map<String, dynamic>) f) =>
    ((x ?? []) as List).map((e) => f(_m(e))).toList();
DateTime? _dt(dynamic s) => s == null ? null : DateTime.parse(s as String);
String? _ds(DateTime? d) => d?.toIso8601String();

// ---------- kategori ----------
class Cat {
  final String id, name;
  final IconData icon;
  final int risk; // 1 rendah, 2 sensitif (masuk rumah / anak)
  final int lo, hi; // rekomendasi harga borongan
  const Cat(this.id, this.name, this.icon, this.risk, this.lo, this.hi);
}

const cats = <Cat>[
  Cat('clean', 'Cleaning', Icons.cleaning_services_outlined, 2, 50000, 250000),
  Cat('elec', 'Servis Elektronik Ringan', Icons.electrical_services_outlined, 1, 40000, 200000),
  Cat('move', 'Angkat & Pindahan', Icons.local_shipping_outlined, 1, 80000, 500000),
  Cat('garden', 'Taman & Halaman', Icons.yard_outlined, 1, 50000, 300000),
  Cat('repair', 'Perbaikan Rumah Ringan', Icons.handyman_outlined, 1, 75000, 400000),
  Cat('errand', 'Antar-Jemput & Titip', Icons.directions_run, 2, 20000, 150000),
  Cat('laundry', 'Laundry / Setrika', Icons.local_laundry_service_outlined, 1, 30000, 150000),
  Cat('other', 'Lain-lain / Apa Saja', Icons.apps_outlined, 1, 30000, 300000),
];
Cat catOf(String id) => cats.firstWhere((c) => c.id == id, orElse: () => cats.last);

const ptypes = {'lump': 'Borongan', 'hourly': 'Per jam', 'daily': 'Harian'};
String unitOf(String pt) => pt == 'hourly' ? '/jam' : pt == 'daily' ? '/hari' : '';

int totalOf(String ptype, int price, double dur) =>
    ptype == 'lump' ? price : (price * (dur <= 0 ? 1 : dur)).round();
int feeOf(int amt) => (amt * 0.02).round().clamp(2000, 5000).toInt();
List<int> recRange(String cat, String pt) {
  if (pt == 'hourly') return [15000, 50000];
  if (pt == 'daily') return [100000, 250000];
  final c = catOf(cat);
  return [c.lo, c.hi];
}

const ordLabels = {
  'AWAIT_AGENT': 'Menunggu konfirmasi agen',
  'AGREED': 'Menunggu pembayaran',
  'SCHEDULED': 'Dijadwalkan',
  'ON_THE_WAY': 'Agen berangkat',
  'ARRIVED': 'Agen tiba',
  'IN_PROGRESS': 'Sedang dikerjakan',
  'PENDING_CONFIRM': 'Menunggu konfirmasi selesai',
  'COMPLETED': 'Selesai',
  'REVIEWED': 'Selesai & dinilai',
  'CANCELLED': 'Dibatalkan',
  'REFUNDED': 'Dana dikembalikan',
  'DISPUTED': 'Sengketa',
  'RESOLVED': 'Sengketa selesai',
};
const reqLabels = {
  'IN_REVIEW': 'Ditinjau admin',
  'OPEN': 'Mencari agen',
  'HAS_ACCEPTORS': 'Ada agen',
  'FULL': 'Slot penuh',
  'LOCKED': 'Terisi',
  'EXPIRED': 'Kedaluwarsa',
  'CANCELLED': 'Dibatalkan',
  'REJECTED': 'Ditolak',
};

const templates = <Map<String, dynamic>>[
  {'t': 'Nyetrika baju', 'c': 'laundry', 'd': 'Menyetrika satu keranjang baju harian, sekitar 30 potong, sampai rapi.', 'p': 60000, 'pt': 'lump'},
  {'t': 'Bersihkan halaman', 'c': 'garden', 'd': 'Menyapu daun, memangkas rumput dan merapikan halaman depan serta belakang rumah.', 'p': 120000, 'pt': 'lump'},
  {'t': 'Angkat barang', 'c': 'move', 'd': 'Mengangkat lemari dan kardus dari lantai satu ke mobil bak, sekitar 15 barang.', 'p': 150000, 'pt': 'lump'},
  {'t': 'Bersihkan rumah', 'c': 'clean', 'd': 'Menyapu, mengepel dan membersihkan kamar mandi rumah tipe 36 sampai bersih.', 'p': 25000, 'pt': 'hourly'},
  {'t': 'Titip belikan makanan', 'c': 'errand', 'd': 'Membelikan makanan di warung dekat rumah dan mengantarnya ke alamat saya.', 'p': 25000, 'pt': 'lump'},
];

// ---------- agen simulasi ----------
class Agent {
  final String id, name, bio;
  final List<String> cats;
  final double rating, dist;
  final int jobs, level, base;
  final bool verified, online, direct;
  Agent({required this.id, required this.name, required this.bio, required this.cats, required this.rating,
      required this.dist, required this.jobs, required this.level, required this.base,
      required this.verified, required this.online, required this.direct});
  String get short {
    final p = name.split(' ');
    return p.length > 1 ? '${p.first} ${p.last[0]}.' : name;
  }
}

class Acc {
  String agentId, status, note; // accepted / declined / withdrawn / selected
  int price;
  DateTime at;
  Acc({required this.agentId, required this.price, this.status = 'accepted', this.note = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'a': agentId, 'p': price, 's': status, 'n': note, 't': _ds(at)};
  factory Acc.fromJson(Map<String, dynamic> j) =>
      Acc(agentId: j['a'], price: j['p'], status: j['s'], note: j['n'], at: _dt(j['t']));
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
        'sa': _ds(schedAt), 'c': _ds(created), 'e': _ds(expires), 'acc': acc.map((a) => a.toJson()).toList(),
        'ch': chosen, 'dr': direct,
      };
  factory Req.fromJson(Map<String, dynamic> j) => Req(
        id: j['id'], clientId: j['ci'], clientName: j['cn'], title: j['ti'], cat: j['ca'], desc: j['de'],
        address: j['ad'], area: j['ar'], status: j['st'], ptype: j['pt'], notes: j['no'], sched: j['sc'],
        reason: j['re'], workers: j['wk'], price: j['pr'], quota: j['qu'], photos: j['ph'],
        dur: (j['du'] as num).toDouble(), radius: (j['ra'] as num).toDouble(), dist: (j['di'] as num).toDouble(),
        lat: (j['la'] as num).toDouble(), lng: (j['ln'] as num).toDouble(), clientRating: (j['cr'] as num).toDouble(),
        schedAt: _dt(j['sa']), created: _dt(j['c']), expires: _dt(j['e']),
        acc: _lm(j['acc'], Acc.fromJson), chosen: List<String>.from(j['ch'] ?? []), direct: j['dr'] ?? false,
      );
}

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
        'mr': myRev, 'tr': theirRev, 'tp': tipped, 'cod': cod, 'un': unit, 'pr': price, 'fe': fee, 'ex': extra, 'cr': _ds(created),
        'pb': _ds(payBy), 'sa': _ds(schedAt), 'pa': _ds(paidAt), 'sd': _ds(startedAt), 'ai': _ds(arrivedAt),
        'fi': _ds(finishedAt), 'nx': _ds(nextAt), 'dn': _ds(doneAt), 'lg': log, 'chg': chg,
      };
  factory Ord.fromJson(Map<String, dynamic> j) => Ord(
        id: j['id'], reqId: j['rq'], title: j['ti'], cat: j['ca'], address: j['ad'], area: j['ar'], status: j['st'],
        ptype: j['pt'], otherId: j['oi'], otherName: j['on'], pin: j['pin'], escrow: j['es'], payMethod: j['pm'],
        disputeId: j['di'], iAmClient: j['ic'], myRev: j['mr'], theirRev: j['tr'], tipped: j['tp'], cod: j['cod'] ?? false, unit: j['un'],
        price: j['pr'], fee: j['fe'], extra: j['ex'], created: _dt(j['cr']), payBy: _dt(j['pb']), schedAt: _dt(j['sa']),
        paidAt: _dt(j['pa']), startedAt: _dt(j['sd']), arrivedAt: _dt(j['ai']), finishedAt: _dt(j['fi']),
        nextAt: _dt(j['nx']), doneAt: _dt(j['dn']), log: List<String>.from(j['lg'] ?? []),
        chg: j['chg'] == null ? null : _m(j['chg']),
      );
}

class Msg {
  String id, from, type, body; // from: me / other / system ; type: text image location offer order_offer contact ewallet system
  Map<String, dynamic> data;
  DateTime at;
  bool flagged;
  Msg({required this.id, required this.from, this.type = 'text', this.body = '', Map<String, dynamic>? data,
      DateTime? at, this.flagged = false})
      : data = data ?? {},
        at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'f': from, 'ty': type, 'b': body, 'd': data, 't': _ds(at), 'fl': flagged};
  factory Msg.fromJson(Map<String, dynamic> j) => Msg(id: j['id'], from: j['f'], type: j['ty'], body: j['b'],
      data: _m(j['d']), at: _dt(j['t']), flagged: j['fl']);
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
      msgs: _lm(j['ms'], Msg.fromJson));
}

class Note {
  String id, title, body;
  DateTime at;
  bool read;
  Note({required this.id, required this.title, required this.body, DateTime? at, this.read = false})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'ti': title, 'b': body, 't': _ds(at), 'r': read};
  factory Note.fromJson(Map<String, dynamic> j) =>
      Note(id: j['id'], title: j['ti'], body: j['b'], at: _dt(j['t']), read: j['r']);
}

class Led {
  String id, role, type, note; // role: c (klien) / a (agen)
  int amount;
  DateTime at;
  Led({required this.id, required this.role, required this.type, required this.amount, this.note = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'r': role, 'ty': type, 'a': amount, 'n': note, 't': _ds(at)};
  factory Led.fromJson(Map<String, dynamic> j) =>
      Led(id: j['id'], role: j['r'], type: j['ty'], amount: j['a'], note: j['n'], at: _dt(j['t']));
}

class Rep {
  String id, no, cat, desc, target, orderId, status, action, police;
  int evid;
  DateTime at;
  Rep({required this.id, required this.no, required this.cat, required this.desc, this.target = '', this.orderId = '',
      this.status = 'Diterima', this.action = '', this.police = '', this.evid = 0, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'no': no, 'c': cat, 'd': desc, 'tg': target, 'o': orderId, 's': status,
        'ac': action, 'po': police, 'ev': evid, 't': _ds(at)};
  factory Rep.fromJson(Map<String, dynamic> j) => Rep(id: j['id'], no: j['no'], cat: j['c'], desc: j['d'],
      target: j['tg'], orderId: j['o'], status: j['s'], action: j['ac'], police: j['po'], evid: j['ev'], at: _dt(j['t']));
}

class Sos {
  String id, orderId, info;
  bool resolved;
  DateTime at;
  Sos({required this.id, this.orderId = '', this.info = '', this.resolved = false, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'i': info, 'r': resolved, 't': _ds(at)};
  factory Sos.fromJson(Map<String, dynamic> j) =>
      Sos(id: j['id'], orderId: j['o'], info: j['i'], resolved: j['r'], at: _dt(j['t']));
}

class Tix {
  String id, no, subject, body, status, reply;
  DateTime at;
  Tix({required this.id, required this.no, required this.subject, required this.body, this.status = 'Dibuka',
      this.reply = '', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'no': no, 's': subject, 'b': body, 'st': status, 'r': reply, 't': _ds(at)};
  factory Tix.fromJson(Map<String, dynamic> j) => Tix(id: j['id'], no: j['no'], subject: j['s'], body: j['b'],
      status: j['st'], reply: j['r'], at: _dt(j['t']));
}

class Disp {
  String id, orderId, type, desc, status, response, decision, prev; // status: open / responded / resolved / cancelled
  int evid;
  DateTime at;
  Disp({required this.id, required this.orderId, required this.type, required this.desc, this.status = 'open',
      this.response = '', this.decision = '', this.prev = 'PENDING_CONFIRM', this.evid = 0, DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'ty': type, 'd': desc, 's': status, 'r': response,
        'de': decision, 'pv': prev, 'ev': evid, 't': _ds(at)};
  factory Disp.fromJson(Map<String, dynamic> j) => Disp(id: j['id'], orderId: j['o'], type: j['ty'], desc: j['d'],
      status: j['s'], response: j['r'], decision: j['de'], prev: j['pv'] ?? 'PENDING_CONFIRM', evid: j['ev'], at: _dt(j['t']));
}

class Rev {
  String id, orderId, aboutId, from, comment;
  int rating;
  List<String> tags;
  bool pub;
  DateTime at;
  Rev({required this.id, this.orderId = '', required this.aboutId, required this.from, required this.rating,
      List<String>? tags, this.comment = '', this.pub = true, DateTime? at})
      : tags = tags ?? [],
        at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'ab': aboutId, 'f': from, 'r': rating, 'tg': tags,
        'c': comment, 'p': pub, 't': _ds(at)};
  factory Rev.fromJson(Map<String, dynamic> j) => Rev(id: j['id'], orderId: j['o'], aboutId: j['ab'], from: j['f'],
      rating: j['r'], tags: List<String>.from(j['tg'] ?? []), comment: j['c'], pub: j['p'], at: _dt(j['t']));
}

class Payout {
  String id, dest, status;
  int amount;
  DateTime at;
  Payout({required this.id, required this.amount, required this.dest, this.status = 'Diproses', DateTime? at})
      : at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'a': amount, 'd': dest, 's': status, 't': _ds(at)};
  factory Payout.fromJson(Map<String, dynamic> j) =>
      Payout(id: j['id'], amount: j['a'], dest: j['d'], status: j['s'], at: _dt(j['t']));
}

class Kyc {
  String status = 'none'; // none / pending / approved / rejected / needs_more
  String name = '', nik = '', birth = '', addr = '', emName = '', emPhone = '', bank = 'BCA', bankNo = '',
      bankHolder = '', reason = '';
  bool photo = false, ktp = false, selfie = false, skck = false, agree = false, online = false, directOk = true;
  List<String> cats = [];
  double radius = 5;
  int fromH = 8, toH = 17, tries = 0;
  DateTime? submitted;
  Map<String, dynamic> toJson() => {'status': status, 'name': name, 'nik': nik, 'birth': birth, 'addr': addr,
        'emName': emName, 'emPhone': emPhone, 'bank': bank, 'bankNo': bankNo, 'bankHolder': bankHolder,
        'reason': reason, 'photo': photo, 'ktp': ktp, 'selfie': selfie, 'skck': skck, 'agree': agree,
        'online': online, 'directOk': directOk, 'cats': cats, 'radius': radius, 'fromH': fromH, 'toH': toH,
        'tries': tries, 'submitted': _ds(submitted)};
  static Kyc fromJson(Map<String, dynamic> j) {
    final k = Kyc();
    k.status = j['status'];
    k.name = j['name'];
    k.nik = j['nik'];
    k.birth = j['birth'];
    k.addr = j['addr'];
    k.emName = j['emName'];
    k.emPhone = j['emPhone'];
    k.bank = j['bank'];
    k.bankNo = j['bankNo'];
    k.bankHolder = j['bankHolder'];
    k.reason = j['reason'];
    k.photo = j['photo'];
    k.ktp = j['ktp'];
    k.selfie = j['selfie'];
    k.skck = j['skck'];
    k.agree = j['agree'];
    k.online = j['online'];
    k.directOk = j['directOk'];
    k.cats = List<String>.from(j['cats']);
    k.radius = (j['radius'] as num).toDouble();
    k.fromH = j['fromH'];
    k.toH = j['toH'];
    k.tries = j['tries'];
    k.submitted = _dt(j['submitted']);
    return k;
  }
}

List<T> listFrom<T>(dynamic x, T Function(Map<String, dynamic>) f) => _lm(x, f);

// ---------- lokasi tersimpan ----------
class SavedLoc {
  String id, label, address;
  double lat, lng;
  SavedLoc({required this.id, required this.label, required this.address, this.lat = 0.5, this.lng = 0.5});
  Map<String, dynamic> toJson() => {'id': id, 'l': label, 'a': address, 'la': lat, 'ln': lng};
  factory SavedLoc.fromJson(Map<String, dynamic> j) => SavedLoc(
      id: j['id'], label: j['l'], address: j['a'], lat: (j['la'] as num).toDouble(), lng: (j['ln'] as num).toDouble());
}

// ---------- saran jasa per kategori (kartu horizontal di form request) ----------
const catSuggest = <String, List<Map<String, dynamic>>>{
  'clean': [
    {'t': 'Bersihkan rumah', 'c': 'clean', 'd': 'Menyapu, mengepel dan membersihkan kamar mandi rumah tipe 36 sampai bersih.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Sapu halaman', 'c': 'clean', 'd': 'Menyapu halaman depan dan belakang rumah serta membuang sampah daun.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Ngepel teras dan lantai', 'c': 'clean', 'd': 'Mengepel teras dan seluruh lantai rumah sampai bersih dan tidak licin.', 'p': 50000, 'pt': 'lump'},
    {'t': 'Bersihkan kaca dan jendela', 'c': 'clean', 'd': 'Membersihkan kaca, jendela dan pintu kaca bagian dalam dan luar rumah.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Bersihkan kamar mandi', 'c': 'clean', 'd': 'Menyikat lantai, dinding, kloset dan bak mandi sampai bersih dan wangi.', 'p': 60000, 'pt': 'lump'},
  ],
  'elec': [
    {'t': 'Pasang kipas angin', 'c': 'elec', 'd': 'Memasang kipas angin dinding atau plafon yang sudah saya sediakan.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Ganti lampu dan fitting', 'c': 'elec', 'd': 'Mengganti beberapa lampu dan fitting yang mati di dalam rumah.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Pasang stop kontak', 'c': 'elec', 'd': 'Memasang atau mengganti stop kontak dan saklar di beberapa ruangan.', 'p': 70000, 'pt': 'lump'},
    {'t': 'Cek kulkas atau mesin cuci', 'c': 'elec', 'd': 'Memeriksa kulkas atau mesin cuci yang bermasalah dan perbaikan ringan.', 'p': 100000, 'pt': 'lump'},
    {'t': 'Pasang TV di dinding', 'c': 'elec', 'd': 'Memasang bracket dan TV di dinding ruang keluarga dengan rapi.', 'p': 100000, 'pt': 'lump'},
  ],
  'move': [
    {'t': 'Angkat barang', 'c': 'move', 'd': 'Mengangkat lemari dan kardus dari lantai satu ke mobil bak, sekitar 15 barang.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Bantu pindahan rumah', 'c': 'move', 'd': 'Membantu mengemas dan memindahkan perabot rumah ke tempat tinggal baru.', 'p': 300000, 'pt': 'lump'},
    {'t': 'Angkat galon dan gas', 'c': 'move', 'd': 'Mengangkat galon air dan tabung gas ke dalam rumah sampai ke dapur.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Bongkar muat barang', 'c': 'move', 'd': 'Membongkar dan memuat barang dagangan dari dan ke mobil pengangkut.', 'p': 35000, 'pt': 'hourly'},
    {'t': 'Pindah kasur dan lemari', 'c': 'move', 'd': 'Memindahkan kasur dan lemari antar ruangan atau antar lantai dengan aman.', 'p': 120000, 'pt': 'lump'},
  ],
  'garden': [
    {'t': 'Bersihkan halaman', 'c': 'garden', 'd': 'Menyapu daun, memangkas rumput dan merapikan halaman depan serta belakang rumah.', 'p': 120000, 'pt': 'lump'},
    {'t': 'Pangkas rumput', 'c': 'garden', 'd': 'Memangkas rumput halaman dengan mesin atau gunting sampai rata dan rapi.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Pangkas pagar tanaman', 'c': 'garden', 'd': 'Merapikan pagar tanaman dan membuang sisa pangkasan dari area rumah.', 'p': 90000, 'pt': 'lump'},
    {'t': 'Tanam dan pindah tanaman', 'c': 'garden', 'd': 'Menanam bibit atau memindahkan tanaman pot ke bedengan di halaman.', 'p': 70000, 'pt': 'lump'},
    {'t': 'Siram dan rawat tanaman', 'c': 'garden', 'd': 'Menyiram, memupuk dan merawat tanaman hias di taman selama beberapa jam.', 'p': 30000, 'pt': 'hourly'},
  ],
  'repair': [
    {'t': 'Benerin genteng bocor', 'c': 'repair', 'd': 'Mengganti beberapa genteng yang bocor dan memeriksa titik rembesan air.', 'p': 250000, 'pt': 'lump'},
    {'t': 'Cat dinding', 'c': 'repair', 'd': 'Mengecat ulang dinding satu ruangan, cat dan peralatan sudah disediakan.', 'p': 200000, 'pt': 'lump'},
    {'t': 'Perbaiki pintu dan engsel', 'c': 'repair', 'd': 'Memperbaiki pintu yang macet, engsel longgar dan kunci yang seret.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Tambal plafon bocor', 'c': 'repair', 'd': 'Menambal plafon yang rusak akibat bocor lalu merapikan dan mengecatnya.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Perbaiki keran dan saluran', 'c': 'repair', 'd': 'Mengganti keran bocor dan membersihkan saluran air yang tersumbat ringan.', 'p': 100000, 'pt': 'lump'},
  ],
  'errand': [
    {'t': 'Titip belikan makanan', 'c': 'errand', 'd': 'Membelikan makanan di warung dekat rumah dan mengantarnya ke alamat saya.', 'p': 25000, 'pt': 'lump'},
    {'t': 'Antar paket', 'c': 'errand', 'd': 'Mengantar paket atau dokumen ke alamat tujuan di sekitar kota ini.', 'p': 30000, 'pt': 'lump'},
    {'t': 'Belikan galon dan gas', 'c': 'errand', 'd': 'Membelikan galon air dan gas elpiji lalu mengantarnya sampai ke rumah.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Antre dan urus berkas', 'c': 'errand', 'd': 'Mengantre dan mengurus berkas sederhana di kantor atau loket pelayanan.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Ambil pesanan di toko', 'c': 'errand', 'd': 'Mengambil pesanan di toko lalu mengantarnya ke alamat saya dengan aman.', 'p': 30000, 'pt': 'lump'},
  ],
  'laundry': [
    {'t': 'Nyetrika baju', 'c': 'laundry', 'd': 'Menyetrika satu keranjang baju harian, sekitar 30 potong, sampai rapi.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Cuci dan jemur baju', 'c': 'laundry', 'd': 'Mencuci baju satu keranjang lalu menjemurnya sampai kering dan rapi.', 'p': 50000, 'pt': 'lump'},
    {'t': 'Lipat dan susun baju', 'c': 'laundry', 'd': 'Melipat baju bersih dan menyusunnya ke dalam lemari dengan rapi.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Cuci karpet atau sprei', 'c': 'laundry', 'd': 'Mencuci karpet atau sprei ukuran besar sampai bersih dan wangi.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Setrika seragam sekolah', 'c': 'laundry', 'd': 'Menyetrika seragam sekolah beberapa anak sampai rapi dan siap dipakai.', 'p': 50000, 'pt': 'lump'},
  ],
  'other': [
    {'t': 'Bantu atur gudang', 'c': 'other', 'd': 'Menata dan membersihkan gudang kecil, membuang barang bekas yang tak terpakai.', 'p': 120000, 'pt': 'lump'},
    {'t': 'Jaga stand atau toko', 'c': 'other', 'd': 'Menjaga stand atau toko selama beberapa jam saat pemilik sedang keluar.', 'p': 30000, 'pt': 'hourly'},
    {'t': 'Bantu acara keluarga', 'c': 'other', 'd': 'Membantu menyiapkan kursi, tenda dan membereskan tempat setelah acara selesai.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Bantu masak dan cuci piring', 'c': 'other', 'd': 'Membantu menyiapkan masakan dan mencuci piring untuk acara di rumah.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Tenaga serabutan harian', 'c': 'other', 'd': 'Tenaga harian untuk berbagai pekerjaan ringan yang akan dijelaskan di lokasi.', 'p': 150000, 'pt': 'daily'},
  ],
};

// ---------- tawaran jasa (layanan baku yang dibuat agen, bisa langsung dipesan klien) ----------
class Svc {
  String id, agentId, title, cat, desc, ptype;
  int price;
  double dur;
  bool active;
  Svc({required this.id, required this.agentId, required this.title, required this.cat, this.desc = '',
      this.ptype = 'lump', required this.price, this.dur = 0, this.active = true});
  Map<String, dynamic> toJson() => {'id': id, 'ag': agentId, 'ti': title, 'ca': cat, 'de': desc, 'pt': ptype,
        'pr': price, 'du': dur, 'ac': active};
  factory Svc.fromJson(Map<String, dynamic> j) => Svc(id: j['id'], agentId: j['ag'], title: j['ti'], cat: j['ca'],
      desc: j['de'], ptype: j['pt'], price: j['pr'], dur: (j['du'] as num).toDouble(), active: j['ac']);
}
