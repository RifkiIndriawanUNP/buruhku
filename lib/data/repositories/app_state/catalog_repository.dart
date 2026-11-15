part of 'app_state.dart';

/// Katalog agen & jasa, favorit, tawaran jasa milik agen.
class CatalogRepository extends RepoBase {
  CatalogRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  List<Rev> get revs => hub.revs;
  set revs(List<Rev> v) => hub.revs = v;
  String get name => hub.name;
  set name(String v) => hub.name = v;
  String get address => hub.address;
  set address(String v) => hub.address = v;
  Set<String> get favs => hub.favs;
  set favs(Set<String> v) => hub.favs = v;
  Set<String> get blocked => hub.blocked;
  set blocked(Set<String> v) => hub.blocked = v;
  Kyc get kyc => hub.kyc;
  set kyc(Kyc v) => hub.kyc = v;
  List<Chat> get chats => hub.chats;
  set chats(List<Chat> v) => hub.chats = v;
  List<Svc> get mySvcs => hub.mySvcs;
  set mySvcs(List<Svc> v) => hub.mySvcs = v;
  Set<String> get favSvc => hub.favSvc;
  set favSvc(Set<String> v) => hub.favSvc = v;
  Map<String, List<int>> get rate => hub.rate;
  set rate(Map<String, List<int>> v) => hub.rate = v;
  int get declines => hub.declines;
  set declines(int v) => hub.declines = v;
  int get accepts => hub.accepts;
  set accepts(int v) => hub.accepts = v;
  List<Agent> get agents => hub.agents;
  List<Svc> get simSvcs => hub.simSvcs;
  Random get _rnd => hub._rnd;
  String nid(String p) => hub.nid(p);
  T _pick<T>(List<T> l) => hub._pick(l);
  void touch() => hub.touch();
  void notify(String t, String b, {String? refType, String? refId}) => hub.notify(t, b, refType: refType, refId: refId);
  int get myLevel => hub.myLevel;
  Chat chatFor({required String type, required String refId, required String otherId, required String otherName, required bool otherAgent, String title = ''}) => hub.chatFor(type: type, refId: refId, otherId: otherId, otherName: otherName, otherAgent: otherAgent, title: title);
  void respondOffer(Chat c, Msg m, String act, {int? counter}) => hub.respondOffer(c, m, act, counter: counter);

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
    } else if (sort == 'populer') {
      l.sort((a, b) => b.jobs.compareTo(a.jobs));
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
      'schedAt': date ? at.toIso8601String() : null, 'when': date ? fdt(at) : 'Sekarang', 'lat': Env.mapLat, 'lng': Env.mapLng,
      'status': 'pending', 'by': 'other',
    });
    c.msgs.add(Msg(id: nid('m'), from: 'other', type: 'order_offer', body: 'Penawaran order', data: d));
    c.unread++;
    notify('Order langsung baru', 'Klien $name memesan "${d['title']}" (${rp(d['price'] as int)}).', refType: 'chat', refId: c.id);
  }
}
