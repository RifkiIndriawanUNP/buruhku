
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agents/agent_list_view_model.dart';
import 'package:buruhku/ui/agents/agent_map_view.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

class AgentListPage extends StatefulWidget {
  final String? cat;
  final String title;
  final String sort;

  const AgentListPage({
    this.cat,
    required this.title,
    this.sort = 'relevansi',
    super.key,
  });

  @override
  State<AgentListPage> createState() => _AgentListPageState();
}

class _AgentListPageState extends State<AgentListPage> {
  late final AgentListViewModel vm = AgentListViewModel(
    store: context.read<AppState>(),
    cat: widget.cat,
    sort: widget.sort,
  );

  bool _map = false;
  bool _fabExt = true;
  int _tab = 0; // 0 = agen, 1 = jasa

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final l = vm.agents;

    return AppScaffold(
      appBar: PageBar(
        title: Text(widget.title),
        actions: [
          if (_tab == 0)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () => sheet(
                context,
                (_) => ListenableBuilder(
                  listenable: vm,
                  builder: (ctx, _) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter dan urutkan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text('Jarak maksimum'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final d in [1.0, 3.0, 5.0, 10.0, 15.0])
                                ChoiceChip(
                                  label: Text('${d.toInt()} km'),
                                  selected: vm.maxDist == d,
                                  onSelected: (_) => vm.maxDist = d,
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Text('Rating minimum'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final d in [0.0, 3.5, 4.0, 4.5])
                                ChoiceChip(
                                  label: Text(d == 0 ? 'Semua' : '$d+'),
                                  selected: vm.minRating == d,
                                  onSelected: (_) => vm.minRating = d,
                                ),
                            ],
                          ),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hanya terverifikasi'),
                            value: vm.verified,
                            onChanged: (v) => vm.verified = v,
                          ),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hanya yang online'),
                            value: vm.online,
                            onChanged: (v) => vm.online = v,
                          ),

                          const Text('Urutkan'),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final e in {
                                'relevansi': 'Relevansi',
                                'jarak': 'Terdekat',
                                'rating': 'Rating',
                                'populer': 'Terpopuler',
                                'harga': 'Termurah',
                              }.entries)
                                ChoiceChip(
                                  label: Text(e.value),
                                  selected: vm.sort == e.key,
                                  onSelected: (_) => vm.sort = e.key,
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          full(
                            pbtn(
                              'Terapkan',
                              () => Navigator.pop(ctx),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),

      body: ScrollFabListener(
        onExtended: (v) {
          if (v != _fabExt) {
            setState(() => _fabExt = v);
          }
        },
        child: Stack(
          children: [
            Column(
              children: [
                if (widget.cat != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: PillTabs(
                      labels: const ['Agen', 'Jasa'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ),

                Expanded(
                  child: _tab == 1
                      ? _services(context)
                      : _map
                          ? AgentMapView(
                              agents: l,
                              radiusKm: vm.maxDist,
                            )
                          : l.isEmpty
                              ? const Empty(
                                  Icons.search_off,
                                  'Tidak ada agen yang cocok. Longgarkan filter atau buat request agar agen yang menghubungimu.',
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    kBarSpace,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent:
                                        AgentCard.gridExtent(context),
                                  ),
                                  itemCount: l.length,
                                  itemBuilder: (_, i) => AgentCard(l[i]),
                                ),
                ),
              ],
            ),

            // Toggle daftar / peta
            if (_tab == 0)
              Positioned(
                right: 16,
                bottom: 12,
                child: ScrollFab(
                  icon: _map
                      ? Icons.view_agenda_outlined
                      : Icons.map_outlined,
                  label: _map ? 'Daftar' : 'Peta',
                  extended: _map || _fabExt,
                  onTap: () => setState(() {
                    _map = !_map;
                    _fabExt = true;
                  }),
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: full(
            pbtn(
              'Buat request ${widget.cat == null ? 'jasa' : catOf(widget.cat!).name}',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestFormPage(cat: widget.cat),
                ),
              ),
              icon: Icons.edit_note,
            ),
          ),
        ),
      ),
    );
  }

  Widget _services(BuildContext context) {
    final l = context.s.svcsNear(cat: widget.cat);

    if (l.isEmpty) {
      return const Empty(
        Icons.storefront_outlined,
        'Belum ada tawaran jasa di kategori ini. Buat request agar agen yang menghubungimu.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, kBarSpace),
      children: [
        for (final v in l) ServiceTile(v),
      ],
    );
  }
}
