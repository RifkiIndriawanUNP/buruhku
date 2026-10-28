import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'seed.dart';
import 'ui.dart' show rp, fdt;

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);
}

extension StoreCtx on BuildContext {
  AppStore get s => dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
  AppStore get r => getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Order langsung yang menunggu respons agen (muncul di Home agen dan di chat).
class DirectReq {
  final Chat chat;
  final Msg msg;
  DirectReq(this.chat, this.msg);
}

class AppStore extends ChangeNotifier {
  final agents = buildAgents();
  late final List<Svc> simSvcs = buildServices(agents);
  final _rnd = Random();
  Timer? _tick, _saveT;
  SharedPreferences? _p;

  // ---- akun ----
  bool onboarded = false, loggedIn = false, agentMode = false;
  String phone = '', name = '', address = '', emName = '', emPhone = '', pin = '';
  bool nOrder = true, nChat = true, nPromo = false, biometric = false;
  List<String> wallets = []; // 'GoPay|0812xxxx'
  Set<String> favs = {}, blocked = {}, hidden = {};
  Kyc kyc = Kyc();
  // ---- data ----
  List<Req> reqs = [];
  List<Ord> orders = [];
  List<Chat> chats = [];
  List<Note> notes = [];
  List<Led> ledger = [];
  List<Rep> reports = [];
  List<Sos> soses = [];
  List<Tix> tickets = [];
  List<Disp> disputes = [];
  List<Rev> revs = [];
  List<Payout> payouts = [];
  List<SavedLoc> places = [];
  List<Svc> mySvcs = [];
  Set<String> favSvc = {};
  Map<String, List<int>> rate = {};
  int balance = 0, penalty = 0, idc = 1000, declines = 0, accepts = 0;
  DateTime lastActive = DateTime.now();
  // ---- sementara (tidak disimpan) ----
  int tab = 0;
  String openChatId = '';
  Note? toastNote;
  String otp = '123456', pendingPhone = '';
  int otpTries = 0;
  DateTime? otpLock;

  String nid(String p) => '$p${++idc}';
  String _pin() => (1000 + _rnd.nextInt(9000)).toString();
  int _round5(num n) => ((n / 5000).round() * 5000).toInt();
  T _pick<T>(List<T> l) => l[_rnd.nextInt(l.length)];
  int _h(String s) => s.codeUnits.fold(0, (a, b) => a + b);

  // ================= persistensi =================
  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p!.getString('buruhku_v1');
    var ok = false;
    if (raw != null) {
      try {
        _load(jsonDecode(raw) as Map<String, dynamic>);
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) _seed();
    _tick = Timer.periodic(const Duration(seconds: 3), (_) => _onTick());
  }

  @override
  void dispose() {
    _tick?.cancel();
    _saveT?.cancel();
    super.dispose();
  }

  void _seed() {
    reqs = seedIncoming();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _saveT?.cancel();
    _saveT = Timer(const Duration(milliseconds: 600), _save);
  }

  void _save() => _p?.setString('buruhku_v1', jsonEncode(_dump()));

  Map<String, dynamic> _dump() => {
        'onboarded': onboarded, 'loggedIn': loggedIn, 'agentMode': agentMode, 'phone': phone, 'name': name,
        'address': address, 'emName': emName, 'emPhone': emPhone, 'pin': pin, 'nOrder': nOrder, 'nChat': nChat,
        'nPromo': nPromo, 'biometric': biometric, 'wallets': wallets, 'favs': favs.toList(),
        'blocked': blocked.toList(), 'hidden': hidden.toList(), 'kyc': kyc.toJson(),
        'reqs': reqs.map((e) => e.toJson()).toList(), 'orders': orders.map((e) => e.toJson()).toList(),
        'chats': chats.map((e) => e.toJson()).toList(), 'notes': notes.map((e) => e.toJson()).toList(),
        'ledger': ledger.map((e) => e.toJson()).toList(), 'reports': reports.map((e) => e.toJson()).toList(),
        'soses': soses.map((e) => e.toJson()).toList(), 'tickets': tickets.map((e) => e.toJson()).toList(),
        'disputes': disputes.map((e) => e.toJson()).toList(), 'revs': revs.map((e) => e.toJson()).toList(),
        'payouts': payouts.map((e) => e.toJson()).toList(), 'places': places.map((e) => e.toJson()).toList(), 'mySvcs': mySvcs.map((e) => e.toJson()).toList(),
        'favSvc': favSvc.toList(), 'rate': rate, 'balance': balance,
        'penalty': penalty, 'idc': idc, 'declines': declines, 'accepts': accepts, 'lastActive': lastActive.toIso8601String(),
      };

  void _load(Map<String, dynamic> j) {
    onboarded = j['onboarded'];
    loggedIn = j['loggedIn'];
    agentMode = j['agentMode'];
    phone = j['phone'];
    name = j['name'];
    address = j['address'];
    emName = j['emName'];
    emPhone = j['emPhone'];
    pin = j['pin'];
    nOrder = j['nOrder'];
    nChat = j['nChat'];
    nPromo = j['nPromo'];
    biometric = j['biometric'];
    wallets = List<String>.from(j['wallets']);
    favs = Set<String>.from(j['favs']);
    blocked = Set<String>.from(j['blocked']);
    hidden = Set<String>.from(j['hidden']);
    kyc = Kyc.fromJson(Map<String, dynamic>.from(j['kyc']));
    reqs = listFrom(j['reqs'], Req.fromJson);
    orders = listFrom(j['orders'], Ord.fromJson);
    chats = listFrom(j['chats'], Chat.fromJson);
    notes = listFrom(j['notes'], Note.fromJson);
    ledger = listFrom(j['ledger'], Led.fromJson);
    reports = listFrom(j['reports'], Rep.fromJson);
    soses = listFrom(j['soses'], Sos.fromJson);
    tickets = listFrom(j['tickets'], Tix.fromJson);
    disputes = listFrom(j['disputes'], Disp.fromJson);
    revs = listFrom(j['revs'], Rev.fromJson);
    payouts = listFrom(j['payouts'], Payout.fromJson);
    places = listFrom(j['places'], SavedLoc.fromJson);
    mySvcs = listFrom(j['mySvcs'], Svc.fromJson);
    favSvc = Set<String>.from(j['favSvc'] ?? []);
    rate = (j['rate'] as Map).map((k, v) => MapEntry(k as String, List<int>.from(v)));
    balance = j['balance'];
    penalty = j['penalty'];
    idc = j['idc'];
    declines = j['declines'];
    accepts = j['accepts'];
    lastActive = DateTime.parse(j['lastActive']);
  }

  void _wipe() {
    onboarded = true;
    agentMode = false;
    name = address = emName = emPhone = pin = '';
    wallets = [];
    favs = {};
    blocked = {};
    hidden = {};
    kyc = Kyc();
    orders = [];
    chats = [];
    notes = [];
    ledger = [];
    reports = [];
    soses = [];
    tickets = [];
    disputes = [];
    revs = [];
    payouts = [];
    places = [];
    mySvcs = [];
    favSvc = {};
    rate = {};
    balance = penalty = declines = accepts = 0;
    tab = 0;
    _seed();
  }

  // ================= auth =================
  bool get otpLocked => otpLock != null && DateTime.now().isBefore(otpLock!);
  String requestOtp(String ph) {
    pendingPhone = ph;
    otp = (100000 + _rnd.nextInt(900000)).toString();
    return otp;
  }

  String? checkOtp(String code) {
    if (otpLocked) return 'Terlalu banyak percobaan. Coba lagi dalam 1 menit.';
    if (code == otp) {
      otpTries = 0;
      return null;
    }
    otpTries++;
    if (otpTries >= 5) {
      otpLock = DateTime.now().add(const Duration(minutes: 1));
      otpTries = 0;
      return 'OTP salah 5 kali. Akun dikunci sementara 1 menit.';
    }
    return 'Kode OTP salah (${5 - otpTries} percobaan lagi).';
  }

  void finishOnboarding() {
    onboarded = true;
    notifyListeners();
  }

  void completeLogin() {
    if (phone.isNotEmpty && phone != pendingPhone) _wipe();
    phone = pendingPhone;
    loggedIn = true;
    onboarded = true;
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    agentMode = false;
    tab = 0;
    notifyListeners();
  }

  void saveProfile({required String n, String? addr, String? en, String? ep}) {
    name = n;
    if (addr != null) address = addr;
    if (en != null) emName = en;
    if (ep != null) emPhone = ep;
    if (notes.isEmpty) notify('Selamat datang di Buruhku', 'Buat request pertamamu atau jelajahi agen terdekat.');
    notifyListeners();
  }

  void deleteAccount() {
    _wipe();
    phone = '';
    loggedIn = false;
    onboarded = false;
    notifyListeners();
  }

  String exportJson() {
    final d = _dump();
    d.remove('pin');
    return const JsonEncoder.withIndent('  ').convert(d);
  }

  void setMode(bool agent) {
    agentMode = agent;
    tab = 0;
    notifyListeners();
  }

  void goTab(int i) {
    tab = i;
    notifyListeners();
  }

  void touch() => lastActive = DateTime.now();

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

