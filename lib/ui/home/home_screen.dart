import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/account/account_screen.dart';
import 'package:buruhku/ui/agents/agent_list_screen.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/home/home_view_model.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/ui/search/search_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

class HomeTab extends StatefulWidget {
  final HomeViewModel viewModel;
  const HomeTab({required this.viewModel, super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final q = TextEditingController();
  HomeViewModel get vm => widget.viewModel;

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final near = vm.nearbyAgents;
    final pop = vm.popularAgents;
    final svcs = vm.nearbyServices;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, kBarSpace), children: [
      Row(children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final v = await askText(context, 'Lokasi aktif', hint: 'Alamat atau patokan');
              if (v != null && v.isNotEmpty) {
                vm.setAddress(v);
              }
            },
            child: Row(children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 6),
              Expanded(child: Text(vm.address.isEmpty ? 'Atur lokasi' : vm.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.expand_more),
            ]),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifPage())),
          icon: Badge(isLabelVisible: vm.unreadNotes > 0, label: Text('${vm.unreadNotes}'), backgroundColor: g900, child: const Icon(Icons.notifications_none)),
        ),
      ]),
      if (vm.canSwitchToAgent) ...[
        const SizedBox(height: 6),
        Box(
          onTap: () => vm.switchToAgentMode(),
          color: g100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: const Row(children: [
            Icon(Icons.swap_horiz),
            SizedBox(width: 10),
            Expanded(child: Text('Beralih ke mode agen', style: TextStyle(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right),
          ]),
        ),
      ],
      const SizedBox(height: 8),
      TextField(
        controller: q, textInputAction: TextInputAction.search,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari jasa atau agen (mis. setrika, genteng)'),
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(v.trim())));
        },
      ),
      const SizedBox(height: 12),
      Box(color: g100, child: Row(children: [
        const Icon(Icons.verified_user_outlined, size: 32),
        const SizedBox(width: 12),
        const Expanded(child: Text('Aman bersama Buruhku\nAgen terverifikasi KTP dan selfie. Dana ditahan escrow sampai pekerjaan selesai.', style: TextStyle(fontSize: 12.5, height: 1.35))),
      ])),
      const SizedBox(height: 12),
      full(pbtn('Buat request jasa', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestFormPage())), icon: Icons.edit_note)),
      const Section('Kategori jasa'),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .82,
        children: [
          for (final c in cats)
            Box(
              padding: const EdgeInsets.all(6),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentListPage(cat: c.id, title: c.name))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(c.icon, size: 28),
                const SizedBox(height: 6),
                Text(c.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5)),
              ]),
            ),
        ],
      ),
      Section('Jasa sekitar', action: 'Lihat semua', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListPage(title: 'Jasa sekitar')))),
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Tawaran jasa dari agen di sekitarmu. Langsung order, tanpa isi form.', style: TextStyle(fontSize: 12.5, color: g500))),
      if (svcs.isEmpty)
        const Text('Belum ada tawaran jasa di sekitarmu.', style: TextStyle(color: g500))
      else
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: svcs.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ServiceCard(svcs[i]),
          ),
        ),
      Section('Agen terdekat', action: 'Lihat semua', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentListPage(title: 'Agen terdekat', sort: 'jarak')))),
      _hList(context, near),
      const Section('Agen terpopuler'),
      _hList(context, pop),
      const SizedBox(height: 24),
    ]);
  }

  Widget _hList(BuildContext c, List<Agent> l) => SizedBox(
        height: 178,
        child: ListView.separated(
          scrollDirection: Axis.horizontal, itemCount: l.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => AgentCard(l[i]),
        ),
      );
}
