import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Liquid-glass bottom navigation, adapted for Buruhku.
/// Logika & visual identik dengan referensi; hanya label, ikon,
/// dan aksi tombol kanan yang disesuaikan.
class LiquidGlassNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  /// Aksi untuk tombol kanan (bekas "search" → sekarang "buat request").
  final VoidCallback? onCreatePressed;

  const LiquidGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onCreatePressed,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  // ---- Layout ----
  static const _itemCount = 4;
  static const _pillHeight = 64.0;
  static const _gap = 12.0;
  static const _sidePadding = 4.0;

  static const _lensExtraWidth = 45.0;
  static const _lensExtraHeight = 35.0;

  // ---- Lens look ----
  static const _magnify = 0.18;
  static const _fadeInMs = 220;
  static const _fadeOutMs = 130;
  static const _globalOrigin = true;

  // ★ Ikon disesuaikan dengan kebutuhan Buruhku
  static const _icons = <IconData>[
    Icons.home_rounded,
    Icons.assignment_outlined, // Ikon Aktivitas (Riwayat & Favorit)
    Icons.post_add_rounded,    // Ikon Request (Bukan +)
    Icons.forum_rounded,       // Ikon Order Aktif (Chat)
    Icons.person_rounded,
  ];
  static const _labels = <String>['Beranda', 'Aktivitas', 'Request', 'Order Aktif', 'Akun'];

  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 240,
    ratio: 0.7,
  );

  final GlobalKey _pillKey = GlobalKey();
  late final AnimationController _posCtrl;
  late final AnimationController _pressCtrl;
  late final CurvedAnimation _press;

  int _target = 0;
  int? _pointer;
  bool _moved = false;
  double _downX = 0;
  int _hapticIndex = 0;
  late VelocityTracker _velocityTracker;

  @override
  void initState() {
    super.initState();
    _target = widget.selectedIndex;
    _hapticIndex = widget.selectedIndex;

    _posCtrl = AnimationController.unbounded(
      vsync: this,
      value: widget.selectedIndex.toDouble(),
    );

    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _fadeInMs),
      reverseDuration: const Duration(milliseconds: _fadeOutMs),
    );
    _press = CurvedAnimation(
      parent: _pressCtrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    _pressCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _target && _pointer == null) {
      _pressCtrl.forward();
      _settleTo(widget.selectedIndex, fadeWhenDone: true);
    }
  }

  // (Isi method _settleTo, _finish, _posFromX,
  //  _onPointerDown, _onPointerMove, _onPointerUp, _onPointerCancel
  //  IDENTIK dengan kode referensi — tidak diubah)

  void _settleTo(int index, {double velocity = 0, bool fadeWhenDone = false}) {
    _target = index;
    _hapticIndex = index;
    _posCtrl
        .animateWith(SpringSimulation(
          _spring,
          _posCtrl.value,
          index.toDouble(),
          velocity,
          tolerance: const Tolerance(distance: 0.004, velocity: 0.05),
        ))
        .whenComplete(() {
      if (fadeWhenDone && mounted && _pointer == null) _pressCtrl.reverse();
    });
  }

  void _finish(int index, {double velocity = 0}) {
    if (index != widget.selectedIndex) HapticFeedback.selectionClick();
    _target = index;
    if (index != widget.selectedIndex) widget.onItemSelected(index);
    _pressCtrl.reverse();
    _settleTo(index, velocity: velocity);
  }

  double _posFromX(double x, double itemWidth) =>
      ((x - _sidePadding) / itemWidth - 0.5)
          .clamp(-0.15, _itemCount - 1 + 0.15)
          .toDouble();

  void _onPointerDown(PointerDownEvent e, double itemWidth) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _moved = false;
    _downX = e.localPosition.dx;
    _velocityTracker = VelocityTracker.withKind(e.kind)
      ..addPosition(e.timeStamp, e.position);
    _posCtrl.stop();
    _pressCtrl.forward();
    _posCtrl.animateTo(
      _posFromX(e.localPosition.dx, itemWidth),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPointerMove(PointerMoveEvent e, double itemWidth) {
    if (e.pointer != _pointer) return;
    _velocityTracker.addPosition(e.timeStamp, e.position);
    if (!_moved && (e.localPosition.dx - _downX).abs() > 4) _moved = true;
    if (!_moved) return;
    final next = _posFromX(e.localPosition.dx, itemWidth);
    _posCtrl.value = next;
    final idx = next.round().clamp(0, _itemCount - 1).toInt();
    if (idx != _hapticIndex) {
      _hapticIndex = idx;
      HapticFeedback.selectionClick();
    }
  }

  void _onPointerUp(PointerUpEvent e, double itemWidth) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    if (_moved) {
      final v = _velocityTracker.getVelocity().pixelsPerSecond.dx / itemWidth;
      final projected = _posCtrl.value + v * 0.06;
      final index = projected.round().clamp(0, _itemCount - 1).toInt();
      _finish(index, velocity: v);
    } else {
      final index = ((e.localPosition.dx - _sidePadding) / itemWidth)
          .floor()
          .clamp(0, _itemCount - 1)
          .toInt();
      _finish(index);
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _finish(_posCtrl.value.round().clamp(0, _itemCount - 1).toInt());
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final pillWidth = maxW - _pillHeight - _gap;
            final itemWidth = (pillWidth - _sidePadding * 2) / _itemCount;

            return SizedBox(
              width: maxW,
              height: _pillHeight,
              child: Row(
                children: [
                  SizedBox(
                    key: _pillKey,
                    width: pillWidth,
                    height: _pillHeight,
                    child: _buildPill(itemWidth),
                  ),
                  const SizedBox(width: _gap),
                  _buildActionButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _iconRow(double pos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
      child: Row(
        children: List.generate(_itemCount, (i) {
          final t = (1 - (pos - i).abs()).clamp(0.0, 1.0).toDouble();
          return Expanded(
            child: _NavItem(
              icon: _icons[i],
              label: _labels[i],
              selectedAmount: t,
            ),
          );
        }),
      ),
    );
  }

  Offset _pillOrigin() {
    final ro = _pillKey.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      return ro.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  Widget _buildPill(double itemWidth) {
    final radius = BorderRadius.circular(_pillHeight / 2);
    final idleW = itemWidth + 8.0;
    const idleH = _pillHeight - 10.0;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) => _onPointerDown(e, itemWidth),
      onPointerMove: (e) => _onPointerMove(e, itemWidth),
      onPointerUp: (e) => _onPointerUp(e, itemWidth),
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_posCtrl, _pressCtrl]),
        builder: (context, _) {
          final pos = _posCtrl.value;
          final press = _press.value;
          final pressC = press.clamp(0.0, 1.0).toDouble();
          final lensActive = press > 0.01;

          final between =
              ((pos - pos.round()).abs() * 2).clamp(0.0, 1.0).toDouble();
          final stretch = between * 28.0 * pressC;

          final cx = _sidePadding + (pos + 0.5) * itemWidth;
          const cy = _pillHeight / 2;

          final lensW = idleW + _lensExtraWidth * press + stretch;
          final lensH = idleH + _lensExtraHeight * press - (stretch * 0.2);

          final lensRect = Rect.fromCenter(
            center: Offset(cx, cy),
            width: lensW,
            height: lensH,
          );

          final idleOpacity = (1 - press).clamp(0.0, 1.0).toDouble();

          Matrix4? zoom;
          if (lensActive) {
            final s = 1 + _magnify * pressC;
            final center = _globalOrigin
                ? _pillOrigin() + Offset(cx, cy)
                : Offset(lensW / 2, lensH / 2);
            zoom = Matrix4.translationValues(center.dx, center.dy, 0) *
                Matrix4.diagonal3Values(s, s, 1) *
                Matrix4.translationValues(-center.dx, -center.dy, 0);
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _FrostedBase(radius: radius)),
              Positioned(
                left: cx - idleW / 2,
                top: (_pillHeight - idleH) / 2,
                width: idleW,
                height: idleH,
                child: Opacity(
                  opacity: idleOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(idleH / 2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: _iconRow(pos)),
              if (lensActive)
                Positioned(
                  left: lensRect.left,
                  top: lensRect.top,
                  width: lensRect.width,
                  height: lensRect.height,
                  child: IgnorePointer(
                    child: _GlassLens(
                      width: lensRect.width,
                      height: lensRect.height,
                      matrix: zoom!,
                      opacity: pressC,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ★ Tombol kanan — sebelumnya "search", sekarang "+" (buat request)
  Widget _buildActionButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onCreatePressed?.call();
      },
      child: SizedBox(
        width: _pillHeight,
        height: _pillHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: _FrostedBase(
                radius: BorderRadius.circular(_pillHeight / 2),
              ),
            ),
            const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Bagian di bawah ini IDENTIK dengan file referensi — copy apa adanya:
//   _GlassLens, _LensRimPainter, _FrostedBase, _NavItem
// ══════════════════════════════════════════════════════════════════════════

class _GlassLens extends StatelessWidget {
  final double width;
  final double height;
  final Matrix4 matrix;
  final double opacity;

  const _GlassLens({
    required this.width,
    required this.height,
    required this.matrix,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        foregroundPainter: _LensRimPainter(opacity: opacity),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.matrix(
                    matrix.storage,
                    filterQuality: FilterQuality.medium,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.10 * opacity),
                          Colors.white.withValues(alpha: 0.02 * opacity),
                          Colors.white.withValues(alpha: 0.04 * opacity),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: RadialGradient(
                        center: const Alignment(-0.6, -0.8),
                        radius: 1.5,
                        colors: [
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.8],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF7DD3FC).withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                        stops: const [0.5, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LensRimPainter extends CustomPainter {
  final double opacity;
  const _LensRimPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect =
        RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2))
            .deflate(1.0);

    canvas.drawRRect(
      rrect.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: 0.10 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    void fringe(Color color, Offset shift) {
      canvas.save();
      canvas.translate(shift.dx, shift.dy);
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = color.withValues(alpha: 0.38 * opacity),
      );
      canvas.restore();
    }

    fringe(const Color(0xFFFF4D4D), const Offset(1.2, 1.0));
    fringe(const Color(0xFF4D7CFF), const Offset(-1.2, -1.0));

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.95 * opacity),
            Colors.white.withValues(alpha: 0.18 * opacity),
            Colors.white.withValues(alpha: 0.06 * opacity),
            const Color(0xFF7DD3FC).withValues(alpha: 0.55 * opacity),
            const Color(0xFFFFA85C).withValues(alpha: 0.80 * opacity),
          ],
          stops: const [0.0, 0.30, 0.55, 0.80, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LensRimPainter old) => old.opacity != opacity;
}

class _FrostedBase extends StatelessWidget {
  final BorderRadius radius;
  const _FrostedBase({required this.radius});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x8C2A2A2E), Color(0x8C0C0C0E)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double selectedAmount;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selectedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.white.withValues(
      alpha: (0.62 + 0.38 * selectedAmount).clamp(0.0, 1.0).toDouble(),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight:
                selectedAmount > 0.5 ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}