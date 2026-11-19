import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:buruhku/utils/geo.dart';
import 'package:buruhku/ui/account/account_screen.dart';
import 'package:buruhku/ui/agents/agent_detail_screen.dart';
import 'package:buruhku/ui/chat/chat_cards.dart';
import 'package:buruhku/ui/location/location_screen.dart';
import 'package:buruhku/ui/order/order_screen.dart';
import 'package:buruhku/ui/request/request_screen.dart';

String _preview(Msg m) {
  switch (m.type) {
    case 'image':
      return 'Foto';
    case 'location':
      return 'Lokasi';
    case 'offer':
      return 'Penawaran ${rp(m.data['price'] as int)}';
    case 'order_offer':
      return 'Penawaran order';
    case 'contact':
      return 'Kontak WhatsApp';
    case 'ewallet':
      return 'Akun e-wallet';
    default:
      return m.body;
  }
}

Acc? _pickable(Chat c, Req? r) {
  if (r == null || !r.mine || c.type != 'order' || !c.otherAgent) return null;
  if (!['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status) || r.chosen.length >= r.workers) return null;
  for (final a in r.acc) {
    if (a.agentId == c.otherId && a.status == 'accepted') return a;
  }
  return null;
}

/// Daftar chat milik mode aktif, difilter [seg] ('all'/'order'/'direct') dan kata kunci, terbaru di atas.
List<Chat> _chatList(AppState s, String seg, String kw) => s.chats
    .where((c) => c.otherAgent == !s.agentMode && (seg == 'all' || c.type == seg))
    .where((c) => kw.isEmpty || c.otherName.toLowerCase().contains(kw) || c.title.toLowerCase().contains(kw))
    .toList()
  ..sort((a, b) => (b.msgs.isEmpty ? DateTime(2000) : b.msgs.last.at).compareTo(a.msgs.isEmpty ? DateTime(2000) : a.msgs.last.at));

const _searchHero = 'chat-search';

/// Geser tulisan kolom cari ke atas (negatif) atau ke bawah (positif) dalam piksel. Default -4: mengoreksi teks yang terukur turun sekitar 4 piksel dari tengah ikon.
const double _searchTextDy = -4;

/// Transisi tombol cari: bulatan 52 memanjang jadi kolom cari (dan sebaliknya saat kembali).
Widget _searchShuttle(BuildContext _, Animation<double> a, HeroFlightDirection dir, BuildContext __, BuildContext ___) => AnimatedBuilder(
      animation: a,
      builder: (_, __) {
        final t = Curves.easeInOut.transform(dir == HeroFlightDirection.push ? a.value : 1 - a.value);
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          alignment: Alignment.lerp(Alignment.center, Alignment.centerLeft, t),
          padding: EdgeInsets.only(left: 12 * t),
          child: const Icon(Icons.search, size: 28, color: g900),
        );
      },
    );

PageRouteBuilder<void> _fadeRoute(Widget page) => PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});
  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  String seg = 'all';

  String _date(DateTime d) {
    final n = DateTime.now();
    if (d.year == n.year && d.month == n.month && d.day == n.day) return ftime(d);
    return '${two(d.day)}.${two(d.month)}.${two(d.year % 100)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = _chatList(s, seg, '');

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: FloatHeader(
        height: 128,
        header: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Row(children: [
            const Expanded(child: Text('Pesan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
            Hero(
              tag: _searchHero,
              flightShuttleBuilder: _searchShuttle,
              createRectTween: (b, e) => RectTween(begin: b, end: e),
              child: RoundBtn(
                size: 52,
                onTap: () => Navigator.push(context, _fadeRoute(_ChatSearchPage(row: _row))),
                child: const Icon(Icons.search, size: 28, color: g900),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            FilterPill('Semua', selected: seg == 'all', onTap: () => setState(() => seg = 'all')),
            const SizedBox(width: 8),
            FilterPill('Order', selected: seg == 'order', onTap: () => setState(() => seg = 'order')),
            const SizedBox(width: 8),
            FilterPill('Pesan Langsung', selected: seg == 'direct', onTap: () => setState(() => seg = 'direct')),
          ]),
        )),
        ]),
        builder: (inset) => l.isEmpty
            ? Padding(padding: EdgeInsets.only(top: inset), child: Empty(Icons.chat_bubble_outline, seg == 'direct' ? 'Chat langsung dimulai dari profil agen.' : seg == 'order' ? 'Chat negosiasi muncul saat ada agen yang ACC requestmu.' : 'Belum ada percakapan.'))
            : ListView(padding: padBelow(inset, const EdgeInsets.fromLTRB(16, 4, 16, kBarSpace)), children: [
                SoftCard(radius: 28, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Column(children: [for (final c in l) _row(context, c)])),
              ]),
      ),
    );
  }

  /// Foto profil agen kalau lawan chat adalah agen, kalau tidak inisial nama.
  Widget _avatar(BuildContext context, Chat c) {
    if (c.otherAgent) {
      final ag = context.s.agentById(c.otherId);
      if (ag.id == c.otherId && (ag.avatarUrl ?? '').isNotEmpty) return AvatarPh(52, url: ag.avatarUrl);
    }
    return InitialAvatar(c.otherName, size: 52);
  }

  Widget _row(BuildContext context, Chat c) {
    final last = c.msgs.isEmpty ? null : c.msgs.last;
    final preview = last == null ? 'Belum ada pesan' : _preview(last);
    final text = c.type == 'order' && c.title.isNotEmpty ? '${c.title} \u2022 $preview' : preview;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(c.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          _avatar(context, c),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Flexible(child: Text(c.otherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25, color: g900))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD0D1D6))),
                  child: Text(c.type == 'order' ? 'Order' : 'Langsung', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: g700)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.3, color: g500)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            if (last != null)
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (last.from == 'me') ...[const Icon(Icons.done_all, size: 16, color: kGreen), const SizedBox(width: 4)],
                Text(_date(last.at), style: const TextStyle(fontSize: 13, height: 1.2, color: g500)),
              ]),
            if (c.unread > 0) ...[
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)),
                child: Text('${c.unread}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1)),
              ),
            ] else if (c.closed) ...[
              const SizedBox(height: 4),
              const Icon(Icons.lock_outline, size: 14, color: g500),
            ],
          ]),
        ]),
      ),
    );
  }
}

