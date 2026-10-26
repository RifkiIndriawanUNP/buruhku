import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'account.dart';
import 'location.dart';
import 'order.dart';
import 'request.dart';

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

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key});
  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  String seg = 'all';
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final l = s.chats.where((c) => c.otherAgent == !s.agentMode && (seg == 'all' || c.type == seg)).toList()
      ..sort((a, b) => (b.msgs.isEmpty ? DateTime(2000) : b.msgs.last.at).compareTo(a.msgs.isEmpty ? DateTime(2000) : a.msgs.last.at));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pesan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Seg(const {'all': 'Semua', 'order': 'Order', 'direct': 'Langsung'}, seg, (v) => setState(() => seg = v)),
        ]),
      ),
      Expanded(
        child: l.isEmpty
            ? Empty(Icons.chat_bubble_outline, seg == 'direct' ? 'Chat langsung dimulai dari profil agen.' : seg == 'order' ? 'Chat negosiasi muncul saat ada agen yang ACC requestmu.' : 'Belum ada percakapan.')
            : ListView.separated(
                itemCount: l.length, separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final c = l[i];
                  final last = c.msgs.isEmpty ? null : c.msgs.last;
                  return ListTile(
                    leading: const Avatar(),
                    title: Row(children: [
                      Flexible(child: Text(c.otherName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (seg == 'all') ...[const SizedBox(width: 6), Tag(c.type == 'order' ? 'Order' : 'Langsung')],
                    ]),
                    subtitle: Text('${c.title.isEmpty ? '' : '${c.title}\n'}${last == null ? 'Belum ada pesan' : _preview(last)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    isThreeLine: c.title.isNotEmpty,
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (last != null) Text(ftime(last.at), style: const TextStyle(fontSize: 11, color: g500)),
                      const SizedBox(height: 4),
                      if (c.unread > 0) Badge(label: Text('${c.unread}'), backgroundColor: g900) else if (c.closed) const Icon(Icons.lock_outline, size: 14, color: g500),
                    ]),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(c.id))),
                  );
                },
              ),
      ),
    ]);
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
  late final AppStore store;

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

  Ord? _order(AppStore s, Chat c) {
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
            ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Kirim foto'), onTap: () { Navigator.pop(x); s.sendMedia(c, 'image', 'Foto lokasi pekerjaan'); }),
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
    if (c == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Chat tidak ditemukan.'));
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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          const Avatar(size: 36),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(c.type == 'order' ? (c.title.isEmpty ? 'Chat order' : c.title) : 'Chat langsung', style: const TextStyle(fontSize: 11.5, color: g500), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
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
          Container(
            color: g100, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.how_to_reg_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Harga ${rp(pa.price)}${unitOf(pr.ptype)}  |  ACC ${s.activeAcc(pr).length}/${pr.quota}', style: const TextStyle(fontSize: 12.5))),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => pickAgent(context, s, pr, pa),
                child: Text(pr.workers > 1 ? 'Detail order' : 'Pilih agen'),
              ),
            ]),
          ),
        if (o != null)
          Container(
            color: g100, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              const Icon(Icons.receipt_long_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Order: ${ordLabels[o.status] ?? o.status}  |  ${rp(o.total)}', style: const TextStyle(fontSize: 12.5))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(o.id))), child: Text(o.status == 'AGREED' && o.iAmClient ? 'Bayar' : 'Buka order')),
            ]),
          )
        else if (c.type == 'direct')
          const Padding(padding: EdgeInsets.all(8), child: Warn('Chat langsung tanpa order tidak dilindungi escrow. Buat penawaran order lewat tombol + agar aman.', icon: Icons.shield_outlined)),
        Expanded(
          child: ListView(
            controller: sc, padding: const EdgeInsets.all(12),
            children: [for (final m in c.msgs) _Bubble(c, m)],
          ),
        ),
        if (c.closed || blocked)
          const Padding(padding: EdgeInsets.all(12), child: Warn('Chat ini ditutup (hanya baca).', icon: Icons.lock_outline))
        else
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: g200))),
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
              child: Row(children: [
                IconButton(onPressed: () => _attach(c), icon: const Icon(Icons.add_circle_outline)),
                Expanded(child: TextField(controller: ctl, minLines: 1, maxLines: 4, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'Tulis pesan...'))),
                const SizedBox(width: 6),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send, size: 18)),
              ]),
            ),
          ),
      ]),
    );
  }
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

  Future<void> _counter(AppStore s) async {
    final m = widget.m;
    final v = await askText(context, 'Tawar lagi', hint: 'Nominal dalam Rupiah', money: true);
    final p = money(v ?? '');
    if (p < 15000) {
      if (v != null && mounted) toast(context, 'Nominal minimal Rp15.000.');
      return;
    }
    s.respondOffer(widget.c, m, 'counter', counter: p);
  }

  Widget _actions(AppStore s) {
    final m = widget.m;
    if (m.data['status'] != 'pending') {
      final st = {'accepted': 'Disepakati', 'rejected': 'Ditolak', 'countered': 'Ditawar balik'}[m.data['status']] ?? '';
      return Tag(st, filled: m.data['status'] == 'accepted');
    }
    if (m.from == 'me') return const Text('Menunggu respons...', style: TextStyle(fontSize: 12, color: g500));
    if (widget.c.closed) return const SizedBox();
    return Row(children: [
      Expanded(child: pbtn('Setuju', () => s.respondOffer(widget.c, m, 'accept'))),
      const SizedBox(width: 6),
      Expanded(child: obtn('Tawar', () => _counter(s))),
      const SizedBox(width: 6),
      IconButton.outlined(onPressed: () => s.respondOffer(widget.c, m, 'reject'), icon: const Icon(Icons.close)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final m = widget.m;
    if (m.type == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: g100, borderRadius: BorderRadius.circular(12)),
          child: Text(m.body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: g700)),
        ),
      );
    }
    final me = m.from == 'me';
    Widget body;
    switch (m.type) {
      case 'image':
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Ph(w: 180, h: 130), const SizedBox(height: 4), Text(m.body)]);
        break;
      case 'location':
        body = SizedBox(width: 200, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const FakeMap(h: 90, pin: Offset(.5, .6)), const SizedBox(height: 4), Text(m.body, style: const TextStyle(fontSize: 12.5))]));
        break;
      case 'offer':
        final pt = m.data['ptype'] as String;
        body = SizedBox(width: 230, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.sell_outlined, size: 16), SizedBox(width: 6), Text('Penawaran harga', style: TextStyle(fontWeight: FontWeight.w700))]),
          const SizedBox(height: 6),
          Text('${rp(m.data['price'] as int)}${unitOf(pt)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(ptypes[pt] ?? '', style: const TextStyle(fontSize: 12, color: g500)),
          const SizedBox(height: 8),
          _actions(s),
        ]));
        break;
      case 'order_offer':
        final d = m.data;
        body = SizedBox(width: 250, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.assignment_outlined, size: 16), SizedBox(width: 6), Text('Penawaran order', style: TextStyle(fontWeight: FontWeight.w700))]),
          const SizedBox(height: 6),
          Text(d['title'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(d['desc'] as String? ?? '', style: const TextStyle(fontSize: 12.5, color: g700)),
          const SizedBox(height: 4),
          Text('${d['address']}\n${d['when']}', style: const TextStyle(fontSize: 12, color: g500)),
          const SizedBox(height: 4),
          Text('${rp(d['price'] as int)}${unitOf(d['ptype'] as String)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _actions(s),
        ]));
        break;
      case 'contact':
        body = SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.phone_outlined, size: 16), SizedBox(width: 6), Text('Kontak WhatsApp', style: TextStyle(fontWeight: FontWeight.w700))]),
          Text(m.body, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Di luar Buruhku tidak dilindungi.', style: TextStyle(fontSize: 11, color: g500)),
          if (!me) obtn('Buka WhatsApp', () => info(context, 'Buka WhatsApp', 'Pada aplikasi rilis, tombol ini membuka https://wa.me/${m.body.replaceAll(RegExp(r'\D'), '')}'), icon: Icons.open_in_new),
        ]));
        break;
      case 'ewallet':
        final no = (m.data['no'] ?? '').toString();
        final masked = no.length > 4 ? '${'•' * (no.length - 4)}${no.substring(no.length - 4)}' : no;
        body = SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const Icon(Icons.account_balance_wallet_outlined, size: 16), const SizedBox(width: 6), Text('E-wallet ${m.body}', style: const TextStyle(fontWeight: FontWeight.w700))]),
          Text(reveal || me ? no : masked, style: const TextStyle(fontSize: 16)),
          Text('Tujuan: ${m.data['purpose']}', style: const TextStyle(fontSize: 11.5, color: g500)),
          if (!me) TextButton(onPressed: () => setState(() => reveal = !reveal), child: Text(reveal ? 'Sembunyikan' : 'Tampilkan')),
        ]));
        break;
      default:
        body = Text(m.body);
    }
    final bubble = GestureDetector(
      onLongPress: me ? null : () async {
        if (await confirm(context, 'Laporkan pesan?', '"${_preview(m)}"', ok: 'Laporkan') && context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: widget.c.otherName, targetId: widget.c.otherId, prefill: 'Pesan: ${_preview(m)}')));
        }
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: me ? g200 : cW, border: Border.all(color: g300), borderRadius: BorderRadius.circular(10)),
        child: body,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        bubble,
        if (m.flagged)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
              child: const Warn('Terindikasi penipuan (link, permintaan transfer di luar aplikasi, atau OTP/PIN). Jangan bayar atau kirim kode di luar Buruhku.'),
            ),
          ),
        Padding(padding: const EdgeInsets.only(top: 2), child: Text(ftime(m.at), style: const TextStyle(fontSize: 10, color: g500))),
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
  Offset pin = const Offset(.5, .5);
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
              const SizedBox(height: 14),
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
                  'when': sched == 'date' ? fdt(when!) : 'Sekarang', 'lat': pin.dx, 'lng': pin.dy,
                  'price': money(price.text), 'ptype': pt, 'dur': pt == 'lump' ? 0.0 : double.parse(dur.text),
                });
                Navigator.pop(x, true);
              })),
            ]),
          ),
        );
      }));
}
