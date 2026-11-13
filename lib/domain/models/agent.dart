// ---------- agen simulasi ----------
class Agent {
  final String id, name, bio;
  final List<String> cats;
  final double rating, dist;
  final int jobs, level, base;
  final bool verified, online, direct;
  Agent({required this.id, required this.name, required this.bio, required this.cats, required this.rating,
      required this.dist, required this.jobs, required this.level, required this.base,
      required this.verified, required this.online, required this.direct});
  String get short {
    final p = name.split(' ');
    return p.length > 1 ? '${p.first} ${p.last[0]}.' : name;
  }
}
