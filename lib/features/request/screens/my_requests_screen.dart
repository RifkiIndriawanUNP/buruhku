import 'package:flutter/material.dart';
import '../../../app/services.dart';
import '../../../core/utils/rupiah.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/job_request.dart';
import 'acceptors_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Request Saya')),
      body: StreamBuilder<List<JobRequest>>(
        stream: Services.requests.watchMyRequests(user.id),
        builder: (context, snap) {
          final list = snap.data ?? const <JobRequest>[];
          final active = list
              .where((r) => r.status != RequestStatus.completed &&
                  r.status != RequestStatus.cancelled &&
                  r.status != RequestStatus.expired)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (active.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada request aktif.\nTekan tombol + di bawah untuk membuat request jasa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = active[i];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AcceptorsScreen(requestId: r.id),
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
                            child: Text(r.title,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          _Badge(status: r.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${rupiah(r.offeredPrice)} · ${r.priceType.label}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
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

class _Badge extends StatelessWidget {
  final RequestStatus status;
  const _Badge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case RequestStatus.open:
      case RequestStatus.hasAcceptors:
        c = Colors.blue;
        break;
      case RequestStatus.negotiating:
        c = Colors.orange;
        break;
      case RequestStatus.agreed:
        c = Colors.purple;
        break;
      case RequestStatus.paidEscrow:
      case RequestStatus.inProgress:
        c = Colors.teal;
        break;
      case RequestStatus.completed:
        c = Colors.green;
        break;
      default:
        c = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label,
          style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
    );
  }
}