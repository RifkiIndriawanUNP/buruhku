import 'dart:math';
import 'models.dart';

const _fn = ['Budi', 'Agus', 'Joko', 'Slamet', 'Dedi', 'Rudi', 'Eko', 'Hendra', 'Andi', 'Yanto', 'Bayu', 'Fajar',
  'Wawan', 'Iwan', 'Tono', 'Sugeng', 'Ucok', 'Asep', 'Dani', 'Rizal', 'Siti', 'Rina', 'Wati', 'Yuli', 'Ani', 'Dewi',
  'Maya', 'Lilis', 'Tari', 'Nur', 'Ratna', 'Imam', 'Gilang', 'Teguh', 'Anwar', 'Yusuf'];
const _ln = ['Santoso', 'Wijaya', 'Pratama', 'Saputra', 'Hidayat', 'Nugroho', 'Kusuma', 'Lestari', 'Siregar',
  'Gunawan', 'Setiawan', 'Ramadhan', 'Permana', 'Wibowo', 'Halim'];
const _bios = [
  'Biasa kerja harian di sekitar sini, rapi dan tepat waktu.',
  'Tenaga kuat, sudah sering bantu pindahan dan angkat barang.',
  'Teliti dan sabar. Siap mengerjakan apa saja yang halal.',
  'Pengalaman 3 tahun kerja serabutan. Alat dasar bawa sendiri.',
  'Lagi cari tambahan penghasilan, kerja jujur dan komunikatif.',
];
const areas = ['Cikembang', 'Citepus', 'Palabuhanratu', 'Pasirsuren', 'Gunungguruh', 'Jayanti', 'Sukamulya', 'Cibodas'];

List<Agent> buildAgents() {
  final r = Random(7);
  final list = <Agent>[];
  for (var i = 0; i < 36; i++) {
    final cs = <String>{};
    final k = 1 + r.nextInt(3);
    while (cs.length < k) {
      cs.add(cats[r.nextInt(cats.length)].id);
    }
    final jobs = r.nextInt(220);
    final rating = double.parse((3.6 + r.nextInt(15) / 10).toStringAsFixed(1));
    list.add(Agent(
      id: 'a${i + 1}',
      name: '${_fn[i % _fn.length]} ${_ln[r.nextInt(_ln.length)]}',
      bio: _bios[r.nextInt(_bios.length)],
      cats: cs.toList(),
      rating: rating,
      jobs: jobs,
      dist: double.parse((0.4 + r.nextDouble() * 13).toStringAsFixed(1)),
      level: jobs >= 50 && rating >= 4.7 ? 3 : (jobs >= 5 ? 2 : 1),
      base: 20000 + r.nextInt(8) * 5000,
      verified: r.nextDouble() < 0.9,
      online: r.nextDouble() < 0.65,
      direct: r.nextDouble() < 0.85,
    ));
  }
  return list;
}

