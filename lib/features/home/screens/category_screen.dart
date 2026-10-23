import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import 'agent_profile_screen.dart';

class CategoryScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final agents = Services.requests.nearbyAgents(categoryId,
        lat: Env.demoLat, lng: Env.demoLng);
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: agents.isEmpty
          ? const Center(child: Text('Belum ada agen untuk kategori ini'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: agents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = agents[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AgentProfileScreen(agent: a),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: AppBox(
                    child: Row(
                      children: [
                        InitialAvatar(name: a.displayName, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(a.displayName,
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  if (a.verified)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.verified, size: 14, color: Colors.blue),
                                    ),
                                ],
                              ),
                              Text(
                                '⭐ ${a.ratingAvg.toStringAsFixed(1)} · ${a.jobsCompleted} job · ${a.distanceFrom(Env.demoLat, Env.demoLng).toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              if (a.bio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(a.bio,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}