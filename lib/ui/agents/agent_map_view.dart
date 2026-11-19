import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/utils/geo.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/core/theme.dart';

/// Peta layar penuh berisi agen hasil filter. Ketuk marker untuk melihat ringkasan agen.
/// Lingkaran menunjukkan jarak maksimum dari filter.
class AgentMapView extends StatefulWidget {
  final List<Agent> agents;
  final double radiusKm;
  const AgentMapView({required this.agents, required this.radiusKm, super.key});
  @override
  State<AgentMapView> createState() => _AgentMapViewState();
}

class _AgentMapViewState extends State<AgentMapView> {
  String? sel;

  @override
  Widget build(BuildContext context) {
    final l = widget.agents;
    final picked = l.where((a) => a.id == sel).firstOrNull;
    return Stack(children: [
      Positioned.fill(
        child: AppMap(
          height: double.infinity,
          framed: false,
          pin: kMapCenter,
          circleCenter: kMapCenter,
          radiusKm: widget.radiusKm,
          fitKey: '${l.length}-${widget.radiusKm}',
          onBackgroundTap: (_) => setState(() => sel = null),
          marks: [
            for (final a in l) MapMark.agent(a.pos, online: a.online, selected: a.id == sel, imageUrl: a.avatarUrl, onTap: () => setState(() => sel = a.id)),
          ],
        ),
      ),
      // Card agen: di bawah tab bar atas
if (picked != null)
  Positioned(
    top: 145,
    left: 12,
    right: 12,
    child: AgentCard(
      picked,
      wide: true,
    ),
  ),

    // Informasi jumlah agen: tetap di bawah
    if (picked == null)
      Positioned(
        top: 145,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: cW,
              border: Border.all(color: g300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l.isEmpty
                  ? 'Tidak ada agen yang cocok dengan filter.'
                  : '${l.length} agen dalam ${widget.radiusKm.toInt()} km.',
              style: TextStyle(
                fontSize: 13,
                color: g700,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
