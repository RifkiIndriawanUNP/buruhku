import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/utils/geo.dart';
import 'package:buruhku/ui/agents/agent_detail_screen.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/chat/chat_screen.dart';
import 'package:buruhku/ui/location/location_screen.dart';

String svcPrice(Svc v) => '${rp(v.price)}${unitOf(v.ptype)}';

// ---------------------------------------------------------------- kartu & baris
/// Kartu tawaran jasa.
/// [width] diisi = mode carousel (dipakai di daftar horizontal Beranda; induknya harus
/// membungkus dengan IntrinsicHeight + stretch supaya tinggi kartu seragam).
/// [width] kosong = mengisi lebar induk, dipakai di ListView vertikal.
class ServiceCard extends StatelessWidget {
  final Svc svc;
  final double? width;
  const ServiceCard(this.svc, {this.width, super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(svc.agentId);
    final c = catOf(svc.cat);
    final fav = s.favSvc.contains(svc.id);
    final unit = unitOf(svc.ptype);
    if (width == null) return _wide(context, s, a, c, fav, unit);
    return _square(context, s, a, c, fav, unit);
  }

  /// Mode kotak (carousel): foto di atas, tag, judul, penjual, rating, lalu tarif dan tombol Order satu baris.
  Widget _square(BuildContext context, AppState s, Agent a, Cat c, bool fav, String unit) {
    final w = width!;
    final photoH = ((w - 20) * .56).clamp(90.0, 150.0).toDouble();
    final n = s.reviewsOfSvc(svc.id).length;
    final rating = s.ratingOfSvc(svc);
    final eta = (5 + a.dist * 4).round();
    void detail() => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailPage(svc.id)));
    Future<void> order() async {
      final cid = await orderServiceSheet(context, svc);
      if (cid != null && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(cid)));
    }

    return SizedBox(
      width: w,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(10),
          onTap: detail,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              PhotoPlaceholder(height: photoH, radius: 16, url: svc.imageUrl),
              if (a.online) Positioned(top: 8, left: 8, child: _EtaChip('Kilat ~$eta mnt')),
              Positioned(
                top: 6,
                right: 6,
                child: RoundBtn(
                  size: 32,
                  onTap: () => context.r.toggleFavSvc(svc.id),
                  child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 18, color: fav ? Colors.red : g500),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 4, runSpacing: 4, children: [CatTag(c.name, c.color), CatTag(ptypes[svc.ptype] ?? '', kPeach)]),
            const SizedBox(height: 8),
            Text(svc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
            const SizedBox(height: 8),
            Row(children: [
              AvatarPh(24, url: a.avatarUrl),
              const SizedBox(width: 6),
              Flexible(child: Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g900))),
              if (a.verified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 15)],
              if (!a.online) ...[const SizedBox(width: 6), const Text('Offline', style: TextStyle(fontSize: 10, color: g500))],
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, size: 14, color: kStar),
              const SizedBox(width: 3),
              Text(n == 0 ? 'Baru' : '${rating.toStringAsFixed(1)} ($n)', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: g900)),
              const Spacer(),
              Flexible(child: Text('\u2022 ~${a.dist.toStringAsFixed(1)} km', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: g500))),
            ]),
            const Spacer(),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: kLine),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tarif mulai', style: TextStyle(fontSize: 11, color: g500)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(TextSpan(
                      text: rpSp(svc.price),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: g900),
                      children: [if (unit.isNotEmpty) TextSpan(text: unit, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: g500))],
                    )),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              _OrderChip(onTap: order),
            ]),
          ]),
        ),
      ),
    );
  }

  /// Mode memanjang: foto kecil di kiri, info rapat di kanan. Tinggi mengikuti isi, tanpa ruang kosong.
  Widget _wide(BuildContext context, AppState s, Agent a, Cat c, bool fav, String unit) {
    Widget ph() => Container(color: kPh, child: const Center(child: Icon(Icons.image_outlined, color: kPhIcon, size: 28)));
    final url = svc.imageUrl;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(10),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailPage(svc.id))),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: 108,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                // Hanya anak Positioned, jadi foto mengikuti tinggi kolom teks (tidak memaksa baris lebih tinggi).
                child: Stack(children: [
                  Positioned.fill(child: (url != null && url.isNotEmpty) ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => ph()) : ph()),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: RoundBtn(
                      size: 28,
                      onTap: () => context.r.toggleFavSvc(svc.id),
                      child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 16, color: fav ? Colors.red : g500),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(svc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: [CatTag(c.name, c.color), CatTag(ptypes[svc.ptype] ?? '', kPeach)]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Row(children: [
                      AvatarPh(20, url: a.avatarUrl),
                      const SizedBox(width: 6),
                      Flexible(child: Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g900))),
                      if (a.verified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 14)],
                      if (!a.online) ...[const SizedBox(width: 6), const Text('Offline', style: TextStyle(fontSize: 10, color: g500))],
                    ]),
                  ),
                  const Icon(Icons.star, size: 13, color: kStar),
                  const SizedBox(width: 3),
                  Text(s.ratingOfSvc(svc) > 0 ? s.ratingOfSvc(svc).toStringAsFixed(1) : 'Baru', style: const TextStyle(fontSize: 12, color: g700)),
                ]),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(TextSpan(
                        text: rpSp(svc.price),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: g900),
                        children: [if (unit.isNotEmpty) TextSpan(text: unit, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: g500))],
                      )),
                    ),
                  ),
                  Text('~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11.5, color: g500)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Lencana estimasi waktu di atas foto kartu jasa.
class _EtaChip extends StatelessWidget {
  final String text;
  const _EtaChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.bolt, size: 13, color: Color(0xFFF5A12B)),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: g900)),
        ]),
      );
}

