// ignore_for_file: invalid_use_of_protected_member
part of 'app_store.dart';

/// Simulasi berkala (pengganti backend). Hapus/ganti saat memakai server.
extension SimOps on AppStore {
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
        } else if ((r.workers > 1 ? (r.chosen.isEmpty && interestCount(r) < AppStore.kSearchTarget) : r.status != 'FULL') && _simAgentAcc(r)) {
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
