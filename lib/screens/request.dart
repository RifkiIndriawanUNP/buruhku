import 'package:flutter/material.dart';
import '../models.dart';
import '../seed.dart';
import '../store.dart';
import '../ui.dart';
import 'chat.dart';
import 'location.dart';
import 'order.dart';
import 'service.dart';
import 'shell.dart';

// ---------------------------------------------------------------- tab Request
class MyRequestsTab extends StatelessWidget {
  const MyRequestsTab({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Request & favorit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          ),
          const TabBar(tabs: [Tab(text: 'Request'), Tab(text: 'Agen favorit'), Tab(text: 'Jasa favorit')]),
          const Expanded(child: TabBarView(children: [_RequestList(), FavAgentsView(), FavServicesView()])),
        ]),
      );
}

class _RequestList extends StatelessWidget {
  const _RequestList();
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = s.myReqs;
    return ListView(padding: const EdgeInsets.all(16), children: [
      full(pbtn('Buat request baru', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestFormPage())), icon: Icons.add)),
      const SizedBox(height: 4),
      const Section('Template cepat'),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final t in templates)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(t['t'] as String), avatar: const Icon(Icons.bolt, size: 16),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(tpl: t))),
              ),
            ),
        ]),
      ),
      const Section('Daftar request'),
      if (l.isEmpty) const Padding(padding: EdgeInsets.only(top: 40), child: Empty(Icons.assignment_outlined, 'Belum ada request. Tulis pekerjaan apa saja, agen terdekat akan menghubungimu.')),
      for (final r in l)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Box(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReqDetailPage(r.id))),
            child: Row(children: [
              Icon(catOf(r.cat).icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${rp(r.price)}${unitOf(r.ptype)}  |  ${r.workers} buruh', style: const TextStyle(color: g700, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Tag(reqLabels[r.status] ?? r.status, filled: r.status == 'OPEN' || r.status == 'HAS_ACCEPTORS'),
                    if (['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status)) Tag('ACC ${s.activeAcc(r).length}/${r.quota}', icon: Icons.group_outlined),
                    if (r.workers > 1) Tag('${r.chosen.length}/${r.workers} dimulai', icon: Icons.groups_outlined),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- form request
class RequestFormPage extends StatefulWidget {
  final Req? edit;
  final String? cat;
  final Map<String, dynamic>? tpl;
  const RequestFormPage({this.edit, this.cat, this.tpl, super.key});
  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final key = GlobalKey<FormState>();
  final title = TextEditingController(), desc = TextEditingController(), addr = TextEditingController();
  final notes = TextEditingController(), price = TextEditingController(), dur = TextEditingController();
  String cat = 'other', sched = 'now', ptype = 'lump';
  int workers = 1, photos = 0;
  DateTime? when;
  Offset pin = const Offset(.5, .5);

  @override
  void initState() {
    super.initState();
    final e = widget.edit, t = widget.tpl;
    if (e != null) {
      title.text = e.title;
      desc.text = e.desc;
      addr.text = e.address;
      notes.text = e.notes;
      price.text = fmtNum(e.price);
      dur.text = e.dur > 0 ? '${e.dur}' : '';
      cat = e.cat;
      sched = e.sched == 'date' ? 'date' : 'now';
      ptype = e.ptype;
      workers = e.workers;
      photos = e.photos;
      when = e.schedAt;
      pin = Offset(e.lat, e.lng);
    } else {
      if (t != null) _applyTpl(t);
      if (widget.cat != null) cat = widget.cat!;
    }
  }

  void _applyTpl(Map<String, dynamic> t) {
    title.text = t['t'];
    desc.text = t['d'];
    cat = t['c'];
    price.text = fmtNum(t['p'] as int);
    ptype = t['pt'];
    if (ptype != 'lump') dur.text = '3';
  }

  /// Saran jasa: mengikuti kategori jika request dibuka dari kategori di Beranda, selain itu jasa populer.
  List<Map<String, dynamic>> get _sugg => widget.cat != null ? (catSuggest[cat] ?? templates) : templates;

  int get p => money(price.text);
  double get d => double.tryParse(dur.text.replaceAll(',', '.')) ?? 0;

  Req _build() => Req(
        title: title.text.trim(), cat: cat, desc: desc.text.trim(), address: addr.text.trim(),
        area: 'Kel. ${areas[(pin.dx * 8).floor().clamp(0, 7)]}', ptype: ptype, price: p, workers: workers,
        photos: photos, dur: ptype == 'lump' ? 0 : d, notes: notes.text.trim(), sched: sched,
        schedAt: sched == 'date' ? when : null, lat: pin.dx, lng: pin.dy,
      );

  Future<void> _pickWhen() async {
    final d = await pickDateTime(context, initial: when);
    if (d != null) setState(() => when = d);
  }

  Future<void> _preview() async {
    if (!key.currentState!.validate()) return;
    if (sched == 'date' && (when == null || when!.isBefore(DateTime.now()))) {
      toast(context, 'Pilih tanggal dan jam yang valid.');
      return;
    }
    final r = _build();
    final rec = recRange(cat, ptype);
    final total = totalOf(ptype, p, r.dur);
    final ok = await sheet<bool>(context, (c) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ringkasan request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Kv('Judul', r.title),
            Kv('Kategori', catOf(cat).name),
            Kv('Jadwal', sched == 'now' ? 'Sekarang' : fdt(when!)),
            Kv('Jumlah buruh', '${r.workers} orang'),
            Kv('Harga penawaran', '${rp(p)}${unitOf(ptype)}'),
            if (ptype != 'lump') Kv('Estimasi total', rp(total)),
            Kv('Estimasi biaya platform', rp(feeOf(total))),
            const SizedBox(height: 8),
            if (p < rec[0]) const Warn('Harga di bawah rekomendasi wajar. Agen mungkin enggan ACC. Pertimbangkan menaikkan harga.'),
            const SizedBox(height: 8),
            const Text('Pembayaran dilakukan setelah agen dipilih. Dana ditahan escrow sampai pekerjaan selesai.', style: TextStyle(color: g500, fontSize: 12.5)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: obtn('Ubah', () => Navigator.pop(c, false))),
              const SizedBox(width: 10),
              Expanded(child: pbtn(widget.edit == null ? 'Kirim request' : 'Simpan', () => Navigator.pop(c, true))),
            ]),
          ]),
        ));
    if (ok != true || !mounted) return;
    final s = context.r;
    final e = widget.edit;
    if (e != null) {
      final material = e.price != r.price || e.address != r.address || e.sched != r.sched || e.schedAt != r.schedAt;
      e.title = r.title;
      e.cat = r.cat;
      e.desc = r.desc;
      e.address = r.address;
      e.area = r.area;
      e.ptype = r.ptype;
      e.price = r.price;
      e.workers = r.workers;
      e.photos = r.photos;
      e.dur = r.dur;
      e.notes = r.notes;
      e.sched = r.sched;
      e.schedAt = r.schedAt;
      e.lat = r.lat;
      e.lng = r.lng;
      s.afterEdit(e, material);
      toast(context, material ? 'Request diubah. Agen yang sudah ACC diberi tahu.' : 'Request diubah.');
      Navigator.pop(context);
      return;
    }
    final m = s.submitReq(r);
    if (m[0] == 'reject') {
      await info(context, 'Request ditolak', '${m[1]}\n\nSaran: ubah pekerjaan menjadi tugas yang legal dan aman, atau hubungi layanan profesional bersertifikat.');
      return;
    }
    if (m[0] == 'review') await info(context, 'Perlu tinjauan admin', '${m[1]}\n\nRequest akan dicari agen setelah disetujui admin.');
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReqDetailPage(r.id)));
  }

  @override
  Widget build(BuildContext context) {
    final rec = recRange(cat, ptype);
    final total = totalOf(ptype, p, d);
    return Scaffold(
      appBar: AppBar(title: Text(widget.edit == null ? 'Buat request' : 'Ubah request')),
      body: Form(
        key: key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (widget.edit == null) ...[
            Text(widget.cat != null ? 'Saran jasa ${catOf(cat).name}' : 'Jasa populer', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sugg.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _sugg[i];
                  return SizedBox(
                    width: 150,
                    child: Box(
                      onTap: () => setState(() => _applyTpl(t)),
                      padding: const EdgeInsets.all(10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(catOf(t['c'] as String).icon, size: 18),
                        const SizedBox(height: 4),
                        Text(t['t'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const Spacer(),
                        Text('${rp(t['p'] as int)}${unitOf(t['pt'] as String)}', style: const TextStyle(fontSize: 11, color: g500)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          TF('Judul jasa', title, maxLen: 80, validator: (v) => (v ?? '').trim().isEmpty ? 'Judul wajib diisi' : null),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: cat, decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() => cat = v ?? cat),
            ),
          ),
          TF('Deskripsi pekerjaan', desc, lines: 4, validator: (v) => (v ?? '').trim().length < 20 ? 'Deskripsi minimal 20 karakter' : null),
          LocationField(addr: addr, pin: pin, onPin: (o) => setState(() => pin = o)),
          const SizedBox(height: 8),
          const Text('Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Seg(const {'now': 'Sekarang', 'date': 'Tanggal & jam'}, sched, (v) => setState(() => sched = v)),
          if (sched == 'date') ...[
            const SizedBox(height: 8),
            obtn(when == null ? 'Pilih tanggal dan jam' : fdt(when!), _pickWhen, icon: Icons.event),
          ],
          if (sched == 'now') const Padding(padding: EdgeInsets.only(top: 6), child: Text('Disiarkan ke agen terdekat. Kedaluwarsa dalam 30 menit.', style: TextStyle(fontSize: 12, color: g500))),
          const SizedBox(height: 16),
          Row(children: [
            const Expanded(child: Text('Jumlah buruh', style: TextStyle(fontWeight: FontWeight.w700))),
            Counter(workers, 1, 10, (v) => setState(() => workers = v)),
          ]),
          const SizedBox(height: 16),
          const Text('Jenis harga', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Seg(ptypes, ptype, (v) => setState(() => ptype = v)),
          const SizedBox(height: 12),
          if (ptype != 'lump')
            TF('Estimasi durasi (${ptype == 'hourly' ? 'jam' : 'hari'})', dur, type: TextInputType.number, onChanged: (_) => setState(() {}),
                validator: (v) => d <= 0 ? 'Durasi wajib untuk tarif ${ptype == 'hourly' ? 'per jam' : 'harian'}' : null),
          TF('Harga penawaran (Rp${unitOf(ptype)})', price, money: true, onChanged: (_) => setState(() {}),
              validator: (v) => p < 15000 ? 'Minimal Rp15.000' : null),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Rekomendasi harga wajar: ${rp(rec[0])} sampai ${rp(rec[1])}${unitOf(ptype)}${ptype != 'lump' && p > 0 ? '\nEstimasi total: ${rp(total)}' : ''}',
                style: const TextStyle(fontSize: 12.5, color: g700)),
          ),
          const Text('Foto pendukung (maks 5)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < photos; i++) Stack(children: [
              const Ph(w: 64, h: 64),
              Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => setState(() => photos--), child: const Icon(Icons.cancel, size: 18))),
            ]),
            if (photos < 5)
              InkWell(
                onTap: () => setState(() => photos++),
                child: Container(width: 64, height: 64, decoration: BoxDecoration(border: Border.all(color: g500), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.add_a_photo_outlined)),
              ),
          ]),
          const SizedBox(height: 16),
          TF('Catatan khusus (opsional)', notes, hint: 'mis. bawa alat sendiri, makan disediakan'),
          full(pbtn('Lihat ringkasan', _preview, icon: Icons.fact_check_outlined)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- detail request
class ReqDetailPage extends StatelessWidget {
  final String id;
  const ReqDetailPage(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = s.reqById(id);
    if (r == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Request tidak ditemukan.'));
    if (r.workers > 1) return GroupOrderPage(r.id);
    final open = ['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status);
    final accs = r.acc.where((a) => a.status == 'accepted' || a.status == 'selected').toList();
    final orders = s.orders.where((o) => o.reqId == r.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Detail request'), actions: [
        if (open || r.status == 'EXPIRED' || r.status == 'IN_REVIEW')
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(edit: r)));
              if (v == 'cancel' && await confirm(context, 'Batalkan request?', 'Agen yang sudah ACC akan diberi tahu. Tanpa biaya karena belum ada pembayaran.', ok: 'Batalkan')) {
                s.cancelReq(r);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Ubah request')), PopupMenuItem(value: 'cancel', child: Text('Batalkan request'))],
          ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Icon(catOf(r.cat).icon, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(r.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          Tag(reqLabels[r.status] ?? r.status, filled: true),
          if (open) Tag('ACC ${s.activeAcc(r).length}/${r.quota}', icon: Icons.group_outlined),
          if (r.direct) const Tag('Order langsung', icon: Icons.bolt_outlined),
        ]),
        if (open)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Live((_) => Text('Sisa waktu mencari agen: ${clock(r.expires.difference(DateTime.now()))}', style: const TextStyle(color: g700))),
          ),
        if (r.status == 'IN_REVIEW') Padding(padding: const EdgeInsets.only(top: 10), child: Warn('${r.reason}\nBuka Akun > Panel Admin (Simulasi) untuk menyetujui.')),
        const SizedBox(height: 10),
        Box(child: Column(children: [
          Kv('Kategori', catOf(r.cat).name),
          Kv('Harga', '${rp(r.price)}${unitOf(r.ptype)} (${ptypes[r.ptype]})'),
          if (r.ptype != 'lump') Kv('Estimasi total', rp(r.unitTotal)),
          Kv('Jumlah buruh', '${r.workers} orang'),
          Kv('Jadwal', (r.sched == 'now' || r.schedAt == null) ? 'Sekarang' : fdt(r.schedAt!)),
          Kv('Alamat', r.address),
          Kv('Radius pencarian', '${r.radius.toStringAsFixed(0)} km'),
          if (r.notes.isNotEmpty) Kv('Catatan', r.notes),
        ])),
        const SizedBox(height: 8),
        Text(r.desc, style: const TextStyle(height: 1.4)),
        if (r.status == 'EXPIRED') ...[
          const Section('Belum ada kesepakatan'),
          const Warn('Request kedaluwarsa. Pilih salah satu cara agar lebih mudah dapat agen.'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            obtn('Naikkan harga 10%', () => s.relist(r, addPrice: (r.price * 0.1 / 1000).round() * 1000), icon: Icons.trending_up),
            obtn('Perluas radius +5 km', () => s.relist(r, addRadius: 5), icon: Icons.radar),
            obtn('Perpanjang', () => s.relist(r), icon: Icons.update),
          ]),
        ],
        if (open || accs.isNotEmpty) ...[
          Section('Agen yang ACC (${accs.length}/${r.quota})'),
          if (accs.isEmpty) const Box(child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: g700)), SizedBox(width: 12), Expanded(child: Text('Mencari agen terdekat dan memberi notifikasi bertahap (3 km, 7 km, lalu lebih jauh)...'))])),
          for (final a in accs) _AccCard(r, a),
        ],
        if (orders.isNotEmpty) ...[
          const Section('Order'),
          for (final o in orders)
            ListTile(
              contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long_outlined), title: Text('${o.otherName}  ${rp(o.total)}'),
              subtitle: Text(ordLabels[o.status] ?? o.status), trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(o.id))),
            ),
        ],
        const SizedBox(height: 30),
      ]),
    );
  }
}

