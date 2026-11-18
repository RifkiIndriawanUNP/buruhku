import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/account/account_screen.dart';
import 'package:buruhku/ui/agents/agent_list_screen.dart';
import 'package:buruhku/ui/agents/agent_widgets.dart';
import 'package:buruhku/ui/home/home_view_model.dart';
import 'package:buruhku/ui/search/search_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

const _hPad = 16.0;

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
    final w = MediaQuery.sizeOf(context).width;
    final svcW = (w * .564).clamp(200.0, 260.0).toDouble();
    final agentW = ((w - _hPad * 2 - 8) / 2).clamp(150.0, 220.0).toDouble();

    final list = ListView(padding: const EdgeInsets.only(top: 12), children: [
      _header(context),
      if (vm.canSwitchToAgent) _agentSwitch(),
      const SizedBox(height: 16),
      _search(context),
      const _Head('Kategori jasa'),
      _categories(context),
      _Head('Jasa sekitar', onAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceListPage(title: 'Jasa sekitar')))),
      if (svcs.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(horizontal: _hPad), child: Text('Belum ada tawaran jasa di sekitarmu.', style: TextStyle(color: g500)))
      else
        _hScroll([for (final v in svcs) ServiceCard(v, width: svcW)]),
      _Head('Agen terdekat', onAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentListPage(title: 'Agen terdekat', sort: 'jarak')))),
      _hScroll([for (final a in near) AgentCard(a, width: agentW)]),
      _Head('Agen terpopuler', onAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentListPage(title: 'Agen terpopuler', sort: 'populer')))),
      _hScroll([for (final a in pop) AgentCard(a, width: agentW)]),
      const SizedBox(height: kBarSpace),
    ]);

    // Teks dibatasi maksimal 125% supaya tata letak tetap rapi di pengaturan font besar.
    return MediaQuery.withClampedTextScaling(maxScaleFactor: 1.25, child: list);
  }

  // ------------------------------------------------------------ header
  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: _hPad),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Location', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final v = await askText(context, 'Lokasi aktif', hint: 'Alamat atau patokan');
                  if (v != null && v.isNotEmpty) {
                    vm.setAddress(v);
                  }
                },
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, size: 22, color: g500),
                  const SizedBox(width: 6),
                  Expanded(child: Text(vm.address.isEmpty ? 'Atur lokasi' : vm.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: g500))),
                ]),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          RoundBtn(
            size: 52,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifPage())),
            child: Badge(
              isLabelVisible: vm.unreadNotes > 0,
              label: Text('${vm.unreadNotes}'),
              backgroundColor: g900,
              child: const Icon(Icons.notifications, size: 28, color: kGreen),
            ),
          ),
        ]),
      );

  Widget _agentSwitch() => Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 0),
        child: SoftCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => vm.switchToAgentMode(),
          child: const Row(children: [
            Icon(Icons.swap_horiz, color: g900),
            SizedBox(width: 10),
            Expanded(child: Text('Beralih ke mode agen', style: TextStyle(fontWeight: FontWeight.w600, color: g900))),
            Icon(Icons.chevron_right, color: g500),
          ]),
        ),
      );

  // ------------------------------------------------------------ pencarian
  Widget _search(BuildContext context) {
    const none = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28)), borderSide: BorderSide.none);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: TextField(
        controller: q,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, size: 26, color: g900),
          ),
          hintText: 'Cari jasa atau agen (contoh. Setrika baju)',
          hintStyle: TextStyle(fontSize: 14.5, color: g500),
          border: none,
          enabledBorder: none,
          focusedBorder: none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
        onSubmitted: (v) {
          if (v.trim().isEmpty) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(v.trim())));
        },
      ),
    );
  }

  // ------------------------------------------------------------ kategori (baris x 4 kolom, tinggi mengikuti isi)
  Widget _categories(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cats.length; i += 4) {
      final chunk = cats.skip(i).take(4).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var j = 0; j < 4; j++) Expanded(child: j < chunk.length ? _CatItem(chunk[j]) : const SizedBox.shrink()),
        ]),
      ));
    }
    return Padding(padding: const EdgeInsets.symmetric(horizontal: _hPad - 8), child: Column(children: rows));
  }

  // ------------------------------------------------------------ daftar horizontal
  // IntrinsicHeight + stretch: semua kartu setinggi kartu tertinggi, tidak ada tinggi tetap
  // yang bisa overflow. Padding bawah memberi ruang untuk bayangan kartu kaca.
  Widget _hScroll(List<Widget> items) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(_hPad, 4, _hPad, 32),
        child: IntrinsicHeight(
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              items[i],
            ],
          ]),
        ),
      );
}

class _Head extends StatelessWidget {
  final String title;
  final VoidCallback? onAll;
  const _Head(this.title, {this.onAll});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_hPad, 14, _hPad, 12),
        child: Row(children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
          if (onAll != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAll,
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2), child: Text('Lihat semua', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kSeeAll))),
            ),
        ]),
      );
}

class _CatItem extends StatelessWidget {
  final Cat c;
  const _CatItem(this.c);
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bc) {
        final tile = (bc.maxWidth * .68).clamp(48.0, 76.0).toDouble();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentListPage(cat: c.id, title: c.name))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: tile,
                height: tile,
                child: SoftCard(radius: tile * .3, padding: EdgeInsets.zero, child: Center(child: CatIcon(c, size: tile * .62))),
              ),
              const SizedBox(height: 8),
              Text(c.short, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2, color: g900)),
            ]),
          ),
        );
      });
}
