part of 'app_state.dart';

/// Request jasa, moderasi, ACC agen, pemilihan agen.
class RequestRepository extends RepoBase {
  RequestRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  String get address => hub.address;
  set address(String v) => hub.address = v;
  String get pin => hub.pin;
  set pin(String v) => hub.pin = v;
  List<Req> get reqs => hub.reqs;
  set reqs(List<Req> v) => hub.reqs = v;
  List<Ord> get orders => hub.orders;
  set orders(List<Ord> v) => hub.orders = v;
  List<Chat> get chats => hub.chats;
  set chats(List<Chat> v) => hub.chats = v;
  List<Disp> get disputes => hub.disputes;
  set disputes(List<Disp> v) => hub.disputes = v;
  Random get _rnd => hub._rnd;
  String nid(String p) => hub.nid(p);
  String _pin() => hub._pin();
  void notify(String t, String b) => hub.notify(t, b);
  String cancelOrder(Ord o, String reason, {bool forceFull = false}) => hub.cancelOrder(o, reason, forceFull: forceFull);
  Agent agentById(String id) => hub.agentById(id);
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName, required bool otherAgent, String title = ''}) => hub.chatFor(type: type, refId: refId, otherId: otherId, otherName: otherName, otherAgent: otherAgent, title: title);
  void _sys(Chat c, String t) => hub._sys(c, t);
  void _incoming(Chat c, String body, {String type = 'text', Map<String, dynamic>? data, bool silent = false}) => hub._incoming(c, body, type: type, data: data, silent: silent);

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
}