List<Req> seedIncoming() {
  final n = DateTime.now();
  Req mk(String id, String cn, String t, String c, String d, int p, String pt, double dur, int w, double dist,
      String area, {List<String> pre = const []}) {
    return Req(
      id: id, clientId: 'sim', clientName: cn, title: t, cat: c, desc: d, price: p, ptype: pt, dur: dur, workers: w,
      dist: dist, area: 'Kel. $area', address: 'Jl. Melati No. ${10 + dist.round() * 3}, $area',
      quota: max(5, w + 2), expires: n.add(const Duration(hours: 3)),
      created: n.subtract(const Duration(minutes: 8)), sched: 'now',
      acc: pre.map((a) => Acc(agentId: a, price: p)).toList(),
      clientRating: 4.2 + (dist.round() % 8) / 10,
    );
  }

  final list = [
    mk('SIM1', 'Ibu Sari', 'Benerin genteng bocor', 'repair', 'Genteng bagian dapur bocor, perlu diganti 5 buah. Tangga ada.', 250000, 'lump', 0, 1, 1.2, 'Cikembang', pre: ['a3', 'a8']),
    mk('SIM2', 'Pak Hendra', 'Bersihkan halaman belakang', 'garden', 'Memangkas rumput dan membuang sampah daun, luas sekitar 80 meter persegi.', 150000, 'lump', 0, 1, 2.4, 'Citepus'),
    mk('SIM3', 'Mbak Rina', 'Nyetrika baju sekeranjang', 'laundry', 'Baju sudah dicuci dan kering. Tinggal disetrika dan dilipat rapi.', 30000, 'hourly', 3, 1, 3.1, 'Jayanti'),
    mk('SIM4', 'Pak Wawan', 'Angkat lemari dan kasur', 'move', 'Pindah kontrakan, butuh 2 orang angkat lemari, kasur dan kardus ke mobil bak.', 120000, 'lump', 0, 2, 4.8, 'Pasirsuren'),
    mk('SIM5', 'Bu Lestari', 'Bantu bersih-bersih rumah', 'clean', 'Bersihkan rumah tipe 45 sehabis acara keluarga. Alat pel dan sapu ada.', 35000, 'hourly', 4, 1, 5.5, 'Sukamulya'),
    mk('SIM6', 'Mas Dimas', 'Titip belikan galon dan gas', 'errand', 'Belikan 2 galon air dan antar ke rumah. Uang belanja saya ganti.', 40000, 'lump', 0, 1, 6.9, 'Gunungguruh'),
  ];
  list[3].sched = 'date';
  list[3].schedAt = DateTime(n.year, n.month, n.day + 1, 9);
  return list;
}

const simNames = ['Ibu Sari', 'Pak Hendra', 'Mbak Rina', 'Pak Wawan', 'Bu Lestari', 'Mas Dimas', 'Pak Anto', 'Bu Mawar'];

const _revText = [
  'Kerjanya rapi dan tepat waktu, terima kasih.',
  'Sopan dan cepat. Pasti pesan lagi.',
  'Hasil sesuai harapan, harga pas.',
  'Agak telat sedikit tapi hasilnya bagus.',
  'Tenaganya kuat, kerjaan cepat selesai.',
];
const _revFrom = ['Rani', 'Bagas', 'Ibu Tini', 'Pak Darto', 'Sinta'];

List<Rev> genReviews(Agent a) {
  if (a.jobs == 0) return [];
  final r = Random(a.id.hashCode);
  final out = <Rev>[];
  for (var i = 0; i < 3; i++) {
    out.add(Rev(
      id: '${a.id}r$i', aboutId: a.id, from: _revFrom[r.nextInt(_revFrom.length)],
      rating: a.rating >= 4.5 ? 5 - r.nextInt(2) : 3 + r.nextInt(3),
      tags: [['Tepat waktu', 'Rapi', 'Sopan', 'Kuat'][r.nextInt(4)]],
      comment: _revText[r.nextInt(_revText.length)],
      at: DateTime.now().subtract(Duration(days: 3 + r.nextInt(60))),
    ));
  }
  return out;
}

/// Tawaran jasa milik agen simulasi (deterministik, tidak disimpan).
List<Svc> buildServices(List<Agent> agents) {
  final r = Random(11);
  final out = <Svc>[];
  var n = 0;
  for (final a in agents) {
    if (!a.verified || !a.direct || a.jobs < 4) continue;
    final k = 1 + r.nextInt(3);
    final used = <String>{};
    for (var i = 0; i < k; i++) {
      final cid = a.cats[r.nextInt(a.cats.length)];
      final list = catSuggest[cid] ?? templates;
      final t = list[r.nextInt(list.length)];
      final title = t['t'] as String;
      if (!used.add('$cid$title')) continue;
      final f = 0.9 + (a.base - 20000) / 100000;
      var p = (((t['p'] as int) * f) / 1000).round() * 1000;
      if (p < 15000) p = 15000;
      final pt = t['pt'] as String;
      out.add(Svc(
          id: 'S${++n}', agentId: a.id, title: title, cat: cid, desc: t['d'] as String, ptype: pt, price: p,
          dur: pt == 'lump' ? 0.0 : (pt == 'hourly' ? 3.0 : 1.0)));
    }
  }
  return out;
}
