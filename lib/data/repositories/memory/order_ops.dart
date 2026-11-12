// ignore_for_file: invalid_use_of_protected_member
part of 'app_store.dart';

/// Order: pembayaran, status, sengketa, ulasan, dompet agen.
extension OrderOps on AppStore {
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
}