/// Halaman pencarian chat penuh: kolom cari (hasil transisi dari tombol bulat) + hasil langsung saat mengetik.
class _ChatSearchPage extends StatefulWidget {
  final Widget Function(BuildContext, Chat) row;
  const _ChatSearchPage({required this.row});
  @override
  State<_ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<_ChatSearchPage> {
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

  @override
  Widget build(BuildContext context) {
    final kw = q.text.trim().toLowerCase();
    final l = kw.isEmpty ? <Chat>[] : _chatList(context.s, 'all', kw);
    return AppScaffold(
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            RoundBtn(size: 52, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
            const SizedBox(width: 8),
            Expanded(
              child: Hero(
                tag: _searchHero,
                flightShuttleBuilder: _searchShuttle,
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
                        onChanged: (_) => setState(() {}),
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
                          hintText: 'Cari nama atau judul pekerjaan',
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
        Expanded(
          child: kw.isEmpty
              ? const Empty(Icons.search, 'Ketik nama atau judul pekerjaan untuk mencari percakapan.')
              : l.isEmpty
                  ? const Empty(Icons.chat_bubble_outline, 'Tidak ada percakapan yang cocok.')
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                      SoftCard(radius: 28, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Column(children: [for (final c in l) widget.row(context, c)])),
                    ]),
        ),
      ]),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String id;
  const ChatPage(this.id, {super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ctl = TextEditingController();
  final sc = ScrollController();
  int last = -1;
  late final AppState store;

  @override
  void initState() {
    super.initState();
    store = context.r;
    store.openChatId = widget.id;
  }

  @override
  void dispose() {
    store.openChatId = '';
    super.dispose();
  }

  Ord? _order(AppState s, Chat c) {
    for (final o in s.orders) {
      if (o.otherId == c.otherId && o.reqId == c.refId && c.refId.isNotEmpty) return o;
    }
    return null;
  }

  void _send() {
    final t = ctl.text.trim();
    if (t.isEmpty) return;
    final c = store.chatById(widget.id)!;
    ctl.clear();
    store.sendText(c, t);
    if (store.looksFraud(t)) toast(context, 'Pesanmu terindikasi pola penipuan. Hati-hati berbagi data sensitif.');
  }

  Future<void> _attach(Chat c) async {
    final s = store;
    await sheet<void>(context, (x) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Kirim foto'), onTap: () async {
              Navigator.pop(x);
              final path = await pickTempPhoto(context);
              if (path != null) s.sendMedia(c, 'image', 'Foto lokasi pekerjaan', {'path': path});
            }),
            ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Kirim lokasi'), onTap: () { Navigator.pop(x); s.sendMedia(c, 'location', s.address.isEmpty ? 'Titik lokasi dari peta' : s.address); }),
            ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(c.type == 'order' ? 'Ajukan penawaran harga' : 'Buat penawaran order'),
              onTap: () { Navigator.pop(x); _offer(c); },
            ),
            ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Bagikan kontak WhatsApp'), onTap: () { Navigator.pop(x); _shareWa(c); }),
            ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: const Text('Bagikan akun e-wallet'), onTap: () { Navigator.pop(x); _shareWallet(c); }),
          ]),
        ));
  }

  Future<void> _offer(Chat c) async {
    if (c.type == 'direct') {
      final agent = c.otherAgent && c.otherId.startsWith('a') ? store.agentById(c.otherId) : null;
      await directOfferSheet(context, c, agent);
      return;
    }
    final r = store.reqById(c.refId);
    final v = await askText(context, 'Penawaran harga${r == null ? '' : unitOf(r.ptype)}', hint: 'Nominal dalam Rupiah', money: true);
    final p = money(v ?? '');
    if (p < 15000) {
      if (v != null && mounted) toast(context, 'Nominal minimal Rp15.000.');
      return;
    }
    store.sendOffer(c, p, r?.ptype ?? 'lump');
  }

  Future<void> _shareWa(Chat c) async {
    final ok = await confirm(context, 'Bagikan WhatsApp?', 'Komunikasi dan pembayaran di luar Buruhku tidak dilindungi. Bagikan hanya jika kamu yakin.', ok: 'Lanjut');
    if (!ok || !mounted) return;
    final v = await askText(context, 'Nomor WhatsApp', hint: store.phone, number: true);
    if (v == null || !mounted) return;
    store.shareWa(c, v.isEmpty ? store.phone : v);
  }

  Future<void> _shareWallet(Chat c) async {
    if (store.wallets.isEmpty) {
      await info(context, 'Belum ada e-wallet', 'Tambahkan e-wallet di Akun > Dompet & metode bayar terlebih dulu.');
      return;
    }
    final w = await sheet<String>(context, (x) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Pilih e-wallet', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final e in store.wallets) ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: Text(e.split('|').first), subtitle: Text(e.split('|').last), onTap: () => Navigator.pop(x, e)),
        ])));
    if (w == null || !mounted) return;
    final purpose = await sheet<String>(context, (x) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Tujuan berbagi', style: TextStyle(fontWeight: FontWeight.w700))),
          ListTile(title: const Text('Tip'), onTap: () => Navigator.pop(x, 'Tip')),
          ListTile(title: const Text('Pembayaran tambahan yang disepakati'), onTap: () => Navigator.pop(x, 'Pembayaran tambahan')),
        ])));
    if (purpose == null || !mounted) return;
    final ok = await confirm(context, 'Peringatan keamanan', 'E-wallet hanya untuk tip atau tambahan yang sudah disepakati, bukan pembayaran utama. Pembayaran utama wajib lewat escrow Buruhku.', ok: 'Bagikan');
    if (ok) store.shareEwallet(c, w, purpose);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = s.chatById(widget.id);
    if (c == null) return AppScaffold(appBar: PageBar(), body: const Empty(Icons.error_outline, 'Chat tidak ditemukan.'));
    if (c.unread > 0) WidgetsBinding.instance.addPostFrameCallback((_) => store.markRead(c));
    if (c.msgs.length != last) {
      last = c.msgs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (sc.hasClients) sc.jumpTo(sc.position.maxScrollExtent);
      });
    }
    final o = _order(s, c);
    final pr = s.reqById(c.refId);
    final pa = _pickable(c, pr);
    final blocked = s.blocked.contains(c.otherId);
    return AppScaffold(
      appBar: ProfileBar(
        avatar: Avatar(size: 44, imageUrl: c.otherAgent ? s.agentById(c.otherId).avatarUrl : null),
        title: c.otherName,
        subtitle: c.type == 'order' ? (c.title.isEmpty ? 'Chat order' : c.title) : 'Chat langsung',
        // Lawan chat agen: ketuk kapsul untuk membuka profilnya.
        onTap: c.otherAgent ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(c.otherId))) : null,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'block' && await confirm(context, 'Blokir ${c.otherName}?', 'Kamu tidak akan menerima pesan atau melihat penawaran dari pengguna ini.', ok: 'Blokir')) s.blockUser(c);
              if (v == 'report' && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: c.otherName, targetId: c.otherId, orderId: o?.id ?? '')));
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Laporkan pengguna')), PopupMenuItem(value: 'block', child: Text('Blokir pengguna'))],
          ),
        ],
      ),
      body: Column(children: [
        if (o == null && pa != null && pr != null)
          _ChatBanner(
            icon: Icons.how_to_reg_outlined,
            text: '${rp(pa.price)}${unitOf(pr.ptype)}  \u00b7  ACC ${s.activeAcc(pr).length}/${pr.quota}',
            action: pr.workers > 1 ? 'Detail order' : 'Pilih agen',
            onTap: () => pickAgent(context, s, pr, pa),
          )
        else if (o != null)
          _ChatBanner(
            icon: Icons.receipt_long_outlined,
            text: '${ordLabels[o.status] ?? o.status}  \u00b7  ${rp(o.total)}',
            action: o.status == 'AGREED' && o.iAmClient ? 'Bayar' : 'Buka order',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(o.id))),
          )
        else if (c.type == 'direct')
          const Padding(padding: EdgeInsets.fromLTRB(16, 4, 16, 0), child: Warn('Tanpa order, chat ini tidak dilindungi escrow.', icon: Icons.shield_outlined)),
        Expanded(
          child: ListView(
            controller: sc,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [for (final m in c.msgs) _Bubble(c, m)],
          ),
        ),
        if (c.closed || blocked)
          const Padding(padding: EdgeInsets.all(16), child: Warn('Chat ini ditutup (hanya baca).', icon: Icons.lock_outline))
        else
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                GestureDetector(
                  onTap: () => _attach(c),
                  child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: cW, shape: BoxShape.circle), child: const Icon(Icons.add, size: 28, color: g900)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctl,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: cW,
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(26)), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(26)), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(26)), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle), child: const Icon(Icons.send_rounded, size: 20, color: Colors.white)),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Info singkat di atas chat (request atau order terkait) dengan satu tombol aksi.
class _ChatBanner extends StatelessWidget {
  final IconData icon;
  final String text, action;
  final VoidCallback onTap;
  const _ChatBanner({required this.icon, required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: kGreenBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: kGreen)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: g900))),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
              onPressed: onTap,
              child: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );
}

