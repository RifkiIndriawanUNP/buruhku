import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:buruhku/ui/core/theme.dart';

const kBarSpace = 110.0; // ruang kosong di akhir list supaya item terakhir tidak tertutup bar
// ---------- bottom bar ----------
class BarItem {
  final IconData icon;        // ikon outline (tidak dipilih)
  final String label;
  final int badge;
  final IconData? activeIcon; // ikon filled (dipilih), opsional
  const BarItem(this.icon, this.label, [this.badge = 0, this.activeIcon]);
}


class BottomBar extends StatefulWidget {
  final int index;
  final List<BarItem> items;
  final int? center;
  final ValueChanged<int> onTap;
  final bool compact;
  const BottomBar({required this.index, required this.items, required this.onTap, this.center, this.compact = false, super.key});
  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _Geo {
  static const pad = 6.0;
  final List<double> lefts = [], widths = [];
  _Geo(int n, int? center, double inner, {double centerWeight = 1.35}) {
    final wt = [for (var i = 0; i < n; i++) i == center ? centerWeight : 1.0];
    final sum = wt.fold(0.0, (a, b) => a + b);
    var x = 0.0;
    for (final k in wt) {
      final w = inner * k / sum;
      lefts.add(x);
      widths.add(w);
      x += w;
    }
  }
  int get n => lefts.length;
  double center(int i) => lefts[i] + widths[i] / 2;
  double _at(double Function(int) f, double p) {
    if (n < 2) return f(0);
    p = p.clamp(0.0, n - 1.0);
    final i = p.floor().clamp(0, n - 2);
    final t = p - i;
    return f(i) + (f(i + 1) - f(i)) * t;
  }
  double centerAt(double p) => _at(center, p);
  double widthAt(double p) => _at((i) => widths[i], p);
  double posOf(double x) {
    x -= pad;
    if (n < 2 || x <= center(0)) return 0;
    if (x >= center(n - 1)) return n - 1.0;
    for (var i = 0; i < n - 1; i++) {
      if (x <= center(i + 1)) return i + (x - center(i)) / (center(i + 1) - center(i));
    }
    return n - 1.0;
  }
}

class _BottomBarState extends State<BottomBar> with TickerProviderStateMixin {
  static const _barH = 66.0;       // tinggi bar normal
  static const _barHCompact = 52.0; // tinggi bar saat kompak
  static const _slotCompact = 45.0; // lebar tiap ikon saat kompak (jarak antar ikon)
  static const _posSpring = SpringDescription(mass: 1, stiffness: 260, damping: 24);
  static const _pressSpring = SpringDescription(mass: 1, stiffness: 420, damping: 16);
  static const _stretchSpring = SpringDescription(mass: 1, stiffness: 320, damping: 11);
  static const _compactSpring = SpringDescription(mass: 1, stiffness: 240, damping: 26);

  late final AnimationController _stretch = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _pos = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());
  late final AnimationController _press = AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _compact = AnimationController.unbounded(vsync: this, value: widget.compact ? 1 : 0);

  double _downY = 0;
  bool _down = false, _dragging = false;
  double _downX = 0;
  int _hover = 0;
  double _w = 0;   // lebar bar saat ini (animasi)
  double _cv = 0;  // progres kompak 0..1 (animasi)

  double get _h => _barH + (_barHCompact - _barH) * _cv;

  void _spring(AnimationController c, SpringDescription d, double to) =>
      c.animateWith(SpringSimulation(d, c.value, to, c.velocity));

  @override
  void didUpdateWidget(BottomBar old) {
    super.didUpdateWidget(old);
    if (old.compact != widget.compact) {
      _spring(_compact, _compactSpring, widget.compact ? 1 : 0);
    }
    if (!_down && (old.index != widget.index || old.items.length != widget.items.length)) {
      _spring(_pos, _posSpring, widget.index.toDouble());
    }
  }

  @override
  void dispose() {
    _compact.dispose();
    _pos.dispose();
    _press.dispose();
    _stretch.dispose();
    super.dispose();
  }

  int _slot(_Geo g, double x) => g.posOf(x).round().clamp(0, g.n - 1);

  void _onDown(PointerEvent e, _Geo g) {
    _down = true;
    _dragging = false;
    _downX = e.localPosition.dx;
    _downY = e.localPosition.dy;
    _stretch.stop();
    _hover = _slot(g, _downX);
    _spring(_press, _pressSpring, 1);
    _spring(_pos, _posSpring, _hover.toDouble());
    HapticFeedback.selectionClick();
  }

