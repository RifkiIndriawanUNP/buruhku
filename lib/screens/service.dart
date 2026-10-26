import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'chat.dart';
import 'location.dart';
import 'shell.dart';

String svcPrice(Svc v) => '${rp(v.price)}${unitOf(v.ptype)}';

// ---------------------------------------------------------------- kartu & baris
class ServiceCard extends StatelessWidget {
  final Svc svc;
  const ServiceCard(this.svc, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(svc.agentId);
    return SizedBox(
      width: 176,
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailPage(svc.id))),
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(catOf(svc.cat).icon, size: 20),
            const Spacer(),
            GestureDetector(
              onTap: () => context.r.toggleFavSvc(svc.id),
              child: Icon(s.favSvc.contains(svc.id) ? Icons.favorite : Icons.favorite_border, size: 20),
            ),
          ]),
          const SizedBox(height: 6),
          Text(svc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          const SizedBox(height: 2),
          Text('${a.short}  |  ${s.ratingOf(a).toStringAsFixed(1)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: g500)),
          const Spacer(),
          Text(svcPrice(svc), style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, color: g500)),
        ]),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final Svc svc;
  const ServiceTile(this.svc, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(svc.agentId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailPage(svc.id))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(catOf(svc.cat).icon, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(svc.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${a.short}  |  ${s.ratingOf(a).toStringAsFixed(1)}  |  ~${a.dist.toStringAsFixed(1)} km${a.online ? '' : '  |  Offline'}', style: const TextStyle(fontSize: 12, color: g500)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [Tag(catOf(svc.cat).name), Tag(ptypes[svc.ptype] ?? '')]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(svcPrice(svc), style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => context.r.toggleFavSvc(svc.id),
              icon: Icon(s.favSvc.contains(svc.id) ? Icons.favorite : Icons.favorite_border),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- daftar tawaran jasa (klien)
class ServiceListPage extends StatefulWidget {
  final String? cat;
  final String title;
  const ServiceListPage({this.cat, required this.title, super.key});
  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  late String? cat = widget.cat;
  String sort = 'jarak';
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = s.svcsNear(cat: cat, sort: sort);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Urutkan',
          onSelected: (v) => setState(() => sort = v),
          itemBuilder: (_) => [
            for (final e in {'jarak': 'Terdekat', 'harga': 'Termurah', 'rating': 'Rating agen'}.entries) CheckedPopupMenuItem(value: e.key, checked: sort == e.key, child: Text(e.value)),
          ],
        ),
      ]),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Semua'), selected: cat == null, onSelected: (_) => setState(() => cat = null))),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(avatar: Icon(c.icon, size: 16), label: Text(c.name), selected: cat == c.id, onSelected: (_) => setState(() => cat = c.id)),
              ),
          ]),
        ),
        Expanded(
          child: l.isEmpty
              ? const Empty(Icons.storefront_outlined, 'Belum ada tawaran jasa untuk pilihan ini. Buat request agar agen yang menghubungimu.')
              : ListView(padding: const EdgeInsets.all(16), children: [for (final v in l) ServiceTile(v)]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- detail tawaran jasa
class ServiceDetailPage extends StatelessWidget {
  final String id;
  const ServiceDetailPage(this.id, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final v = s.svcById(id);
    if (v == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Tawaran jasa tidak ditemukan.'));
    final a = s.agentById(v.agentId);
    final others = s.svcsOfAgent(a.id).where((x) => x.id != v.id).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Tawaran jasa'), actions: [
        IconButton(onPressed: () => s.toggleFavSvc(v.id), icon: Icon(s.favSvc.contains(v.id) ? Icons.favorite : Icons.favorite_border)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Icon(catOf(v.cat).icon, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(v.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [Tag(catOf(v.cat).name), Tag(ptypes[v.ptype] ?? ''), if (v.dur > 0) Tag('Estimasi ${v.dur % 1 == 0 ? v.dur.toInt() : v.dur} ${v.ptype == 'hourly' ? 'jam' : 'hari'}', icon: Icons.schedule)]),
        const SizedBox(height: 14),
        Box(color: g100, child: Row(children: [
          const Expanded(child: Text('Harga dari agen', style: TextStyle(color: g500))),
          Text(svcPrice(v), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ])),
        const Section('Deskripsi'),
        Text(v.desc, style: const TextStyle(height: 1.4)),
        const Section('Cara order'),
        const Warn('Pilih lokasi dan jadwal, harga sudah terisi. Kamu bisa menawar harga. Agen menyetujui, menawar balik, atau menolak, lalu bayar lewat escrow atau COD.', icon: Icons.bolt_outlined),
        const Section('Ditawarkan oleh'),
        AgentTile(a),
        if (others.isNotEmpty) ...[
          const Section('Tawaran lain dari agen ini'),
          for (final x in others) ServiceTile(x),
        ],
        const SizedBox(height: 70),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: full(pbtn('Order jasa ini', () async {
            final cid = await orderServiceSheet(context, v);
            if (cid != null && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(cid)));
          }, icon: Icons.shopping_bag_outlined)),
        ),
      ),
    );
  }
}

/// Order cepat dari tawaran jasa: harga, durasi, dan deskripsi sudah terisi; klien cukup memilih lokasi, jadwal,
/// dan (opsional) menawar harga. Hasilnya masuk ke order langsung (chat langsung dengan kartu penawaran).
/// Mengembalikan id chat jika berhasil.
Future<String?> orderServiceSheet(BuildContext context, Svc svc) {
  final s = context.r;
  final a = s.agentById(svc.agentId);
  final addr = TextEditingController(text: s.address);
  final price = TextEditingController(text: fmtNum(svc.price));
  final dur = TextEditingController(text: svc.dur > 0 ? '${svc.dur}' : (svc.ptype == 'lump' ? '' : '1'));
  var sched = 'now';
  DateTime? when;
  var pin = const Offset(.5, .5);
  final key = GlobalKey<FormState>();
  return sheet<String>(context, (x) => StatefulBuilder(builder: (ctx, set) {
        final p = money(price.text);
        final note = p == svc.price
            ? 'Sesuai harga agen: biasanya langsung disetujui.'
            : (p < svc.price ? 'Kamu menawar ${rp(svc.price - p)} lebih rendah. Agen bisa setuju, menawar balik, atau menolak.' : 'Kamu menawar ${rp(p - svc.price)} lebih tinggi dari harga agen.');
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Order jasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Box(color: g100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(svc.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${a.short}  |  ${catOf(svc.cat).name}', style: const TextStyle(fontSize: 12, color: g500)),
                const SizedBox(height: 4),
                Text(svc.desc, style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 4),
                Text('Harga agen ${svcPrice(svc)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ])),
              const SizedBox(height: 14),
              LocationField(addr: addr, pin: pin, mapH: 110, onPin: (o) => set(() => pin = o)),
              const SizedBox(height: 8),
              const Text('Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Seg(const {'now': 'Sekarang', 'date': 'Tanggal & jam'}, sched, (v) => set(() => sched = v)),
              if (sched == 'date') ...[
                const SizedBox(height: 8),
                obtn(when == null ? 'Pilih tanggal dan jam' : fdt(when!), () async {
                  final d = await pickDateTime(ctx, initial: when);
                  if (d != null) set(() => when = d);
                }, icon: Icons.event),
              ],
              const SizedBox(height: 14),
              if (svc.ptype != 'lump') TF('Durasi (${svc.ptype == 'hourly' ? 'jam' : 'hari'})', dur, type: TextInputType.number, validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Wajib diisi' : null),
              TF('Harga (Rp${unitOf(svc.ptype)}), bisa kamu tawar', price, money: true, onChanged: (_) => set(() {}), validator: (v) => money(v ?? '') < 15000 ? 'Minimal Rp15.000' : null),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(note, style: const TextStyle(fontSize: 12, color: g500))),
              full(pbtn(p == svc.price ? 'Order sekarang' : 'Kirim tawaran', () {
                if (!key.currentState!.validate()) return;
                if (sched == 'date' && (when == null || when!.isBefore(DateTime.now()))) {
                  toast(ctx, 'Pilih tanggal dan jam yang valid.');
                  return;
                }
                final ch = s.chatFor(type: 'direct', refId: '', otherId: a.id, otherName: a.short, otherAgent: true);
                s.sendOrderOffer(ch, {
                  'title': svc.title, 'cat': svc.cat, 'desc': svc.desc, 'address': addr.text.trim(),
                  'sched': sched, 'schedAt': sched == 'date' ? when!.toIso8601String() : null,
                  'when': sched == 'date' ? fdt(when!) : 'Sekarang', 'lat': pin.dx, 'lng': pin.dy,
                  'price': money(price.text), 'ptype': svc.ptype,
                  'dur': svc.ptype == 'lump' ? 0.0 : (double.tryParse(dur.text.replaceAll(',', '.')) ?? 1.0),
                  'svcId': svc.id, 'svcPrice': svc.price,
                });
                Navigator.pop(x, ch.id);
              }, icon: Icons.send_outlined)),
            ]),
          ),
        );
      }));
}

// ---------------------------------------------------------------- favorit (di tab '+')
class FavAgentsView extends StatelessWidget {
  const FavAgentsView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final favs = s.agents.where((a) => s.favs.contains(a.id)).toList();
    if (favs.isEmpty) return const Empty(Icons.favorite_border, 'Ketuk ikon hati di profil agen untuk menyimpan agen favorit.');
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final a in favs)
        Dismissible(
          key: ValueKey('fa${a.id}'), direction: DismissDirection.endToStart,
          background: Container(color: g200, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline)),
          onDismissed: (_) => s.toggleFav(a.id),
          child: AgentTile(a),
        ),
    ]);
  }
}

