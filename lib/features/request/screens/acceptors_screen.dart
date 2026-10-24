import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/acceptance.dart';
import '../../../data/models/job_request.dart';
import '../../../data/models/message.dart';
import '../../chat/screens/chat_screen.dart';
import '../../payment/screens/payment_screen.dart';

class AcceptorsScreen extends StatelessWidget {
  final String requestId;
  const AcceptorsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agen yang Tertarik')),
      body: StreamBuilder<JobRequest?>(
        stream: Services.requests.watchRequest(requestId),
        builder: (context, reqSnap) {
          final req = reqSnap.data;
          if (req == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              AppBox(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(req.description,
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Penawaran: ${rupiah(req.offeredPrice)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _StatusChip(status: req.status),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Kuota ACC maksimal ${req.acceptQuota} agen. Pilih salah satu untuk lanjut ke pembayaran.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Acceptance>>(
                  stream: Services.requests.watchAcceptances(requestId),
                  builder: (context, accSnap) {
                    final accs = (accSnap.data ?? [])
                        .where((a) => a.status == AcceptanceStatus.accepted)
                        .toList();
                    if (accs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Menunggu agen menyetujui request Anda…\nBiasanya 5–15 detik di mode demo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: accs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = accs[i];
                        return AppBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InitialAvatar(name: a.agentName, size: 40),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.agentName,
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(
                                          '⭐ ${a.agentRating.toStringAsFixed(1)} · ${a.agentJobsCompleted} job · ${a.agentDistanceKm.toStringAsFixed(1)} km',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(rupiah(a.proposedPrice),
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        final chatId = 'chat_order_${requestId}_${a.agentId}';
                                        final user = Services.auth.currentUser!;
                                        Services.chats.getOrCreateOrderChat(
                                          chatId: chatId,
                                          requestId: requestId,
                                          title: req.title,
                                          participants: [user.id, a.agentId],
                                        );
                                        Services.simulator.greetIfNeeded(
                                          chatId: chatId,
                                          requestId: requestId,
                                          acceptance: a,
                                          clientId: user.id,
                                        );
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              chatId: chatId,
                                              title: a.agentName,
                                              agentId: a.agentId,
                                              agentName: a.agentName,
                                              requestId: requestId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Chat'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () async {
                                        // 1. Set agen ini jadi terpilih
                                        await Services.requests.updateAcceptance(a.copyWith(status: AcceptanceStatus.selected));
                                        
                                        // 2. Batalkan agen lain & kirim pesan sistem
                                        final allAccs = Services.requests.getAcceptances(req.id);
                                        for (var other in allAccs) {
                                          if (other.id != a.id && other.status == AcceptanceStatus.accepted) {
                                            final otherChatId = 'chat_order_${req.id}_${other.agentId}';
                                            Services.chats.sendMessage(ChatMessage(
                                              id: 'sys_${DateTime.now().microsecondsSinceEpoch}',
                                              chatId: otherChatId, senderId: 'system', senderName: 'Sistem',
                                              type: MessageType.system, body: 'Maaf, klien telah memilih agen lain. Request ditutup.',
                                              createdAt: DateTime.now(),
                                            ));
                                            Services.requests.updateAcceptance(other.copyWith(status: AcceptanceStatus.declined));
                                          }
                                        }

                                        if (!context.mounted) return;
                                        // Lanjut ke pembayaran
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => PaymentScreen(request: req, acceptance: a),
                                        ));
                                      },
                                      child: const Text('Pilih'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RequestStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w700)),
    );
  }
}