import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agents/agent_detail_screen.dart';

class AgentCard extends StatelessWidget {
  final Agent a;
  const AgentCard(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return SizedBox(
      width: 148,
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Avatar(size: 40), const Spacer(), if (a.verified) const Icon(Icons.verified_outlined, size: 18)]),
          const SizedBox(height: 8),
          Text(a.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(children: [const Icon(Icons.star, size: 14), Text(' ${s.ratingOf(a).toStringAsFixed(1)}', style: const TextStyle(fontSize: 12)), Text(' (${a.jobs})', style: const TextStyle(fontSize: 11, color: g500))]),
          Text('~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 12, color: g500)),
          const Spacer(),
          Text(a.cats.map((c) => catOf(c).name.split(' ').first).take(2).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: g700)),
        ]),
      ),
    );
  }
}

class AgentTile extends StatelessWidget {
  final Agent a;
  const AgentTile(this.a, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(a.id))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Avatar(size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(a.short, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                const SizedBox(width: 6),
                if (a.verified) const Tag('Terverifikasi', icon: Icons.verified_outlined),
              ]),
              const SizedBox(height: 4),
              Row(children: [Stars(s.ratingOf(a)), Text('  ${s.ratingOf(a).toStringAsFixed(1)}  ${a.jobs} job', style: const TextStyle(fontSize: 12, color: g700))]),
              const SizedBox(height: 4),
              Text('${a.online ? 'Online' : 'Offline'}  |  ~${a.dist.toStringAsFixed(1)} km  |  mulai ${rp(a.base)}', style: const TextStyle(fontSize: 12, color: g500)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, children: [for (final c in a.cats) Tag(catOf(c).name)]),
            ]),
          ),
          IconButton(
            onPressed: () => context.r.toggleFav(a.id),
            icon: Icon(s.favs.contains(a.id) ? Icons.favorite : Icons.favorite_border),
          ),
        ]),
      ),
    );
  }
}
