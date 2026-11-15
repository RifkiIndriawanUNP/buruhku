import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agents/agent_detail_screen.dart';

/// Kartu agen.
///
/// * Tanpa [wide] (default): susunan vertikal untuk grid atau carousel. Semua teksnya
///   satu baris dan tinggi bagian lain tetap, jadi tingginya bisa dihitung persis lewat
///   [gridExtent] dan tidak pernah overflow.
/// * [wide] true: susunan lebar untuk ListView vertikal atau overlay peta.
/// * [width] diisi: lebar tetap (dipakai di daftar horizontal Beranda).
class AgentCard extends StatelessWidget {
  final Agent a;
  final double? width;
  final bool wide;
  const AgentCard(this.a, {this.width, this.wide = false, super.key});

  static const _pad = 12.0;
  static const _avatar = 52.0;
  static const _btn = 38.0;
  static const _tag = 18.0;
  static const _maxScale = 1.2;
  static const _lh = 1.2; // tinggi baris tetap supaya perhitungan akurat

  /// Tinggi kartu mode vertikal. Pakai sebagai `mainAxisExtent` di GridView.
  static double gridExtent(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _maxScale);
    double t(double fs) => ts.scale(fs) * _lh;
    return _pad * 2 + _avatar + 8 + t(15) + 1 + t(11.5) + 6 + _tag + 10 + t(13) + t(11) + 10 + _btn + 2 /* garis tepi kartu */ + 4 /* pembulatan tinggi teks */;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final fav = s.favs.contains(a.id);
    final rating = s.ratingOf(a);

    final name = Row(children: [
      Flexible(child: Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: _lh, color: g900))),
      if (a.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
    ]);
    final status = Text(a.online ? 'Online' : 'Offline', maxLines: 1, style: const TextStyle(fontSize: 11.5, height: _lh, color: g500));

    final Widget head;
    if (wide) {
      head = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AvatarPh(56, url: a.avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            name,
            status,
            const SizedBox(height: 6),
            Wrap(spacing: 4, runSpacing: 4, children: [for (final id in a.cats.take(3)) CatTag(catOf(id).name, catOf(id).color, fontSize: 9.5, height: _tag)]),
          ]),
        ),
      ]);
    } else {
      head = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AvatarPh(_avatar, url: a.avatarUrl),
        const SizedBox(height: 8),
        name,
        const SizedBox(height: 1),
        status,
        const SizedBox(height: 6),
        // Satu baris, maksimal dua tag. Teks tag dipotong dengan elipsis bila sempit.
        Row(children: [
          for (var i = 0; i < a.cats.length && i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Flexible(child: CatTag(catOf(a.cats[i]).name, catOf(a.cats[i]).color, fontSize: 9, height: _tag)),
          ],
        ]),
      ]);
    }

    final card = MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxScale,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(_pad),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          head,
          const SizedBox(height: 10),
          Row(children: [
            _stat(rating.toStringAsFixed(1), 'Rating', Icons.star),
            _stat('~${a.dist.toStringAsFixed(1)} KM', 'Jarak'),
            _stat('${a.jobs}', 'Order', Icons.person),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: PillBtn(
                a.direct ? 'Order Langsung' : 'Lihat Profil',
                height: _btn,
                onTap: () => a.direct ? startAgentChat(context, a, offer: true) : Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id))),
              ),
            ),
            const SizedBox(width: 6),
            RoundBtn(
              size: _btn,
              onTap: () => context.r.toggleFav(a.id),
              child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 20, color: Colors.red),
            ),
          ]),
        ]),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }

  Widget _stat(String value, String label, [IconData? icon]) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 14, color: kNavy), const SizedBox(width: 4)],
              Text(value, maxLines: 1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: _lh, color: g900)),
            ]),
          ),
          Text(label, maxLines: 1, style: const TextStyle(fontSize: 11, height: _lh, color: g500)),
        ]),
      );
}

/// Dipakai di ListView vertikal (pencarian, favorit, detail jasa): kartu agen mode lebar.
class AgentTile extends StatelessWidget {
  final Agent a;
  const AgentTile(this.a, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: kCardGap), child: AgentCard(a, wide: true));
}