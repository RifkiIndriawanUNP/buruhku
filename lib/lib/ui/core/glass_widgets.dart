import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

const Color kTelegramBlue = Color(0xFF2AABEE);

// Jam global: animasi tetap berlanjut mulus saat pindah halaman.
final Stopwatch _bgClock = Stopwatch()..start();

// ───────────────────────── BACKGROUND IKAN KOI ─────────────────────────

class GlassBackground extends StatefulWidget {
  final Widget child;
  const GlassBackground({super.key, required this.child});

  @override
  State<GlassBackground> createState() => _GlassBackgroundState();
}

class _GlassBackgroundState extends State<GlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Hanya dipakai sebagai pemicu repaint tiap frame.
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _KoiPainter(_controller)),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _Koi {
  double x = 0, y = 0;
  double heading; // arah renang (radian)
  double turn = 0; // kecepatan belok saat ini
  double targetTurn = 0; // kecepatan belok yang dituju (acak)
  double nextChange = 0; // kapan ganti target belok
  double phase; // fase gerak ekor
  final double speed; // px per detik
  final double scale; // panjang ikan relatif terhadap sisi terpendek layar
  final double homeX, homeY; // posisi awal (0..1)
  final Color c1, c2;

  _Koi({
    required this.heading,
    required this.phase,
    required this.speed,
    required this.scale,
    required this.homeX,
    required this.homeY,
    required this.c1,
    required this.c2,
  });
}

class _KoiWorld {
  final math.Random _rnd = math.Random();
  late final List<_Koi> koi;
  double _last = 0;
  bool _ready = false;

  _KoiWorld() {
    double rA() => _rnd.nextDouble() * 2 * math.pi;
    koi = [
      _Koi(heading: rA(), phase: 0.0, speed: 20, scale: 0.62, homeX: 0.85, homeY: 0.10,
          c1: const Color(0xFF2AABEE), c2: const Color(0xFF7C4DFF)),
      _Koi(heading: rA(), phase: 2.0, speed: 17, scale: 0.52, homeX: 0.10, homeY: 0.58,
          c1: const Color(0xFFFFB74D), c2: const Color(0xFFFF5E8A)),
      _Koi(heading: rA(), phase: 4.0, speed: 22, scale: 0.66, homeX: 0.80, homeY: 0.92,
          c1: const Color(0xFFAB47BC), c2: const Color(0xFF26C6DA)),
    ];
  }

  double _angDiff(double a, double b) {
    var d = (a - b) % (2 * math.pi);
    if (d > math.pi) d -= 2 * math.pi;
    return d;
  }

  void update(double t, Size size) {
    if (!_ready) {
      for (final k in koi) {
        k.x = size.width * k.homeX;
        k.y = size.height * k.homeY;
      }
      _last = t;
      _ready = true;
      return;
    }

    final dt = (t - _last).clamp(0.0, 0.05).toDouble();
    _last = t;
    if (dt == 0) return;

    final base = math.min(size.width, size.height);
    final margin = base * 0.25; // ikan boleh keluar layar sedikit
    final center = Offset(size.width / 2, size.height / 2);

    for (final k in koi) {
      // Arah belok acak, berganti tiap beberapa detik
      if (t > k.nextChange) {
        k.targetTurn = (_rnd.nextDouble() - 0.5) * 0.9;
        k.nextChange = t + 2 + _rnd.nextDouble() * 4;
      }

      var desiredTurn = k.targetTurn;

      // Kalau terlalu jauh di luar layar, belok halus kembali ke tengah
      final outside = k.x < -margin ||
          k.x > size.width + margin ||
          k.y < -margin ||
          k.y > size.height + margin;
      if (outside) {
        final toCenter = math.atan2(center.dy - k.y, center.dx - k.x);
        final diff = _angDiff(toCenter, k.heading);
        desiredTurn = diff.clamp(-1.0, 1.0) * 0.8;
      }

      k.turn += (desiredTurn - k.turn) * dt * 1.5;
      k.heading += k.turn * dt;
      k.x += math.cos(k.heading) * k.speed * dt;
      k.y += math.sin(k.heading) * k.speed * dt;
      k.phase += dt * (2.0 + k.turn.abs() * 1.5);
    }
  }
}

final _KoiWorld _world = _KoiWorld();

class _KoiPainter extends CustomPainter {
  final Listenable repaint;
  _KoiPainter(this.repaint) : super(repaint: repaint);

