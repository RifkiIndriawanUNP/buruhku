import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/acceptance.dart';
import '../../../data/models/job_request.dart';
import '../../chat/screens/chat_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser!;
    // All requests currently open (simulate as incoming)
    final incoming = Services.requests.publicRequestsSnapshot
        .where((r) =>
            r.clientId != user.id &&
            (r.status == RequestStatus.open ||
                r.status == RequestStatus.hasAcceptors))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Agen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppBox(
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Status: Siap Kerja',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _online,
                  onChanged: (v) => setState(() => _online = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pendapatan hari ini',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(rupiah(0),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: AppBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rating',
                          style:
                              TextStyle(fontSize: 11, color: Colors.black54)),
                      SizedBox(height: 4),
                      Text('5.0',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Request Masuk',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (incoming.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Belum ada request masuk saat ini.',
                    style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            ...incoming.map((r) => _IncomingCard(request: r, agentId: 'demo_agent')),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final JobRequest request;
  final String agentId;
  const _IncomingCard({required this.request, required this.agentId});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser!;
    final acceptances = Services.requests.getAcceptances(request.id);
    final alreadyAccepted = acceptances.any((a) => a.agentId == agentId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(request.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(request.priceType.label,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(request.address,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(rupiah(request.offeredPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                if (!alreadyAccepted)
                  FilledButton(
                    onPressed: () async {
                      final acc = Acceptance(
                        id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
                        requestId: request.id,
                        agentId: agentId,
                        agentName: user.fullName,
                        agentRating: 5.0,
                        agentJobsCompleted: 0,
                        agentDistanceKm: 0,
                        proposedPrice: request.offeredPrice,
                        acceptedAt: DateTime.now(),
                      );
                      Services.requests.internalAddAcceptance(acc);
                      final chatId = 'chat_order_${request.id}_$agentId';
                      Services.chats.getOrCreateOrderChat(
                        chatId: chatId,
                        requestId: request.id,
                        title: request.title,
                        participants: [user.id, request.clientId],
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            title: request.title,
                            agentId: request.clientId,
                            agentName: request.clientId,
                            requestId: request.id,
                          ),
                        ),
                      );
                    },
                    child: const Text('ACC'),
                  )
                else
                  const Text('Sudah ACC',
                      style: TextStyle(color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}