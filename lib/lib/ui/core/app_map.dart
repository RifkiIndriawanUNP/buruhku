import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:buruhku/config/env.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/ui/core/page_bar.dart';
import 'package:buruhku/utils/geo.dart';

/// Satu titik di peta (agen, agen yang sedang berjalan, dst.).
Widget _markerFallback() => Container(color: g100, child: const Icon(Icons.person, size: 20, color: g500));

class MapMark {
  final LatLng point;
  final Widget child;
  final double size;
  final Alignment alignment;
  const MapMark(this.point, this.child, {this.size = 34, this.alignment = Alignment.center});

  /// Marker bulat berisi foto profil agen. Cincin hijau = online, abu-abu = offline.
  factory MapMark.agent(LatLng p, {required bool online, bool selected = false, VoidCallback? onTap, String? imageUrl}) => MapMark(
        p,
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(selected ? 3.5 : 2.5),
            decoration: BoxDecoration(color: online ? kGreen : g400, shape: BoxShape.circle),
            child: ClipOval(
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _markerFallback())
                  : _markerFallback(),
            ),
          ),
        ),
        size: selected ? 50 : 40,
      );

  /// Agen yang sedang menuju lokasi (pelacakan order).
  factory MapMark.walker(LatLng p) => MapMark(
        p,
        Container(
          decoration: BoxDecoration(color: kGreen, shape: BoxShape.circle, border: Border.all(color: cW, width: 2)),
          child: const Icon(Icons.directions_walk, size: 20, color: cW),
        ),
        size: 36,
      );
}

/// Peta OpenStreetMap berbasis flutter_map.
///
/// - [pin]: titik tujuan/lokasi kerja (ikon pin).
/// - [onPick]: kalau diisi, mengetuk peta memindahkan pin dan memanggil callback ini.
/// - [marks]: titik lain (agen, dst.). [route]: garis antar titik.
/// - [circleCenter] + [radiusKm]: lingkaran (radius pencarian atau area perkiraan).
/// - [fitKey]: kamera dipas-kan ke semua titik saat pertama tampil dan setiap kali nilainya berubah.
/// - [interactive]: false untuk pratinjau statis.
class AppMap extends StatefulWidget {
  final double height;
  final LatLng? pin, center, circleCenter;
  final double? zoom, radiusKm;
  final ValueChanged<LatLng>? onPick, onBackgroundTap;
  final List<MapMark> marks;
  final List<LatLng> route;
  final bool interactive, framed;
  final Object? fitKey;
  const AppMap({
    super.key,
    this.height = 170,
    this.pin,
    this.center,
    this.zoom,
    this.onPick,
    this.onBackgroundTap,
    this.marks = const [],
    this.route = const [],
    this.circleCenter,
    this.radiusKm,
    this.interactive = true,
    this.framed = true,
    this.fitKey,
  });

  @override
  State<AppMap> createState() => _AppMapState();
}

class _AppMapState extends State<AppMap> {
  final _c = MapController();

  // Dibuat SEKALI per peta. Kalau dibuat ulang di setiap build (sekali per detik saat pelacakan),
  // flutter_map memproses ulang opsi dan lapisan tile sehingga terasa patah-patah.
  MapOptions? _opts;
  late final TileLayer _tiles = TileLayer(
    urlTemplate: Env.tileUrl,
    userAgentPackageName: Env.tileUserAgent,
    keepBuffer: 1,
    panBuffer: widget.interactive ? 1 : 0, // peta pratinjau tidak perlu memuat tile cadangan
    tileUpdateTransformer: TileUpdateTransformers.throttle(const Duration(milliseconds: 80)),
  );
  bool _ready = false;
  LatLng? _tapped;

  List<LatLng> _points() => [
        if (widget.pin != null) widget.pin!,
        for (final m in widget.marks) m.point,
        ...widget.route,
      ];

