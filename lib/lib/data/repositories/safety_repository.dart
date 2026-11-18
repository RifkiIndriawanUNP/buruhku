import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:buruhku/domain/models/models.dart';

typedef NoticeFn = void Function(String title, String body);

/// Laporan, SOS, dan tiket bantuan. Sumber kebenaran untuk tiga data tersebut.
///
/// Tidak tahu apa pun soal layar maupun AppState: hal yang dibutuhkan dari luar
/// (notifikasi, pembuat id, label kontak darurat) diberikan lewat konstruktor,
/// sehingga mudah dites dan nanti mudah dihubungkan ke Service server.
class SafetyRepository extends ChangeNotifier {
  SafetyRepository({
    required NoticeFn onNotice,
    required String Function(String prefix) nextId,
    required String Function() contactLabel,
    Random? random,
  })  : _notice = onNotice,
        _nextId = nextId,
        _contact = contactLabel,
        _rnd = random ?? Random();

  final NoticeFn _notice;
  final String Function(String prefix) _nextId;
  final String Function() _contact;
  final Random _rnd;

  List<Rep> reports = [];
  List<Sos> soses = [];
  List<Tix> tickets = [];

  Rep fileReport({required String cat, required String desc, String target = '', String orderId = '', int evid = 0}) {
    final r = Rep(id: _nextId('R'), no: 'RPT-${1000 + reports.length + 1}', cat: cat, desc: desc, target: target, orderId: orderId, evid: evid);
    reports.insert(0, r);
    _notice('Laporan diterima', 'Tiket ${r.no} dibuat. Tim Trust & Safety akan menanggapi dalam 1x24 jam.');
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
    _notice('Update laporan ${r.no}', r.action);
    notifyListeners();
  }

  Sos triggerSos(String orderId) {
    final who = _contact();
    final s = Sos(id: _nextId('S'), orderId: orderId, info: 'Lokasi live dikirim ke $who');
    soses.insert(0, s);
    _notice('SOS terkirim', 'Lokasi dibagikan ke $who dan tim keamanan Buruhku.');
    notifyListeners();
    return s;
  }

  void resolveSos(Sos s) {
    s.resolved = true;
    notifyListeners();
  }

  Tix createTicket(String subject, String body) {
    final t = Tix(id: _nextId('T'), no: 'TKT-${100 + tickets.length + 1}', subject: subject, body: body);
    tickets.insert(0, t);
    notifyListeners();
    return t;
  }

  // ---- penyimpanan (kunci sama dengan snapshot lama, jadi data lama tetap terbaca) ----
  Map<String, dynamic> toJson() => {
        'reports': reports.map((e) => e.toJson()).toList(),
        'soses': soses.map((e) => e.toJson()).toList(),
        'tickets': tickets.map((e) => e.toJson()).toList(),
      };

  void fromJson(Map<String, dynamic> j) {
    reports = listFrom(j['reports'], Rep.fromJson);
    soses = listFrom(j['soses'], Sos.fromJson);
    tickets = listFrom(j['tickets'], Tix.fromJson);
  }

  void clear() {
    reports = [];
    soses = [];
    tickets = [];
  }
}