class FavServicesView extends StatelessWidget {
  const FavServicesView({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final favs = s.favSvc.map(s.svcById).whereType<Svc>().toList();
    if (favs.isEmpty) return const Empty(Icons.favorite_border, 'Ketuk ikon hati di tawaran jasa untuk menyimpannya sebagai jasa favorit.');
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final v in favs)
        Dismissible(
          key: ValueKey('fs${v.id}'), direction: DismissDirection.endToStart,
          background: Container(color: g200, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline)),
          onDismissed: (_) => s.toggleFavSvc(v.id),
          child: ServiceTile(v),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- kelola tawaran jasa (agen)
class MyServicesPage extends StatelessWidget {
  const MyServicesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ok = s.kyc.status == 'approved';
    final l = s.mySvcs;
    return Scaffold(
      appBar: AppBar(title: const Text('Tawaran jasa saya')),
      body: !ok
          ? const Empty(Icons.how_to_reg_outlined, 'Daftar dan verifikasi sebagai agen dulu untuk membuat tawaran jasa.')
          : l.isEmpty
              ? Empty(Icons.storefront_outlined, 'Belum ada tawaran jasa. Buat tawaran dengan harga yang kamu tentukan, klien tinggal memesan.',
                  action: pbtn('Tambah penawaran jasa', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceEditPage())), icon: Icons.add))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  const Warn('Tawaran aktif tampil di Beranda klien sekitar dan bisa langsung dipesan. Pesanan masuk ke Order langsung di Home kamu.', icon: Icons.storefront_outlined),
                  const SizedBox(height: 12),
                  for (final v in l)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Box(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceEditPage(svc: v))),
                        child: Row(children: [
                          Icon(catOf(v.cat).icon, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${svcPrice(v)}  |  ${catOf(v.cat).name}', style: const TextStyle(fontSize: 12, color: g500)),
                              const SizedBox(height: 4),
                              Tag(v.active ? 'Aktif' : 'Nonaktif', filled: v.active),
                            ]),
                          ),
                          Switch(value: v.active, onChanged: (x) {
                            v.active = x;
                            s.updateSvc(v);
                          }),
                          PopupMenuButton<String>(
                            onSelected: (a) async {
                              if (a == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceEditPage(svc: v)));
                              if (a == 'del' && await confirm(context, 'Hapus tawaran?', '"${v.title}" tidak akan tampil lagi untuk klien.', ok: 'Hapus')) s.deleteSvc(v);
                            },
                            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Ubah')), PopupMenuItem(value: 'del', child: Text('Hapus'))],
                          ),
                        ]),
                      ),
                    ),
                ]),
      bottomNavigationBar: ok && l.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: full(pbtn('Tambah penawaran jasa', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceEditPage())), icon: Icons.add)),
              ),
            )
          : null,
    );
  }
}

