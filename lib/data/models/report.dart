class Report {
  final String id;
  final String reporterId;
  final String? reportedUserId;
  final String? orderId;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.reporterId,
    this.reportedUserId,
    this.orderId,
    required this.category,
    required this.description,
    this.status = 'open',
    required this.createdAt,
  });
}