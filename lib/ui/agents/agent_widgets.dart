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
  static const _avatar = 52.0; // dipakai mode lebar
  static const _avatarSq = 56.0; // mode kotak
  static const _btn = 38.0; // tombol mode lebar
  static const _buy = 42.0; // tombol mode kotak
  static const _tag = 18.0;
  static const _maxScale = 1.2;
  static const _lh = 1.2; // tinggi baris tetap supaya perhitungan akurat

  /// Tinggi kartu mode kotak. Pakai sebagai `mainAxisExtent` di GridView.
  /// Urutan isi: foto+hati, nama, status, tag, kotak statistik (angka lalu label), tombol.
  static double gridExtent(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: _maxScale);
    double t(double fs) => ts.scale(fs) * _lh;
    return _pad * 2 + _avatarSq + 8 + t(15) + 2 + t(12) + 6 + _tag + 8 + (16 + t(13) + t(11)) + 10 + _buy + 8 /* cadangan pembulatan */;
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

    if (wide) return _wide(context, name, fav, rating);

    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id)));
    final card = MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxScale,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(_pad),
        onTap: open,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Foto bulat dengan titik status, hati polos di kanan atas.
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              AvatarPh(_avatarSq, url: a.avatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(width: 14, height: 14, decoration: BoxDecoration(color: a.online ? kGreen : g400, shape: BoxShape.circle, border: Border.all(color: cW, width: 2))),
              ),
            ]),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.r.toggleFav(a.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 24, color: fav ? Colors.red : g500),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          name,
          const SizedBox(height: 2),
          Text(
            a.online ? 'Online' : 'Offline',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: _lh, color: a.online ? kGreen : g500),
          ),
          const SizedBox(height: 6),
          // Satu baris, maksimal dua tag. Teks tag dipotong dengan elipsis bila sempit.
          Row(children: [
            for (var i = 0; i < a.cats.length && i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Flexible(child: CatTag(catOf(a.cats[i]).name, catOf(a.cats[i]).color, fontSize: 9, height: _tag)),
            ],
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              _stat(rating.toStringAsFixed(1), 'Rating', Icons.star),
              _stat('~${a.dist.toStringAsFixed(1)} KM', 'Jarak'),
              _stat('${a.jobs}', 'Order'),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, _buy), padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () => a.direct ? startAgentChat(context, a, offer: true) : open(),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(a.direct ? 'Order Langsung' : 'Lihat Profil', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800))),
            ),
          ),
        ]),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }

  /// Mode lebar: padat dan minimalis. Foto + nama + satu baris info + tag, tombol aksi satu baris di bawah.
  /// Status online ditandai titik di foto, jadi tidak butuh baris teks sendiri.
  Widget _wide(BuildContext context, Widget name, bool fav, double rating) {
    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id)));
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxScale,
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(_pad),
        onTap: open,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              AvatarPh(_avatar, url: a.avatarUrl),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(width: 13, height: 13, decoration: BoxDecoration(color: a.online ? kGreen : g400, shape: BoxShape.circle, border: Border.all(color: cW, width: 2))),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                name,
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: kNavy),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${rating.toStringAsFixed(1)}  \u00b7  ~${a.dist.toStringAsFixed(1)} km  \u00b7  ${a.jobs} order',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, height: _lh, color: g700),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: [for (final id in a.cats.take(3)) CatTag(catOf(id).name, catOf(id).color, fontSize: 9.5, height: _tag)]),
              ]),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.r.toggleFav(a.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Icon(fav ? Icons.favorite : Icons.favorite_border, size: 22, color: Colors.red),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Abu-abu muda supaya tombol terlihat di atas kartu putih yang rata.
          Material(
            color: cBg,
            borderRadius: BorderRadius.circular(_btn / 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(_btn / 2),
              onTap: () => a.direct ? startAgentChat(context, a, offer: true) : open(),
              child: SizedBox(
                height: _btn,
                width: double.infinity,
                child: Center(child: Text(a.direct ? 'Order Langsung' : 'Lihat Profil', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: g900))),
              ),
            ),
          ),
        ]),
      ),
    );
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