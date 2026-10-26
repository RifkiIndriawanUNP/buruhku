import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'chat.dart';
import 'order.dart';
import 'service.dart';

// ---------------------------------------------------------------- request masuk
class IncomingTab extends StatefulWidget {
  const IncomingTab({super.key});
  @override
  State<IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<IncomingTab> {
  String seg = 'req';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final ok = k.status == 'approved';
    final l = ok ? s.incoming : <Req>[];
    final dl = ok ? s.incomingDirect : <DirectReq>[];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Expanded(child: Text('Home agen', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        if (ok) ...[
          Text(k.online ? 'Online' : 'Offline', style: const TextStyle(fontWeight: FontWeight.w700)),
          Switch(value: k.online, onChanged: (v) => s.setOnline(v)),
        ],
        IconButton(tooltip: 'Beralih ke mode klien', onPressed: () => s.setMode(false), icon: const Icon(Icons.swap_horiz)),
      ]),
      if (!ok) _kycBanner(context, s),
      if (ok) ...[
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _stat('Hari ini', rp(s.earned(const Duration(days: 1))))),
          const SizedBox(width: 8),
          Expanded(child: _stat('Rating', s.myRating == 0 ? '-' : s.myRating.toStringAsFixed(1))),
          const SizedBox(width: 8),
          Expanded(child: _stat('Penerimaan', '${(s.acceptRate * 100).round()}%')),
        ]),
        if (s.penalty > 0) Padding(padding: const EdgeInsets.only(top: 10), child: Warn('Kamu punya ${s.penalty} pembatalan sepihak. Reputasi turun, hindari membatalkan order.')),
        if (!k.online) const Padding(padding: EdgeInsets.only(top: 10), child: Warn('Kamu offline. Aktifkan status Online untuk menerima request dan order langsung.', icon: Icons.cloud_off_outlined)),
        const SizedBox(height: 12),
        Box(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyServicesPage())),
          child: Row(children: [
            const Icon(Icons.storefront_outlined, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tawaran jasa saya', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(s.mySvcs.isEmpty ? 'Buat tawaran dengan harga sendiri, klien tinggal order' : '${s.mySvcs.where((x) => x.active).length} aktif dari ${s.mySvcs.length} tawaran', style: const TextStyle(fontSize: 12, color: g500)),
              ]),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceEditPage())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Seg({'req': 'Request sekitar (${l.length})', 'direct': 'Order langsung (${dl.length})'}, seg, (v) => setState(() => seg = v)),
        const SizedBox(height: 10),
        if (seg == 'req') ...[
          if (l.isEmpty) const Padding(padding: EdgeInsets.only(top: 30), child: Empty(Icons.inbox_outlined, 'Belum ada request baru. Request sesuai keahlian dan radiusmu muncul otomatis saat kamu online.')),
          if (k.online)
            for (final r in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Box(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingDetailPage(r.id))),
                  child: Row(children: [
                    Icon(catOf(r.cat).icon, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${r.area}  |  ~${r.dist.toStringAsFixed(1)} km  |  ${ago(r.created)}', style: const TextStyle(fontSize: 12, color: g500)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, children: [Tag('${r.workers} buruh', icon: Icons.group_outlined), Tag('ACC ${s.activeAcc(r).length}/${r.quota}'), Tag('Klien ${r.clientRating.toStringAsFixed(1)}', icon: Icons.star_outline)]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(rp(r.price), style: const TextStyle(fontWeight: FontWeight.w800)), Text(unitOf(r.ptype).isEmpty ? 'borongan' : unitOf(r.ptype), style: const TextStyle(fontSize: 11, color: g500))]),
                  ]),
                ),
              ),
        ] else ...[
          if (dl.isEmpty) const Padding(padding: EdgeInsets.only(top: 30), child: Empty(Icons.bolt_outlined, 'Belum ada order langsung. Pesanan dari tawaran jasamu atau chat langsung klien muncul di sini.')),
          for (final d in dl) _DirectCard(d),
        ],
      ],
    ]);
  }

  Widget _stat(String l, String v) => Box(padding: const EdgeInsets.all(10), child: Column(children: [Text(v, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(fontSize: 11, color: g500))]));

  Widget _kycBanner(BuildContext context, AppStore s) {
    final k = s.kyc;
    final msg = {
      'none': 'Kamu belum terdaftar sebagai agen. Daftar dan verifikasi KTP + selfie untuk mulai menerima order.',
      'pending': 'Data kamu sedang direview admin (maks 1x24 jam). Untuk demo, setujui di Akun > Panel Admin (Simulasi).',
      'rejected': 'Verifikasi ditolak: ${k.reason}',
      'needs_more': 'Admin butuh data tambahan: ${k.reason}',
    }[k.status]!;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(children: [
        const Empty(Icons.badge_outlined, ''),
        Warn(msg, icon: Icons.info_outline),
        const SizedBox(height: 12),
        if (k.status == 'none' || k.status == 'needs_more' || (k.status == 'rejected' && k.tries < 3))
          full(pbtn(k.status == 'none' ? 'Daftar jadi agen' : 'Lengkapi pendaftaran', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycPage())), icon: Icons.how_to_reg_outlined)),
        if (k.status == 'rejected' && k.tries >= 3) const Text('Batas pendaftaran ulang (3x) tercapai. Hubungi Bantuan.', style: TextStyle(color: g500)),
        const SizedBox(height: 8),
        full(obtn('Kembali ke mode klien', () => s.setMode(false))),
      ]),
    );
  }
}

