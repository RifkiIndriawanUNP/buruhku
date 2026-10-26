import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'account.dart';
import 'agent.dart';
import 'chat.dart';
import 'order.dart';
import 'request.dart';
import 'service.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final n = s.toastNote;
    if (n != null) {
      s.toastNote = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('${n.title}\n${n.body}', maxLines: 3, overflow: TextOverflow.ellipsis),
              action: SnackBarAction(label: 'Lihat', textColor: cW, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifPage())))));
      });
    }
    final agent = s.agentMode;
    final items = agent
        ? [const BarItem(Icons.inbox_outlined, 'Masuk'), const BarItem(Icons.work_outline, 'Pekerjaanku'), BarItem(Icons.chat_bubble_outline, 'Pesan', s.unreadChats), const BarItem(Icons.account_balance_wallet_outlined, 'Pendapatan'), const BarItem(Icons.person_outline, 'Akun')]
        : [const BarItem(Icons.home_outlined, 'Beranda'), const BarItem(Icons.event_note_outlined, 'Aktivitas'), const BarItem(Icons.add, 'Request'), BarItem(Icons.chat_bubble_outline, 'Pesan', s.unreadChats), const BarItem(Icons.person_outline, 'Akun')];
    final pages = agent
        ? const [IncomingTab(), JobsTab(), ChatsTab(), EarningsTab(), AccountTab()]
        : const [HomeTab(), HistoryTab(), MyRequestsTab(), ChatsTab(), AccountTab()];
    final i = s.tab.clamp(0, 4).toInt();
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: i, children: pages)),
      bottomNavigationBar: BottomBar(index: i, items: items, center: agent ? null : 2, onTap: (v) => context.r.goTab(v)),
    );
  }
}