  // Kurva tertutup halus (Catmull-Rom → Bezier)
  Path _smoothClosed(List<Offset> pts) {
    final n = pts.length;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  // Siluet koi tampak atas. Kepala di +x, ekor di -x (koordinat lokal).
  Path _koiPath(double L, double phase, double turn) {
    final bodyLen = L * 0.72;
    final maxW = L * 0.15;
    final amp = L * 0.07 + turn.abs() * L * 0.05;
    const steps = 12;

    double sx(double u) => L / 2 - u * bodyLen;
    double sy(double u) => amp * u * u * math.sin(phase - u * 3.0);
    double hw(double u) =>
        maxW * (0.9 * math.sin(math.pi * math.pow(u, 0.75)) + 0.1 * u);

    // Badan
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (int i = 0; i <= steps; i++) {
      final u = i / steps;
      top.add(Offset(sx(u), sy(u) - hw(u)));
      bottom.add(Offset(sx(u), sy(u) + hw(u)));
    }
    final outline = <Offset>[
      ...top,
      ...bottom.reversed.skip(0).take(steps), // tanpa duplikat ujung hidung
    ];
    var body = _smoothClosed(outline);

    // Ekor bercabang
    final endX = sx(1);
    final endY = sy(1);
    final endHw = hw(1);
    final tl = L * 0.30;
    final ty = endY + amp * 0.6 * math.sin(phase - 3.9);
    final tail = Path()
      ..moveTo(endX, endY - endHw)
      ..quadraticBezierTo(endX - tl * 0.5, endY - tl * 0.35,
          endX - tl, ty - tl * 0.45)
      ..quadraticBezierTo(endX - tl * 0.55, ty - tl * 0.1,
          endX - tl * 0.62, ty)
      ..quadraticBezierTo(endX - tl * 0.55, ty + tl * 0.1,
          endX - tl, ty + tl * 0.45)
      ..quadraticBezierTo(endX - tl * 0.5, endY + tl * 0.35,
          endX, endY + endHw)
      ..close();
    body = Path.combine(PathOperation.union, body, tail);

    // Sirip dada (kiri & kanan), mengepak pelan
    const fu = 0.25;
    final fl = L * 0.13;
    final flap = 0.85 + 0.15 * math.sin(phase * 1.2);
    for (final d in const [-1.0, 1.0]) {
      final bx = sx(fu);
      final by = sy(fu) + d * hw(fu) * 0.9;
      final fin = Path()
        ..moveTo(bx, by)
        ..quadraticBezierTo(bx - fl * 0.1, by + d * fl * 0.9 * flap,
            bx - fl * 0.95, by + d * fl * 1.0 * flap)
        ..quadraticBezierTo(bx - fl * 0.6, by + d * fl * 0.2,
            bx - fl * 0.5, by)
        ..close();
      body = Path.combine(PathOperation.union, body, fin);
    }

    return body;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = _bgClock.elapsedMilliseconds / 1000.0;
    final base = math.min(size.width, size.height);
    _world.update(t, size);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F7FA), Color(0xFFEDEFF6)],
        ).createShader(Offset.zero & size),
    );

    for (final k in _world.koi) {
      final L = base * k.scale;
      final path = _koiPath(L, k.phase, k.turn);

      canvas.save();
      canvas.translate(k.x, k.y);
      canvas.rotate(k.heading);

      final rect = Rect.fromLTWH(-L * 0.55, -L * 0.3, L * 1.1, L * 0.6);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [k.c1.withAlpha(120), k.c2.withAlpha(120)],
          ).createShader(rect)
          // blur kecil agar bentuk koi masih jelas terbaca
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _KoiPainter old) => true;
}

// ───────────────────────────── FROSTED GLASS CARD ─────────────────────────────

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final VoidCallback? onTap;

  /// Kekuatan blur latar. 0 = tanpa BackdropFilter (hemat untuk elemen kecil
  /// yang berada di atas kartu kaca lain).
  final double blur;

  /// false = tanpa bayangan jatuh (tombol kecil di dalam kartu).
  final bool shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.radius = 32,
    this.onTap,
    this.blur = 24,
    this.shadow = false,
  });

  Widget _maybeBlur(Widget w) => blur <= 0
      ? w
      : BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: w);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(34),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: _maybeBlur(
            CustomPaint(
              foregroundPainter: _GlassEdgePainter(radius),
              child: Container(
                width: double.infinity,
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xA8FFFFFF),
                      Color(0x80F2F4EC),
                      Color(0x8CEDEFE6),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassEdgePainter extends CustomPainter {
  final double radius;
  _GlassEdgePainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(outer);

    canvas.drawRRect(
      outer.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCCFFFFFF),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x66FFFFFF),
          ],
          stops: [0.0, 0.40, 0.65, 1.0],
        ).createShader(rect),
    );

    canvas.drawRRect(
      outer.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00000000),
            Color(0x00000000),
            Color(0x14000000),
          ],
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    canvas.restore();

    canvas.drawRRect(
      outer.deflate(0.8),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0x66FFFFFF),
            Color(0x4DFFFFFF),
            Color(0xCCFFFFFF),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ).createShader(rect),
    );

    canvas.drawRRect(
      outer.deflate(0.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = Colors.black.withAlpha(16),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassEdgePainter old) => old.radius != radius;
}

// ───────────────────────────── TOMBOL KEMBALI  ─────────────────────────────

class AppBackButton extends StatelessWidget {
  final String label;
  const AppBackButton({super.key, this.label = 'Kembali'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.maybePop(context),
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded, color: kTelegramBlue, size: 36),
            Text(
              label,
              style: const TextStyle(
                color: kTelegramBlue,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}