class _Bubble extends StatefulWidget {
  final Chat c;
  final Msg m;
  const _Bubble(this.c, this.m);
  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  bool reveal = false;

  Future<void> _counter(AppState s) async {
    final m = widget.m;
    final v = await askText(context, 'Tawar lagi', hint: 'Nominal dalam Rupiah', money: true);
    final p = money(v ?? '');
    if (p < 15000) {
      if (v != null && mounted) toast(context, 'Nominal minimal Rp15.000.');
      return;
    }
    s.respondOffer(widget.c, m, 'counter', counter: p);
  }

  /// Tombol respons penawaran. Null kalau tidak perlu (sudah dijawab, milikku, atau chat ditutup):
  /// statusnya sudah tampil sebagai pil di kartu.
  Widget? _actions(AppState s) {
    final m = widget.m;
    if (m.data['status'] != 'pending' || m.from == 'me' || widget.c.closed) return null;
    return Row(children: [
      Expanded(child: pbtnS('Setuju', () => s.respondOffer(widget.c, m, 'accept'))),
      const SizedBox(width: 8),
      Expanded(child: obtnS('Tawar', () => _counter(s))),
      const SizedBox(width: 8),
      IconButton.outlined(visualDensity: VisualDensity.compact, onPressed: () => s.respondOffer(widget.c, m, 'reject'), icon: const Icon(Icons.close, size: 20)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final m = widget.m;
    if (m.type == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE4E5E9), borderRadius: BorderRadius.circular(12)),
          child: Text(m.body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: g700)),
        ),
      );
    }
    final me = m.from == 'me';
    final maxW = MediaQuery.sizeOf(context).width * .78;
    final status = (m.data['status'] as String?) ?? 'pending';
    final Widget body;
    switch (m.type) {
      case 'image':
        body = ImageMsgCard(path: m.data['path'] as String?);
      case 'location':
        body = LocationMsgCard(address: m.body);
      case 'offer':
        body = PriceOfferCard(price: m.data['price'] as int, ptype: m.data['ptype'] as String, status: status, actions: _actions(s));
      case 'order_offer':
        body = OrderOfferCard(d: m.data, status: status, actions: _actions(s));
      case 'contact':
        body = ContactMsgCard(
          number: m.body,
          onOpen: me ? null : () => info(context, 'Buka WhatsApp', 'Pada aplikasi rilis, tombol ini membuka https://wa.me/${m.body.replaceAll(RegExp(r'\D'), '')}'),
        );
      case 'ewallet':
        body = WalletMsgCard(
          name: m.body,
          number: (m.data['no'] ?? '').toString(),
          purpose: (m.data['purpose'] ?? '').toString(),
          mine: me,
          revealed: reveal,
          onToggle: () => setState(() => reveal = !reveal),
        );
      default:
        body = Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: me ? kGreen : cW,
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(me ? 18 : 4), bottomRight: Radius.circular(me ? 4 : 18)),
          ),
          child: Text(m.body, style: TextStyle(fontSize: 15, height: 1.35, color: me ? Colors.white : g900)),
        );
    }
    final bubble = GestureDetector(
      onLongPress: me ? null : () async {
        if (await confirm(context, 'Laporkan pesan?', '"${_preview(m)}"', ok: 'Laporkan') && context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: widget.c.otherName, targetId: widget.c.otherId, prefill: 'Pesan: ${_preview(m)}')));
        }
      },
      child: body,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        bubble,
        if (m.flagged)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: const Warn('Terindikasi penipuan (link, permintaan transfer di luar aplikasi, atau OTP/PIN). Jangan bayar atau kirim kode di luar Buruhku.'),
            ),
          ),
        Padding(padding: const EdgeInsets.only(top: 4, left: 4, right: 4), child: Text(ftime(m.at), style: const TextStyle(fontSize: 11, color: g500))),
      ]),
    );
  }
}

