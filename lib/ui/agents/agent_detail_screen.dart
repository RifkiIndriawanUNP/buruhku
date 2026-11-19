import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/account/account_screen.dart';
import 'package:buruhku/ui/chat/chat_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

/// Buka chat langsung dengan agen. [offer] true = tampilkan form penawaran order dulu
/// (dipakai tombol "Order langsung" di profil agen dan di kartu agen).
Future<void> startAgentChat(BuildContext context, Agent a, {bool offer = false}) async {
  final s = context.r;
  final ch = s.chatFor(type: 'direct', refId: '', otherId: a.id, otherName: a.short, otherAgent: true);
  if (offer) {
    final ok = await directOfferSheet(context, ch, a);
    if (ok != true || !context.mounted) return;
  }
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
}

class AgentDetail extends StatelessWidget {
  final String id;
  const AgentDetail(this.id, {super.key});

  Future<void> _chat(BuildContext context, Agent a, {bool offer = false}) => startAgentChat(context, a, offer: offer);

  Widget _stat(Widget top, String label) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          top,
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: g500)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(id);
    final revs = s.reviewsOf(a.id);
    final rating = s.ratingOf(a);
    final svcs = s.svcsOfAgent(a.id);
    final lvl = {1: 'L1 Baru', 2: 'L2 Terpercaya', 3: 'L3 Premium'}[a.level]!;
    final svcW = (MediaQuery.sizeOf(context).width * .564).clamp(200.0, 260.0).toDouble();
    const val = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: g900);
    String? svcLabel(Rev r) => r.svcId.isEmpty ? null : s.svcById(r.svcId)?.title;

    return AppScaffold(underBar: true,
      appBar: PageBar(title: const Text('Profil agen'), actions: [
        IconButton(onPressed: () => s.toggleFav(a.id), icon: Icon(s.favs.contains(a.id) ? Icons.favorite : Icons.favorite_border, color: s.favs.contains(a.id) ? Colors.red : g500)),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: a.short, targetId: a.id))), icon: const Icon(Icons.flag_outlined)),
      ]),
      body: ListView(padding: pageListPad(context), children: [
        // Kepala profil: foto, nama, status, lencana, lalu tiga angka utama.
        DetailCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                GestureDetector(onTap: () => showPhotoViewer(context, [a.avatarUrl ?? '']), child: AvatarPh(84, url: a.avatarUrl)),
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(width: 18, height: 18, decoration: BoxDecoration(color: a.online ? kGreen : g400, shape: BoxShape.circle, border: Border.all(color: cW, width: 3))),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: g900))),
                    if (a.verified) ...[const SizedBox(width: 4), const VerifiedBadge(size: 20)],
                  ]),
                  const SizedBox(height: 2),
                  Text(a.online ? 'Online' : 'Offline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: a.online ? kGreen : g500)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 4, runSpacing: 4, children: [
                    Tag(lvl, icon: Icons.shield_outlined),
                    if (a.jobs >= 50 && a.rating >= 4.7) const Tag('Terpercaya', icon: Icons.workspace_premium_outlined),
                    if (a.rating >= 4.5) const Tag('Tepat waktu', icon: Icons.schedule),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                _stat(Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, size: 16, color: kStar), const SizedBox(width: 4), Text(rating.toStringAsFixed(1), style: val)]), '${revs.length} ulasan'),
                _stat(Text('${a.jobs}', style: val), 'Order selesai'),
                _stat(Text('~${a.dist.toStringAsFixed(1)} km', style: val), 'Jarak'),
              ]),
            ),
          ]),
        ),
        DetailCard(
          title: 'Tentang',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.bio, style: const TextStyle(fontSize: 14, height: 1.45, color: g900)),
            const SizedBox(height: 12),
            Kv('Area layanan', 'Sekitar ~${a.dist.toStringAsFixed(0)} km dari lokasimu'),
            Kv('Tarif mulai', '${rp(a.base)} per pekerjaan kecil'),
            const SizedBox(height: 8),
            AppMap(height: 140, center: a.pos, zoom: 14, circleCenter: a.pos, radiusKm: .6, interactive: false),
            const Padding(padding: EdgeInsets.only(top: 4), child: Text('Lokasi perkiraan agen, bukan titik tepat.', style: TextStyle(fontSize: 12, color: g500))),
          ]),
        ),
        DetailCard(
          title: 'Keahlian',
          child: Wrap(spacing: 6, runSpacing: 6, children: [for (final c in a.cats) CatTag(catOf(c).name, catOf(c).color)]),
        ),
        if (svcs.isNotEmpty) ...[
          const DetailHead('Tawaran jasa'),
          HScroll([for (final v in svcs) ServiceCard(v, width: svcW)]),
        ],
        DetailCard(
          title: 'Portofolio',
          child: a.portfolio.isNotEmpty
              ? SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: a.portfolio.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) => GestureDetector(
                      onTap: () => showPhotoViewer(context, a.portfolio, initial: idx),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(a.portfolio[idx], width: 130, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Ph(w: 130, h: 100)),
                      ),
                    ),
                  ),
                )
              : const Text('Belum ada portofolio.', style: TextStyle(color: g500)),
        ),
        // Ulasan agen = gabungan ulasan semua jasanya. Rating di atas = rata-rata rating jasanya.
        DetailCard(
          title: 'Ulasan',
          action: revs.length > 3 ? 'Lihat semua' : null,
          onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewListPage(title: 'Ulasan ${a.short}', rating: rating, revs: revs, svcLabel: svcLabel))),
          child: revs.isEmpty
              ? const Text('Belum ada ulasan.', style: TextStyle(color: g500))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ReviewSummary(rating: rating, revs: revs),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 1, color: kLine)),
                  ReviewList(revs.take(3).toList(), svcLabel: svcLabel),
                ]),
        ),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: cW, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: !a.direct
                ? const Warn('Agen ini tidak menerima chat langsung. Buat request agar agen bisa ACC.', icon: Icons.chat_bubble_outline)
                : Row(children: [
                    GestureDetector(
                      onTap: () => _chat(context, a),
                      child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: cBg, shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline, size: 24, color: g900)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: pbtn('Order langsung', () => _chat(context, a, offer: true), icon: Icons.assignment_outlined)),
                  ]),
          ),
        ),
      ),
    );
  }
}
