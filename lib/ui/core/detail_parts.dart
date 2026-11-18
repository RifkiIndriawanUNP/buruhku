import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/utils/formatters.dart';
import 'package:buruhku/ui/core/card_parts.dart';
import 'package:buruhku/ui/core/page_bar.dart';
import 'package:buruhku/ui/core/photo_viewer.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/ui/core/widgets.dart';

/// Bagian-bagian bersama untuk halaman detail ala e-commerce (detail jasa dan detail agen).

/// Kartu putih rata dengan judul dan tautan opsional. Jarak antar kartu 12.
class DetailCard extends StatelessWidget {
  final String? title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DetailCard({this.title, this.action, this.onAction, required this.child, this.padding = const EdgeInsets.all(16), super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: SoftCard(
            padding: padding,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) ...[
                DetailHead(title!, action: action, onAction: onAction, padded: false),
                const SizedBox(height: 10),
              ],
              child,
            ]),
          ),
        ),
      );
}

/// Judul bagian dengan tautan "Lihat semua" di kanan.
class DetailHead extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final bool padded;
  const DetailHead(this.title, {this.action, this.onAction, this.padded = true, super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padded ? const EdgeInsets.fromLTRB(16, 4, 16, 8) : EdgeInsets.zero,
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: g900))),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(action!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kGreen))),
            ),
        ]),
      );
}

/// Daftar horizontal dengan tinggi seragam (dipakai untuk kartu mode carousel).
class HScroll extends StatelessWidget {
  final List<Widget> children;
  const HScroll(this.children, {super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
          ]),
        ),
      );
}

/// Foto utama yang bisa digeser (beberapa slide) dengan penanda posisi di kanan bawah.
class PhotoSlider extends StatefulWidget {
  final List<String> urls;
  final double height;
  final IconData emptyIcon;
  const PhotoSlider({required this.urls, required this.height, this.emptyIcon = Icons.image_outlined, super.key});
  @override
  State<PhotoSlider> createState() => _PhotoSliderState();
}

class _PhotoSliderState extends State<PhotoSlider> {
  final _c = PageController();
  int _i = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ph() => Container(color: kPh, child: Center(child: Icon(widget.emptyIcon, color: kPhIcon, size: 56)));

  @override
  Widget build(BuildContext context) {
    final n = widget.urls.length;
    return SizedBox(
      height: widget.height,
      child: Stack(children: [
        Positioned.fill(
          child: n == 0
              ? _ph()
              : PageView.builder(
                  controller: _c,
                  itemCount: n,
                  onPageChanged: (i) => setState(() => _i = i),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => showPhotoViewer(context, widget.urls, initial: i),
                    child: Image.network(widget.urls[i], fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph()),
                  ),
                ),
        ),
        if (n > 1)
          Positioned(
            right: 14,
            bottom: 26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(12)),
              child: Text('${_i + 1}/$n', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        if (n > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < n; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(color: i == _i ? Colors.white : const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(3)),
                ),
            ]),
          ),
      ]),
    );
  }
}

/// Ringkasan rating: angka besar, bintang, jumlah ulasan, dan sebaran per bintang.
class ReviewSummary extends StatelessWidget {
  final double rating;
  final List<Rev> revs;
  const ReviewSummary({required this.rating, required this.revs, super.key});

  @override
  Widget build(BuildContext context) {
    final total = revs.length;
    int count(int star) => revs.where((r) => r.rating == star).length;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, color: g900)),
        const SizedBox(height: 2),
        Stars(rating, size: 14),
        const SizedBox(height: 4),
        Text('$total ulasan', style: const TextStyle(fontSize: 12, color: g500)),
      ]),
      const SizedBox(width: 18),
      Expanded(
        child: Column(children: [
          for (var star = 5; star >= 1; star--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(width: 10, child: Text('$star', style: const TextStyle(fontSize: 11, color: g700))),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: total == 0 ? 0 : count(star) / total, minHeight: 6, backgroundColor: cBg, color: const Color(0xFFFFB400)),
                  ),
                ),
                SizedBox(width: 22, child: Text('${count(star)}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 11, color: g500))),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

/// Satu ulasan. [svcLabel] diisi kalau ingin menampilkan jasa yang diulas (dipakai di ulasan agen).
class ReviewTile extends StatelessWidget {
  final Rev r;
  final String? svcLabel;
  const ReviewTile(this.r, {this.svcLabel, super.key});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(size: 36, imageUrl: r.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.from, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: g900)),
              Text(ago(r.at), style: const TextStyle(fontSize: 11.5, color: g500)),
            ]),
          ),
          Stars(r.rating.toDouble(), size: 13),
        ]),
        if (svcLabel != null) ...[
          const SizedBox(height: 6),
          Text('Jasa: $svcLabel', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: g500)),
        ],
        const SizedBox(height: 6),
        Text(r.comment, style: const TextStyle(fontSize: 14, height: 1.35, color: g900)),
        if (r.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 4, runSpacing: 4, children: [for (final t in r.tags) Tag(t)])),
        if (r.photoUrl != null && r.photoUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => showPhotoViewer(context, [r.photoUrl!]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(r.photoUrl!, height: 84, width: 124, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        ],
      ]);
}

/// Daftar ulasan yang dipisah garis tipis.
class ReviewList extends StatelessWidget {
  final List<Rev> revs;
  final String? Function(Rev)? svcLabel;
  const ReviewList(this.revs, {this.svcLabel, super.key});

  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < revs.length; i++) ...[
          if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 1, color: kLine)),
          ReviewTile(revs[i], svcLabel: svcLabel?.call(revs[i])),
        ],
      ]);
}

/// Halaman semua ulasan.
class ReviewListPage extends StatelessWidget {
  final String title;
  final double rating;
  final List<Rev> revs;
  final String? Function(Rev)? svcLabel;
  const ReviewListPage({required this.title, required this.rating, required this.revs, this.svcLabel, super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(underBar: true,
        appBar: PageBar(title: Text(title)),
        body: ListView(padding: pageListPad(context), children: [
          DetailCard(child: ReviewSummary(rating: rating, revs: revs)),
          DetailCard(child: revs.isEmpty ? const Text('Belum ada ulasan.', style: TextStyle(color: g500)) : ReviewList(revs, svcLabel: svcLabel)),
        ]),
      );
}
