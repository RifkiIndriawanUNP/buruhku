import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/reveal.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/utils/formatters.dart';

// Potongan UI yang dipakai bersama oleh kartu jasa dan kartu agen.

const kBlue = Color(0xFF2AABEE); // lencana terverifikasi
const kSeeAll = Color(0xFF4CC585); // teks "Lihat semua"
const kPeach = Color(0xFFFFCCBC); // tag jenis harga

// Jarak baku. Pakai konstanta ini, jangan angka lepas, supaya semua kartu terasa sama rapatnya.
const kGapXs = 4.0; // antar baris teks kecil
const kGapSm = 8.0; // antar elemen dalam satu kartu
const kGapMd = 12.0; // antar blok dalam satu kartu
const kCardGap = 12.0; // antar kartu putih (SoftCard) di daftar vertikal
/// Padding halaman baku: tepi kiri-kanan 16, atas 8, bawah 24. Dipakai semua ListView tingkat halaman.
const kPagePad = EdgeInsets.fromLTRB(16, 8, 16, 24);
/// Untuk halaman yang isinya sudah berupa kartu bermargin 16 (DetailCard, SetCard, SetGroup).
const kPageListPad = EdgeInsets.only(top: 8, bottom: 24);
const kTileGap = 12.0; // antar kartu garis (Box) di daftar vertikal

/// Rupiah dengan spasi: "Rp 63.000".
String rpSp(num n) => rp(n).replaceFirst('Rp', 'Rp ');

/// Foto jasa sementara (placeholder abu-abu) atau foto online jika url tersedia.
class PhotoPlaceholder extends StatelessWidget {
  final double height;
  final double radius;
  final String? url;
  const PhotoPlaceholder({required this.height, this.radius = 14, this.url, super.key});
  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _loading(),
        ),
      );
    }
    return _fallback();
  }

  Widget _loading() => Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: kPh, borderRadius: BorderRadius.circular(radius)),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: kNavy),
        ),
      );

  Widget _fallback() => Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: kPh, borderRadius: BorderRadius.circular(radius)),
        child: Icon(Icons.image_outlined, color: kPhIcon, size: 32),
      );
}

/// Foto profil sementara (lingkaran) atau avatar online jika url tersedia.
class AvatarPh extends StatelessWidget {
  final double size;
  final String? url;
  const AvatarPh(this.size, {this.url, super.key});
  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: kAvatarBg),
        child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
      );
}

/// Pil kecil untuk kategori / jenis harga. Tinggi tetap, teks satu baris.
class CatTag extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize, height;
  const CatTag(this.text, this.color, {this.fontSize = 10, this.height = 20, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Color.lerp(color, Colors.black, .18)!, width: .8),
          ),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: const Color(0xFF1C1C1C), height: 1.1)),
            ),
          ),
        ),
      );
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({this.size = 16, super.key});
  @override
  Widget build(BuildContext context) => Icon(Icons.verified, size: size, color: kBlue);
}

/// Kartu putih rata (tanpa bayangan dan garis), seperti grup menu Akun; latar abu-abu halaman yang memisahkannya. Dipakai oleh kartu jasa, kartu agen, dan tile kategori.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const SoftCard({required this.child, this.padding = const EdgeInsets.all(12), this.radius = 22, this.onTap, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cW,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      );
}

/// Tombol bulat bergaris (lonceng, hati).
class RoundBtn extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  const RoundBtn({required this.size, required this.child, this.onTap, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: SoftCard(radius: size / 2, padding: EdgeInsets.zero, onTap: onTap, child: Center(child: child)),
      );
}

/// Tombol pil bergaris dengan teks satu baris (mengecil otomatis bila sempit).
class PillBtn extends StatelessWidget {
  final String label;
  final double height;
  final VoidCallback? onTap;
  const PillBtn(this.label, {this.height = 38, this.onTap, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: SoftCard(
          radius: height / 2,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: g900, height: 1.2)),
            ),
          ),
        ),
      );
}

/// Foto profil sementara berupa lingkaran gradasi dengan inisial nama.
class InitialAvatar extends StatelessWidget {
  final String name;
  final double size;
  const InitialAvatar(this.name, {this.size = 52, super.key});

  static const _pal = [
    [Color(0xFFFF9A6B), Color(0xFFE0533C)],
    [Color(0xFFA78BFA), Color(0xFF6F58D8)],
    [Color(0xFF55C8EE), Color(0xFF2E95D6)],
    [Color(0xFF6ED3A4), Color(0xFF2FA46F)],
    [Color(0xFFFFB35C), Color(0xFFEF8A2A)],
  ];

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    var ini = parts.isEmpty ? '?' : parts.first[0];
    if (parts.length > 1) ini += parts.last[0];
    final c = _pal[name.codeUnits.fold<int>(0, (a, b) => a + b) % _pal.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c)),
      child: Text(ini.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: size * .36, height: 1.1)),
    );
  }
}