  // ================= agen & katalog =================
  Agent agentById(String id) => agents.firstWhere((a) => a.id == id, orElse: () => agents.first);
  double ratingOf(Agent a) {
    final l = rate[a.id];
    if (l == null || l[1] == 0) return a.rating;
    final j = max(a.jobs, 1);
    return (a.rating * j + l[0]) / (j + l[1]);
  }

  List<Rev> reviewsOf(String id) {
    final a = agents.firstWhere((x) => x.id == id, orElse: () => agents.first);
    final l = [...revs.where((v) => v.aboutId == id && v.pub), ...genReviews(a)];
    l.sort((x, y) => y.at.compareTo(x.at));
    return l;
  }

  List<Agent> searchAgents({String? cat, String q = '', double maxDist = 15, double minRating = 0,
      bool verified = false, bool online = false, int maxBase = 999999, String sort = 'relevansi'}) {
    final ql = q.toLowerCase();
    final l = agents.where((a) {
      if (blocked.contains(a.id)) return false;
      if (cat != null && !a.cats.contains(cat)) return false;
      if (ql.isNotEmpty && !(a.name.toLowerCase().contains(ql) || a.bio.toLowerCase().contains(ql) ||
          a.cats.any((c) => catOf(c).name.toLowerCase().contains(ql)))) return false;
      return a.dist <= maxDist && ratingOf(a) >= minRating && (!verified || a.verified) && (!online || a.online) && a.base <= maxBase;
    }).toList();
    double score(Agent a) => ratingOf(a) * 2 - a.dist * 0.3 + (a.online ? 1 : 0);
    if (sort == 'jarak') {
      l.sort((a, b) => a.dist.compareTo(b.dist));
    } else if (sort == 'rating') {
      l.sort((a, b) => ratingOf(b).compareTo(ratingOf(a)));
    } else if (sort == 'harga') {
      l.sort((a, b) => a.base.compareTo(b.base));
    } else {
      l.sort((a, b) => score(b).compareTo(score(a)));
    }
    return l;
  }

  void toggleFav(String id) {
    favs.contains(id) ? favs.remove(id) : favs.add(id);
    notifyListeners();
  }

  // ================= tawaran jasa =================
  Svc? svcById(String id) {
    for (final v in mySvcs) {
      if (v.id == id) return v;
    }
    for (final v in simSvcs) {
      if (v.id == id) return v;
    }
    return null;
  }

  List<Svc> svcsOfAgent(String agentId) => simSvcs.where((v) => v.agentId == agentId && v.active).toList();

  /// Tawaran jasa agen di sekitar klien (yang bisa langsung dipesan).
  List<Svc> svcsNear({String? cat, String q = '', String sort = 'jarak'}) {
    final ql = q.toLowerCase();
    final l = simSvcs.where((v) {
      final a = agentById(v.agentId);
      if (!v.active || !a.verified || blocked.contains(a.id)) return false;
      if (cat != null && v.cat != cat) return false;
      if (ql.isNotEmpty && !(v.title.toLowerCase().contains(ql) || v.desc.toLowerCase().contains(ql))) return false;
      return true;
    }).toList();
    if (sort == 'harga') {
      l.sort((a, b) => a.price.compareTo(b.price));
    } else if (sort == 'rating') {
      l.sort((a, b) => ratingOf(agentById(b.agentId)).compareTo(ratingOf(agentById(a.agentId))));
    } else {
      l.sort((a, b) => agentById(a.agentId).dist.compareTo(agentById(b.agentId).dist));
    }
    return l;
  }

  void toggleFavSvc(String id) {
    favSvc.contains(id) ? favSvc.remove(id) : favSvc.add(id);
    notifyListeners();
  }

  void addSvc(Svc v) {
    v.id = nid('SV');
    v.agentId = 'me';
    mySvcs.insert(0, v);
    notify('Tawaran jasa dibuat', '"${v.title}" bisa langsung dipesan klien.');
    notifyListeners();
  }

  void updateSvc(Svc v) => notifyListeners();

  void deleteSvc(Svc v) {
    mySvcs.remove(v);
    favSvc.remove(v.id);
    notifyListeners();
  }

  /// Order langsung dari klien yang menunggu ACC agen (dari tawaran jasa atau chat langsung).
  List<DirectReq> get incomingDirect {
    final out = <DirectReq>[];
    for (final c in chats) {
      if (c.otherAgent || c.type != 'direct' || c.closed || blocked.contains(c.otherId)) continue;
      for (final m in c.msgs) {
        if (m.type == 'order_offer' && m.from == 'other' && m.data['status'] == 'pending') out.add(DirectReq(c, m));
      }
    }
    out.sort((a, b) => b.msg.at.compareTo(a.msg.at));
    return out;
  }

  String? acceptDirect(Chat c, Msg m) {
    if (kyc.status != 'approved') return 'Verifikasi KYC belum disetujui.';
    if (!kyc.online) return 'Aktifkan status Online dulu.';
    final d = m.data;
    final cat = (d['cat'] ?? 'other') as String;
    if (catOf(cat).risk > 1 && myLevel < 2) return 'Kategori sensitif butuh SKCK dan level L2.';
    final tot = totalOf(d['ptype'] as String, d['price'] as int, (d['dur'] as num).toDouble());
    if (myLevel == 1 && tot > 500000) return 'Level L1 dibatasi order maks Rp500.000.';
    accepts++;
    touch();
    respondOffer(c, m, 'accept');
    return null;
  }

  void rejectDirect(Chat c, Msg m) {
    declines++;
    touch();
    respondOffer(c, m, 'reject');
  }

  void _spawnSimDirect() {
    final name = _pick(simNames);
    final c = chatFor(type: 'direct', refId: '', otherId: 'c:$name', otherName: name, otherAgent: false);
    if (c.closed || c.msgs.any((m) => m.type == 'order_offer' && m.data['status'] == 'pending')) return;
    final mine = mySvcs.where((x) => x.active).toList();
    final t0 = DateTime.now().add(const Duration(days: 1));
    final at = DateTime(t0.year, t0.month, t0.day, 9 + _rnd.nextInt(6));
    final date = _rnd.nextBool();
    Map<String, dynamic> d;
    if (mine.isNotEmpty && _rnd.nextInt(10) < 8) {
      final v = _pick(mine);
      d = {'title': v.title, 'cat': v.cat, 'desc': v.desc, 'price': v.price, 'ptype': v.ptype, 'dur': v.dur, 'svcId': v.id, 'svcPrice': v.price};
    } else {
      final cid = kyc.cats.isEmpty ? 'other' : _pick(kyc.cats);
      final t = _pick(catSuggest[cid] ?? templates);
      d = {'title': t['t'], 'cat': cid, 'desc': t['d'], 'price': t['p'], 'ptype': t['pt'], 'dur': t['pt'] == 'lump' ? 0.0 : 2.0};
    }
    d.addAll({
      'address': 'Jl. Kenanga No. ${1 + _rnd.nextInt(60)}, ${_pick(areas)}', 'sched': date ? 'date' : 'now',
      'schedAt': date ? at.toIso8601String() : null, 'when': date ? fdt(at) : 'Sekarang', 'lat': 0.5, 'lng': 0.5,
      'status': 'pending', 'by': 'other',
    });
    c.msgs.add(Msg(id: nid('m'), from: 'other', type: 'order_offer', body: 'Penawaran order', data: d));
    c.unread++;
    notify('Order langsung baru', '$name memesan "${d['title']}" (${rp(d['price'] as int)}).');
  }

  // ================= lokasi tersimpan =================
  void addPlace(String label, String addr, Offset pin) {
    places.add(SavedLoc(id: nid('PL'), label: label, address: addr, lat: pin.dx, lng: pin.dy));
    if (address.isEmpty) address = addr;
    notifyListeners();
  }

  void updatePlace(SavedLoc p, String label, String addr, Offset pin) {
    if (address == p.address) address = addr;
    p.label = label;
    p.address = addr;
    p.lat = pin.dx;
    p.lng = pin.dy;
    notifyListeners();
  }

  void deletePlace(SavedLoc p) {
    places.remove(p);
    notifyListeners();
  }

  // ================= moderasi & request =================
  static const _ban = ['narkoba', 'sabu', 'ganja', 'judi', 'togel', 'curi', 'maling', 'tagih utang', 'debt collector',
    'tukang pukul', 'pukul', 'hajar', 'ancam', 'teror', 'palsu', 'ikuti dia', 'intai', 'bunuh', 'pelacur', 'esek',
    'pijat plus', 'pendamping dewasa', 'panjat tower', 'tower', 'tegangan tinggi', 'bahan kimia', 'limbah berbahaya',
    'gas bocor', 'suntik', 'infus', 'balas dendam', 'intimidasi'];
  static const _warn = ['antar anak', 'jaga anak', 'titip anak', 'masuk rumah', 'malam', 'titip paket', 'bawa paket',
    'kendaraan saya', 'mobil saya', 'motor saya', 'kirim barang'];