  CameraFit _fit(List<LatLng> pts) => CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(44), maxZoom: 16);

  @override
  void didUpdateWidget(AppMap old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    final pin = widget.pin;
    final moved = pin != null && pin != old.pin && pin != _tapped;
    final refit = widget.fitKey != null && widget.fitKey != old.fitKey;
    if (!moved && !refit) return;
    // Kamera digeser setelah frame selesai, supaya tidak mengubah state saat build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (refit) {
        final pts = _points();
        if (pts.length >= 2) {
          _c.fitCamera(_fit(pts));
          return;
        }
      }
      if (pin != null) _c.move(pin, _c.camera.zoom);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _zoomBy(double d) {
    if (!_ready) return;
    _c.move(_c.camera.center, (_c.camera.zoom + d).clamp(3.0, 18.0));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final pts = _points();
    final start = w.center ?? w.pin ?? kMapCenter;
    final fit = w.fitKey != null && pts.length >= 2;
    final map = Stack(children: [
      FlutterMap(
        mapController: _c,
        options: _opts ??= MapOptions(
          initialCenter: start,
          initialZoom: w.zoom ?? Env.mapZoom,
          initialCameraFit: fit ? _fit(pts) : null,
          minZoom: 3,
          maxZoom: 18,
          backgroundColor: g100,
          interactionOptions: InteractionOptions(flags: w.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
          onMapReady: () => _ready = true,
          onTap: (w.onPick == null && w.onBackgroundTap == null)
              ? null
              : (_, p) {
                  if (widget.onPick != null) {
                    _tapped = p;
                    widget.onPick!(p);
                  }
                  widget.onBackgroundTap?.call(p);
                },
        ),
        children: [
          _tiles,
          if (w.route.length >= 2) PolylineLayer(polylines: [Polyline(points: w.route, strokeWidth: 3, color: g500)]),
          if (w.circleCenter != null && w.radiusKm != null)
            CircleLayer(circles: [
              CircleMarker(point: w.circleCenter!, radius: w.radiusKm! * 1000, useRadiusInMeter: true, color: const Color(0x141C1C1C), borderColor: g700, borderStrokeWidth: 1.5),
            ]),
          MarkerLayer(markers: [
            for (final m in w.marks) Marker(point: m.point, width: m.size, height: m.size, alignment: m.alignment, child: m.child),
            if (w.pin != null) Marker(point: w.pin!, width: 40, height: 40, alignment: Alignment.topCenter, child: const Icon(Icons.location_on, size: 40, color: g900)),
          ]),
        ],
      ),
      if (w.onPick != null) const Positioned(left: 8, bottom: 4, child: _Label('Ketuk peta untuk pasang pin')),
      const Positioned(right: 6, bottom: 4, child: _Label('© OpenStreetMap')),
      if (w.interactive && w.height >= 140)
        Positioned(
          right: 6,
          bottom: 28,
          child: Column(children: [
            _ZoomBtn(Icons.add, () => _zoomBy(1)),
            const SizedBox(height: 4),
            _ZoomBtn(Icons.remove, () => _zoomBy(-1)),
          ]),
        ),
    ]);
    return Container(
      height: w.height,
      clipBehavior: w.framed ? Clip.antiAlias : Clip.none,
      decoration: w.framed ? BoxDecoration(border: Border.all(color: g300), borderRadius: BorderRadius.circular(8)) : null,
      child: RepaintBoundary(child: map),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: const Color(0xCCFFFFFF),
        child: Text(text, style: const TextStyle(fontSize: 10, color: g700)),
      );
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: cW,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: const BorderSide(color: g200)),
        child: InkWell(borderRadius: BorderRadius.circular(6), onTap: onTap, child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: g900))),
      );
}
/// Pratinjau peta RINGAN untuk daftar dan chat: tanpa memuat tile dari internet.
/// Peta sungguhan baru dibuka (satu saja) saat diketuk.
class MapThumb extends StatelessWidget {
  final LatLng pin;
  final double height;
  final String title;
  const MapThumb({super.key, required this.pin, this.height = 90, this.title = 'Lokasi'});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MapFullPage(pin: pin, title: title))),
        child: Container(
          height: height,
          decoration: BoxDecoration(color: g100, border: Border.all(color: g300), borderRadius: BorderRadius.circular(8)),
          child: const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.location_on, size: 30, color: g900),
              SizedBox(height: 2),
              Text('Ketuk untuk lihat peta', style: TextStyle(fontSize: 11, color: g700)),
            ]),
          ),
        ),
      );
}

/// Halaman peta layar penuh untuk satu titik.
class MapFullPage extends StatelessWidget {
  final LatLng pin;
  final String title;
  const MapFullPage({super.key, required this.pin, this.title = 'Lokasi'});

  @override
  Widget build(BuildContext context) => AppScaffold(underBar: true,
        appBar: PageBar(title: Text(title)),
        body: AppMap(height: double.infinity, framed: false, pin: pin, zoom: 15),
      );
}
