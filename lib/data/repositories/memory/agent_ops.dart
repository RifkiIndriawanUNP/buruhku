// ignore_for_file: invalid_use_of_protected_member
part of 'app_store.dart';

/// Mode agen: request masuk, ACC/tolak, status online.
extension AgentOps on AppStore {
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
}
