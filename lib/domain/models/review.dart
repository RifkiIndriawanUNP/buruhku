import 'package:buruhku/utils/json.dart';

class Rev {
  String id, orderId, aboutId, from, comment;
  int rating;
  List<String> tags;
  bool pub;
  DateTime at;
  String? avatarUrl;
  String? photoUrl;
  Rev({required this.id, this.orderId = '', required this.aboutId, required this.from, required this.rating,
      List<String>? tags, this.comment = '', this.pub = true, DateTime? at, this.avatarUrl, this.photoUrl})
      : tags = tags ?? [],
        at = at ?? DateTime.now();
  Map<String, dynamic> toJson() => {'id': id, 'o': orderId, 'ab': aboutId, 'f': from, 'r': rating, 'tg': tags,
        'c': comment, 'p': pub, 't': jDateStr(at), 'av': avatarUrl, 'ph': photoUrl};
  factory Rev.fromJson(Map<String, dynamic> j) => Rev(id: j['id'], orderId: j['o'] ?? '', aboutId: j['ab'] ?? '', from: j['f'] ?? '',
      rating: j['r'] ?? 5, tags: List<String>.from(j['tg'] ?? []), comment: j['c'] ?? '', pub: j['p'] ?? true, at: jDate(j['t']),
      avatarUrl: j['av'], photoUrl: j['ph']);
}
