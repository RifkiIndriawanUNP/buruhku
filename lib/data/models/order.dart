enum OrderStatus {
  agreed,
  paidEscrow,
  scheduled,
  onTheWay,
  inProgress,
  pendingConfirm,
  completed,
  cancelled,
  disputed,
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.agreed => 'Menunggu Pembayaran',
        OrderStatus.paidEscrow => 'Dibayar — Dana Ditahan',
        OrderStatus.scheduled => 'Terjadwal',
        OrderStatus.onTheWay => 'Agen Berangkat',
        OrderStatus.inProgress => 'Sedang Dikerjakan',
        OrderStatus.pendingConfirm => 'Menunggu Konfirmasi',
        OrderStatus.completed => 'Selesai',
        OrderStatus.cancelled => 'Dibatalkan',
        OrderStatus.disputed => 'Sengketa',
        OrderStatus.refunded => 'Refund',
      };

  bool get isActive => [
        OrderStatus.agreed,
        OrderStatus.paidEscrow,
        OrderStatus.scheduled,
        OrderStatus.onTheWay,
        OrderStatus.inProgress,
        OrderStatus.pendingConfirm,
      ].contains(this);
}

class Order {
  final String id;
  final String requestId;
  final String clientId;
  final String agentId;
  final String agentName;
  final String title;
  final int agreedPrice;
  final int platformFee;
  final OrderStatus status;
  final String jobPin;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.agentId,
    required this.agentName,
    required this.title,
    required this.agreedPrice,
    required this.platformFee,
    this.status = OrderStatus.agreed,
    required this.jobPin,
    required this.createdAt,
  });

  int get totalForClient => agreedPrice + platformFee;
  int get payoutToAgent => agreedPrice - (agreedPrice * 0.10).round();

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        requestId: requestId,
        clientId: clientId,
        agentId: agentId,
        agentName: agentName,
        title: title,
        agreedPrice: agreedPrice,
        platformFee: platformFee,
        status: status ?? this.status,
        jobPin: jobPin,
        createdAt: createdAt,
      );
}