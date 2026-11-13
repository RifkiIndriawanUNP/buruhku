import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/theme.dart';

// ---------- peta & QR palsu (wireframe) ----------
class _Grid extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = g200..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 28) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (var y = 0.0; y < s.height; y += 28) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
    final r = Paint()..color = g300..strokeWidth = 5..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, s.height * .65), Offset(s.width, s.height * .35), r);
    c.drawLine(Offset(s.width * .3, 0), Offset(s.width * .55, s.height), r);
  }

  @override
  bool shouldRepaint(_) => false;
}

class FakeMap extends StatelessWidget {
  final double h;
  final Offset? pin;
  final ValueChanged<Offset>? onTap;
  final List<Offset> marks;
  const FakeMap({this.h = 170, this.pin, this.onTap, this.marks = const []});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final w = box.maxWidth;
        return GestureDetector(
            onTapDown: onTap == null ? null : (d) => onTap!(Offset((d.localPosition.dx / w).clamp(0.0, 1.0), (d.localPosition.dy / h).clamp(0.0, 1.0))),
            child: Container(
                height: h, clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: g100, border: Border.all(color: g300), borderRadius: BorderRadius.circular(8)),
                child: Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _Grid())),
                  for (final m in marks) Positioned(left: m.dx * w - 12, top: m.dy * h - 24, child: const Icon(Icons.directions_walk, size: 24, color: g700)),
                  if (pin != null) Positioned(left: pin!.dx * w - 14, top: pin!.dy * h - 28, child: const Icon(Icons.location_on, size: 28, color: g900)),
                  if (onTap != null) const Positioned(right: 8, bottom: 6, child: Text('Ketuk peta untuk pasang pin', style: TextStyle(fontSize: 10, color: g500))),
                ])));
      });
}

class _Qr extends CustomPainter {
  final int seed;
  _Qr(this.seed);
  @override
  void paint(Canvas c, Size s) {
    final r = Random(seed);
    const n = 25;
    final cell = s.width / n;
    final p = Paint()..color = g900;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final tl = i < 7 && j < 7, tr = i < 7 && j >= n - 7, bl = i >= n - 7 && j < 7;
        bool on;
        if (tl || tr || bl) {
          final a = i >= n - 7 ? i - (n - 7) : i, b = j >= n - 7 ? j - (n - 7) : j;
          on = a == 0 || a == 6 || b == 0 || b == 6 || (a >= 2 && a <= 4 && b >= 2 && b <= 4);
        } else {
          on = r.nextBool();
        }
        if (on) {
          c.drawRect(Rect.fromLTWH(i * cell, j * cell, cell, cell), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class FakeQr extends StatelessWidget {
  final int seed;
  const FakeQr(this.seed);
  @override
  Widget build(BuildContext context) => Container(
      width: 180, height: 180, padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cW, border: Border.all(color: g900)),
      child: CustomPaint(painter: _Qr(seed)));
}
