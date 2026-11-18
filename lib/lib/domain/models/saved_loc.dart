import 'package:buruhku/config/env.dart';
import 'package:buruhku/utils/geo.dart';

// ---------- lokasi tersimpan ----------
class SavedLoc {
  String id, label, address;
  double lat, lng;
  SavedLoc({required this.id, required this.label, required this.address, this.lat = Env.mapLat, this.lng = Env.mapLng});
  Map<String, dynamic> toJson() => {'id': id, 'l': label, 'a': address, 'la': lat, 'ln': lng};
  factory SavedLoc.fromJson(Map<String, dynamic> j) => SavedLoc(
      id: j['id'], label: j['l'], address: j['a'], lat: fixLat((j['la'] as num).toDouble(), (j['ln'] as num).toDouble()),
      lng: fixLng((j['la'] as num).toDouble(), (j['ln'] as num).toDouble()));
}
