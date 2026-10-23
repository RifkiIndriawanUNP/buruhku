import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Order')),
      body: StreamBuilder<Order?>(
        stream: Services.orders.watchOrder(orderId),
        builder: (context, snap) {
          final order = snap.data;
          if (order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(order.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(order.status.label,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Agen: ${order.agentName}',
                        style: const TextStyle(color: Colors.black54)),
                    const Divider(height: 20),
                    _row('Harga kesepakatan', rupiah(order.agreedPrice)),
                    _row('Biaya layanan', rupiah(order.platformFee)),
                    _row('Total dibayar', rupiah(order.totalForClient),
                        bold: true),
                    _row('Diterima agen', rupiah(order.payoutToAgent)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppBox(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.key, color: Colors.amber),
                        SizedBox(width: 6),
                        Text('PIN Kerja',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.jobPin,
                      style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'Berikan PIN ini ke agen saat tiba di lokasi untuk memulai pekerjaan.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.paidEscrow)
                FilledButton.icon(
                  onPressed: () async {
                    await Services.orders.startWork(order.id);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Simulasi: Agen Mulai Bekerja'),
                ),
              if (order.status == OrderStatus.inProgress)
                FilledButton.icon(
                  onPressed: () async {
                    await Services.orders.confirmComplete(order.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pekerjaan selesai. Dana diteruskan ke agen.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Konfirmasi Pekerjaan Selesai'),
                ),
              if (order.status == OrderStatus.completed)
                AppBox(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Pekerjaan selesai. Dana sudah diteruskan ke agen.',
                            style: TextStyle(color: Colors.green.shade900)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(k,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w800 : FontWeight.normal)),
          ),
          Text(v,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}