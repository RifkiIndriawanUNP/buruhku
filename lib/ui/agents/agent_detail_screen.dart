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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(id);
    final revs = s.reviewsOf(a.id);
    final lvl = {1: 'L1 Baru', 2: 'L2 Terpercaya', 3: 'L3 Premium'}[a.level]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil agen'), actions: [
        IconButton(onPressed: () => s.toggleFav(a.id), icon: Icon(s.favs.contains(a.id) ? Icons.favorite : Icons.favorite_border)),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: a.short, targetId: a.id))), icon: const Icon(Icons.flag_outlined)),
      ]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, kBarSpace), children: [
        Row(children: [
          const Avatar(size: 76),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.short, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [Stars(s.ratingOf(a), size: 16), Text('  ${s.ratingOf(a).toStringAsFixed(1)}')]),
            Text('${a.jobs} pekerjaan selesai  |  ~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(color: g500, fontSize: 12.5)),
          ])),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (a.verified) const Tag('Terverifikasi', icon: Icons.verified_outlined, filled: true),
          Tag(lvl, icon: Icons.shield_outlined),
          if (a.jobs >= 50 && a.rating >= 4.7) const Tag('Terpercaya', icon: Icons.workspace_premium_outlined),
          if (a.rating >= 4.5) const Tag('Tepat waktu', icon: Icons.schedule),
          Tag(a.online ? 'Online' : 'Offline', icon: Icons.circle_outlined),
        ]),
        const Section('Tentang'),
        Text(a.bio, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 8),
        Kv('Area layanan', 'Sekitar ~${a.dist.toStringAsFixed(0)} km dari lokasimu'),
        const SizedBox(height: 8),
        AppMap(height: 150, center: a.pos, zoom: 14, circleCenter: a.pos, radiusKm: .6, interactive: false),
        const Padding(padding: EdgeInsets.only(top: 4), child: Text('Lokasi perkiraan agen, bukan titik tepat.', style: TextStyle(fontSize: 11.5, color: g500))),
        Kv('Tarif mulai', '${rp(a.base)} per pekerjaan kecil'),
        const Section('Keahlian'),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final c in a.cats) Tag(catOf(c).name, icon: catOf(c).icon)]),
        if (s.svcsOfAgent(a.id).isNotEmpty) ...[
          const Section('Tawaran jasa'),
          for (final v in s.svcsOfAgent(a.id)) ServiceTile(v),
        ],
        const Section('Portofolio'),
        const Row(children: [Expanded(child: Ph(h: 80)), SizedBox(width: 8), Expanded(child: Ph(h: 80)), SizedBox(width: 8), Expanded(child: Ph(h: 80))]),
        Section('Ulasan (${revs.length})'),
        if (revs.isEmpty) const Text('Belum ada ulasan.', style: TextStyle(color: g500)),
        for (final v in revs.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(v.from, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Stars(v.rating.toDouble(), size: 13)]),
              if (v.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: [for (final t in v.tags) Tag(t)])),
              const SizedBox(height: 4),
              Text(v.comment),
              Text(ago(v.at), style: const TextStyle(fontSize: 11, color: g500)),
            ])),
          ),
        const SizedBox(height: 70),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: !a.direct
              ? const Warn('Agen ini tidak menerima chat langsung. Buat request agar agen bisa ACC.', icon: Icons.chat_bubble_outline)
              : Row(children: [
                  Expanded(child: obtn('Chat langsung', () => _chat(context, a), icon: Icons.chat_bubble_outline)),
                  const SizedBox(width: 10),
                  Expanded(child: pbtn('Order langsung', () => _chat(context, a, offer: true), icon: Icons.assignment_outlined)),
                ]),
        ),
      ),
    );
  }
}
