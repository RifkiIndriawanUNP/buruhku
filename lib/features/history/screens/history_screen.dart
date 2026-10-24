import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
//import '../../../data/models/agent.dart';
import '../../../data/models/order.dart';
import '../../order/screens/order_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Aktivitas Saya'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Riwayat Order'), Tab(text: 'Agen Favorit')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryList(context, user.id),
            _buildFavoriteList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, String userId) {
    return StreamBuilder<List<Order>>(
      stream: Services.orders.watchMyOrders(userId),
      builder: (context, snap) {
        final list = snap.data ?? const <Order>[];
        if (list.isEmpty) return const Center(child: Text('Belum ada riwayat.'));
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final o = list[i];
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
              child: AppBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Agen: ${o.agentName}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text(rupiah(o.totalForClient), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteList() {
    // Ambil dummy agen dari repository
    final agents = Services.requests.nearbyAgents('cleaning'); 
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 16),
      itemCount: agents.length,
      itemBuilder: (_, i) {
        final a = agents[i];
        return AppBox(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              InitialAvatar(name: a.displayName),
              const SizedBox(width: 12),
              Expanded(child: Text(a.displayName, style: const TextStyle(fontWeight: FontWeight.bold))),
              const Icon(Icons.favorite, color: Colors.red),
            ],
          ),
        );
      },
    );
  }
}