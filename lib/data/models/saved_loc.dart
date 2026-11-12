// ---------- lokasi tersimpan ----------
class SavedLoc {
  String id, label, address;
  double lat, lng;
  SavedLoc({required this.id, required this.label, required this.address, this.lat = 0.5, this.lng = 0.5});
  Map<String, dynamic> toJson() => {'id': id, 'l': label, 'a': address, 'la': lat, 'ln': lng};
  factory SavedLoc.fromJson(Map<String, dynamic> j) => SavedLoc(
      id: j['id'], label: j['l'], address: j['a'], lat: (j['la'] as num).toDouble(), lng: (j['ln'] as num).toDouble());
}
