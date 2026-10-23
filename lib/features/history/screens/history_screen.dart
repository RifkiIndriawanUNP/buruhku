import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/order.dart';
import '../../order/screens/order_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Order')),
      body: StreamBuilder<List<Order>>(
        stream: Services.orders.watchMyOrders(user.id),
        builder: (context, snap) {
          final list = snap.data ?? const <Order>[];
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Belum ada order.\nBuat request, pilih agen, lalu bayar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final o = list[i];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(orderId: o.id),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                child: AppBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(o.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          _OrderStatusChip(status: o.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Agen: ${o.agentName}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(rupiah(o.totalForClient),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case OrderStatus.completed:
        c = Colors.green;
        break;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        c = Colors.grey;
        break;
      case OrderStatus.disputed:
        c = Colors.red;
        break;
      default:
        c = Colors.teal;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 10, color: c, fontWeight: FontWeight.w700)),
    );
  }
}