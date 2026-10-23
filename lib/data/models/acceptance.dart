enum AcceptanceStatus { accepted, declined, withdrawn, selected }

class Acceptance {
  final String id;
  final String requestId;
  final String agentId;
  final String agentName;
  final double agentRating;
  final int agentJobsCompleted;
  final double agentDistanceKm;
  final AcceptanceStatus status;
  final int proposedPrice;
  final DateTime acceptedAt;

  Acceptance({
    required this.id,
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.agentRating,
    required this.agentJobsCompleted,
    required this.agentDistanceKm,
    this.status = AcceptanceStatus.accepted,
    required this.proposedPrice,
    required this.acceptedAt,
  });

  Acceptance copyWith({
    AcceptanceStatus? status,
    int? proposedPrice,
  }) =>
      Acceptance(
        id: id,
        requestId: requestId,
        agentId: agentId,
        agentName: agentName,
        agentRating: agentRating,
        agentJobsCompleted: agentJobsCompleted,
        agentDistanceKm: agentDistanceKm,
        status: status ?? this.status,
        proposedPrice: proposedPrice ?? this.proposedPrice,
        acceptedAt: acceptedAt,
      );
}