/// Kartu order langsung: bisa langsung di-ACC dari Home (selain lewat chat).
class _DirectCard extends StatelessWidget {
  final DirectReq d;
  const _DirectCard(this.d);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final data = d.msg.data;
    final mine = data['svcId'] != null && s.mySvcs.any((x) => x.id == data['svcId']);
    final pt = data['ptype'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Avatar(size: 38),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.chat.otherName, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(ago(d.msg.at), style: const TextStyle(fontSize: 11, color: g500)),
            ])),
            if (mine) const Tag('Dari tawaranmu', icon: Icons.storefront_outlined),
          ]),
          const SizedBox(height: 10),
          Text(data['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
          if ((data['desc'] as String? ?? '').isNotEmpty) Text(data['desc'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: g700)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.event_outlined, size: 16, color: g500),
            const SizedBox(width: 4),
            Expanded(child: Text('${data['when']}  |  alamat lengkap muncul setelah dibayar', style: const TextStyle(fontSize: 12, color: g500))),
          ]),
          const SizedBox(height: 6),
          Text('${rp(data['price'] as int)}${unitOf(pt)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: pbtn('Terima', () {
              final err = s.acceptDirect(d.chat, d.msg);
              toast(context, err ?? 'Order diterima. Menunggu klien membayar.');
            })),
            const SizedBox(width: 8),
            Expanded(child: obtn('Tawar', () async {
              final v = await askText(context, 'Tawar harga${unitOf(pt)}', hint: 'Nominal dalam Rupiah', money: true);
              final p = money(v ?? '');
              if (v == null) return;
              if (p < 15000) {
                if (context.mounted) toast(context, 'Nominal minimal Rp15.000.');
                return;
              }
              s.respondOffer(d.chat, d.msg, 'counter', counter: p);
            })),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Tolak',
              onPressed: () async {
                if (await confirm(context, 'Tolak order?', 'Klien akan diberi tahu bahwa kamu tidak bisa mengambil order ini.', ok: 'Tolak')) s.rejectDirect(d.chat, d.msg);
              },
              icon: const Icon(Icons.close),
            ),
            IconButton.outlined(
              tooltip: 'Chat',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(d.chat.id))),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- detail request (agen)
class IncomingDetailPage extends StatelessWidget {
  final String id;
  const IncomingDetailPage(this.id, {super.key});