// ---------------------------------------------------------------- Beranda
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final q = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final near = s.searchAgents(sort: 'jarak').take(8).toList();
    final pop = [...s.agents]..sort((a, b) => b.jobs.compareTo(a.jobs));
    final svcs = s.svcsNear().take(8).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final v = await askText(context, 'Lokasi aktif', hint: 'Alamat atau patokan');
              if (v != null && v.isNotEmpty) {
                s.address = v;
                s.notifyListeners();
              }
            },
            child: Row(children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 6),
              Expanded(child: Text(s.address.isEmpty ? 'Atur lokasi' : s.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.expand_more),
            ]),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifPage())),
          icon: Badge(isLabelVisible: s.unreadNotes > 0, label: Text('${s.unreadNotes}'), backgroundColor: g900, child: const Icon(Icons.notifications_none)),
        ),
      ]),
      if (s.kyc.status == 'approved') ...[
        const SizedBox(height: 6),
        Box(
          onTap: () => s.setMode(true),
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
      _hList(context, pop.take(8).toList()),
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

// ---------------------------------------------------------------- daftar agen + filter
class AgentListPage extends StatefulWidget {
  final String? cat;
  final String title;
  final String sort;
  const AgentListPage({this.cat, required this.title, this.sort = 'relevansi', super.key});
  @override
  State<AgentListPage> createState() => _AgentListPageState();
}

class _AgentListPageState extends State<AgentListPage> {
  double dist = 15, minR = 0;
  bool verified = false, online = false;
  late String sort = widget.sort;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = s.searchAgents(cat: widget.cat, maxDist: dist, minRating: minR, verified: verified, online: online, sort: sort);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => sheet(context, (_) => StatefulBuilder(builder: (ctx, set) {
                void u(VoidCallback f) {
                  set(f);
                  setState(f);
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Filter dan urutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Text('Jarak maksimum'),
                    Wrap(spacing: 8, children: [for (final d in [1.0, 3.0, 5.0, 10.0, 15.0]) ChoiceChip(label: Text('${d.toInt()} km'), selected: dist == d, onSelected: (_) => u(() => dist = d))]),
                    const SizedBox(height: 8),
                    const Text('Rating minimum'),
                    Wrap(spacing: 8, children: [for (final d in [0.0, 3.5, 4.0, 4.5]) ChoiceChip(label: Text(d == 0 ? 'Semua' : '$d+'), selected: minR == d, onSelected: (_) => u(() => minR = d))]),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hanya terverifikasi'), value: verified, onChanged: (v) => u(() => verified = v)),
                    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hanya yang online'), value: online, onChanged: (v) => u(() => online = v)),
                    const Text('Urutkan'),
                    Wrap(spacing: 8, children: [for (final e in {'relevansi': 'Relevansi', 'jarak': 'Terdekat', 'rating': 'Rating', 'harga': 'Termurah'}.entries) ChoiceChip(label: Text(e.value), selected: sort == e.key, onSelected: (_) => u(() => sort = e.key))]),
                    const SizedBox(height: 16),
                    full(pbtn('Terapkan', () => Navigator.pop(ctx))),
                  ]),
                );
              })),
        ),
      ]),
      body: l.isEmpty
          ? const Empty(Icons.search_off, 'Tidak ada agen yang cocok. Longgarkan filter atau buat request agar agen yang menghubungimu.')
          : ListView(padding: const EdgeInsets.all(16), children: [for (final a in l) AgentTile(a)]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: full(pbtn('Buat request ${widget.cat == null ? 'jasa' : catOf(widget.cat!).name}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(cat: widget.cat))), icon: Icons.edit_note)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- pencarian
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
        appBar: AppBar(title: Text('"$q"'), bottom: const TabBar(tabs: [Tab(text: 'Jasa'), Tab(text: 'Agen')])),
        body: TabBarView(children: [
          ListView(padding: const EdgeInsets.all(16), children: [
            for (final c in cs)
              ListTile(leading: Icon(c.icon), title: Text(c.name), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentListPage(cat: c.id, title: c.name)))),
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
          ag.isEmpty ? const Empty(Icons.person_search, 'Agen tidak ditemukan.') : ListView(padding: const EdgeInsets.all(16), children: [for (final a in ag) AgentTile(a)]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- detail agen
class AgentDetail extends StatelessWidget {
  final String id;
  const AgentDetail(this.id, {super.key});

  Future<void> _chat(BuildContext context, Agent a, {bool offer = false}) async {
    final s = context.r;
    final ch = s.chatFor(type: 'direct', refId: '', otherId: a.id, otherName: a.short, otherAgent: true);
    if (offer) {
      final ok = await directOfferSheet(context, ch, a);
      if (ok != true || !context.mounted) return;
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final a = s.agentById(id);
    final revs = s.reviewsOf(a.id);
    final lvl = {1: 'L1 Baru', 2: 'L2 Terpercaya', 3: 'L3 Premium'}[a.level]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil agen'), actions: [
        IconButton(onPressed: () => s.toggleFav(a.id), icon: Icon(s.favs.contains(a.id) ? Icons.favorite : Icons.favorite_border)),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: a.short, targetId: a.id))), icon: const Icon(Icons.flag_outlined)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          const Avatar(size: 76),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.short, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [Stars(s.ratingOf(a), size: 16), Text('  ${s.ratingOf(a).toStringAsFixed(1)}')]),
            Text('${a.jobs} pekerjaan selesai  |  ~${a.dist.toStringAsFixed(1)} km', style: const TextStyle(color: g500, fontSize: 12.5)),
          ])),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (a.verified) const Tag('Terverifikasi', icon: Icons.verified_outlined, filled: true),
          Tag(lvl, icon: Icons.shield_outlined),
          if (a.jobs >= 50 && a.rating >= 4.7) const Tag('Terpercaya', icon: Icons.workspace_premium_outlined),
          if (a.rating >= 4.5) const Tag('Tepat waktu', icon: Icons.schedule),
          Tag(a.online ? 'Online' : 'Offline', icon: Icons.circle_outlined),
        ]),
        const Section('Tentang'),
        Text(a.bio, style: const TextStyle(height: 1.4)),
        const SizedBox(height: 8),
        Kv('Area layanan', 'Sekitar ~${a.dist.toStringAsFixed(0)} km dari lokasimu'),
        Kv('Tarif mulai', '${rp(a.base)} per pekerjaan kecil'),
        const Section('Keahlian'),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final c in a.cats) Tag(catOf(c).name, icon: catOf(c).icon)]),
        if (s.svcsOfAgent(a.id).isNotEmpty) ...[
          const Section('Tawaran jasa'),
          for (final v in s.svcsOfAgent(a.id)) ServiceTile(v),
        ],
        const Section('Portofolio'),
        const Row(children: [Expanded(child: Ph(h: 80)), SizedBox(width: 8), Expanded(child: Ph(h: 80)), SizedBox(width: 8), Expanded(child: Ph(h: 80))]),
        Section('Ulasan (${revs.length})'),
        if (revs.isEmpty) const Text('Belum ada ulasan.', style: TextStyle(color: g500)),
        for (final v in revs.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(v.from, style: const TextStyle(fontWeight: FontWeight.w600)), const Spacer(), Stars(v.rating.toDouble(), size: 13)]),
              if (v.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Wrap(spacing: 4, children: [for (final t in v.tags) Tag(t)])),
              const SizedBox(height: 4),
              Text(v.comment),
              Text(ago(v.at), style: const TextStyle(fontSize: 11, color: g500)),
            ])),
          ),
        const SizedBox(height: 70),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: !a.direct
              ? const Warn('Agen ini tidak menerima chat langsung. Buat request agar agen bisa ACC.', icon: Icons.chat_bubble_outline)
              : Row(children: [
                  Expanded(child: obtn('Chat langsung', () => _chat(context, a), icon: Icons.chat_bubble_outline)),
                  const SizedBox(width: 10),
                  Expanded(child: pbtn('Order langsung', () => _chat(context, a, offer: true), icon: Icons.assignment_outlined)),
                ]),
        ),
      ),
    );
  }
}
