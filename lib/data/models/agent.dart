import 'dart:math' as math;

class Agent {
  final String id;
  final String displayName;
  final String? phone;
  final double ratingAvg;
  final int jobsCompleted;
  final double baseLat;
  final double baseLng;
  final bool isOnline;
  final bool verified;
  final List<String> categoryIds;
  final double serviceRadiusKm;
  final String bio;
  final double acceptanceRate;

  Agent({
    required this.id,
    required this.displayName,
    this.phone,
    this.ratingAvg = 5.0,
    this.jobsCompleted = 0,
    required this.baseLat,
    required this.baseLng,
    this.isOnline = true,
    this.verified = true,
    required this.categoryIds,
    this.serviceRadiusKm = 10,
    this.bio = '',
    this.acceptanceRate = 0.8,
  });

  double distanceFrom(double lat, double lng) {
    // Haversine
    const r = 6371.0;
    final dLat = _deg2rad(lat - baseLat);
    final dLng = _deg2rad(lng - baseLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(baseLat)) *
            math.cos(_deg2rad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double d) => d * math.pi / 180;
}