  List<String> moderate(String text) {
    final t = text.toLowerCase();
    for (final w in _ban) {
      if (t.contains(w)) {
        return ['reject', 'Mengandung "$w" yang masuk Daftar Larangan Buruhku (ilegal, berbahaya, atau butuh sertifikasi).'];
      }
    }
    for (final w in _warn) {
      if (t.contains(w)) return ['review', 'Mengandung "$w" sehingga perlu ditinjau admin dan hanya bisa diambil agen level L2+.'];
    }
    return ['ok', ''];
  }

  /// Jumlah agen yang terus dicari untuk daftar "Sedang mencari agen" pada request banyak agen.
  static const int kSearchTarget = 5;

  int interestCount(Req r) => r.acc.where((a) => a.status == 'accepted').length;

  List<Acc> activeAcc(Req r) => r.acc.where((a) => ['accepted', 'invited', 'agreed', 'selected'].contains(a.status)).toList();
  List<Req> get myReqs => reqs.where((r) => r.mine).toList();

  void _refreshReq(Req r) {
    if (!['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status)) return;
    final n = activeAcc(r).length;
    r.status = n == 0 ? 'OPEN' : ((r.workers == 1 && n >= r.quota) ? 'FULL' : 'HAS_ACCEPTORS');
  }

  /// Mengembalikan [verdict, alasan]. 'reject' berarti tidak disimpan.
  List<String> submitReq(Req r) {
    final m = moderate('${r.title} ${r.desc} ${r.notes}');
    if (m[0] == 'reject') return m;
    r.id = nid('REQ');
    r.clientId = 'me';
    r.created = DateTime.now();
    r.expires = r.created.add(r.sched == 'now' ? const Duration(minutes: 30) : const Duration(hours: 24));
    r.quota = max(5, r.workers + 2);
    r.status = m[0] == 'review' ? 'IN_REVIEW' : 'OPEN';
    r.reason = m[1];
    reqs.insert(0, r);
    notify(m[0] == 'review' ? 'Request ditinjau admin' : 'Request dipublikasikan',
        m[0] == 'review' ? '"${r.title}" menunggu tinjauan admin.' : '"${r.title}" dikirim ke agen terdekat.');
    notifyListeners();
    return m;
  }

  void afterEdit(Req r, bool material) {
    if (material) {
      for (final a in activeAcc(r).where((a) => a.status == 'accepted').toList()) {
        if (_rnd.nextInt(100) < 35) {
          a.status = 'withdrawn';
          a.note = 'Mundur setelah request diubah';
          final ag = agentById(a.agentId);
          notify('Agen mundur', '${ag.short} memilih mundur setelah request diubah.');
        } else {
          final c = _chatOf(r.id, a.agentId);
          if (c != null) _sys(c, 'Klien mengubah request. Agen mempertahankan ACC.');
        }
      }
      _refreshReq(r);
    }
    notifyListeners();
  }

  void cancelReq(Req r) {
    r.status = 'CANCELLED';
    for (final c in chats.where((c) => c.refId == r.id && c.type == 'order')) {
      _sys(c, 'Request dibatalkan oleh klien.');
      c.closed = true;
    }
    for (final o in orders.where((o) => o.reqId == r.id && o.status == 'AGREED').toList()) {
      cancelOrder(o, 'Request dibatalkan');
    }
    notifyListeners();
  }

  void relist(Req r, {double addRadius = 0, int addPrice = 0}) {
    r.price += addPrice;
    r.radius += addRadius;
    r.created = DateTime.now();
    r.expires = r.created.add(r.sched == 'now' ? const Duration(minutes: 30) : const Duration(hours: 24));
    r.status = 'OPEN';
    _refreshReq(r);
    notify('Request dibuka lagi', '"${r.title}" disiarkan ulang ke agen.');
    notifyListeners();
  }

  void declineAcc(Req r, Acc a) {
    a.status = 'declined';
    a.note = 'Ditolak klien';
    final c = _chatOf(r.id, a.agentId);
    if (c != null) {
      _sys(c, 'Klien menolak penawaran ini.');
      c.closed = true;
    }
    _refreshReq(r);
    notifyListeners();
  }

  void adminApproveReq(Req r) {
    r.status = 'OPEN';
    r.created = DateTime.now();
    r.expires = r.created.add(r.sched == 'now' ? const Duration(minutes: 30) : const Duration(hours: 24));
    notify('Request disetujui', '"${r.title}" lolos tinjauan dan mulai dicari agen.');
    notifyListeners();
  }

  void adminRejectReq(Req r) {
    r.status = 'REJECTED';
    notify('Request ditolak admin', '"${r.title}" melanggar pedoman komunitas.');
    notifyListeners();
  }

  DateTime? _schedOf(Req r) => r.sched == 'date' ? r.schedAt : (r.sched == 'now' ? DateTime.now() : null);

  // ================= pilih agen (klien) =================
  Ord _makeOrder(Req r, Acc a) {
    a.status = 'selected';
    r.chosen.add(a.agentId);
    final ag = agentById(a.agentId);
    final amt = totalOf(r.ptype, a.price, r.dur);
    final o = Ord(id: nid('ORD'), reqId: r.id, title: r.title, cat: r.cat, address: r.address, area: r.area,
        ptype: r.ptype, otherId: ag.id, otherName: ag.short, pin: _pin(), iAmClient: true, unit: a.price,
        price: amt, fee: feeOf(amt), schedAt: _schedOf(r), nextAt: DateTime.now().add(const Duration(seconds: 4)));
    o.addLog('Kamu memilih ${ag.short} (${rp(amt)})');
    orders.insert(0, o);
    final c = _chatOf(r.id, ag.id);
    if (c != null) _sys(c, 'Klien memilih ${ag.short}. Menunggu konfirmasi akhir agen.');
    return o;
  }

  /// Request 1 agen: pilih satu agen, sisanya otomatis ditutup.
  Ord? selectAgent(Req r, Acc a) {
    if (activeAcc(r).length < r.workers) return null;
    final o = _makeOrder(r, a);
    if (r.chosen.length >= r.workers) {
      r.status = 'LOCKED';
      for (final x in r.acc.where((x) => x.status == 'accepted').toList()) {
        x.status = 'declined';
        x.note = 'Request sudah terisi';
        final cc = _chatOf(r.id, x.agentId);
        if (cc != null) {
          _sys(cc, 'Request sudah terisi.');
          cc.closed = true;
        }
      }
    }
    notifyListeners();
    return o;
  }

  /// Request banyak agen: mulai order untuk semua agen yang sudah ACC (minimal 1).
  int startGroup(Req r) {
    final l = r.acc.where((a) => a.status == 'agreed').toList();
    for (final a in l) {
      _makeOrder(r, a);
    }
    if (l.isNotEmpty) {
      if (r.chosen.length >= r.workers) r.status = 'LOCKED';
      notify('Order dimulai', '${l.length} agen diminta konfirmasi akhir untuk "${r.title}".');
    }
    notifyListeners();
    return l.length;
  }

  /// Memilih agen untuk request banyak agen (dari daftar "sedang mencari agen", agen sekitar, atau favorit).
  /// Agen masuk ke Agen ACC berstatus pending; lalu menyepakati (sepakat) atau menolak (masuk daftar menolak).
  void inviteAgent(Req r, Agent a) {
    Acc? ex;
    for (final x in r.acc) {
      if (x.agentId == a.id) ex = x;
    }
    if (ex != null && ['invited', 'agreed', 'selected'].contains(ex.status)) return;
    final fromInterest = ex != null && ex.status == 'accepted';
    final Acc acc;
    if (fromInterest) {
      acc = ex;
    } else {
      r.acc.removeWhere((x) => x.agentId == a.id);
      acc = Acc(agentId: a.id, price: r.price, note: 'Dipilih klien');
      r.acc.add(acc);
    }
    acc.status = 'invited';
    final ch = chatFor(type: 'order', refId: r.id, otherId: a.id, otherName: a.short, otherAgent: true, title: r.title);
    ch.closed = false;
    _sys(ch, 'Kamu memilih ${a.short} untuk request ini. Menunggu persetujuan agen.');
    if (activeAcc(r).length > r.quota) r.quota = activeAcc(r).length;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      if (acc.status != 'invited') return;
      final refuse = !a.online || _rnd.nextInt(100) < (fromInterest ? 8 : 18);
      if (refuse) {
        acc.status = 'declined';
        acc.note = 'Menolak tawaran';
        _sys(ch, '${a.short} tidak bisa menerima tawaran ini.');
        notify('Agen menolak', '${a.short} menolak tawaran "${r.title}".');
      } else {
        acc.status = 'agreed';
        acc.note = '';
        _incoming(ch, 'Baik, saya sepakat mengerjakan "${r.title}".', silent: true);
        notify('Agen sepakat', '${a.short} sepakat mengerjakan "${r.title}" (${rp(acc.price)}).');
      }
      _refreshReq(r);
      notifyListeners();
    });
  }

  Chat? _chatOf(String refId, String otherId) {
    for (final c in chats) {
      if (c.refId == refId && c.otherId == otherId) return c;
    }
    return null;
  }

  Chat? chatOfOrder(Ord o) => _chatOf(o.reqId, o.otherId);
  Req? reqById(String id) {
    for (final r in reqs) {
      if (r.id == id) return r;
    }
    return null;
  }

