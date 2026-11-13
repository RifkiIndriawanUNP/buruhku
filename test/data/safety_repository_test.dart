import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/safety_repository.dart';

void main() {
  late SafetyRepository repo;
  late List<String> notices;
  var id = 0;

  setUp(() {
    notices = [];
    id = 0;
    repo = SafetyRepository(
      onNotice: (t, b) => notices.add(t),
      nextId: (p) => '$p${++id}',
      contactLabel: () => 'Ibu (0812)',
    );
  });

  tearDown(() => repo.dispose());

  test('laporan baru ada di urutan teratas, bernomor, dan memberi notifikasi', () {
    final a = repo.fileReport(cat: 'Penipuan', desc: 'Minta transfer di luar aplikasi');
    final b = repo.fileReport(cat: 'Pelecehan', desc: 'Ucapan tidak pantas');
    expect(repo.reports.first, b);
    expect(a.no, 'RPT-1001');
    expect(b.no, 'RPT-1002');
    expect(notices, ['Laporan diterima', 'Laporan diterima']);
  });

  test('SOS menyebut kontak darurat dan bisa ditandai selesai', () {
    final s = repo.triggerSos('o1');
    expect(s.info, contains('Ibu (0812)'));
    expect(s.resolved, isFalse);
    repo.resolveSos(s);
    expect(repo.soses.single.resolved, isTrue);
  });

  test('triase: peringatan menutup laporan, eskalasi membuat nomor LP', () {
    final r1 = repo.fileReport(cat: 'Penipuan', desc: 'a');
    repo.adminTriage(r1, 'warn');
    expect(r1.status, 'Selesai');

    final r2 = repo.fileReport(cat: 'Kekerasan', desc: 'b');
    repo.adminTriage(r2, 'legal');
    expect(r2.status, 'Eskalasi legal');
    expect(r2.police, startsWith('LP/B/'));
  });

  test('toJson lalu fromJson mengembalikan semua data', () {
    repo.fileReport(cat: 'Penipuan', desc: 'a');
    repo.triggerSos('o1');
    repo.createTicket('Tanya saldo', 'Kapan cair?');
    final salinan = SafetyRepository(onNotice: (_, __) {}, nextId: (p) => p, contactLabel: () => '-')
      ..fromJson(repo.toJson());
    expect(salinan.reports.length, 1);
    expect(salinan.soses.length, 1);
    expect(salinan.tickets.single.subject, 'Tanya saldo');
    salinan.dispose();
  });

  test('listener dipanggil setiap data berubah', () {
    var n = 0;
    repo.addListener(() => n++);
    repo.createTicket('x', 'y');
    repo.triggerSos('o1');
    expect(n, 2);
  });
}
