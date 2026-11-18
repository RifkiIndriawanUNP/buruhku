part of 'app_state.dart';

/// Mode agen: online/offline, order masuk, ACC.
class AgentModeRepository extends RepoBase {
  AgentModeRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  String get address => hub.address;
  set address(String v) => hub.address = v;
  String get pin => hub.pin;
  set pin(String v) => hub.pin = v;
  Set<String> get hidden => hub.hidden;
  set hidden(Set<String> v) => hub.hidden = v;
  Kyc get kyc => hub.kyc;
  set kyc(Kyc v) => hub.kyc = v;
  List<Req> get reqs => hub.reqs;
  set reqs(List<Req> v) => hub.reqs = v;
  List<Ord> get orders => hub.orders;
  set orders(List<Ord> v) => hub.orders = v;
  int get declines => hub.declines;
  set declines(int v) => hub.declines = v;
  int get accepts => hub.accepts;
  set accepts(int v) => hub.accepts = v;
  int get tab => hub.tab;
  set tab(int v) => hub.tab = v;
  Random get _rnd => hub._rnd;
  String nid(String p) => hub.nid(p);
  String _pin() => hub._pin();
  int _round5(num n) => hub._round5(n);
  T _pick<T>(List<T> l) => hub._pick(l);
  void touch() => hub.touch();
  void notify(String t, String b, {String? refType, String? refId}) => hub.notify(t, b, refType: refType, refId: refId);
  int get myLevel => hub.myLevel;
  List<Acc> activeAcc(Req r) => hub.activeAcc(r);
  void _refreshReq(Req r) => hub._refreshReq(r);
  DateTime? _schedOf(Req r) => hub._schedOf(r);
  Chat? _chatOf(String refId, String otherId) => hub._chatOf(refId, otherId);
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName, required bool otherAgent, String title = ''}) => hub.chatFor(type: type, refId: refId, otherId: otherId, otherName: otherName, otherAgent: otherAgent, title: title);
  void _sys(Chat c, String t) => hub._sys(c, t);
  void _incoming(Chat c, String body, {String type = 'text', Map<String, dynamic>? data, bool silent = false}) => hub._incoming(c, body, type: type, data: data, silent: silent);

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
    notify('Klien memilih kamu', 'Klien ${r.clientName} memilih kamu untuk "${r.title}". Konfirmasi di tab Pekerjaanku.', refType: 'order', refId: o.id);
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
    final sid = nid('SIM');
    final dist = double.parse((0.5 + _rnd.nextDouble() * max(kyc.radius - 0.5, 1)).toStringAsFixed(1));
    final at = pointAt(dist, sid);
    reqs.insert(0, Req(id: sid, lat: at.latitude, lng: at.longitude, clientId: 'sim', clientName: _pick(simNames), title: titles[cid]!, cat: cid,
        desc: 'Mohon dikerjakan rapi. Peralatan dasar tersedia di rumah. Bisa mulai sekarang.', price: p,
        dist: dist,
        area: 'Kel. ${nearestArea(at)}', address: 'Jl. Kenanga No. ${1 + _rnd.nextInt(60)}', created: n,
        expires: n.add(const Duration(hours: 2)), clientRating: 4.0 + _rnd.nextInt(10) / 10));
  }
}