  Future<void> _acc(BuildContext context, AppStore s, Req r) async {
    var counter = false;
    final price = TextEditingController(text: fmtNum(r.price));
    final note = TextEditingController();
    final res = await sheet<bool>(context, (x) => StatefulBuilder(builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('ACC request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Seg({'a': 'Terima ${rp(r.price)}', 'b': 'Ajukan harga'}, counter ? 'b' : 'a', (v) => set(() => counter = v == 'b')),
            const SizedBox(height: 12),
            if (counter) TF('Harga kamu (Rp${unitOf(r.ptype)})', price, money: true),
            TF('Pesan untuk klien (opsional)', note, lines: 2),
            full(pbtn('Kirim ACC', () => Navigator.pop(x, true))),
          ]),
        )));
    if (res != true || !context.mounted) return;
    final p = counter ? money(price.text) : null;
    if (counter && (p == null || p < 15000)) {
      toast(context, 'Harga minimal Rp15.000.');
      return;
    }
    final err = s.agentAccept(r, counter: p, note: note.text.trim());
    if (err != null) {
      toast(context, err);
      return;
    }
    final c = s.chatFor(type: 'order', refId: r.id, otherId: 'c:${r.clientName}', otherName: r.clientName, otherAgent: false, title: r.title);
    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(c.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = s.reqById(id);
    if (r == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Request tidak ditemukan.'));
    final mine = r.acc.where((a) => a.agentId == 'me').toList();
    final myAcc = mine.isEmpty ? null : mine.last;
    final rec = recRange(r.cat, r.ptype);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail request')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [Icon(catOf(r.cat).icon, size: 30), const SizedBox(width: 10), Expanded(child: Text(r.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 10),
        Text(r.desc, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 10),
        Box(child: Column(children: [
          Kv('Klien', '${r.clientName}  (${r.clientRating.toStringAsFixed(1)})'),
          Kv('Area', '${r.area}  |  ~${r.dist.toStringAsFixed(1)} km'),
          Kv('Alamat lengkap', 'Muncul setelah klien membayar'),
          Kv('Harga', '${rp(r.price)}${unitOf(r.ptype)}'),
          if (r.ptype != 'lump') Kv('Estimasi total', rp(r.unitTotal)),
          Kv('Jumlah buruh', '${r.workers} orang'),
          Kv('Jadwal', (r.sched == 'date' && r.schedAt != null) ? fdt(r.schedAt!) : 'Sekarang'),
          Kv('Slot ACC', '${s.activeAcc(r).length}/${r.quota}'),
          Kv('Perkiraan bersih', rp((r.unitTotal * .9).round())),
        ])),
        const SizedBox(height: 8),
        Text('Rekomendasi wajar: ${rp(rec[0])} sampai ${rp(rec[1])}${unitOf(r.ptype)}', style: const TextStyle(fontSize: 12.5, color: g500)),
        if (catOf(r.cat).risk > 1) const Padding(padding: EdgeInsets.only(top: 10), child: Warn('Kategori sensitif: butuh SKCK dan level L2.', icon: Icons.shield_outlined)),
        const SizedBox(height: 16),
        if (myAcc != null && myAcc.status == 'accepted') ...[
          const Warn('ACC terkirim. Menunggu klien memilih. Negosiasi harga lewat chat.', icon: Icons.hourglass_top),
          const SizedBox(height: 10),
          full(pbtn('Buka chat', () {
            final c = s.chatFor(type: 'order', refId: r.id, otherId: 'c:${r.clientName}', otherName: r.clientName, otherAgent: false, title: r.title);
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(c.id)));
          }, icon: Icons.chat_bubble_outline)),
          const SizedBox(height: 8),
          full(obtn('Tarik ACC', () { s.withdrawAcc(r); Navigator.pop(context); })),
        ] else if (myAcc != null)
          Warn('Status ACC kamu: ${myAcc.status == 'selected' ? 'dipilih klien' : 'tidak lanjut'}.', icon: Icons.info_outline)
        else
          Row(children: [
            Expanded(child: obtn('Tolak', () { s.agentReject(r); Navigator.pop(context); })),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: pbtn('ACC / tawar', () => _acc(context, s, r), icon: Icons.check)),
          ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------- pekerjaanku
class JobsTab extends StatelessWidget {
  const JobsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final mine = s.orders.where((o) => !o.iAmClient).toList();
    final act = mine.where((o) => o.active).toList();
    final his = mine.where((o) => !o.active).toList();
    final waiting = s.reqs.where((r) => !r.mine && r.acc.any((a) => a.agentId == 'me' && a.status == 'accepted')).toList();
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Pekerjaanku', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))),
        const TabBar(tabs: [Tab(text: 'Aktif'), Tab(text: 'Selesai')]),
        Expanded(
          child: TabBarView(children: [
            (act.isEmpty && waiting.isEmpty)
                ? const Empty(Icons.work_outline, 'Belum ada pekerjaan aktif. ACC request di tab Masuk.')
                : ListView(padding: const EdgeInsets.all(16), children: [
                    if (waiting.isNotEmpty) ...[
                      const Text('Menunggu pilihan klien', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final r in waiting)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Box(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingDetailPage(r.id))),
                            child: Row(children: [const Icon(Icons.hourglass_top), const SizedBox(width: 12), Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600))), const Tag('ACC terkirim')]),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                    for (final o in act) OrderTile(o),
                  ]),
            his.isEmpty ? const Empty(Icons.history, 'Pekerjaan selesai akan tercatat di sini.') : ListView(padding: const EdgeInsets.all(16), children: [for (final o in his) OrderTile(o)]),
          ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- pendapatan
class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  Future<void> _withdraw(BuildContext context, AppStore s) async {
    if (s.pin.isEmpty) {
      final p = await askText(context, 'Buat PIN transaksi (4-6 digit)', number: true, obscure: true);
      if (p == null || p.length < 4 || p.length > 6) {
        if (p != null && context.mounted) toast(context, 'PIN harus 4 sampai 6 digit.');
        return;
      }
      s.pin = p;
      s.notifyListeners();
    }
    if (!context.mounted) return;
    final dests = ['${s.kyc.bank} ${s.kyc.bankNo}', ...s.wallets.map((w) => w.replaceAll('|', ' '))];
    var dest = dests.first;
    final amt = TextEditingController(), pin = TextEditingController();
    String? err;
    await sheet<void>(context, (x) => StatefulBuilder(builder: (ctx, set) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tarik saldo (tersedia ${rp(s.balance)})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(initialValue: dest, decoration: const InputDecoration(labelText: 'Tujuan'), items: [for (final d in dests) DropdownMenuItem(value: d, child: Text(d))], onChanged: (v) => set(() => dest = v ?? dest)),
            const SizedBox(height: 12),
            TF('Nominal (min Rp25.000)', amt, money: true),
            TF('PIN transaksi', pin, type: TextInputType.number, obscure: true, maxLen: 6),
            if (err != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(err!, style: const TextStyle(color: g700))),
            full(pbtn('Tarik saldo', () {
              final e = s.withdraw(money(amt.text), dest, pin.text);
              if (e != null) {
                set(() => err = e);
                return;
              }
              Navigator.pop(x);
              toast(context, 'Penarikan diproses (maks H+1).');
            })),
          ]),
        )));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lv = s.myLevel;
    final led = s.ledger.where((l) => l.role == 'a').toList();
    final revs = s.revs.where((v) => v.aboutId == 'me' && v.pub).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Pendapatan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Box(color: g900, border: g900, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Saldo tersedia', style: TextStyle(color: g300)),
        Text(rp(s.balance), style: const TextStyle(color: cW, fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('Tertahan di escrow: ${rp(s.held)}', style: const TextStyle(color: g300, fontSize: 12.5)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: cW, foregroundColor: g900), onPressed: s.kyc.status == 'approved' ? () => _withdraw(context, s) : null, child: const Text('Tarik saldo'))),
        ]),
      ])),
      if (s.balance < 0) const Padding(padding: EdgeInsets.only(top: 10), child: Warn('Saldo negatif karena komisi order COD. Akan terpotong otomatis dari pendapatan berikutnya.', icon: Icons.payments_outlined)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Box(padding: const EdgeInsets.all(10), child: Column(children: [Text(rp(s.earned(const Duration(days: 1))), style: const TextStyle(fontWeight: FontWeight.w800)), const Text('Hari ini', style: TextStyle(fontSize: 11, color: g500))]))),
        const SizedBox(width: 8),
        Expanded(child: Box(padding: const EdgeInsets.all(10), child: Column(children: [Text(rp(s.earned(const Duration(days: 7))), style: const TextStyle(fontWeight: FontWeight.w800)), const Text('7 hari', style: TextStyle(fontSize: 11, color: g500))]))),
        const SizedBox(width: 8),
        Expanded(child: Box(padding: const EdgeInsets.all(10), child: Column(children: [Text(rp(s.earned(const Duration(days: 30))), style: const TextStyle(fontWeight: FontWeight.w800)), const Text('30 hari', style: TextStyle(fontSize: 11, color: g500))]))),
      ]),
      const Section('Reputasi'),
      Box(child: Column(children: [
        Kv('Level', lv == 0 ? 'Belum terverifikasi' : {1: 'L1 Baru (maks Rp500rb/order)', 2: 'L2 Terpercaya', 3: 'L3 Premium'}[lv]!),
        Kv('Pekerjaan selesai', '${s.myJobs}'),
        Kv('Rating', s.myRating == 0 ? '-' : s.myRating.toStringAsFixed(2)),
        Kv('Tingkat penerimaan', '${(s.acceptRate * 100).round()}%'),
        Kv('Pembatalan sepihak', '${s.penalty}'),
        if (lv == 1) const Padding(padding: EdgeInsets.only(top: 6), child: Text('Naik ke L2: unggah SKCK, selesaikan 5 order dengan rating baik.', style: TextStyle(fontSize: 12, color: g500))),
      ])),
      if (s.kyc.status == 'approved' && !s.kyc.skck) ...[const SizedBox(height: 8), full(obtn('Unggah SKCK untuk level L2', () => s.uploadSkck(), icon: Icons.upload_file))],
      const SizedBox(height: 8),
      full(obtn('Pengaturan agen', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentSettingsPage())), icon: Icons.tune)),
      if (s.payouts.isNotEmpty) ...[
        const Section('Penarikan'),
        for (final p in s.payouts.take(5)) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.north_east), title: Text(rp(p.amount)), subtitle: Text('${p.dest}  |  ${fdt(p.at)}'), trailing: Tag(p.status, filled: p.status == 'Berhasil')),
      ],
      const Section('Riwayat transaksi'),
      if (led.isEmpty) const Text('Belum ada transaksi.', style: TextStyle(color: g500)),
      for (final l in led.take(20))
        ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Icon(l.amount >= 0 ? Icons.south_west : Icons.north_east, size: 18), title: Text(l.note), subtitle: Text(fdt(l.at)), trailing: Text(rp(l.amount), style: const TextStyle(fontWeight: FontWeight.w700))),
      const Section('Ulasan untukku'),
      if (revs.isEmpty) const Text('Ulasan muncul setelah kedua pihak menilai.', style: TextStyle(color: g500)),
      for (final v in revs.take(5)) ListTile(contentPadding: EdgeInsets.zero, title: Row(children: [Text(v.from), const Spacer(), Stars(v.rating.toDouble(), size: 13)]), subtitle: Text(v.comment)),
    ]);
  }
}

