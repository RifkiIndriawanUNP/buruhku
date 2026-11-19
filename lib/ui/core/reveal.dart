import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// Animasi masuk PER WIDGET / PER BARIS: tiap baris muncul bergantian dari atas ke bawah,
/// dari kabur (blur) menjadi tajam, memudar masuk, dan naik sedikit.
///
/// Cara pakai (hampir semuanya otomatis):
/// - [RevealListView] pengganti `ListView(children: [...])`: tiap anak muncul bergantian.
/// - [SetGroup] menganimasikan barisnya satu per satu.
/// - Tab di Shell memutar ulang urutan ini setiap tab dibuka ([RevealTab]).
/// - Manual: bungkus widget dengan `RevealItem(index: n, child: ...)`, atau `Reveal(delay: ..., child: ...)`.
///
/// Hanya bagian yang dibangun dalam ~0,9 detik pertama setelah halaman/tab terbuka yang dianimasikan.
/// Baris yang baru muncul karena digulir tidak dianimasikan, jadi scroll tetap ringan.

// ---------------------------------------------------------------------------------------------------
// Reveal: satu animasi masuk untuk satu widget.
// ---------------------------------------------------------------------------------------------------
class Reveal extends StatefulWidget {
  final Widget child;

  /// Tunda sebelum mulai (untuk membuat urutan).
  final Duration delay;
  final Duration duration;

  /// Kekuatan blur awal (sigma). 0 = tanpa blur.
  final double blur;

  /// Jarak naik awal dalam piksel.
  final double dy;

  /// false = langsung tampil tanpa animasi. Berubah dari false ke true = diputar.
  final bool active;

  /// Bila nilai ini berubah (dan [active] true), animasi diputar ulang.
  final Object? trigger;

  /// true = tahan di keadaan tersembunyi (belum mulai). Saat berubah ke false, animasi mulai.
  final bool hold;

  const Reveal({
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.blur = 6,
    this.dy = 14,
    this.active = true,
    this.trigger,
    this.hold = false,
    super.key,
  });

  /// Matikan global, misalnya di test: `Reveal.enabled = false;`
  static bool enabled = true;

  /// true = ikuti pengaturan "kurangi gerakan/animasi" dari sistem (animasi mati bila pengguna mematikannya).
  /// Default false supaya animasi selalu terlihat saat pengembangan. Ubah ke true sebelum rilis bila perlu.
  static bool respectReduceMotion = false;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // GlobalKey menjaga State anak (teks yang diketik, dsb.) tetap hidup saat pembungkus animasi dilepas.
  final GlobalKey _childKey = GlobalKey();
  late final AnimationController _c = AnimationController(vsync: this, duration: _total);

  Duration get _total => widget.delay + widget.duration;

  @override
  void initState() {
    super.initState();
    _c.value = 1;
    if (widget.active) {
      _c.value = 0; // mulai dari tersembunyi
      if (!widget.hold) _play();
    }
  }

  @override
  void didUpdateWidget(Reveal old) {
    super.didUpdateWidget(old);
    _c.duration = _total;
    if (!widget.active) return;
    final restart = !old.active || widget.trigger != old.trigger;
    if (restart) {
      if (widget.hold) {
        _c.value = 0;
      } else {
        _play();
      }
    } else if (old.hold && !widget.hold) {
      _play();
    }
  }