  void _onMove(PointerEvent e, _Geo g) {
    if (!_down) return;
    final rawY = e.localPosition.dy - _downY;
    _stretch.value = (rawY / (1 + rawY.abs() / 5)).clamp(-24.0, 24.0);
    if (!_dragging && (e.localPosition.dx - _downX).abs() < 6) return;
    _dragging = true;
    _pos.stop();
    _pos.value = g.posOf(e.localPosition.dx);
    final h = _slot(g, e.localPosition.dx);
    if (h != _hover) {
      _hover = h;
      HapticFeedback.selectionClick();
    }
  }

  void _onUp(PointerEvent e, _Geo g, {bool cancel = false}) {
    if (!_down) return;
    _down = false;
    _spring(_press, _pressSpring, 0);
    _spring(_stretch, _stretchSpring, 0);
    if (cancel) {
      _spring(_pos, _posSpring, widget.index.toDouble());
      return;
    }
    final i = _slot(g, e.localPosition.dx);
    _spring(_pos, _posSpring, i.toDouble());
    widget.onTap(i);
  }

  Widget _item(int i, double w, Color col, bool bold) {
    final it = widget.items[i];
    if (i == widget.center) {
      // pill -> lingkaran 42x42 saat kompak
      final pillW = 42 + max(0.0, (w - 4) - 42) * (1 - _cv);
      return Center(
        child: Container(
          width: pillW, height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: const LinearGradient(colors: [kGreenLt, kGreen], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
          child: Icon(it.icon, color: cW, size: 28),
        ),
      );
    }
    final lab = 1 - _cv;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Badge(
        isLabelVisible: it.badge > 0, label: Text('${it.badge}'), backgroundColor: const Color(0xFFE53935),
        child: Icon(i == widget.index ? (it.activeIcon ?? it.icon) : it.icon, color: col, size: 24),
      ),
      SizedBox(height: 2 * lab),
      // label memudar dan menutup (tinggi menyusut) saat kompak
      ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: lab,
          child: Opacity(
            opacity: lab * lab,
            child: Text(it.label, maxLines: 1, overflow: TextOverflow.clip,
                style: TextStyle(fontSize: 11, color: col, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
          ),
        ),
      ),
    ]);
  }

  Widget _row(_Geo g, Color Function(int) col, bool Function(int) bold) => SizedBox(
        width: _w, height: _h,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _Geo.pad),
          child: Row(children: [
            for (var i = 0; i < g.n; i++) SizedBox(width: g.widths[i], child: _item(i, g.widths[i], col(i), bold(i))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final bottomPad = bottom > 12 ? bottom - 6 : 14.0;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 10, 24, bottomPad),
        child: LayoutBuilder(builder: (ctx, bc) {
        final full = bc.maxWidth;
        final n = widget.items.length;
        final compactW = min(full, _Geo.pad * 2 + n * _slotCompact);

        return AnimatedBuilder(
          animation: Listenable.merge([_pos, _press, _stretch, _compact]),
          builder: (_, __) {
            final c = _compact.value.clamp(0.0, 1.0);
            _cv = c;
            final barW = full + (compactW - full) * c;
            _w = barW;
            final g = _Geo(n, widget.center, barW - _Geo.pad * 2, centerWeight: 1.35 - 0.35 * c);

            final pr = _press.value;
            final prc = pr.clamp(0.0, 1.0);
            final p = _pos.value.clamp(0.0, g.n - 1.0);
            final cx = _Geo.pad + g.centerAt(p);
            final wd = g.widthAt(p);

            final grow = 8.0 * pr;
            final growV = 6.0 * pr;
            final t = g.n < 2 ? 0.0 : p / (g.n - 1);
            final stretchL = (1 - t) * 14.0 * pr;
            final stretchR = t * 14.0 * pr;

            final contentScale = 1 + 0.08 * pr;
            final contentShift = (stretchR - stretchL) / 2;
            final sv = _stretch.value;
            final upS = sv < 0 ? -sv : 0.0;
            final downS = sv > 0 ? sv : 0.0;
            final squeeze = sv.abs() * 0.3;

            final restW = wd, restH = _h - 12;
            final lensW = wd + 48 * pr - squeeze * 0.5;
            final lensH = (_h - 12) + 22 * pr + sv.abs() * 0.8;
            final lensL = cx - lensW / 2, lensT = (_h - lensH) / 2 + sv * 0.4;

            final shellRad = (_h + growV * 2 + upS + downS) / 2;
            final shellRadius = BorderRadius.circular(shellRad);

            return Align(
              heightFactor: 1,
              child: SizedBox(
                width: barW,
                height: _h,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _onDown(e, g),
                  onPointerMove: (e) => _onMove(e, g),
                  onPointerUp: (e) => _onUp(e, g),
                  onPointerCancel: (e) => _onUp(e, g, cancel: true),
                  child: Stack(clipBehavior: Clip.none, children: [
                    // 1) background bar
                    Positioned(
                      left: -(grow + stretchL - squeeze),
                      right: -(grow + stretchR - squeeze),
                      top: -(growV + upS),
                      bottom: -(growV + downS),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: shellRadius,
                          border: Border.all(color: const Color(0xFFDCDDE1), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: shellRadius,
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        cW.withAlpha(180),
                                        const Color(0xFFF7F7F7).withAlpha(180),
                                        const Color(0xFFF7F7F7).withAlpha(180),
                                      ],
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                                CustomPaint(painter: _SmokePainter()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 2) isi bar
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(contentShift, sv * 0.25),
                        child: Transform.scale(
                          scale: contentScale,
                          child: Stack(clipBehavior: Clip.none, children: [
                            if (prc < 1)
                              Positioned(
                                left: cx - restW / 2, top: (_h - restH) / 2, width: restW, height: restH,
                                child: Opacity(
                                  opacity: 1 - prc,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: const Color(0xFFE2E2E2), borderRadius: BorderRadius.circular(restH / 2)),
                                  ),
                                ),
                              ),

                            _row(
                              g,
                              (i) => i == widget.index ? Color.lerp(kGreen, g900, prc)! : g900,
                              (i) => i == widget.index && prc < .5,
                            ),

                            if (prc > .01)
                              Positioned(
                                left: lensL, top: lensT, width: lensW, height: lensH,
                                child: Opacity(
                                  opacity: prc,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(lensH / 2),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(lensH / 2),
                                      child: Stack(clipBehavior: Clip.hardEdge, children: [
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [cW.withAlpha(250), const Color(0xFFF1F1F1).withAlpha(240)],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: -lensL, top: -lensT, width: _w, height: _h,
                                          child: Transform.scale(
                                            scale: 1 + .16 * pr,
                                            alignment: Alignment((cx / _w) * 2 - 1, 0),
                                            child: _row(g, (_) => kGreen, (_) => true),
                                          ),
                                        ),
                                        Positioned.fill(child: CustomPaint(painter: _LensPainter())),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          },
        );
      }),
    ));
  }
}

/// Tekstur smoky halus (blob lembut + grain tipis) — statis, dioptimalkan untuk performa tinggi.
class _SmokePainter extends CustomPainter {
  static final List<({double nx, double ny, double nrad, bool isShade})> _blobs = () {
    final r = Random(7);
    return List.generate(16, (_) => (
      nx: r.nextDouble(),
      ny: r.nextDouble(),
      nrad: 20 + r.nextDouble() * 70,
      isShade: r.nextBool(),
    ));
  }();

  static final List<Offset> _dots = () {
    final r = Random(7);
    return List.generate(100, (_) => Offset(r.nextDouble(), r.nextDouble()));
  }();

  static final Paint _dotPaint = Paint()..color = g900.withAlpha(8);
  static final Paint _wispPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 18
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF9C9C9C).withAlpha(10);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);

    // blob lembut (asap)
    for (final b in _blobs) {
      final cx = b.nx * size.width;
      final cy = b.ny * size.height;
      final shade = b.isShade ? const Color(0xFFB8B8B8) : cW;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [shade.withAlpha(28), shade.withAlpha(0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: b.nrad));
      canvas.drawCircle(Offset(cx, cy), b.nrad, paint);
    }

    // grain noise tipis
    for (final d in _dots) {
      canvas.drawCircle(Offset(d.dx * size.width, d.dy * size.height), 0.7, _dotPaint);
    }

    // garis asap memanjang halus
    final path = Path()..moveTo(-10, size.height * 0.55);
    for (var x = 0.0; x <= size.width + 10; x += 30) {
      final y = size.height * 0.55 + sin(x / 55) * 6;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, _wispPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LensPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    canvas.drawRRect(
      r.deflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..shader = const SweepGradient(colors: [
          Color(0x9966E0FF), Color(0x99FFFFFF), Color(0x99FFE95C), Color(0x99FF8AD8),
          Color(0x99FFFFFF), Color(0x9966E0FF),
        ]).createShader(rect),
    );
    canvas.drawRRect(
      r.deflate(4.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xE6FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