// ---------------------------------------------------------------- wizard KYC
class KycPage extends StatefulWidget {
  const KycPage({super.key});
  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  int step = 0;
  final keys = List.generate(6, (_) => GlobalKey<FormState>());
  final name = TextEditingController(), nik = TextEditingController(), addr = TextEditingController();
  final emN = TextEditingController(), emP = TextEditingController(), bankNo = TextEditingController(), holder = TextEditingController();
  DateTime? birth;
  bool a1 = false, a2 = false, a3 = false;
  static const steps = ['Data diri', 'Dokumen', 'SKCK', 'Keahlian', 'Rekening', 'Persetujuan'];

  @override
  void initState() {
    super.initState();
    final s = context.r;
    final k = s.kyc;
    name.text = k.name.isEmpty ? s.name : k.name;
    nik.text = k.nik;
    addr.text = k.addr.isEmpty ? s.address : k.addr;
    emN.text = k.emName.isEmpty ? s.emName : k.emName;
    emP.text = k.emPhone.isEmpty ? s.emPhone : k.emPhone;
    bankNo.text = k.bankNo;
    holder.text = k.bankHolder;
  }

  Future<void> _liveness(Kyc k) async {
    for (final t in ['Hadap lurus ke kamera...', 'Kedipkan mata...', 'Toleh ke kanan...']) {
      if (!mounted) return;
      showDialog<void>(context: context, barrierDismissible: false, builder: (_) => AlertDialog(content: Row(children: [const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 14), Expanded(child: Text(t))])));
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.pop(context);
    }
    setState(() => k.selfie = true);
  }

  bool _next(AppStore s) {
    final k = s.kyc;
    if (!(keys[step].currentState?.validate() ?? true)) return false;
    switch (step) {
      case 0:
        if (birth == null) { toast(context, 'Pilih tanggal lahir.'); return false; }
        final n = DateTime.now();
        final age = n.year - birth!.year - ((n.month < birth!.month || (n.month == birth!.month && n.day < birth!.day)) ? 1 : 0);
        if (age < 18) { toast(context, 'Usia minimal 18 tahun.'); return false; }
        if (!k.photo) { toast(context, 'Ambil foto profil dulu.'); return false; }
        k.name = name.text.trim();
        k.nik = nik.text.trim();
        k.birth = fdate(birth!);
        k.addr = addr.text.trim();
        k.emName = emN.text.trim();
        k.emPhone = emP.text.trim();
        break;
      case 1:
        if (!k.ktp || !k.selfie) { toast(context, 'Foto KTP dan selfie liveness wajib.'); return false; }
        break;
      case 3:
        if (k.cats.isEmpty) { toast(context, 'Pilih minimal 1 keahlian.'); return false; }
        break;
      case 4:
        if (holder.text.trim().toLowerCase() != k.name.toLowerCase()) { toast(context, 'Nama pemilik rekening harus sama dengan nama di KTP.'); return false; }
        k.bankNo = bankNo.text.trim();
        k.bankHolder = holder.text.trim();
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    Widget body;
    switch (step) {
      case 0:
        body = Column(children: [
          TF('Nama sesuai KTP', name, validator: (v) => (v ?? '').trim().length < 3 ? 'Wajib diisi' : null),
          TF('NIK (16 digit)', nik, type: TextInputType.number, maxLen: 16, validator: (v) => (v ?? '').length != 16 ? 'NIK harus 16 digit' : null),
          obtn(birth == null ? 'Pilih tanggal lahir' : fdate(birth!), () async {
            final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
            if (d != null) setState(() => birth = d);
          }, icon: Icons.cake_outlined),
          const SizedBox(height: 12),
          TF('Alamat sesuai domisili', addr, lines: 2, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
          TF('Nama kontak darurat', emN, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
          TF('No. HP kontak darurat', emP, type: TextInputType.phone, validator: (v) => (v ?? '').trim().length < 9 ? 'Nomor tidak valid' : null),
          Row(children: [const Avatar(size: 48), const SizedBox(width: 12), Expanded(child: obtn(k.photo ? 'Foto profil siap' : 'Ambil foto profil', () => setState(() => k.photo = true), icon: k.photo ? Icons.check : Icons.photo_camera_outlined))]),
        ]);
        break;
      case 1:
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Foto KTP', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Ph(h: 130, icon: Icons.badge_outlined),
          const SizedBox(height: 8),
          obtn(k.ktp ? 'KTP terbaca (OCR cocok dengan NIK)' : 'Foto KTP', () => setState(() => k.ktp = true), icon: k.ktp ? Icons.check : Icons.photo_camera_outlined),
          const SizedBox(height: 16),
          const Text('Selfie + liveness', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Center(child: Avatar(size: 96, icon: Icons.face_outlined)),
          const SizedBox(height: 8),
          obtn(k.selfie ? 'Liveness lolos, kecocokan wajah 94%' : 'Mulai liveness (kedip + toleh)', () => _liveness(k), icon: k.selfie ? Icons.check : Icons.face_retouching_natural_outlined),
          const SizedBox(height: 12),
          const Warn('Data KTP dan selfie dienkripsi serta hanya dipakai untuk verifikasi identitas.', icon: Icons.lock_outline),
        ]);
        break;
      case 2:
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SKCK (opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Tanpa SKCK kamu mulai di level L1: hanya kategori risiko rendah dan maks Rp500.000 per order. Dengan SKCK dan 5 order rating baik, kamu naik ke L2 dan bisa ambil kategori sensitif (masuk rumah, antar anak).', style: TextStyle(height: 1.4)),
          const SizedBox(height: 14),
          const Ph(h: 110, icon: Icons.description_outlined),
          const SizedBox(height: 8),
          obtn(k.skck ? 'SKCK terunggah' : 'Unggah SKCK', () => setState(() => k.skck = !k.skck), icon: k.skck ? Icons.check : Icons.upload_file),
        ]);
        break;
      case 3:
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Keahlian (maks 5)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cats)
              FilterChip(
                avatar: Icon(c.icon, size: 16), label: Text(c.name), selected: k.cats.contains(c.id),
                onSelected: (v) => setState(() {
                  if (v && k.cats.length >= 5) { toast(context, 'Maksimal 5 keahlian.'); return; }
                  v ? k.cats.add(c.id) : k.cats.remove(c.id);
                }),
              ),
          ]),
          const SizedBox(height: 16),
          Text('Radius kerja: ${k.radius.round()} km', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: k.radius, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => k.radius = v)),
          Text('Jam ketersediaan: ${two(k.fromH)}:00 sampai ${two(k.toH)}:00', style: const TextStyle(fontWeight: FontWeight.w700)),
          RangeSlider(values: RangeValues(k.fromH.toDouble(), k.toH.toDouble()), min: 0, max: 24, divisions: 24, onChanged: (v) => setState(() { k.fromH = v.start.round(); k.toH = v.end.round(); })),
        ]);
        break;
      case 4:
        body = Column(children: [
          DropdownButtonFormField<String>(initialValue: k.bank, decoration: const InputDecoration(labelText: 'Bank / e-wallet'), items: [for (final b in ['BCA', 'Mandiri', 'BNI', 'BRI', 'GoPay', 'DANA', 'OVO']) DropdownMenuItem(value: b, child: Text(b))], onChanged: (v) => setState(() => k.bank = v ?? k.bank)),
          const SizedBox(height: 12),
          TF('Nomor rekening / akun', bankNo, type: TextInputType.number, validator: (v) => (v ?? '').trim().length < 6 ? 'Nomor tidak valid' : null),
          TF('Nama pemilik', holder, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
          const Warn('Nama pemilik harus sama dengan nama di KTP agar penarikan saldo bisa diproses.', icon: Icons.account_balance_outlined),
        ]);
        break;
      default:
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Box(child: Column(children: [Kv('Nama', k.name), Kv('NIK', k.nik), Kv('Keahlian', k.cats.map((c) => catOf(c).name).join(', ')), Kv('Radius', '${k.radius.round()} km'), Kv('Rekening', '${k.bank} ${k.bankNo}'), Kv('SKCK', k.skck ? 'Ada' : 'Tidak ada (mulai L1)')])),
          CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a1, onChanged: (v) => setState(() => a1 = v ?? false), title: const Text('Saya setuju Syarat & Ketentuan Agen')),
          CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a2, onChanged: (v) => setState(() => a2 = v ?? false), title: const Text('Saya menyetujui Kode Etik dan Daftar Larangan')),
          CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a3, onChanged: (v) => setState(() => a3 = v ?? false), title: const Text('Saya setuju Kebijakan Privasi dan pemrosesan data KTP')),
        ]);
    }
    return Scaffold(
      appBar: AppBar(title: Text('Daftar agen: ${steps[step]}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [for (var i = 0; i < steps.length; i++) Expanded(child: Container(height: 5, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: i <= step ? g900 : g200, borderRadius: BorderRadius.circular(3))))]),
        ),
        Expanded(child: Form(key: keys[step], child: ListView(padding: const EdgeInsets.all(16), children: [body]))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              if (step > 0) Expanded(child: obtn('Kembali', () => setState(() => step--))),
              if (step > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: pbtn(step == steps.length - 1 ? 'Kirim pendaftaran' : 'Lanjut', () {
                  if (!_next(s)) return;
                  if (step == steps.length - 1) {
                    if (!(a1 && a2 && a3)) { toast(context, 'Setujui semua persyaratan dulu.'); return; }
                    s.submitKyc();
                    Navigator.pop(context);
                    info(context, 'Pendaftaran terkirim', 'Cek otomatis lolos (NIK, kecocokan wajah, duplikasi). Data masuk antrean review admin maks 1x24 jam.');
                  } else {
                    setState(() => step++);
                  }
                }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- pengaturan agen
class AgentSettingsPage extends StatelessWidget {
  const AgentSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan agen')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Status online'), value: k.online, onChanged: s.kyc.status == 'approved' ? (v) => s.setOnline(v) : null),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Terima chat dan order langsung'), value: k.directOk, onChanged: (v) { k.directOk = v; s.notifyListeners(); }),
        const Section('Keahlian'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in cats)
            FilterChip(
              avatar: Icon(c.icon, size: 16), label: Text(c.name), selected: k.cats.contains(c.id),
              onSelected: (v) {
                if (v && k.cats.length >= 5) { toast(context, 'Maksimal 5 keahlian.'); return; }
                if (!v && k.cats.length == 1) { toast(context, 'Minimal 1 keahlian.'); return; }
                v ? k.cats.add(c.id) : k.cats.remove(c.id);
                s.notifyListeners();
              },
            ),
        ]),
        const Section('Radius dan jam'),
        Text('Radius kerja: ${k.radius.round()} km'),
        Slider(value: k.radius, min: 1, max: 20, divisions: 19, onChanged: (v) { k.radius = v; s.notifyListeners(); }),
        Text('Jam ketersediaan: ${two(k.fromH)}:00 sampai ${two(k.toH)}:00'),
        RangeSlider(values: RangeValues(k.fromH.toDouble(), k.toH.toDouble()), min: 0, max: 24, divisions: 24, onChanged: (v) { k.fromH = v.start.round(); k.toH = v.end.round(); s.notifyListeners(); }),
        const Section('Rekening pencairan'),
        Box(child: Column(children: [Kv('Bank', k.bank), Kv('Nomor', k.bankNo), Kv('Atas nama', k.bankHolder)])),
        const SizedBox(height: 8),
        const Text('Mengubah rekening perlu verifikasi ulang. Hubungi Bantuan.', style: TextStyle(fontSize: 12, color: g500)),
      ]),
    );
  }
}