  void _play() {
    if (!Reveal.enabled) {
      _c.value = 1;
      return;
    }
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (!Reveal.enabled || (Reveal.respectReduceMotion && MediaQuery.of(context).disableAnimations)) return child;
    final totalMs = _total.inMilliseconds.toDouble();
    final delayMs = widget.delay.inMilliseconds.toDouble();
    final durMs = math.max(1, widget.duration.inMilliseconds).toDouble();

    return AnimatedBuilder(
      animation: _c,
      child: child,
      builder: (context, child) {
        if (_c.value >= 1) return child!; // selesai: lepas semua pembungkus
        final t = ((_c.value * totalMs - delayMs) / durMs).clamp(0.0, 1.0);
        final e = Curves.easeOutCubic.transform(t);
        final sigma = widget.blur * (1 - e);
        Widget w = Opacity(opacity: Curves.easeOut.transform((t * 1.6).clamp(0.0, 1.0)), child: child);
        if (sigma > .05) w = ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: w);
        return Transform.translate(offset: Offset(0, widget.dy * (1 - e)), child: w);
      },
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Urutan (stagger)
// ---------------------------------------------------------------------------------------------------

/// Satu "sesi" urutan: dibuat saat daftar pertama kali tampil atau saat tab dibuka lagi.
class _Stagger {
  final DateTime born = DateTime.now();
  static const window = Duration(milliseconds: 900);
  bool get open => DateTime.now().difference(born) < window;
}

class _StaggerScope extends InheritedWidget {
  final _Stagger? stagger;
  const _StaggerScope({required this.stagger, required super.child});

  static _Stagger? of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_StaggerScope>()?.stagger;
  static bool exists(BuildContext c) => c.getInheritedWidgetOfExactType<_StaggerScope>() != null;

  @override
  bool updateShouldNotify(_StaggerScope old) => stagger != old.stagger;
}

/// Penanda "putaran ke-berapa" sebuah tab dibuka. Berubah = daftar di dalamnya memulai urutan baru.
class RevealEpoch extends InheritedWidget {
  final int epoch;
  const RevealEpoch({required this.epoch, required super.child, super.key});

  static int of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<RevealEpoch>()?.epoch ?? 0;

  @override
  bool updateShouldNotify(RevealEpoch old) => epoch != old.epoch;
}

/// Bungkus tiap tab: setiap kali tab menjadi aktif, urutan animasi di dalamnya diputar ulang.
class RevealTab extends StatefulWidget {
  final bool active;
  final Widget child;
  const RevealTab({required this.active, required this.child, super.key});
  @override
  State<RevealTab> createState() => _RevealTabState();
}

class _RevealTabState extends State<RevealTab> {
  int _epoch = 0;

  @override
  void didUpdateWidget(RevealTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _epoch++;
  }

  @override
  Widget build(BuildContext context) => RevealEpoch(epoch: _epoch, child: widget.child);
}

/// Geser awal urutan untuk anak-anak sebuah [SelfReveal] (misalnya baris dalam SetGroup).
class _RevealBase extends InheritedWidget {
  final int base;
  const _RevealBase({required this.base, required super.child});

  static int of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<_RevealBase>()?.base ?? 0;

  @override
  bool updateShouldNotify(_RevealBase old) => base != old.base;
}

/// Tanda untuk widget yang menganimasikan anak-anaknya sendiri satu per satu.
/// [RevealListView] tidak membungkusnya lagi (supaya tidak dua kali) dan melanjutkan urutan sebanyak [revealCount].
mixin SelfReveal on Widget {
  int get revealCount;
}

/// Pembungkus bebas bertanda [SelfReveal]: pakai bila di dalamnya kamu memasang [RevealItem] sendiri.
class RevealGroup extends StatelessWidget with SelfReveal {
  final int count;
  final Widget child;
  const RevealGroup({required this.count, required this.child, super.key});

  @override
  int get revealCount => count;

  @override
  Widget build(BuildContext context) => child;
}

/// Satu baris/widget dalam urutan. [index] = posisinya (0 = pertama). Jeda antarbaris 55 ms, maksimal baris ke-14.
class RevealItem extends StatefulWidget {
  final int index;
  final Widget child;
  const RevealItem({required this.index, required this.child, super.key});

  static const step = Duration(milliseconds: 55);
  static const maxSteps = 14;

  @override
  State<RevealItem> createState() => _RevealItemState();
}

class _RevealItemState extends State<RevealItem> {
  _Stagger? _s;
  bool _go = false;
  bool _hold = false;
  Animation<double>? _ra;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = _StaggerScope.of(context);
    if (s == _s) return;
    _s = s;
    _go = s != null && s.open; // di luar jendela 0,9 detik = langsung tampil
    _watchRoute();
  }

  /// Selama halaman masih bertransisi masuk, baris ditahan tersembunyi. Animasi baris baru mulai setelah halaman
  /// diam, supaya terlihat jelas dan tidak berebut frame dengan transisi halaman.
  void _watchRoute() {
    _ra?.removeStatusListener(_onRoute);
    _ra = null;
    _hold = false;
    if (!_go) return;
    final a = ModalRoute.of(context)?.animation;
    if (a != null && a.status != AnimationStatus.completed) {
      _hold = true;
      _ra = a..addStatusListener(_onRoute);
    }
  }

  void _onRoute(AnimationStatus st) {
    if (st != AnimationStatus.completed) return;
    _ra?.removeStatusListener(_onRoute);
    _ra = null;
    if (mounted) setState(() => _hold = false);
  }

  @override
  void dispose() {
    _ra?.removeStatusListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = math.min(_RevealBase.of(context) + widget.index, RevealItem.maxSteps);
    return Reveal(active: _go, hold: _hold, trigger: _s, delay: RevealItem.step * i, child: widget.child);
  }
}

/// Bungkus daftar baris menjadi [RevealItem] berurutan. Untuk baris di dalam Column/Row biasa.
List<Widget> revealRows(List<Widget> rows, {int start = 0}) => [
      for (var i = 0; i < rows.length; i++) RevealItem(index: start + i, child: rows[i]),
    ];

class _StaggerHost extends StatefulWidget {
  final Widget child;
  const _StaggerHost({required this.child});
  @override
  State<_StaggerHost> createState() => _StaggerHostState();
}

class _StaggerHostState extends State<_StaggerHost> {
  _Stagger? _s;
  int? _epoch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final e = RevealEpoch.of(context);
    if (_s == null || e != _epoch) {
      _epoch = e;
      _s = _Stagger();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Daftar di dalam daftar lain (mis. baris kartu horizontal) tidak punya urutan sendiri: ikut induknya.
    final nested = _StaggerScope.exists(context);
    return _StaggerScope(stagger: nested ? null : _s, child: widget.child);
  }
}

/// Pengganti `ListView(children: [...])`: tiap anak muncul bergantian (blur-in) saat daftar dibuka.
/// Parameter sama dengan ListView.
class RevealListView extends ListView {
  RevealListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    super.cacheExtent,
    super.keyboardDismissBehavior,
    List<Widget> children = const <Widget>[],
  }) : super(children: _wrap(children));

  static List<Widget> _wrap(List<Widget> src) {
    final out = <Widget>[];
    var i = 0;
    for (final w in src) {
      if (w is SizedBox && w.child == null) {
        out.add(w); // jarak kosong: tidak perlu dianimasikan
      } else if (w is SelfReveal) {
        out.add(_RevealBase(base: i, child: w));
        i += (w).revealCount;
      } else {
        out.add(RevealItem(key: w.key is GlobalKey ? null : w.key, index: i++, child: w));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) => _StaggerHost(child: super.build(context));
}