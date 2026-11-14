import 'package:latlong2/latlong.dart' show Distance, LatLng;
import 'package:buruhku/config/env.dart';

/// Helper koordinat. Murni Dart (tanpa widget), jadi aman dipakai di model dan repository.

const _dist = Distance();

/// Titik pusat demo (lihat Env.mapLat / Env.mapLng).
final LatLng kMapCenter = LatLng(Env.mapLat, Env.mapLng);

/// Sudut (derajat dari utara) tempat data simulasi boleh diletakkan.
/// 0..130 = dari utara sampai tenggara pusat demo, supaya titik dummy jatuh di darat.
/// Ubah dua konstanta ini kalau pusat demo dipindah.
const double _arcStart = 0, _arcSpan = 130;

int _mix(String key) {
  var h = 0x2545F4;
  for (final c in key.codeUnits) {
    h = ((h ^ c) * 0x9E3779) & 0xFFFFFF;
    h ^= h >> 11;
  }
  return h;
}

/// Titik [km] dari pusat demo dengan arah yang selalu sama untuk [key] yang sama.
/// Dipakai untuk posisi dummy agen dan request, jadi jarak di peta sama dengan jarak di kartu.
final Map<String, LatLng> _pointCache = {};

LatLng pointAt(double km, String key) => _pointCache.putIfAbsent('$key|$km', () {
  final bearing = _arcStart + (_mix(key) % 1000) / 1000 * _arcSpan;
  return _dist.offset(kMapCenter, km * 1000, bearing);
});

double kmBetween(LatLng a, LatLng b) => _dist.distance(a, b) / 1000;

// Kelurahan dummy: (jarak km, arah) dari pusat demo. Jaraknya sama dengan data seed request.
const Map<String, (double, double)> _areaSpots = {
  'Palabuhanratu': (0.0, 0.0),
  'Cikembang': (1.2, 20.0),
  'Citepus': (2.4, 75.0),
  'Jayanti': (3.1, 40.0),
  'Pasirsuren': (4.8, 105.0),
  'Sukamulya': (5.5, 10.0),
  'Gunungguruh': (6.9, 65.0),
  'Cibodas': (8.5, 120.0),
};

final Map<String, LatLng> _areaPoints = {
  for (final e in _areaSpots.entries) e.key: _dist.offset(kMapCenter, e.value.$1 * 1000, e.value.$2),
};

/// Titik tengah kelurahan dummy (pusat demo jika namanya tidak dikenal).
LatLng areaPoint(String area) => _areaPoints[area] ?? kMapCenter;

/// Nama kelurahan dummy terdekat dari [p].
String nearestArea(LatLng p) {
  String best = _areaSpots.keys.first;
  var bestKm = double.infinity;
  for (final name in _areaSpots.keys) {
    final km = kmBetween(p, areaPoint(name));
    if (km < bestKm) {
      bestKm = km;
      best = name;
    }
  }
  return best;
}

// Data lama (sebelum ada peta sungguhan) menyimpan posisi pin sebagai pecahan 0..1.
// Nilai seperti itu dianggap belum punya koordinat dan diganti pusat demo.
bool _legacy(double la, double ln) => la >= 0 && la <= 1 && ln >= 0 && ln <= 1;
double fixLat(double la, double ln) => _legacy(la, ln) ? Env.mapLat : la;
double fixLng(double la, double ln) => _legacy(la, ln) ? Env.mapLng : ln;
