import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agents/agent_list_screen.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

class SearchPage extends StatelessWidget {
  final String q;
  const SearchPage(this.q, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ql = q.toLowerCase();
    final cs = cats.where((c) => c.name.toLowerCase().contains(ql)).toList();
    final ts = templates.where((t) => (t['t'] as String).toLowerCase().contains(ql) || (t['d'] as String).toLowerCase().contains(ql)).toList();
    final ag = s.searchAgents(q: q);
    final sv = s.svcsNear(q: q).take(8).toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PageBar(title: Text('"$q"'), bottom: PillTabBar(const ['Jasa', 'Agen'])),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, kBarSpace), children: [
            for (final c in cs)
              ListTile(leading: CatIcon(c, size: 34), title: Text(c.name), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentListPage(cat: c.id, title: c.name)))),
            for (final t in ts)
              ListTile(
                leading: const Icon(Icons.bolt_outlined), title: Text(t['t'] as String), subtitle: const Text('Template order cepat'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(tpl: t))),
              ),
            for (final v in sv) ServiceTile(v),
            if (cs.isEmpty && ts.isEmpty && sv.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Empty(Icons.edit_note, 'Belum ada jasa baku untuk "$q". Tulis sendiri pekerjaannya, agen yang menyesuaikan.',
                    action: pbtn('Buat request', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestFormPage())))),
              ),
          ]),
          ag.isEmpty ? const Empty(Icons.person_search, 'Agen tidak ditemukan.') : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, kBarSpace), children: [for (final a in ag) AgentTile(a)]),
        ]),
      ),
    );
  }
}