/// Tombol "Order" di baris tarif kartu jasa. Sama dengan tombol di kartu agen: hijau penuh.
class _OrderChip extends StatelessWidget {
  final VoidCallback onTap;
  const _OrderChip({required this.onTap});
  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 18)),
        onPressed: onTap,
        child: const Text('Order', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
      );
}

/// Dipakai di semua ListView vertikal (daftar jasa, pencarian, favorit, profil agen).
class ServiceTile extends StatelessWidget {
  final Svc svc;
  const ServiceTile(this.svc, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: kCardGap), child: ServiceCard(svc));
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => [
              for (final e in {'jarak': 'Terdekat', 'harga': 'Termurah', 'rating': 'Rating agen'}.entries) CheckedPopupMenuItem(value: e.key, checked: sort == e.key, child: Text(e.value)),
            ],
          ),
        ],
        bottom: BarBottom(
          height: 52,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), children: [
            Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('Semua'), selected: cat == null, onSelected: (_) => setState(() => cat = null))),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(avatar: CatIcon(c, size: 22), label: Text(c.name), selected: cat == c.id, onSelected: (_) => setState(() => cat = c.id)),
              ),
          ]),
        ),
      ),
      body: l.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 52),
              child: const Empty(Icons.storefront_outlined, 'Belum ada tawaran jasa untuk pilihan ini. Buat request agar agen yang menghubungimu.'),
            )
          : ListView(padding: underBarPad(context, kPagePad, extra: 52), children: [for (final v in l) ServiceTile(v)]),
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
    if (v == null) return AppScaffold(appBar: PageBar(), body: const Empty(Icons.error_outline, 'Tawaran jasa tidak ditemukan.'));
    final a = s.agentById(v.agentId);
    final c = catOf(v.cat);
    final revs = s.reviewsOfSvc(v.id);
    final rating = s.ratingOfSvc(v);
    final others = s.svcsOfAgent(a.id).where((x) => x.id != v.id).toList();
    final fav = s.favSvc.contains(v.id);
    final unit = unitOf(v.ptype);
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final svcW = (size.width * .564).clamp(200.0, 260.0).toDouble();
    // Semua foto jasa jadi satu slider di bagian atas (foto utama dulu).
    final urls = <String>[
      if (v.imageUrl != null && v.imageUrl!.isNotEmpty) v.imageUrl!,
      ...v.photos.where((p) => p.isNotEmpty && p != v.imageUrl),
    ];
    void openAgent() => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id)));
    Future<void> order() async {
      final cid = await orderServiceSheet(context, v);
      if (cid != null && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(cid)));
    }

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        Stack(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: PhotoSlider(urls: urls, height: (size.width * .85).clamp(260.0, 400.0).toDouble(), emptyIcon: Icons.cleaning_services_outlined),
          ),
          Positioned(
            top: top + 8,
            left: 16,
            child: RoundBtn(size: 44, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: g900)),
          ),
          Positioned(
            top: top + 8,
            right: 16,
            child: RoundBtn(
              size: 44,
              onTap: () => s.toggleFavSvc(v.id),
              child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 22, color: fav ? Colors.red : g500),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Harga, judul, rating
        DetailCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(
              text: rpSp(v.price),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: g900),
              children: [if (unit.isNotEmpty) TextSpan(text: unit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: g500))],
            )),
            const SizedBox(height: 6),
            Text(v.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: g900)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.star, size: 16, color: kStar),
              const SizedBox(width: 4),
              Text(revs.isEmpty ? 'Belum ada ulasan' : '${rating.toStringAsFixed(1)}  (${revs.length} ulasan)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: g900)),
              const Spacer(),
              const Icon(Icons.place_outlined, size: 15, color: g500),
              const SizedBox(width: 2),
              Text('~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 13, color: g500)),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 4, runSpacing: 4, children: [
              CatTag(c.name, c.color),
              CatTag(ptypes[v.ptype] ?? '', kPeach),
              if (v.dur > 0) Tag('Estimasi ${v.dur % 1 == 0 ? v.dur.toInt() : v.dur} ${v.ptype == 'hourly' ? 'jam' : 'hari'}', icon: Icons.schedule),
            ]),
          ]),
        ),
        // Penjual
        DetailCard(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openAgent,
            child: Row(children: [
              AvatarPh(52, url: a.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: g900))),
                    if (a.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                  ]),
                  const SizedBox(height: 2),
                  Text(a.online ? 'Online' : 'Offline', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: a.online ? kGreen : g500)),
                  const SizedBox(height: 2),
                  Text('\u2605 ${s.ratingOf(a).toStringAsFixed(1)}  \u00b7  ${a.jobs} order selesai', style: const TextStyle(fontSize: 12, color: g500)),
                ]),
              ),
              const SizedBox(width: 8),
              Material(
                color: cBg,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: openAgent,
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9), child: Text('Kunjungi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g900))),
                ),
              ),
            ]),
          ),
        ),
        // Detail jasa
        DetailCard(
          title: 'Detail jasa',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kv('Kategori', c.name),
            Kv('Tipe harga', ptypes[v.ptype] ?? ''),
            if (v.dur > 0) Kv('Estimasi', '${v.dur % 1 == 0 ? v.dur.toInt() : v.dur} ${v.ptype == 'hourly' ? 'jam' : 'hari'}'),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, thickness: 1, color: kLine)),
            const Text('Deskripsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g500)),
            const SizedBox(height: 4),
            Text(v.desc, style: const TextStyle(fontSize: 14.5, height: 1.45, color: g900)),
          ]),
        ),
        // Cara order
        DetailCard(
          title: 'Cara order',
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.bolt, size: 20, color: kGreen),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Pilih lokasi dan jadwal, harga sudah terisi. Kamu bisa menawar harga. Agen menyetujui, menawar balik, atau menolak, lalu bayar lewat escrow atau COD.', style: TextStyle(fontSize: 13.5, height: 1.4, color: g700)),
            ),
          ]),
        ),
        // Ulasan khusus jasa ini
        DetailCard(
          title: 'Ulasan jasa',
          action: revs.length > 3 ? 'Lihat semua' : null,
          onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewListPage(title: 'Ulasan jasa', rating: rating, revs: revs))),
          child: revs.isEmpty
              ? const Text('Belum ada ulasan untuk jasa ini.', style: TextStyle(color: g500))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ReviewSummary(rating: rating, revs: revs),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, thickness: 1, color: kLine)),
                  ReviewList(revs.take(3).toList()),
                ]),
        ),
        if (others.isNotEmpty) ...[
          const DetailHead('Tawaran lain dari agen ini'),
          HScroll([for (final x in others) ServiceCard(x, width: svcW)]),
        ],
        const SizedBox(height: 8),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: cW, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              GestureDetector(
                onTap: () => startAgentChat(context, a),
                child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: cBg, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline, size: 22, color: g900)),
              ),
              const SizedBox(width: 12),
              Expanded(child: pbtn('Order jasa ini', order, icon: Icons.shopping_bag_outlined)),
            ]),
          ),
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
  var pin = kMapCenter;
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
                  'when': sched == 'date' ? fdt(when!) : 'Sekarang', 'lat': pin.latitude, 'lng': pin.longitude,
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
    if (favs.isEmpty) return Padding(padding: EdgeInsets.only(top: HeaderInset.of(context)), child: const Empty(Icons.favorite_border, 'Ketuk ikon hati di profil agen untuk menyimpan agen favorit.'));
    return ListView(padding: insetPad(context), children: [
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
    if (favs.isEmpty) return Padding(padding: EdgeInsets.only(top: HeaderInset.of(context)), child: const Empty(Icons.favorite_border, 'Ketuk ikon hati di tawaran jasa untuk menyimpannya sebagai jasa favorit.'));
    return ListView(padding: insetPad(context), children: [
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Tawaran jasa saya')),
      body: !ok
          ? const Empty(Icons.how_to_reg_outlined, 'Daftar dan verifikasi sebagai agen dulu untuk membuat tawaran jasa.')
          : l.isEmpty
              ? Empty(Icons.storefront_outlined, 'Belum ada tawaran jasa. Buat tawaran dengan harga yang kamu tentukan, klien tinggal memesan.',
                  action: pbtn('Tambah penawaran jasa', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceEditPage())), icon: Icons.add))
              : ListView(padding: pagePad(context), children: [
                  const Warn('Tawaran aktif tampil di Beranda klien sekitar dan bisa langsung dipesan. Pesanan masuk ke Order langsung di Home kamu.', icon: Icons.storefront_outlined),
                  const SizedBox(height: 12),
                  for (final v in l)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Box(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceEditPage(svc: v))),
                        child: Row(children: [
                          CatIcon(catOf(v.cat), size: 41),
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: Text(widget.svc == null ? 'Tambah penawaran jasa' : 'Ubah tawaran jasa')),
      body: Form(
        key: key,
        child: ListView(padding: pagePad(context), children: [
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
