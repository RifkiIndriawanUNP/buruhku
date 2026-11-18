import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:buruhku/ui/core/theme.dart';

/// Tombol melayang berbentuk pil (ikon + label). Saat isi digulir turun label memudar dan tombol
/// mengecil jadi lingkaran. Saat digulir naik atau kembali ke atas, tombol melebar lagi.
class ScrollFab extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool extended;
  const ScrollFab({required this.icon, required this.label, required this.onTap, this.extended = true, super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: kGreen,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 24, color: Colors.white),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: extended ? 1 : 0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: v, child: Opacity(opacity: v, child: child))),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 4),
                    child: Text(label, maxLines: 1, softWrap: false, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Pembungkus yang mendengarkan gulir vertikal di bawahnya dan memberi tahu apakah tombol harus melebar.
/// Menggulir turun = false (mengecil). Menggulir naik atau di paling atas = true (melebar).
class ScrollFabListener extends StatelessWidget {
  final ValueChanged<bool> onExtended;
  final Widget child;
  const ScrollFabListener({required this.onExtended, required this.child, super.key});

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.axis != Axis.vertical) return false;
          if (n is UserScrollNotification) {
            if (n.direction == ScrollDirection.reverse) onExtended(false);
            if (n.direction == ScrollDirection.forward) onExtended(true);
          }
          if (n.metrics.pixels <= n.metrics.minScrollExtent + 1) onExtended(true);
          return false; // biarkan notifikasi terus naik (mis. ke Shell)
        },
        child: child,
      );
}
