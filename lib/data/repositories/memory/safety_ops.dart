// ignore_for_file: invalid_use_of_protected_member
part of 'app_store.dart';

/// Laporan, SOS, dan tiket bantuan.
extension SafetyOps on AppStore {
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
}
