// ---------- tawaran jasa (layanan baku yang dibuat agen, bisa langsung dipesan klien) ----------
class Svc {
  String id, agentId, title, cat, desc, ptype;
  int price;
  double dur;
  bool active;
  String? imageUrl;
  List<String> photos;

  Svc({
    required this.id,
    required this.agentId,
    required this.title,
    required this.cat,
    this.desc = '',
    this.ptype = 'lump',
    required this.price,
    this.dur = 0,
    this.active = true,
    this.imageUrl,
    List<String>? photos,
  }) : photos = photos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id, 'ag': agentId, 'ti': title, 'ca': cat, 'de': desc, 'pt': ptype,
        'pr': price, 'du': dur, 'ac': active, 'img': imageUrl, 'ph': photos,
      };

  factory Svc.fromJson(Map<String, dynamic> j) => Svc(
        id: j['id'], agentId: j['ag'], title: j['ti'], cat: j['ca'],
        desc: j['de'], ptype: j['pt'], price: j['pr'], dur: (j['du'] as num).toDouble(),
        active: j['ac'], imageUrl: j['img'], photos: List<String>.from(j['ph'] ?? []),
      );
}
