import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/card_parts.dart';
import 'package:buruhku/ui/core/theme.dart';

/// Bar atas TANPA latar kotak: isi halaman yang digulir ke belakang bar diburamkan bertahap:
/// paling kabur di tepi atas layar, makin ke bawah makin jernih (lihat [_ProgressiveBlur]).
const _blurTail = 24.0;

Widget _glassBar(Widget child) => Stack(clipBehavior: Clip.none, children: [
      const Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: -_blurTail,
        child: RepaintBoundary(child: _ProgressiveBlur()),
      ),
      child,
    ]);

/// Blur progresif teroptimasi (4 lapis bertingkat + scrim gradien halus):
/// Menggantikan 28 BackdropFilter yang memicu 25+ GPU render pass per frame scroll.
/// Dengan 4 lapis + gradien transparan di atasnya, visual tetap mulus tanpa lag di 60/120fps.
class _ProgressiveBlur extends StatelessWidget {
  const _ProgressiveBlur();

  // Pita bertingkat: [topFraction, heightFraction, sigma]
  static const _layers = [
    (0.00, 0.38, 12.0), // Area status bar & atas: paling kabur
    (0.35, 0.25, 7.5),  // Tengah atas
    (0.57, 0.23, 3.8),  // Tengah bawah
    (0.77, 0.23, 1.4),  // Ekor bawah: transisi jernih
  ];

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight;
      if (h <= 0) return const SizedBox.shrink();
      return IgnorePointer(
        child: Stack(
          children: [
            for (final (topF, heightF, sigma) in _layers)
              Positioned(
                left: 0,
                right: 0,
                top: h * topF,
                height: (h * heightF) + 1.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: sigma,
                      sigmaY: sigma,
                      tileMode: TileMode.clamp,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            // Gradien tipis menyatu dengan warna scaffold untuk menyamarkan batas antar pita blur
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.45, 0.8, 1.0],
                    colors: [
                      bg.withValues(alpha: 0.55),
                      bg.withValues(alpha: 0.22),
                      bg.withValues(alpha: 0.05),
                      bg.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Putih dengan garis dan bayangan lembut, serasi dengan RoundBtn, SoftCard, dan BottomBar.
BoxDecoration _barBtnDeco(double r) => BoxDecoration(
      color: cW,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: kLine),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))],
    );

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
        child: IconTheme(data: IconThemeData(color: g900, size: 24), child: actions.first),
      );
    } else if (n > 1) {
      right = Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: _barBtnDeco(24),
        child: IconTheme(data: IconThemeData(color: g900, size: 24), child: Row(mainAxisSize: MainAxisSize.min, children: actions)),
      );
    }

    final topBar = SizedBox(
      height: _h,
      child: Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: sidePad),
            child: Center(
              child: title == null
                  ? const SizedBox.shrink()
                  : DefaultTextStyle(
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: g900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      child: title!,
                    ),
            ),
          ),
        ),
        if (canBack) Positioned(left: 20, top: 12, child: RoundBtn(size: 48, onTap: () => Navigator.maybePop(context), child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900))),
        Positioned(right: 20, top: 12, child: right),
      ]),
    );

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _glassBar(SafeArea(bottom: false, child: topBar)),
          if (bottom != null) bottom!,
        ],
      ),
    );
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
              RoundBtn(size: _d, onTap: () => Navigator.maybePop(context), child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_d / 2),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Material(
                  color: cW,
                  shape: StadiumBorder(side: BorderSide(color: kLine)),
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
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
                              if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.2, color: g500)),
                            ]),
                          ),
                        ]),
                      ),
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
                decoration: BoxDecoration(
                  color: cW,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(BorderSide(color: kLine)),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: IconTheme(data: IconThemeData(size: 24, color: g900), child: a),
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
class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool underBar;
  final bool extendBody;
  const AppScaffold({
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.underBar = false,
    this.extendBody = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top + (appBar?.preferredSize.height ?? 0);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: extendBody,
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

/// Isi tambahan di bawah judul PageBar (chip, filter, dan sejenisnya).
class BarBottom extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget child;
  const BarBottom({required this.height, required this.child, super.key});
  @override
  Size get preferredSize => Size.fromHeight(height);
  @override
  Widget build(BuildContext context) => SizedBox(height: height, child: child);
}

/// Tab pil biasa (tanpa TabController) untuk slot `PageBar.bottom`.
class PillTabsBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PillTabsBar({required this.labels, required this.index, required this.onChanged, super.key});
  static const double height = PillTabs.height + 14;
  @override
  Size get preferredSize => const Size.fromHeight(height);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: PillTabs(labels: labels, index: index, onChanged: onChanged),
      );
}

/// Jarak atas tambahan untuk isi di bawah [FloatHeader]. Dibaca lewat [insetPad].
class HeaderInset extends InheritedWidget {
  final double top;
  const HeaderInset({required this.top, required super.child, super.key});
  static double of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<HeaderInset>()?.top ?? 0;
  @override
  bool updateShouldNotify(HeaderInset old) => top != old.top;
}

/// Sama seperti [insetPad] tetapi memakai nilai [inset] yang diberikan [FloatHeader.builder].
EdgeInsets padBelow(double inset, [EdgeInsets base = kPagePad]) => base.copyWith(top: base.top + inset);

/// Padding isi halaman tab yang berada di bawah [FloatHeader].
EdgeInsets insetPad(BuildContext c, [EdgeInsets base = kPagePad]) => base.copyWith(top: base.top + HeaderInset.of(c));

/// Halaman tab dengan header melayang: isi memanjang sampai ke atas layar, header (judul, tab pil, chip)
/// berada di atasnya tanpa latar dengan blur bertahap, sama seperti [PageBar].
class FloatHeader extends StatelessWidget {
  final Widget header;
  final double height;
  final Widget Function(double inset) builder;
  const FloatHeader({required this.header, required this.height, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final inset = top + height;
    return Stack(children: [
      Positioned.fill(child: HeaderInset(top: inset, child: builder(inset))),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: _glassBar(Material(
          type: MaterialType.transparency,
          child: Padding(padding: EdgeInsets.only(top: top), child: SizedBox(height: height, child: header)),
        )),
      ),
    ]);
  }
}