/// Tab berbentuk pil kecil. Lebar mengikuti isi dan berada di tengah. Kalau tidak muat, tab dibagi rata
/// selebar layar. Penanda pilihan aktif bergeser mulus ke tab yang dipilih.
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PillTabs({required this.labels, required this.index, required this.onChanged, super.key});

  static const height = 40.0, _inset = 3.0, _padX = 16.0;
  static const _style = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2);

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, c) {
      final natural = [
        for (final l in labels)
          (TextPainter(text: TextSpan(text: l, style: _style), textDirection: TextDirection.ltr, textScaler: scaler, maxLines: 1)..layout()).width + _padX * 2,
      ];
      const borderW = 1.0;
      final totalPad = _inset + borderW;
      final avail = c.maxWidth - totalPad * 2;
      final fill = natural.fold<double>(0, (a, b) => a + b) > avail;
      final widths = fill ? List<double>.filled(labels.length, avail / labels.length) : natural;
      final barW = fill ? c.maxWidth : widths.fold<double>(0, (a, b) => a + b) + totalPad * 2;
      final left = widths.take(index).fold<double>(0, (a, b) => a + b);

      return Center(
        child: Container(
          width: barW,
          height: height,
          padding: const EdgeInsets.all(_inset),
          decoration: BoxDecoration(
            color: cW,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: kLine),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: left,
                top: 0,
                bottom: 0,
                width: widths[index],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kGreenBg,
                    borderRadius: BorderRadius.circular((height - totalPad * 2) / 2),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    fill
                        ? Expanded(
                            child: _tabItem(i),
                          )
                        : SizedBox(
                            width: widths[i],
                            child: _tabItem(i),
                          ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tabItem(int i) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: _style.copyWith(color: i == index ? kGreen : g500),
              child: Text(labels[i], maxLines: 1),
            ),
          ),
        ),
      );
}

/// Chip filter: terpilih = hijau penuh, tidak terpilih = putih berbingkai.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FilterPill(this.label, {required this.selected, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kGreen : cW,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? kGreen : kLine2),
          ),
          child: Text(label, maxLines: 1, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, height: 1.2, color: selected ? Colors.white : g900)),
        ),
      );
}

/// Tinggi header bergaya halaman Pesan (judul 28 + baris pil). Dipasang di FloatHeader.height.
/// 124 + kPagePad.top (8) membuat jarak pil -> isi sama persis dengan halaman Pesan (24).
const double kTitleHeaderH = 124;

/// Tinggi header kalau hanya judul (tanpa pil).
const double kTitleOnlyH = 56;

/// Header halaman bergaya Pesan: judul 28 w800 (baris setinggi 52, seperti baris Pesan + tombol cari),
/// lalu baris [FilterPill]. Kalau [labels] diisi, widget ini harus berada di dalam DefaultTabController:
/// pil mengikuti dan menggerakkan tab-nya.
class PageTitleHeader extends StatefulWidget {
  final String title;
  final List<String>? labels;
  final Widget? trailing;
  const PageTitleHeader(this.title, {this.labels, this.trailing, super.key});
  @override
  State<PageTitleHeader> createState() => _PageTitleHeaderState();
}

class _PageTitleHeaderState extends State<PageTitleHeader> {
  TabController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.labels == null) return;
    final c = DefaultTabController.of(context);
    if (c != _c) {
      _c?.removeListener(_tick);
      _c = c..addListener(_tick);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: SizedBox(
            height: 52,
            child: Row(children: [
              Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
              if (widget.trailing != null) widget.trailing!,
            ]),
          ),
        ),
        if (labels != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                for (var i = 0; i < labels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  FilterPill(labels[i], selected: (_c?.index ?? 0) == i, onTap: () => _c?.animateTo(i)),
                ],
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}


/// Kartu putih bergaya pengaturan Telegram. Isinya adalah beberapa [SetRow].
class SetGroup extends StatelessWidget with SelfReveal {
  final List<Widget> children;
  const SetGroup(this.children, {super.key});

  @override
  int get revealCount => children.length;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(22)),
        child: Column(children: revealRows(children)),
      );
}

/// Satu baris pengaturan: kotak ikon berwarna, judul, subjudul abu-abu, dan widget di kanan (opsional).
class SetRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? sub;
  final Widget? badge;
  final Color? titleColor;
  final VoidCallback? onTap;
  const SetRow(this.icon, this.color, this.title, this.onTap, {this.sub, this.badge, this.titleColor, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, height: 1.25, color: titleColor ?? g900)),
                if (sub != null) Text(sub!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, height: 1.3, color: kSubGray)),
              ]),
            ),
            if (badge != null) ...[const SizedBox(width: 8), badge!],
          ]),
        ),
      );
}

/// Kartu putih untuk isi bebas (formulir, teks) dengan tepi dan jarak sama seperti [SetGroup].
class SetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SetCard({required this.child, this.padding = const EdgeInsets.all(16), super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: padding,
        decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(22)),
        child: child,
      );
}

/// Judul kecil di atas grup, dengan tautan aksi di kanan (opsional).
class SetHead extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const SetHead(this.text, {this.action, this.onAction, super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 24, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen))),
          if (action != null)
            GestureDetector(behavior: HitTestBehavior.opaque, onTap: onAction, child: Text(action!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g900))),
        ]),
      );
}

/// Judul kecil di atas grup pengaturan.
class SetTitle extends StatelessWidget {
  final String text;
  const SetTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen)),
      );
}