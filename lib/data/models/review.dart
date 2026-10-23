class Review {
  final String id;
  final String orderId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;
  final DateTime? publishedAt;

  Review({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.tags = const [],
    this.comment = '',
    required this.createdAt,
    this.publishedAt,
  });
}