class ServiceEditPage extends StatefulWidget {
  final Svc? svc;
  const ServiceEditPage({this.svc, super.key});
  @override
  State<ServiceEditPage> createState() => _ServiceEditPageState();
}

class _ServiceEditPageState extends State<ServiceEditPage> {
  final key = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.svc?.title ?? '');
  late final desc = TextEditingController(text: widget.svc?.desc ?? '');
  late final price = TextEditingController(text: widget.svc == null ? '' : fmtNum(widget.svc!.price));
  late final dur = TextEditingController(text: (widget.svc != null && widget.svc!.dur > 0) ? '${widget.svc!.dur}' : '');
  late String cat = widget.svc?.cat ?? (context.r.kyc.cats.isEmpty ? 'other' : context.r.kyc.cats.first);
  late String ptype = widget.svc?.ptype ?? 'lump';
  late bool active = widget.svc?.active ?? true;

  double get d => double.tryParse(dur.text.replaceAll(',', '.')) ?? 0;

  void _apply(Map<String, dynamic> t) {
    title.text = t['t'] as String;
    desc.text = t['d'] as String;
    price.text = fmtNum(t['p'] as int);
    ptype = t['pt'] as String;
    if (ptype != 'lump' && dur.text.isEmpty) dur.text = '2';
  }

  void _save() {
    if (!key.currentState!.validate()) return;
    final s = context.r;
    final m = s.moderate('${title.text} ${desc.text}');
    if (m[0] == 'reject') {
      info(context, 'Tidak diizinkan', m[1]);
      return;
    }
    final p = money(price.text);
    final du = ptype == 'lump' ? 0.0 : d;
    if (catOf(cat).risk > 1 && s.myLevel < 2) {
      toast(context, 'Kategori sensitif butuh SKCK dan level L2.');
      return;
    }
    if (s.myLevel == 1 && totalOf(ptype, p, du) > 500000) {
      toast(context, 'Level L1 dibatasi order maks Rp500.000.');
      return;
    }
    final v = widget.svc;
    if (v == null) {
      s.addSvc(Svc(id: '', agentId: 'me', title: title.text.trim(), cat: cat, desc: desc.text.trim(), ptype: ptype, price: p, dur: du, active: active));
    } else {
      v.title = title.text.trim();
      v.cat = cat;
      v.desc = desc.text.trim();
      v.ptype = ptype;
      v.price = p;
      v.dur = du;
      v.active = active;
      s.updateSvc(v);
    }
    Navigator.pop(context);
    toast(context, 'Tawaran jasa disimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ids = <String>{...s.kyc.cats, cat}.toList();
    final rec = recRange(cat, ptype);
    final sug = catSuggest[cat] ?? templates;
    return Scaffold(
      appBar: AppBar(title: Text(widget.svc == null ? 'Tambah penawaran jasa' : 'Ubah tawaran jasa')),
      body: Form(
        key: key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: cat, decoration: const InputDecoration(labelText: 'Kategori (sesuai keahlianmu)'),
              items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(catOf(id).name))],
              onChanged: (v) => setState(() => cat = v ?? cat),
            ),
          ),
          if (widget.svc == null) ...[
            const Text('Saran tawaran', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final t in sug) Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(t['t'] as String), onPressed: () => setState(() => _apply(t)))),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          TF('Nama jasa', title, maxLen: 80, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
          TF('Deskripsi (apa yang kamu kerjakan)', desc, lines: 4, validator: (v) => (v ?? '').trim().length < 20 ? 'Minimal 20 karakter' : null),
          const Text('Jenis harga', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Seg(ptypes, ptype, (v) => setState(() => ptype = v)),
          const SizedBox(height: 12),
          if (ptype != 'lump') TF('Estimasi durasi (${ptype == 'hourly' ? 'jam' : 'hari'})', dur, type: TextInputType.number, validator: (v) => d <= 0 ? 'Wajib untuk tarif ${ptype == 'hourly' ? 'per jam' : 'harian'}' : null),
          TF('Harga (Rp${unitOf(ptype)})', price, money: true, validator: (v) => money(v ?? '') < 15000 ? 'Minimal Rp15.000' : null),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Rekomendasi wajar: ${rp(rec[0])} sampai ${rp(rec[1])}${unitOf(ptype)}', style: const TextStyle(fontSize: 12.5, color: g700))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Tampilkan ke klien'), subtitle: const Text('Nonaktifkan jika sedang tidak menerima jasa ini'), value: active, onChanged: (v) => setState(() => active = v)),
          const SizedBox(height: 8),
          full(pbtn('Simpan tawaran', _save, icon: Icons.check)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
