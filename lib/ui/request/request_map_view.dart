import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/utils/geo.dart';

/// Peta di tab Request: agen di sekitar (foto profil) dan request aktifmu (ikon kategori).
/// Ketuk penanda untuk melihat ringkasannya.
class RequestMapView extends StatefulWidget {
  const RequestMapView({super.key});
  @override
  State<RequestMapView> createState() => _RequestMapViewState();
}

class _RequestMapViewState extends State<RequestMapView> {
  String? _agent, _req;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final agents = s.searchAgents(maxDist: 15, sort: 'jarak');
    final reqs = s.myReqs.where((r) => const ['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status)).toList();
    final pa = agents.where((a) => a.id == _agent).firstOrNull;
    final pr = reqs.where((r) => r.id == _req).firstOrNull;
    return Stack(children: [
      Positioned.fill(
        child: AppMap(
          height: double.infinity,
          framed: false,
          pin: kMapCenter,
          fitKey: '${agents.length}-${reqs.length}',
          onBackgroundTap: (_) => setState(() => _agent = _req = null),
          marks: [
            for (final a in agents)
              MapMark.agent(a.pos, online: a.online, selected: a.id == _agent, imageUrl: a.avatarUrl, onTap: () => setState(() {
                    _agent = a.id;
                    _req = null;
                  })),
            for (final r in reqs)
              MapMark(
                LatLng(r.lat, r.lng),
                GestureDetector(
                  onTap: () => setState(() {
                    _req = r.id;
                    _agent = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: cW, shape: BoxShape.circle, border: Border.all(color: kGreen, width: r.id == _req ? 3.5 : 2.5)),
                    child: CatIcon(catOf(r.cat), size: 28),
                  ),
                ),
                size: r.id == _req ? 50 : 42,
              ),
          ],
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: kBarSpace + 40, // di atas tombol Daftar
        child: pa != null
            ? AgentCard(pa, wide: true)
            : pr != null
                ? SoftCard(
                    radius: 22,
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReqDetailPage(pr.id))),
                    child: Row(children: [
                      CatIcon(catOf(pr.cat), size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(pr.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Tag(reqLabels[pr.status] ?? pr.status, filled: true),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(16)),
                    child: Text('${agents.length} agen di sekitar \u00b7 ${reqs.length} request aktif', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: g700)),
                  ),
      ),
    ]);
  }
}