/// Mini-form "Buat Penawaran Order" untuk chat/order langsung ke agen.
Future<bool?> directOfferSheet(BuildContext context, Chat chat, Agent? agent) {
  final s = context.r;
  final title = TextEditingController(), desc = TextEditingController(), addr = TextEditingController(text: s.address);
  final price = TextEditingController(), dur = TextEditingController();
  String pt = 'lump', sched = 'now';
  String cat = agent == null || agent.cats.isEmpty ? 'other' : agent.cats.first;
  DateTime? when;
  LatLng pin = kMapCenter;
  final key = GlobalKey<FormState>();
  return sheet<bool>(context, (x) => StatefulBuilder(builder: (ctx, set) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: key,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order langsung ke ${chat.otherName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TF('Judul pekerjaan', title, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: cat, decoration: const InputDecoration(labelText: 'Kategori'),
                  items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
                  onChanged: (v) => set(() => cat = v ?? cat),
                ),
              ),
              TF('Deskripsi', desc, lines: 2, validator: (v) => (v ?? '').trim().length < 10 ? 'Minimal 10 karakter' : null),
              LocationField(addr: addr, pin: pin, mapH: 110, onPin: (o) => set(() => pin = o)),
              const SizedBox(height: 8),
              const Text('Jadwal', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Seg(const {'now': 'Sekarang', 'date': 'Tanggal & jam'}, sched, (v) => set(() => sched = v)),
              if (sched == 'date') ...[
                const SizedBox(height: 8),
                obtn(when == null ? 'Pilih tanggal dan jam' : fdt(when!), () async {
                  final d = await pickDateTime(ctx, initial: when);
                  if (d != null) set(() => when = d);
                }, icon: Icons.event),
              ],
              const SizedBox(height: 16),
              const Text('Harga', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Seg(ptypes, pt, (v) => set(() => pt = v)),
              const SizedBox(height: 12),
              if (pt != 'lump') TF('Durasi (${pt == 'hourly' ? 'jam' : 'hari'})', dur, type: TextInputType.number, validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Wajib diisi' : null),
              TF('Harga (Rp${unitOf(pt)})', price, money: true, validator: (v) => money(v ?? '') < 15000 ? 'Minimal Rp15.000' : null),
              const Text('Setelah disepakati, kamu membayar ke escrow (atau COD) dan dana baru cair ke agen setelah pekerjaan selesai.', style: TextStyle(fontSize: 12, color: g500)),
              const SizedBox(height: 12),
              full(pbtn('Kirim penawaran', () {
                if (!key.currentState!.validate()) return;
                if (sched == 'date' && (when == null || when!.isBefore(DateTime.now()))) {
                  toast(ctx, 'Pilih tanggal dan jam yang valid.');
                  return;
                }
                final m = s.moderate('${title.text} ${desc.text}');
                if (m[0] == 'reject') {
                  info(ctx, 'Ditolak', m[1]);
                  return;
                }
                s.sendOrderOffer(chat, {
                  'title': title.text.trim(), 'cat': cat, 'desc': desc.text.trim(), 'address': addr.text.trim(),
                  'sched': sched, 'schedAt': sched == 'date' ? when!.toIso8601String() : null,
                  'when': sched == 'date' ? fdt(when!) : 'Sekarang', 'lat': pin.latitude, 'lng': pin.longitude,
                  'price': money(price.text), 'ptype': pt, 'dur': pt == 'lump' ? 0.0 : double.parse(dur.text),
                });
                Navigator.pop(x, true);
              })),
            ]),
          ),
        );
      }));
}