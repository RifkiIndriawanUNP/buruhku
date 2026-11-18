import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/card_parts.dart';
import 'package:buruhku/ui/core/theme.dart';

/// Bar atas TANPA latar: tidak ada warna, kotak, ataupun garis. Isi halaman yang digulir ke belakang bar
/// diburamkan bertahap: paling kabur di tepi atas layar, makin ke bawah makin jernih (lihat [_ProgressiveBlur]).
/// Gradien blur diperpanjang [_blurTail] px ke bawah bar supaya tidak berhenti mendadak di batas bar.
const _blurTail = 28.0;

Widget _glassBar(Widget child) => Stack(clipBehavior: Clip.none, children: [
      const Positioned(left: 0, right: 0, top: 0, bottom: -_blurTail, child: _ProgressiveBlur()),
      child,
    ]);

/// Blur progresif: area bar dibagi pita-pita tipis, tiap pita memburamkan latarnya dengan kekuatan (sigma)
/// berbeda. Satu BackdropFilter dengan ShaderMask tidak bisa dipakai untuk ini (mask tidak berlaku pada
/// hasil blur), jadi pendekatan berpita dipakai tanpa paket tambahan.
///
/// Kekuatan blur mengikuti kurva smoothstep (landai di awal dan di akhir), sehingga tidak ada sambungan
/// yang terlihat. Atur lewat konstanta di bawah:
/// - [_bands]: makin banyak makin halus, tetapi makin berat digambar (turunkan ke 20 bila patah-patah).
/// - [_maxSigma]: kekuatan blur di tepi atas.
class _ProgressiveBlur extends StatelessWidget {
  const _ProgressiveBlur();

  static const _bands = 28;
  static const _maxSigma = 14.0;

  static double _sigma(int i) {
    final t = (i + 0.5) / _bands; // 0 = tepi atas, 1 = ujung bawah
    final ease = t * t * (3 - 2 * t); // smoothstep
    return _maxSigma * (1 - ease);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final bandH = box.maxHeight / _bands;
        return Stack(children: [
          for (var i = 0; i < _bands; i++)
            if (_sigma(i) >= 0.5) // pita yang hampir tak terlihat dilewati agar hemat
              Positioned(
                left: 0,
                right: 0,
                top: i * bandH,
                height: bandH + 1, // tumpang tindih 1 px agar tidak ada celah antar pita
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: _sigma(i), sigmaY: _sigma(i)),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
        ]);
      });
}

/// Putih rata tanpa garis dan bayangan, sama seperti RoundBtn / SoftCard.
BoxDecoration _barBtnDeco(double r) => BoxDecoration(color: cW, borderRadius: BorderRadius.circular(r));

/// Pengganti AppBar: tombol kembali bulat di kiri, judul di tengah, aksi di kanan.
/// Satu aksi = tombol bulat. Dua aksi atau lebih = satu wadah lonjong berisi semua aksi.
class PageBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final bool back;
  const PageBar({this.title, this.actions = const [], this.bottom, this.back = true, super.key});

  static const _h = 72.0;

  @override
  Size get preferredSize => Size.fromHeight(_h + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canBack = back && Navigator.canPop(context);
    final n = actions.length;
    final rightW = n == 0 ? 0.0 : (n == 1 ? 48.0 : 8.0 + 48.0 * n);
    final double sidePad = 20 + math.max<double>(canBack ? 48.0 : 0.0, rightW) + 8;

    Widget right = const SizedBox.shrink();
    if (n == 1) {
      right = Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: _barBtnDeco(24),
        child: IconTheme(data: const IconThemeData(color: g900, size: 24), child: actions.first),
      );
    } else if (n > 1) {
      right = Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _barBtnDeco(24),
        child: IconTheme(data: const IconThemeData(color: g900, size: 24), child: Row(mainAxisSize: MainAxisSize.min, children: actions)),
      );
    }

    return _glassBar(Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: _h,
            child: Stack(children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sidePad),
                  child: Center(
                    child: title == null
                        ? const SizedBox.shrink()
                        : DefaultTextStyle(
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.2, color: g900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            child: title!,
                          ),
                  ),
                ),
              ),
              if (canBack) Positioned(left: 20, top: 12, child: RoundBtn(size: 48, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900))),
              Positioned(right: 20, top: 12, child: right),
            ]),
          ),
          if (bottom != null) bottom!,
        ]),
      ),
    ));
  }
}

/// Pengganti TabBar biasa (tab tetap, tidak bisa digulir) dengan gaya pil.
/// Harus berada di dalam DefaultTabController.
class PillTabBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> labels;
  const PillTabBar(this.labels, {super.key});
  @override
  Size get preferredSize => const Size.fromHeight(PillTabs.height + 14);
  @override
  State<PillTabBar> createState() => _PillTabBarState();
}

class _PillTabBarState extends State<PillTabBar> {
  TabController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: PillTabs(labels: widget.labels, index: _c?.index ?? 0, onChanged: (i) => _c?.animateTo(i)),
      );
}

/// Bar atas bergaya chat: tombol kembali bulat, kapsul putih berisi foto + nama + keterangan
/// (bisa diketuk, misalnya untuk membuka profil), dan tombol aksi bulat di kanan.
class ProfileBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget avatar;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<Widget> actions;
  const ProfileBar({required this.avatar, required this.title, this.subtitle, this.onTap, this.actions = const [], super.key});

  static const _d = 56.0;

  @override
  Size get preferredSize => const Size.fromHeight(_d + 16);

  @override
  Widget build(BuildContext context) {
    final canBack = Navigator.of(context).canPop();
    return _glassBar(Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            if (canBack) ...[
              RoundBtn(size: _d, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Material(
                color: cW,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: SizedBox(
                    height: _d,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
                      child: Row(children: [
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
                            if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.2, color: g500)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            for (final a in actions) ...[
              const SizedBox(width: 8),
              Container(
                width: _d,
                height: _d,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: cW, shape: BoxShape.circle),
                child: IconTheme(data: const IconThemeData(size: 24, color: g900), child: a),
              ),
            ],
          ]),
        ),
      ),
    ));
  }
}

/// Tinggi bar atas (di luar status bar). Dipakai untuk menghitung jarak isi halaman.
const kBarH = 72.0;

/// Padding isi halaman yang digulir di bawah bar kaca: padding baku ditambah status bar dan tinggi bar.
/// [extra] = tinggi tambahan di bawah bar (misalnya tab pil di `PageBar.bottom`).
EdgeInsets underBarPad(BuildContext c, EdgeInsets base, {double extra = 0}) => base.copyWith(top: base.top + MediaQuery.paddingOf(c).top + kBarH + extra);
EdgeInsets pagePad(BuildContext c) => underBarPad(c, kPagePad);
EdgeInsets pageListPad(BuildContext c) => underBarPad(c, kPageListPad);

/// Scaffold untuk halaman ber-[PageBar] atau [ProfileBar]. Isi memanjang sampai ke bawah bar kaca.
///
/// - `underBar: false` (bawaan): isi otomatis diberi jarak atas, jadi tidak tertutup bar.
/// - `underBar: true`: isi (ListView atau peta) dibiarkan memanjang ke belakang bar sehingga bisa digulir
///   di bawah bar yang kabur. ListView-nya wajib memakai `pagePad(context)` atau `pageListPad(context)`.
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool underBar;
  const AppScaffold({
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.underBar = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top + (appBar?.preferredSize.height ?? 0);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: body == null
          ? null
          : underBar
              ? body
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: Padding(padding: EdgeInsets.only(top: inset), child: body),
                ),
    );
  }
}
