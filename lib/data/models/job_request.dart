enum PriceType { lumpSum, hourly, daily }
enum RequestStatus {
  draft,
  open,
  hasAcceptors,
  negotiating,
  agreed,
  paidEscrow,
  inProgress,
  completed,
  cancelled,
  expired,
}

extension PriceTypeX on PriceType {
  String get label => switch (this) {
        PriceType.lumpSum => 'Borongan',
        PriceType.hourly => 'Per jam',
        PriceType.daily => 'Harian',
      };
}

extension RequestStatusX on RequestStatus {
  String get label => switch (this) {
        RequestStatus.draft => 'Draft',
        RequestStatus.open => 'Mencari Agen',
        RequestStatus.hasAcceptors => 'Ada Agen',
        RequestStatus.negotiating => 'Negosiasi',
        RequestStatus.agreed => 'Disepakati',
        RequestStatus.paidEscrow => 'Dibayar (Escrow)',
        RequestStatus.inProgress => 'Dikerjakan',
        RequestStatus.completed => 'Selesai',
        RequestStatus.cancelled => 'Dibatalkan',
        RequestStatus.expired => 'Kadaluarsa',
      };
}

class JobRequest {
  final String id;
  final String clientId;
  final String categoryId;
  final String title;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final DateTime? scheduledAt;
  final int workersNeeded;
  final PriceType priceType;
  final int offeredPrice;
  final RequestStatus status;
  final int acceptQuota;
  final DateTime createdAt;
  final DateTime expiresAt;

  JobRequest({
    required this.id,
    required this.clientId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    this.scheduledAt,
    this.workersNeeded = 1,
    this.priceType = PriceType.lumpSum,
    required this.offeredPrice,
    this.status = RequestStatus.open,
    this.acceptQuota = 5,
    required this.createdAt,
    required this.expiresAt,
  });

  JobRequest copyWith({
    RequestStatus? status,
    int? offeredPrice,
    DateTime? expiresAt,
    int? acceptQuota,
  }) =>
      JobRequest(
        id: id,
        clientId: clientId,
        categoryId: categoryId,
        title: title,
        description: description,
        address: address,
        lat: lat,
        lng: lng,
        scheduledAt: scheduledAt,
        workersNeeded: workersNeeded,
        priceType: priceType,
        offeredPrice: offeredPrice ?? this.offeredPrice,
        status: status ?? this.status,
        acceptQuota: acceptQuota ?? this.acceptQuota,
        createdAt: createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
}