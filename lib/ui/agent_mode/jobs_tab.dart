import 'package:flutter/material.dart';
import 'package:buruhku/ui/agent_mode/agent_jobs_view_model.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/order/order_screen.dart';
import 'incoming_tab.dart';

class JobsTab extends StatelessWidget {
  const JobsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final vm = AgentJobsViewModel(s);
    final act = vm.active;
    final his = vm.history;
    final waiting = vm.waitingForClient;
    final activeCount = act.length + waiting.length;

    return DefaultTabController(
      length: 2,
      child: FloatHeader(
        height: 104,
        header: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Text('Pekerjaanku', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: g900)),
                  const Spacer(),
                  if (activeCount > 0) Tag('$activeCount aktif', icon: Icons.work_outline, filled: true),
                ],
              ),
            ),
            PillTabBar([
              'Aktif${activeCount > 0 ? ' ($activeCount)' : ''}',
              'Selesai${his.isNotEmpty ? ' (${his.length})' : ''}',
            ]),
          ],
        ),
        builder: (inset) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.25,
          child: TabBarView(
            children: [
              (act.isEmpty && waiting.isEmpty)
                  ? Padding(
                      padding: EdgeInsets.only(top: inset),
                      child: const Empty(Icons.work_outline, 'Belum ada pekerjaan aktif.'),
                    )
                  : RevealListView(
                      padding: padBelow(inset),
                      children: [
                        if (waiting.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: g700),
                                const SizedBox(width: 6),
                                Text('Menunggu Klien (${waiting.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: g900)),
                              ],
                            ),
                          ),
                          for (final r in waiting)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SoftCard(
                                radius: 20,
                                padding: const EdgeInsets.all(14),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingDetailPage(r.id))),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A12B).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFF5A12B), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: g900)),
                                          const SizedBox(height: 2),
                                          Text('${r.clientName} \u2022 ${rp(r.price)}', style: TextStyle(fontSize: 12, color: g500)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Tag('ACC terkirim'),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                        for (final o in act) OrderTile(o),
                      ],
                    ),
              his.isEmpty
                  ? Padding(
                      padding: EdgeInsets.only(top: inset),
                      child: const Empty(Icons.history, 'Belum ada riwayat selesai.'),
                    )
                  : RevealListView(
                      padding: padBelow(inset),
                      children: [for (final o in his) OrderTile(o)],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}