  Disp? disputeOf(String id) {
    for (final d in disputes) {
      if (d.id == id) return d;
    }
    return null;
  }

  Ord? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  void _reopenSlot(Ord o, [String? note]) {
    final r = reqById(o.reqId);
    if (r == null) return;
    r.chosen.remove(o.iAmClient ? o.otherId : 'me');
    for (final a in r.acc) {
      if (a.agentId == (o.iAmClient ? o.otherId : 'me') && a.status == 'selected') {
        a.status = 'declined';
        a.note = note ?? 'Dibatalkan';
      }
    }
    if (r.mine && r.status == 'LOCKED' && !r.direct) {
      r.status = 'HAS_ACCEPTORS';
      _refreshReq(r);
      if (DateTime.now().isAfter(r.expires) && r.chosen.isEmpty) r.status = 'EXPIRED';
    }
  }

  // ================= pembayaran & status order =================
  void payOrder(Ord o, String method) {
    o.payMethod = method;
    o.paidAt = DateTime.now();
    o.escrow = 'held';
    o.status = 'SCHEDULED';
    o.nextAt = _departAt(o);
    o.addLog('Pembayaran ${rp(o.total + o.fee)} via $method. Dana ditahan (escrow)');
    ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'escrow_hold', amount: -(o.total + o.fee), note: 'Bayar "${o.title}" via $method'));
    _sysFor(o, 'Pembayaran aman, dana ditahan. Agen siap bekerja.');
    notify('Pembayaran berhasil', 'Dana ${rp(o.total + o.fee)} ditahan sampai pekerjaan selesai.');
    notifyListeners();
  }

  /// Klien memilih bayar tunai langsung ke agen (tanpa escrow, tanpa biaya layanan).
  void chooseCod(Ord o) {
    o.cod = true;
    o.fee = 0;
    o.payMethod = 'COD';
    o.escrow = 'cod';
    o.status = 'SCHEDULED';
    o.paidAt = DateTime.now();
    o.nextAt = _departAt(o);
    o.addLog('Memilih bayar tunai (COD): bayar langsung ke agen setelah pekerjaan selesai. Tanpa perlindungan escrow');
    _sysFor(o, 'Klien memilih bayar tunai (COD). Pembayaran langsung ke agen setelah pekerjaan selesai.');
    notify('COD dipilih', '"${o.title}" dibayar tunai ke agen setelah pekerjaan selesai.');
    notifyListeners();
  }

  DateTime? _departAt(Ord o) {
    final s = o.schedAt, n = DateTime.now();
    if (s == null || s.isBefore(n.add(const Duration(hours: 1)))) return n.add(const Duration(seconds: 8));
    return s.subtract(const Duration(minutes: 20));
  }

  String cancelOrder(Ord o, String reason, {bool forceFull = false}) {
    final now = DateTime.now();
    var msg = 'Dibatalkan.';
    if (o.iAmClient) {
      if (o.escrow != 'held') {
        o.status = 'CANCELLED';
        msg = 'Dibatalkan tanpa biaya.';
        _reopenSlot(o, reason);
      } else {
        final s = o.schedAt;
        final early = s == null || s.difference(now).inHours >= 3;
        final started = ['ON_THE_WAY', 'ARRIVED'].contains(o.status);
        final full = forceFull || (early && !started);
        final refund = full ? o.total + o.fee : (o.total * 0.7).round();
        o.status = 'REFUNDED';
        o.escrow = 'refunded';
        ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'refund', amount: refund, note: 'Refund "${o.title}"'));
        msg = full ? 'Refund 100% (${rp(refund)}) dikembalikan.' : 'Refund parsial ${rp(refund)}. 30% jadi kompensasi agen.';
        _reopenSlot(o, reason);
      }
    } else {
      if (o.escrow == 'held' || o.escrow == 'cod') {
        penalty++;
        msg = o.cod ? 'Dibatalkan. Reputasimu turun.' : 'Dibatalkan. Klien menerima refund 100% dan reputasimu turun.';
        if (!o.cod) o.escrow = 'refunded';
      } else {
        msg = 'Dibatalkan.';
      }
      o.status = 'CANCELLED';
      _reopenSlot(o, reason);
    }
    o.nextAt = null;
    o.doneAt = now;
    o.addLog('Dibatalkan: $reason');
    _sysFor(o, 'Order dibatalkan ($reason).');
    notify('Order dibatalkan', '"${o.title}": $msg');
    notifyListeners();
    return msg;
  }

  void claimClientNoShow(Ord o) {
    final comp = (o.total * 0.3).round();
    final c = (comp * 0.1).round();
    balance += comp - c;
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'release', amount: comp, note: 'Kompensasi klien tidak hadir'));
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'fee', amount: -c, note: 'Komisi platform 10%'));
    o.status = 'CANCELLED';
    o.escrow = 'partial';
    o.doneAt = DateTime.now();
    o.addLog('Klien tidak hadir 30 menit. Kompensasi 30% dicairkan');
    notify('Kompensasi diterima', 'Kamu menerima ${rp(comp - c)} karena klien tidak hadir.');
    notifyListeners();
  }

  void demoNoShow(Ord o) {
    const d = Duration(minutes: 31);
    o.schedAt = (o.schedAt ?? o.paidAt ?? DateTime.now()).subtract(d);
    if (o.arrivedAt != null) o.arrivedAt = o.arrivedAt!.subtract(d);
    o.nextAt = null;
    notifyListeners();
  }

  void demoSkip(Ord o) {
    o.nextAt = DateTime.now();
    if (o.status == 'PENDING_CONFIRM' && o.iAmClient) o.finishedAt = DateTime.now().subtract(const Duration(hours: 25));
    notifyListeners();
  }

  // --- aksi agen (saya = agen) ---
  void confirmAsAgent(Ord o) {
    o.status = 'AGREED';
    o.payBy = DateTime.now().add(const Duration(minutes: 30));
    o.nextAt = DateTime.now().add(const Duration(seconds: 6));
    o.addLog('Kamu mengonfirmasi kesepakatan');
    _sysFor(o, 'Agen mengonfirmasi kesepakatan. Menunggu pembayaran klien.');
    touch();
    notifyListeners();
  }

  void depart(Ord o) {
    o.status = 'ON_THE_WAY';
    o.addLog('Agen berangkat');
    _sysFor(o, 'Agen berangkat menuju lokasi.');
    touch();
    notifyListeners();
  }

  void arrive(Ord o) {
    o.status = 'ARRIVED';
    o.arrivedAt = DateTime.now();
    o.addLog('Agen tiba (check-in GPS valid)');
    final c = chatOfOrder(o);
    if (c != null) {
      _sys(c, 'Agen sudah tiba di lokasi.');
      Future.delayed(const Duration(seconds: 2), () {
        _incoming(c, 'Saya sudah di rumah. PIN kerja: ${o.pin}');
        notifyListeners();
      });
    }
    touch();
    notifyListeners();
  }

  bool startWithPin(Ord o, String p) {
    if (p != o.pin) return false;
    o.status = 'IN_PROGRESS';
    o.startedAt = DateTime.now();
    o.addLog('PIN benar. Pekerjaan dimulai');
    _sysFor(o, 'Pekerjaan dimulai.');
    touch();
    notifyListeners();
    return true;
  }

  void finishJob(Ord o) {
    o.status = 'PENDING_CONFIRM';
    o.finishedAt = DateTime.now();
    o.nextAt = DateTime.now().add(const Duration(seconds: 10));
    o.addLog('Agen menandai selesai (foto hasil diunggah)');
    _sysFor(o, 'Agen menyelesaikan pekerjaan dan mengunggah foto hasil.');
    touch();
    notifyListeners();
  }

  // --- aksi klien (saya = klien) ---
  void confirmArrival(Ord o) {
    o.status = 'IN_PROGRESS';
    o.startedAt = DateTime.now();
    o.nextAt = DateTime.now().add(const Duration(seconds: 12));
    o.addLog('Kamu mengonfirmasi kedatangan. Pekerjaan dimulai');
    _sysFor(o, 'Pekerjaan dimulai.');
    notifyListeners();
  }

  void completeOrder(Ord o, {bool auto = false}) {
    o.status = 'COMPLETED';
    o.doneAt = DateTime.now();
    o.escrow = o.cod ? 'cod' : 'released';
    o.nextAt = null;
    o.theirRev = true;
    if (o.cod) {
      o.addLog(auto ? 'Konfirmasi otomatis 24 jam. Pembayaran tunai ke agen' : 'Pekerjaan dikonfirmasi. Pembayaran tunai ke agen');
      _settleCod(o);
    } else {
      o.addLog(auto ? 'Konfirmasi otomatis 24 jam. Dana dilepas' : 'Pekerjaan dikonfirmasi. Dana dilepas');
      _payAgent(o, o.total);
    }
    if (!o.iAmClient) {
      revs.insert(0, Rev(id: nid('V'), orderId: o.id, aboutId: 'me', from: o.otherName, rating: 4 + _rnd.nextInt(2),
          tags: ['Tepat waktu', 'Rapi'], comment: 'Kerjanya bagus, terima kasih.', pub: false));
    }
    _sysFor(o, o.cod ? 'Pekerjaan selesai. Pembayaran tunai ke agen.' : 'Pekerjaan selesai. Dana dilepas ke agen.');
    notify('Pekerjaan selesai', o.iAmClient ? '"${o.title}" selesai. Beri rating untuk ${o.otherName}.' : (o.cod ? 'Tunai ${rp(o.total)} diterima dari klien. Komisi ${rp(o.commission)} dipotong dari saldo.' : 'Dana ${rp(o.net)} masuk ke saldo.'));
    notifyListeners();
  }

  void _settleCod(Ord o) {
    if (o.iAmClient) {
      ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'cod', amount: -o.total, note: 'Bayar tunai (COD) "${o.title}"'));
    } else {
      final c = o.commission;
      balance -= c;
      ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'cod', amount: o.total, note: 'Tunai diterima dari klien "${o.title}"'));
      ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'fee', amount: -c, note: 'Komisi COD 10% (dipotong dari saldo)'));
    }
  }

  void _payAgent(Ord o, int gross) {
    if (o.iAmClient) return;
    final c = (gross * 0.1).round();
    balance += gross - c;
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'release', amount: gross, note: 'Pembayaran "${o.title}"'));
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'fee', amount: -c, note: 'Komisi platform 10%'));
  }

  void _refundClient(Ord o, int amt) {
    if (!o.iAmClient) return;
    ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'refund', amount: amt, note: 'Refund sengketa "${o.title}"'));
  }

  void requestChange(Ord o, int amount, String reason, bool byMe) {
    o.chg = {'amount': amount, 'reason': reason, 'by': byMe ? 'me' : 'other'};
    o.addLog('Permintaan tambahan ${rp(amount)}: $reason');
    if (byMe) {
      Future.delayed(const Duration(seconds: 4), () {
        if (o.chg == null) return;
        if (_rnd.nextInt(10) < 7) {
          o.extra += amount;
          o.addLog('Klien menyetujui tambahan ${rp(amount)}');
          notify('Tambahan disetujui', 'Klien menyetujui tambahan ${rp(amount)}.');
        } else {
          o.addLog('Klien menolak tambahan');
          notify('Tambahan ditolak', 'Klien menolak permintaan tambahan.');
        }
        o.chg = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void respondChange(Ord o, bool ok) {
    if (o.chg == null) return;
    final a = o.chg!['amount'] as int;
    if (ok) {
      o.extra += a;
      ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'escrow_hold', amount: -a, note: 'Tambahan "${o.title}"'));
      o.addLog('Kamu menyetujui tambahan ${rp(a)} (masuk escrow)');
    } else {
      o.addLog('Kamu menolak tambahan');
    }
    o.chg = null;
    notifyListeners();
  }

  void tip(Ord o, int amt) {
    o.tipped = true;
    ledger.insert(0, Led(id: nid('L'), role: 'c', type: 'tip', amount: -amt, note: 'Tip untuk ${o.otherName}'));
    o.addLog('Tip ${rp(amt)} dikirim');
    notify('Tip terkirim', '${rp(amt)} untuk ${o.otherName}.');
    notifyListeners();
  }

  void submitReview(Ord o, int rating, List<String> tags, String comment) {
    if (o.iAmClient) {
      revs.insert(0, Rev(id: nid('V'), orderId: o.id, aboutId: o.otherId, from: name, rating: rating, tags: tags, comment: comment));
      final l = rate.putIfAbsent(o.otherId, () => [0, 0]);
      l[0] += rating;
      l[1] += 1;
    }
    o.myRev = true;
    for (final v in revs) {
      if (v.orderId == o.id && v.aboutId == 'me') v.pub = true;
    }
    if (o.theirRev && o.status == 'COMPLETED') o.status = 'REVIEWED';
    notify('Ulasan terkirim', 'Ulasan dipublikasikan karena kedua pihak sudah menilai.');
    notifyListeners();
  }

  // --- sengketa ---
  Disp openDispute(Ord o, String type, String desc, int evid) {
    final d = Disp(id: nid('D'), orderId: o.id, type: type, desc: desc, evid: evid, prev: o.status);
    disputes.insert(0, d);
    o.status = 'DISPUTED';
    o.disputeId = d.id;
    o.nextAt = null;
    o.addLog('Sengketa diajukan: $type. Dana tetap ditahan');
    notify('Sengketa diajukan', 'Dana ditahan. Pihak lain punya 48 jam untuk menanggapi.');
    notifyListeners();
    return d;
  }

  void resolveDispute(Disp d, String decision) {
    final o = orderById(d.orderId);
    if (o == null) return;
    d.status = 'resolved';
    d.decision = decision;
    if (o.cod) {
      o.escrow = 'cod';
    } else if (decision == 'release') {
      _payAgent(o, o.total);
      o.escrow = 'released';
    } else if (decision == 'refund') {
      _refundClient(o, o.total + o.fee);
      o.escrow = 'refunded';
    } else {
      _payAgent(o, (o.total / 2).round());
      _refundClient(o, (o.total / 2).round());
      o.escrow = 'split';
    }
    o.status = 'RESOLVED';
    o.doneAt = DateTime.now();
    final txt = _decText[decision] ?? decision;
    o.addLog('Keputusan admin: $txt');
    notify('Sengketa diputuskan', '"${o.title}": $txt.');
    notifyListeners();
  }

  /// Membatalkan sengketa yang diajukan sendiri: order dilanjutkan dari status sebelumnya.
  void cancelDispute(Disp d) {
    final o = orderById(d.orderId);
    d.status = 'cancelled';
    if (o != null) {
      o.disputeId = '';
      o.status = d.prev;
      if (d.prev == 'PENDING_CONFIRM' && !o.iAmClient) o.nextAt = DateTime.now().add(const Duration(seconds: 10));
      if (d.prev == 'IN_PROGRESS' && o.iAmClient) o.nextAt = DateTime.now().add(const Duration(seconds: 12));
      o.addLog('Sengketa dibatalkan. Order dilanjutkan');
    }
    notify('Sengketa dibatalkan', 'Order dilanjutkan seperti semula.');
    notifyListeners();
  }

  static const _decText = {'release': 'dana dilepas ke agen', 'refund': 'refund penuh ke klien', 'split': 'dana dibagi 50:50'};

  // ================= dompet agen =================
  int get held => orders.where((o) => !o.iAmClient && o.escrow == 'held').fold(0, (a, o) => a + o.net);
  String? withdraw(int amount, String dest, String pinIn) {
    if (pin.isEmpty || pinIn != pin) return 'PIN salah.';
    if (amount < 25000) return 'Minimal penarikan Rp25.000.';
    if (amount > balance) return 'Saldo tidak cukup.';
    balance -= amount;
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'payout', amount: -amount, note: 'Tarik saldo ke $dest'));
    payouts.insert(0, Payout(id: nid('P'), amount: amount, dest: dest));
    notify('Penarikan diproses', '${rp(amount)} ke $dest (maks H+1).');
    notifyListeners();
    return null;
  }

  int earned(Duration d) {
    final from = DateTime.now().subtract(d);
    return ledger.where((l) => l.role == 'a' && (l.type == 'release' || l.type == 'fee' || l.type == 'cod') && l.at.isAfter(from)).fold(0, (a, l) => a + l.amount);
  }

  int get myJobs => orders.where((o) => !o.iAmClient && ['COMPLETED', 'REVIEWED'].contains(o.status)).length;
  double get myRating {
    final l = revs.where((v) => v.aboutId == 'me' && v.pub).toList();
    return l.isEmpty ? 0.0 : l.fold<int>(0, (a, v) => a + v.rating) / l.length;
  }

  int get myLevel {
    if (kyc.status != 'approved') return 0;
    if (kyc.skck && myJobs >= 5 && myRating >= 4.0) return (myJobs >= 50 && myRating >= 4.7) ? 3 : 2;
    return 1;
  }

  double get acceptRate => (accepts + declines) == 0 ? 1.0 : accepts / (accepts + declines);

  // ================= mode agen =================
  List<Req> get incoming {
    final now = DateTime.now();
    return reqs.where((r) =>
        !r.mine && ['OPEN', 'HAS_ACCEPTORS'].contains(r.status) && now.isBefore(r.expires) && !hidden.contains(r.id) &&
        !r.acc.any((a) => a.agentId == 'me') && r.dist <= kyc.radius && kyc.cats.contains(r.cat)).toList();
  }

  String? agentAccept(Req r, {int? counter, String note = ''}) {
    if (kyc.status != 'approved') return 'Verifikasi KYC belum disetujui.';
    if (!kyc.online) return 'Aktifkan status Online dulu.';
    if (!kyc.cats.contains(r.cat)) return 'Kategori ini bukan keahlianmu.';
    if (catOf(r.cat).risk > 1 && myLevel < 2) return 'Kategori sensitif butuh SKCK dan level L2.';
    final p = counter ?? r.price;
    if (myLevel == 1 && totalOf(r.ptype, p, r.dur) > 500000) return 'Level L1 dibatasi order maks Rp500.000.';
    if (activeAcc(r).length >= r.quota) return 'Maaf, request sudah penuh.';
    r.acc.add(Acc(agentId: 'me', price: p, note: note));
    accepts++;
    touch();
    final c = chatFor(type: 'order', refId: r.id, otherId: 'c:${r.clientName}', otherName: r.clientName, otherAgent: false, title: r.title);
    _sys(c, 'Kamu ACC dengan harga ${rp(p)}${unitOf(r.ptype)}.');
    if (note.isNotEmpty) c.msgs.add(Msg(id: nid('m'), from: 'me', body: note));
    Future.delayed(const Duration(seconds: 2), () {
      _incoming(c, 'Terima kasih sudah ACC. Kita bisa lanjut kalau harganya cocok.');
      notifyListeners();
    });
    _refreshReq(r);
    notifyListeners();
    return null;
  }

  void agentReject(Req r) {
    hidden.add(r.id);
    declines++;
    touch();
    notifyListeners();
  }

  void withdrawAcc(Req r) {
    for (final a in r.acc) {
      if (a.agentId == 'me' && a.status == 'accepted') a.status = 'withdrawn';
    }
    notifyListeners();
  }

  void setOnline(bool v) {
    kyc.online = v;
    touch();
    notifyListeners();
  }

  void _simClientSelects(Req r, Acc a) {
    a.status = 'selected';
    r.chosen.add('me');
    r.status = 'LOCKED';
    final amt = totalOf(r.ptype, a.price, r.dur);
    final o = Ord(id: nid('ORD'), reqId: r.id, title: r.title, cat: r.cat, address: r.address, area: r.area,
        ptype: r.ptype, otherId: 'c:${r.clientName}', otherName: r.clientName, pin: _pin(), iAmClient: false,
        unit: a.price, price: amt, fee: feeOf(amt), schedAt: _schedOf(r));
    o.addLog('${r.clientName} memilih kamu (${rp(amt)})');
    orders.insert(0, o);
    final c = _chatOf(r.id, 'c:${r.clientName}');
    if (c != null) _sys(c, '${r.clientName} memilih kamu. Mohon konfirmasi akhir dalam 15 menit.');
    notify('Klien memilih kamu', '${r.clientName} memilih kamu untuk "${r.title}". Konfirmasi di tab Pekerjaanku.');
  }

  void _spawnSimReq() {
    if (kyc.cats.isEmpty) return;
    final cid = _pick(kyc.cats);
    final c = catOf(cid);
    final titles = {
      'clean': 'Bersihkan teras dan kamar mandi', 'elec': 'Pasang kipas angin dinding', 'move': 'Bantu angkat kardus ke truk',
      'garden': 'Pangkas pagar tanaman', 'repair': 'Tambal plafon bocor', 'errand': 'Antar paket ke kantor pos',
      'laundry': 'Setrika seragam sekolah', 'other': 'Bantu atur gudang kecil'};
    final p = _round5((c.lo + c.hi) / 2 * (0.8 + _rnd.nextDouble() * 0.4));
    final n = DateTime.now();
    reqs.insert(0, Req(id: nid('SIM'), clientId: 'sim', clientName: _pick(simNames), title: titles[cid]!, cat: cid,
        desc: 'Mohon dikerjakan rapi. Peralatan dasar tersedia di rumah. Bisa mulai sekarang.', price: p,
        dist: double.parse((0.5 + _rnd.nextDouble() * max(kyc.radius - 0.5, 1)).toStringAsFixed(1)),
        area: 'Kel. ${_pick(areas)}', address: 'Jl. Kenanga No. ${1 + _rnd.nextInt(60)}', created: n,
        expires: n.add(const Duration(hours: 2)), clientRating: 4.0 + _rnd.nextInt(10) / 10));
  }

  // ================= KYC =================
  void submitKyc() {
    kyc.status = 'pending';
    kyc.submitted = DateTime.now();
    kyc.tries++;
    kyc.reason = '';
    notify('Pendaftaran agen dikirim', 'Cek otomatis lolos. Data kamu masuk antrean review admin.');
    notifyListeners();
  }

  void adminKyc(String act, [String reason = '']) {
    if (act == 'approve') {
      kyc.status = 'approved';
      kyc.online = true;
      lastActive = DateTime.now();
      notify('Verifikasi disetujui', 'Kamu sekarang bisa menerima order. Mulai dari Mode Agen.');
      final c = chatFor(type: 'direct', refId: '', otherId: 'c:Ibu Mawar', otherName: 'Ibu Mawar', otherAgent: false);
      if (c.msgs.isEmpty) {
        c.msgs.add(Msg(id: nid('m'), from: 'other', body: 'Halo, saya dapat nama kamu dari tetangga. Bisa bantu bersihkan gudang kecil?'));
        c.msgs.add(Msg(id: nid('m'), from: 'other', type: 'order_offer', body: 'Penawaran order', data: {
          'title': 'Bersihkan gudang kecil', 'cat': 'clean', 'desc': 'Membuang barang bekas dan menyapu gudang ukuran 3x4 meter.',
          'address': 'Jl. Kenanga 12, Cikembang', 'price': 180000, 'ptype': 'lump', 'dur': 0.0, 'when': 'Besok, 09:00', 'sched': 'date',
          'schedAt': DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1, 9).toIso8601String(),
          'status': 'pending', 'by': 'other'}));
        c.unread = 2;
      }
    } else if (act == 'reject') {
      kyc.status = 'rejected';
      kyc.reason = reason.isEmpty ? 'Foto KTP kurang jelas.' : reason;
      notify('Verifikasi ditolak', kyc.reason);
    } else {
      kyc.status = 'needs_more';
      kyc.reason = reason.isEmpty ? 'Mohon unggah ulang selfie dengan KTP.' : reason;
      notify('Data tambahan diperlukan', kyc.reason);
    }
    notifyListeners();
  }

  void uploadSkck() {
    kyc.skck = true;
    notify('SKCK diunggah', 'SKCK tercatat. Level L2 aktif setelah 5 pekerjaan dengan rating baik.');
    notifyListeners();
  }

  // ================= chat =================
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName,
      required bool otherAgent, String title = ''}) {
    for (final c in chats) {
      if (c.type == type && c.otherId == otherId && (type == 'direct' || c.refId == refId)) return c;
    }
    final c = Chat(id: nid('C'), type: type, refId: refId, otherId: otherId, otherName: otherName, title: title, otherAgent: otherAgent);
    chats.insert(0, c);
    return c;
  }

  Chat? chatById(String id) {
    for (final c in chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  void markRead(Chat c) {
    if (c.unread != 0) {
      c.unread = 0;
      notifyListeners();
    }
  }

  void _sys(Chat c, String t) => c.msgs.add(Msg(id: nid('m'), from: 'system', type: 'system', body: t));
  void _sysFor(Ord o, String t) {
    final c = chatOfOrder(o);
    if (c != null) _sys(c, t);
  }

  static final _fraud = RegExp(r'(https?://|www\.|\.com|transfer dulu|\bdp\b|bayar dulu|\botp\b|kode verifikasi|\bpin\b|rekening)', caseSensitive: false);
  bool looksFraud(String t) => _fraud.hasMatch(t);

  void _incoming(Chat c, String body, {String type = 'text', Map<String, dynamic>? data, bool silent = false}) {
    if (blocked.contains(c.otherId)) return;
    c.msgs.add(Msg(id: nid('m'), from: 'other', type: type, body: body, data: data, flagged: type == 'text' && looksFraud(body)));
    if (openChatId != c.id) c.unread++;
    if (!silent && nChat && openChatId != c.id) notify('Pesan dari ${c.otherName}', body);
  }

  void sendText(Chat c, String text) {
    if (c.closed || text.trim().isEmpty) return;
    c.msgs.add(Msg(id: nid('m'), from: 'me', body: text.trim(), flagged: looksFraud(text)));
    touch();
    notifyListeners();
    _simReply(c, text);
  }

  void sendMedia(Chat c, String type, String body) {
    c.msgs.add(Msg(id: nid('m'), from: 'me', type: type, body: body));
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _incoming(c, type == 'image' ? 'Fotonya sudah saya terima, terima kasih.' : 'Lokasinya sudah saya lihat.');
      notifyListeners();
    });
  }

  void shareWa(Chat c, String number) {
    c.msgs.add(Msg(id: nid('m'), from: 'me', type: 'contact', body: number));
    notifyListeners();
  }

  void shareEwallet(Chat c, String wallet, String purpose) {
    final p = wallet.split('|');
    c.msgs.add(Msg(id: nid('m'), from: 'me', type: 'ewallet', body: p[0], data: {'no': p.length > 1 ? p[1] : '', 'purpose': purpose}));
    notifyListeners();
  }

  void blockUser(Chat c) {
    blocked.add(c.otherId);
    c.closed = true;
    _sys(c, 'Kamu memblokir pengguna ini.');
    notifyListeners();
  }

  void sendOffer(Chat c, int price, String ptype, {String note = ''}) {
    final m = Msg(id: nid('m'), from: 'me', type: 'offer', body: note, data: {'price': price, 'ptype': ptype, 'status': 'pending', 'by': 'me'});
    c.msgs.add(m);
    touch();
    notifyListeners();
    _simOfferReply(c, m);
  }

  void sendOrderOffer(Chat c, Map<String, dynamic> d) {
    final m = Msg(id: nid('m'), from: 'me', type: 'order_offer', body: 'Penawaran order', data: {...d, 'status': 'pending', 'by': 'me'});
    c.msgs.add(m);
    notifyListeners();
    _simOfferReply(c, m);
  }

  void respondOffer(Chat c, Msg m, String act, {int? counter}) {
    if (act == 'accept') {
      m.data['status'] = 'accepted';
      _sys(c, 'Penawaran ${rp(m.data['price'] as int)} disepakati.');
      _onOfferAccepted(c, m);
    } else if (act == 'reject') {
      m.data['status'] = 'rejected';
      _sys(c, 'Penawaran ditolak.');
    } else if (counter != null) {
      m.data['status'] = 'countered';
      if (m.type == 'order_offer') {
        sendOrderOffer(c, {...m.data, 'price': counter});
      } else {
        sendOffer(c, counter, m.data['ptype'] as String);
      }
      return;
    }
    notifyListeners();
  }

  void _onOfferAccepted(Chat c, Msg m) {
    if (m.type == 'offer') {
      final r = reqById(c.refId);
      if (r == null) return;
      final id = c.otherAgent ? c.otherId : 'me';
      for (final a in r.acc) {
        if (a.agentId == id) a.price = m.data['price'] as int;
      }
    } else {
      _createDirectOrder(c, m.data, c.otherAgent);
    }
  }

  Ord _createDirectOrder(Chat c, Map<String, dynamic> d, bool iAmClient) {
    final dur = (d['dur'] as num).toDouble();
    final price = d['price'] as int;
    final at = d['schedAt'] == null ? null : DateTime.tryParse(d['schedAt'] as String);
    final r = Req(id: nid('REQ'), clientId: iAmClient ? 'me' : 'sim', clientName: iAmClient ? '' : c.otherName,
        title: d['title'], cat: d['cat'] ?? 'other', desc: d['desc'] ?? '', address: d['address'] ?? address,
        area: 'Kel. ${_pick(areas)}', status: 'LOCKED', ptype: d['ptype'], price: price, dur: dur, direct: true,
        sched: at == null ? 'now' : 'date', schedAt: at, lat: (d['lat'] as num?)?.toDouble() ?? 0.5,
        lng: (d['lng'] as num?)?.toDouble() ?? 0.5, chosen: [iAmClient ? c.otherId : 'me']);
    reqs.insert(0, r);
    c.refId = r.id;
    final amt = totalOf(r.ptype, price, dur);
    final o = Ord(id: nid('ORD'), reqId: r.id, title: r.title, cat: r.cat, address: r.address, area: r.area,
        status: 'AGREED', ptype: r.ptype, otherId: c.otherId, otherName: c.otherName, pin: _pin(),
        iAmClient: iAmClient, unit: price, price: amt, fee: feeOf(amt), schedAt: _schedOf(r));
    if (!iAmClient) o.nextAt = DateTime.now().add(const Duration(seconds: 6));
    o.addLog('Order langsung disepakati (${rp(amt)})');
    orders.insert(0, o);
    _sys(c, iAmClient ? 'Order terbentuk. Silakan bayar agar dana ditahan escrow.' : 'Order terbentuk. Menunggu klien membayar.');
    notify('Order langsung terbentuk', iAmClient ? 'Segera bayar "${o.title}" dalam 30 menit.' : 'Klien akan membayar ke escrow.');
    return o;
  }

  void _simReply(Chat c, String t) {
    Future.delayed(Duration(milliseconds: 1200 + _rnd.nextInt(1200)), () {
      if (c.closed || blocked.contains(c.otherId)) return;
      final l = t.toLowerCase();
      String r;
      if (RegExp(r'harga|tawar|rp|biaya|murah|mahal').hasMatch(l)) {
        r = 'Soal harga kita sepakati lewat kartu penawaran ya, supaya tercatat resmi.';
      } else if (RegExp(r'jam|kapan|jadwal|waktu').hasMatch(l)) {
        r = 'Jadwal ikut yang di request ya. Kalau mau diubah, kabari saja.';
      } else if (RegExp(r'alamat|lokasi|dimana|di mana').hasMatch(l)) {
        r = 'Alamat lengkap muncul di detail order setelah pembayaran.';
      } else if (RegExp(r'alat|bawa|bahan').hasMatch(l)) {
        r = 'Alat standar bisa dibawa sendiri, tenang saja.';
      } else if (RegExp(r'terima kasih|makasih|thanks').hasMatch(l)) {
        r = 'Sama-sama.';
      } else {
        r = _pick(['Baik, siap.', 'Oke, noted.', 'Boleh, nanti kita koordinasi lagi di sini.', 'Siap, ada yang perlu disiapkan lagi?']);
      }
      if (_rnd.nextInt(14) == 0) r = 'Bisa transfer dulu ke rekening saya di luar aplikasi? Nanti langsung saya kerjakan.';
      _incoming(c, r);
      notifyListeners();
    });
  }

  void _simOfferReply(Chat c, Msg m) {
    Future.delayed(const Duration(seconds: 2), () {
      if (c.closed || m.data['status'] != 'pending') return;
      final price = m.data['price'] as int;
      if (c.otherAgent && c.otherId.startsWith('a') && !agentById(c.otherId).direct && m.type == 'order_offer') {
        m.data['status'] = 'rejected';
        _incoming(c, 'Maaf, saya sedang tidak menerima order langsung.');
      } else {
        final sp = m.data['svcPrice'];
        final roll = (m.type == 'order_offer' && sp is int && price >= sp) ? 0 : _rnd.nextInt(10);
        if (roll < 6) {
          m.data['status'] = 'accepted';
          _sys(c, '${c.otherName} menyetujui penawaran ${rp(price)}.');
          _onOfferAccepted(c, m);
        } else if (roll < 9) {
          m.data['status'] = 'countered';
          final np = c.otherAgent ? _round5(price * 1.12) : _round5(price * 0.92);
          if (m.type == 'order_offer') {
            _incoming(c, 'Bagaimana kalau ${rp(np)}?', type: 'order_offer', data: {...m.data, 'price': np, 'status': 'pending', 'by': 'other'});
          } else {
            _incoming(c, 'Bagaimana kalau ${rp(np)}?', type: 'offer', data: {'price': np, 'ptype': m.data['ptype'], 'status': 'pending', 'by': 'other'});
          }
        } else {
          m.data['status'] = 'rejected';
          _incoming(c, 'Maaf, harga itu belum bisa.');
        }
      }
      notifyListeners();
    });
  }

  // ================= laporan, SOS, bantuan =================
  Rep fileReport({required String cat, required String desc, String target = '', String orderId = '', int evid = 0}) {
    final r = Rep(id: nid('R'), no: 'RPT-${1000 + reports.length + 1}', cat: cat, desc: desc, target: target, orderId: orderId, evid: evid);
    reports.insert(0, r);
    notify('Laporan diterima', 'Tiket ${r.no} dibuat. Tim Trust & Safety akan menanggapi dalam 1x24 jam.');
    notifyListeners();
    return r;
  }

  void adminTriage(Rep r, String act) {
    if (act == 'warn') {
      r.status = 'Selesai';
      r.action = 'Peringatan dan penurunan reputasi terlapor';
    } else if (act == 'suspend') {
      r.status = 'Selesai';
      r.action = 'Akun terlapor disuspend, dana terkait dibekukan';
    } else {
      r.status = 'Eskalasi legal';
      r.police = 'LP/B/${100 + _rnd.nextInt(900)}/${DateTime.now().year}/POLSEK';
      r.action = 'Paket data disiapkan Tim Legal, pendampingan laporan polisi ${r.police}';
    }
    notify('Update laporan ${r.no}', r.action);
    notifyListeners();
  }

  Sos triggerSos(String orderId) {
    final who = emName.isEmpty ? 'kontak darurat (belum diatur)' : '$emName ($emPhone)';
    final s = Sos(id: nid('S'), orderId: orderId, info: 'Lokasi live dikirim ke $who');
    soses.insert(0, s);
    notify('SOS terkirim', 'Lokasi dibagikan ke $who dan tim keamanan Buruhku.');
    notifyListeners();
    return s;
  }

  void resolveSos(Sos s) {
    s.resolved = true;
    notifyListeners();
  }

  Tix createTicket(String subject, String body) {
    final t = Tix(id: nid('T'), no: 'TKT-${100 + tickets.length + 1}', subject: subject, body: body);
    tickets.insert(0, t);
    notifyListeners();
    return t;
  }

  // ================= simulasi berkala =================
  bool _simAgentAcc(Req r) {
    final el = DateTime.now().difference(r.created).inSeconds;
    if (el < 5 || _rnd.nextInt(100) > 45) return false;
    final wave = el < 12 ? 3.0 : (el < 24 ? 7.0 : 15.0);
    final lim = min(wave, r.radius);
    final c = agents.where((a) => a.verified && a.online && a.cats.contains(r.cat) && a.dist <= lim &&
        (catOf(r.cat).risk == 1 || a.level >= 2) && !blocked.contains(a.id) && !r.acc.any((x) => x.agentId == a.id)).toList();
    if (c.isEmpty) return false;
    c.sort((a, b) => (b.rating * 2 - b.dist * .3).compareTo(a.rating * 2 - a.dist * .3));
    final a = c.first;
    final p = _rnd.nextBool() ? r.price : _round5(r.price * (0.95 + _rnd.nextDouble() * 0.35));
    r.acc.add(Acc(agentId: a.id, price: p));
    final ch = chatFor(type: 'order', refId: r.id, otherId: a.id, otherName: a.short, otherAgent: true, title: r.title);
    _incoming(ch, 'Halo, saya ${a.short}. Saya siap mengerjakan "${r.title}".', silent: true);
    if (p != r.price) {
      _incoming(ch, 'Harga dari saya ${rp(p)}${unitOf(r.ptype)}', type: 'offer', data: {'price': p, 'ptype': r.ptype, 'status': 'pending', 'by': 'other'}, silent: true);
    }
    _refreshReq(r);
    notify('Ada agen ACC (${activeAcc(r).length}/${r.quota})', '${a.short} tertarik pada "${r.title}" dengan harga ${rp(p)}.');
    return true;
  }

  void _agentRespond(Ord o) {
    o.nextAt = null;
    if (_rnd.nextInt(10) < 9) {
      o.status = 'AGREED';
      o.payBy = DateTime.now().add(const Duration(minutes: 30));
      o.addLog('${o.otherName} mengonfirmasi kesepakatan');
      _sysFor(o, '${o.otherName} mengonfirmasi. Silakan bayar dalam 30 menit.');
      notify('Agen mengonfirmasi', 'Bayar "${o.title}" dalam 30 menit agar dana ditahan escrow.');
    } else {
      o.status = 'CANCELLED';
      o.doneAt = DateTime.now();
      o.addLog('${o.otherName} tidak jadi mengambil order');
      _reopenSlot(o, 'Agen tidak jadi mengambil order');
      notify('Agen mundur', '${o.otherName} tidak bisa mengambil order. Pilih agen lain.');
    }
  }

  void _onTick() {
    if (!loggedIn) return;
    final now = DateTime.now();
    var ch = false;
    for (final r in reqs.where((r) => r.mine).toList()) {
      if (['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status)) {
        if (now.isAfter(r.expires)) {
          if (r.chosen.isNotEmpty) {
            r.status = 'LOCKED';
          } else {
            r.status = 'EXPIRED';
            notify('Request kedaluwarsa', '"${r.title}" belum mendapat kesepakatan. Naikkan harga atau perluas radius.');
          }
          ch = true;
        } else if ((r.workers > 1 ? (r.chosen.isEmpty && interestCount(r) < kSearchTarget) : r.status != 'FULL') && _simAgentAcc(r)) {
          ch = true;
        }
      }
    }
    for (final r in reqs.where((r) => !r.mine).toList()) {
      final mine = r.acc.where((a) => a.agentId == 'me' && a.status == 'accepted').toList();
      if (mine.isEmpty) continue;
      final a = mine.first;
      final el = now.difference(a.at).inSeconds;
      final win = _h(r.id) % 4 != 0;
      if (win && el > 12) {
        _simClientSelects(r, a);
        ch = true;
      } else if (!win && el > 40) {
        a.status = 'withdrawn';
        final c = _chatOf(r.id, 'c:${r.clientName}');
        if (c != null) {
          _sys(c, 'Request sudah terisi oleh agen lain.');
          c.closed = true;
        }
        notify('Request terisi', '"${r.title}" diambil agen lain.');
        ch = true;
      }
    }
    for (final o in orders.toList()) {
      final due = o.nextAt != null && !now.isBefore(o.nextAt!);
      if (o.iAmClient) {
        if (o.status == 'AWAIT_AGENT' && due) {
          _agentRespond(o);
          ch = true;
        } else if (o.status == 'AGREED' && now.isAfter(o.payBy)) {
          cancelOrder(o, 'batas pembayaran habis');
          ch = true;
        } else if (o.status == 'SCHEDULED' && due && (reqById(o.reqId)?.workers ?? 1) > 1 && _rnd.nextInt(100) < 8) {
          cancelOrder(o, 'agen membatalkan', forceFull: true);
          ch = true;
        } else if (o.status == 'SCHEDULED' && due) {
          o.status = 'ON_THE_WAY';
          o.nextAt = now.add(const Duration(seconds: 8));
          o.addLog('Agen berangkat');
          _sysFor(o, '${o.otherName} berangkat menuju lokasi.');
          notify('Agen berangkat', '${o.otherName} menuju lokasimu.');
          ch = true;
        } else if (o.status == 'ON_THE_WAY' && due) {
          o.status = 'ARRIVED';
          o.arrivedAt = now;
          o.nextAt = null;
          o.addLog('Agen tiba di lokasi');
          _sysFor(o, '${o.otherName} tiba. Cocokkan wajah dengan foto profil, lalu tunjukkan PIN kerja.');
          notify('Agen tiba', 'Cocokkan wajah ${o.otherName}, lalu konfirmasi kedatangan.');
          ch = true;
        } else if (o.status == 'IN_PROGRESS' && due) {
          o.status = 'PENDING_CONFIRM';
          o.finishedAt = now;
          o.nextAt = null;
          o.addLog('Agen menandai selesai (foto hasil diunggah)');
          _sysFor(o, '${o.otherName} menyelesaikan pekerjaan. Mohon cek hasilnya.');
          notify('Pekerjaan selesai', 'Cek hasil "${o.title}" lalu konfirmasi.');
          ch = true;
        } else if (o.status == 'PENDING_CONFIRM' && o.finishedAt != null && now.difference(o.finishedAt!).inHours >= 24) {
          completeOrder(o, auto: true);
          ch = true;
        }
      } else {
        if (o.status == 'AWAIT_AGENT' && now.difference(o.created).inMinutes >= 15) {
          o.status = 'CANCELLED';
          o.addLog('Batas konfirmasi 15 menit habis');
          _reopenSlot(o);
          ch = true;
        } else if (o.status == 'AGREED' && due) {
          o.nextAt = null;
          o.status = 'SCHEDULED';
          o.paidAt = now;
          if (_rnd.nextInt(10) < 3) {
            o.cod = true;
            o.fee = 0;
            o.payMethod = 'COD';
            o.escrow = 'cod';
            o.addLog('Klien memilih bayar tunai (COD)');
            _sysFor(o, 'Klien memilih bayar tunai (COD). Tagih tunai setelah pekerjaan selesai.');
            notify('Klien memilih COD', 'Tagih ${rp(o.total)} tunai setelah "${o.title}" selesai. Komisi dipotong dari saldo.');
          } else {
            o.escrow = 'held';
            o.addLog('Klien membayar. Dana ditahan (escrow)');
            _sysFor(o, 'Pembayaran aman, dana ditahan. Siap bekerja.');
            notify('Pembayaran masuk escrow', '${rp(o.net)} akan cair setelah "${o.title}" selesai.');
          }
          ch = true;
        } else if (o.status == 'PENDING_CONFIRM' && due) {
          completeOrder(o);
          ch = true;
        }
      }
      if (o.doneAt != null && !o.active && now.difference(o.doneAt!).inDays >= 7) {
        final c = chatOfOrder(o);
        if (c != null && !c.closed) {
          c.closed = true;
          ch = true;
        }
      }
    }
    for (final p in payouts) {
      if (p.status == 'Diproses' && now.difference(p.at).inSeconds > 10) {
        p.status = 'Berhasil';
        notify('Saldo cair', '${rp(p.amount)} masuk ke ${p.dest}.');
        ch = true;
      }
    }
    for (final t in tickets) {
      if (t.status == 'Dibuka' && now.difference(t.at).inSeconds > 10) {
        t.status = 'Dijawab';
        t.reply = 'Terima kasih sudah menghubungi Buruhku. Tim kami sudah memeriksa dan akan menindaklanjuti.';
        notify('Tiket ${t.no} dijawab', t.reply);
        ch = true;
      }
    }
    for (final d in disputes) {
      if (d.status == 'open' && now.difference(d.at).inSeconds > 4) {
        d.status = 'responded';
        d.response = 'Pihak lain menanggapi: pekerjaan sudah dilakukan sesuai kesepakatan dan siap dimediasi.';
        notify('Tanggapan sengketa', d.response);
        ch = true;
      }
    }
    if (kyc.status == 'approved' && kyc.online && now.difference(lastActive).inHours >= 2) {
      kyc.online = false;
      notify('Status Offline', 'Kamu otomatis offline setelah 2 jam tidak aktif.');
      ch = true;
    }
    if (agentMode && kyc.status == 'approved' && kyc.online && incoming.length < 3 && _rnd.nextInt(15) == 0) {
      _spawnSimReq();
      ch = true;
    }
    if (kyc.status == 'approved' && kyc.online && incomingDirect.length < 3 && _rnd.nextInt(25) == 0) {
      _spawnSimDirect();
      ch = true;
    }
    if (ch || toastNote != null) notifyListeners();
  }
}