class _AccCard extends StatelessWidget {
  final Req r;
  final Acc a;
  const _AccCard(this.r, this.a);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ag = s.agentById(a.agentId);
    final selected = a.status == 'selected';
    final canPick = !selected && r.chosen.length < r.workers && ['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(ag.id))),
            child: Row(children: [
              const Avatar(size: 46),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(ag.short, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 6), if (ag.verified) const Icon(Icons.verified_outlined, size: 16)]),
                Row(children: [Stars(s.ratingOf(ag), size: 12), Text('  ${s.ratingOf(ag).toStringAsFixed(1)}  ~${ag.dist.toStringAsFixed(1)} km  ${ag.jobs} job', style: const TextStyle(fontSize: 11.5, color: g500))]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(rp(a.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(unitOf(r.ptype).isEmpty ? 'borongan' : unitOf(r.ptype), style: const TextStyle(fontSize: 11, color: g500)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          if (selected)
            Row(children: [
              const Expanded(child: Tag('Dipilih', icon: Icons.check_circle_outline, filled: true)),
              obtn('Chat', () => _openChat(context, s, ag), icon: Icons.chat_bubble_outline),
            ])
          else
            Row(children: [
              Expanded(child: obtn('Chat', () => _openChat(context, s, ag), icon: Icons.chat_bubble_outline)),
              const SizedBox(width: 8),
              if (canPick) Expanded(child: pbtn('Pilih', () => _pick(context, s, ag))),
              if (canPick) const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Tolak agen',
                onPressed: () async {
                  if (await confirm(context, 'Tolak ${ag.short}?', 'Slot ACC dibuka kembali untuk agen lain.', ok: 'Tolak')) s.declineAcc(r, a);
                },
                icon: const Icon(Icons.close),
              ),
            ]),
        ]),
      ),
    );
  }

  void _openChat(BuildContext c, AppStore s, Agent ag) {
    final ch = s.chatFor(type: 'order', refId: r.id, otherId: ag.id, otherName: ag.short, otherAgent: true, title: r.title);
    Navigator.push(c, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
  }

  Future<void> _pick(BuildContext c, AppStore s, Agent ag) => pickAgent(c, s, r, a);
}

/// Memilih agen yang ACC pada request 1 agen (dipakai di daftar ACC dan di dalam chat).
/// Request banyak agen memakai halaman GroupOrderPage (tombol Mulai order).
Future<void> pickAgent(BuildContext c, AppStore s, Req r, Acc a) async {
  if (r.workers > 1) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => GroupOrderPage(r.id)));
    return;
  }
  final ag = s.agentById(a.agentId);
  final amt = totalOf(r.ptype, a.price, r.dur);
  final ok = await confirm(
      c, 'Pilih ${ag.short}?',
      'Harga final: ${rp(amt)}${r.ptype != 'lump' ? ' (${rp(a.price)}${unitOf(r.ptype)})' : ''}\nBiaya platform: ${rp(feeOf(amt))}\n\nAgen harus konfirmasi akhir (maks 15 menit), lalu kamu bayar ke escrow atau pilih COD.',
      ok: 'Pilih agen');
  if (!ok || !c.mounted) return;
  final o = s.selectAgent(r, a);
  if (o == null || !c.mounted) return;
  Navigator.push(c, MaterialPageRoute(builder: (_) => OrderPage(o.id)));
}
