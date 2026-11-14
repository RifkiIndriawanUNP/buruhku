part of 'app_state.dart';

/// Chat, kartu penawaran, blokir, order langsung.
class ChatRepository extends RepoBase {
  ChatRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  String get address => hub.address;
  set address(String v) => hub.address = v;
  String get pin => hub.pin;
  set pin(String v) => hub.pin = v;
  bool get nChat => hub.nChat;
  set nChat(bool v) => hub.nChat = v;
  Set<String> get blocked => hub.blocked;
  set blocked(Set<String> v) => hub.blocked = v;
  List<Req> get reqs => hub.reqs;
  set reqs(List<Req> v) => hub.reqs = v;
  List<Ord> get orders => hub.orders;
  set orders(List<Ord> v) => hub.orders = v;
  List<Chat> get chats => hub.chats;
  set chats(List<Chat> v) => hub.chats = v;
  String get openChatId => hub.openChatId;
  set openChatId(String v) => hub.openChatId = v;
  Random get _rnd => hub._rnd;
  String nid(String p) => hub.nid(p);
  String _pin() => hub._pin();
  int _round5(num n) => hub._round5(n);
  T _pick<T>(List<T> l) => hub._pick(l);
  void touch() => hub.touch();
  void notify(String t, String b) => hub.notify(t, b);
  Agent agentById(String id) => hub.agentById(id);
  DateTime? _schedOf(Req r) => hub._schedOf(r);
  Chat? chatOfOrder(Ord o) => hub.chatOfOrder(o);
  Req? reqById(String id) => hub.reqById(id);

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

  void sendMedia(Chat c, String type, String body, [Map<String, dynamic>? data]) {
    c.msgs.add(Msg(id: nid('m'), from: 'me', type: type, body: body, data: data));
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
    final la = (d['lat'] as num?)?.toDouble() ?? Env.mapLat, ln = (d['lng'] as num?)?.toDouble() ?? Env.mapLng;
    final r = Req(id: nid('REQ'), clientId: iAmClient ? 'me' : 'sim', clientName: iAmClient ? '' : c.otherName,
        title: d['title'], cat: d['cat'] ?? 'other', desc: d['desc'] ?? '', address: d['address'] ?? address,
        area: 'Kel. ${_pick(areas)}', status: 'LOCKED', ptype: d['ptype'], price: price, dur: dur, direct: true,
        sched: at == null ? 'now' : 'date', schedAt: at, lat: fixLat(la, ln),
        lng: fixLng(la, ln), chosen: [iAmClient ? c.otherId : 'me']);
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
}
