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

/// Kotak cari beranda terbang ke atas (Hero); halamannya baru muncul (fade) setelah kotak sampai.
const _homeSearchHero = 'home-search';

/// Geser tulisan kolom cari ke atas (negatif) atau ke bawah (positif) dalam piksel. Default -4: mengoreksi teks yang terukur turun sekitar 4 piksel dari tengah ikon.
const double _searchTextDy = -4;

PageRouteBuilder<void> _searchRoute(Widget page) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)), child: child),
    );

Widget _boxShuttle(BuildContext _, Animation<double> __, HeroFlightDirection ___, BuildContext ____, BuildContext _____) => Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
        child: Row(children: const [
          SizedBox(width: 48, child: Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.search, size: 28, color: g900)))),
          Expanded(child: Text('Cari jasa atau agen (contoh. Setrika baju)', maxLines: 1, overflow: TextOverflow.clip, style: TextStyle(fontSize: 14, color: g500, decoration: TextDecoration.none, fontWeight: FontWeight.w400))),
        ]),
      ),
    );

/// Halaman pencarian penuh dari beranda: tombol kembali + kolom cari sebaris. Kirim -> hasil di [SearchPage].
class _HomeSearchPage extends StatefulWidget {
  const _HomeSearchPage();
  @override
  State<_HomeSearchPage> createState() => _HomeSearchPageState();
}

class _HomeSearchPageState extends State<_HomeSearchPage> {
  final q = TextEditingController();
  final _f = FocusNode();
  bool _armed = false;

  /// Fokus (keyboard) baru muncul setelah animasi masuk selesai.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_armed) return;
    _armed = true;
    final a = ModalRoute.of(context)?.animation;
    if (a == null || a.isCompleted) {
      _f.requestFocus();
      return;
    }
    void l(AnimationStatus st) {
      if (st != AnimationStatus.completed) return;
      a.removeStatusListener(l);
      if (mounted) _f.requestFocus();
    }
    a.addStatusListener(l);
  }

  @override
  void dispose() {
    q.dispose();
    _f.dispose();
    super.dispose();
  }

  void _go(String v) {
    if (v.trim().isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(v.trim())));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            RoundBtn(size: 52, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
            const SizedBox(width: 8),
            Expanded(
              child: Hero(
                tag: _homeSearchHero,
                flightShuttleBuilder: _boxShuttle,
                createRectTween: (b, e) => RectTween(begin: b, end: e),
                child: Container(
                  height: 52, // sama dengan tombol kembali
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                  child: Stack(children: [
                    // ikon: kotak 28 di tengah tinggi 52
                    const Positioned(left: 12, top: 12, child: Icon(Icons.search, size: 28, color: g900)),
                    // tulisan: area setinggi kotak (52), teks di tengah-tengahnya. Geser dengan _searchTextDy.
                    Positioned(
                      left: 52,
                      right: 16,
                      top: _searchTextDy,
                      height: 52,
                      child: TextField(
                        controller: q,
                        focusNode: _f,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 15, height: 1.0, color: g900),
                        strutStyle: const StrutStyle(fontSize: 15, height: 1.0, forceStrutHeight: true),
                        onSubmitted: _go,
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Cari jasa atau agen (contoh. Setrika baju)',
                          hintStyle: TextStyle(fontSize: 14, height: 1.0, color: g500),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

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
              const Text('Location', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final v = await askText(context, 'Lokasi aktif', hint: 'Alamat atau patokan');
                  if (v != null && v.isNotEmpty) {
                    vm.setAddress(v);
                  }
                },
                child: Row(children: [
                  const Icon(Icons.location_on_outlined, size: 24, color: g500),
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
        padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 0),
        child: SoftCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          onTap: () => vm.switchToAgentMode(),
          child: const Row(children: [
            Icon(Icons.swap_horiz, color: g900),
            SizedBox(width: 8),
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
      child: Hero(
        tag: _homeSearchHero,
        flightShuttleBuilder: _boxShuttle,
        createRectTween: (b, e) => RectTween(begin: b, end: e),
        child: TextField(
        controller: q,
        readOnly: true, // hanya pemicu: mengetuk menerbangkan kotak ke atas, lalu membuka halaman pencarian
        showCursor: false,
        onTap: () => Navigator.push(context, _searchRoute(const _HomeSearchPage())),
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Icons.search, size: 28, color: g900),
          ),
          hintText: 'Cari jasa atau agen (contoh. Setrika baju)',
          hintStyle: TextStyle(fontSize: 14, color: g500),
          border: none,
          enabledBorder: none,
          focusedBorder: none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      )),
    );
  }

  // ------------------------------------------------------------ kategori (baris x 4 kolom, tinggi mengikuti isi)
  Widget _categories(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < cats.length; i += 4) {
      final chunk = cats.skip(i).take(4).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 12),
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