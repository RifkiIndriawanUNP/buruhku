import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/theme.dart';

// ---------- QR palsu (wireframe) ----------
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
