import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'account.dart';
import 'chat.dart';
import 'request.dart';
import 'shell.dart';

// ---------------------------------------------------------------- riwayat & favorit
class OrderTile extends StatelessWidget {
  final Ord o;
  const OrderTile(this.o, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Box(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(o.id))),
          child: Row(children: [
            Icon(catOf(o.cat).icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${o.iAmClient ? 'Agen' : 'Klien'}: ${o.otherName}  |  ${ago(o.created)}', style: const TextStyle(fontSize: 12, color: g500)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  Tag(ordLabels[o.status] ?? o.status, filled: o.active),
                  if (o.cod) const Tag('COD', icon: Icons.payments_outlined),
                  if (o.active && o.schedAt != null && o.schedAt!.isAfter(DateTime.now())) Tag(fdt(o.schedAt!), icon: Icons.event),
                ]),
              ]),
            ),
            Text(rp(o.iAmClient ? o.total : o.net), style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

/// Satu baris di daftar aktivitas: satu order biasa, atau satu grup untuk request >1 agen.
class _Entry {
  final String key;
  final List<Ord> subs;
  final bool group;
  _Entry(this.key, this.subs, this.group);
  bool get active => subs.any((o) => o.active);

  /// Akan datang = semua order aktif belum bayar/terjadwal dan waktunya masih di depan.
  bool upcoming(DateTime now) {
    final act = subs.where((o) => o.active).toList();
    return act.isNotEmpty &&
        act.every((o) => o.schedAt != null && o.schedAt!.isAfter(now) && ['AWAIT_AGENT', 'AGREED', 'SCHEDULED'].contains(o.status));
  }
}

List<_Entry> _entries(AppStore s) {
  final mine = s.orders.where((o) => o.iAmClient).toList();
  final seen = <String>{};
  final out = <_Entry>[];
  for (final o in mine) {
    final r = s.reqById(o.reqId);
    if (r != null && r.workers > 1) {
      if (seen.add(o.reqId)) out.add(_Entry(o.reqId, mine.where((x) => x.reqId == o.reqId).toList(), true));
    } else {
      out.add(_Entry(o.id, [o], false));
    }
  }
  return out;
}

Widget _entryTile(_Entry e) => e.group ? GroupTile(e.key, e.subs) : OrderTile(e.subs.first);

class GroupTile extends StatelessWidget {
  final String reqId;
  final List<Ord> subs;
  const GroupTile(this.reqId, this.subs, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = s.reqById(reqId);
    final valid = subs.where((o) => !['CANCELLED', 'REFUNDED'].contains(o.status)).toList();
    final total = valid.fold<int>(0, (a, o) => a + o.total);
    final counts = <String, int>{};
    for (final o in subs) {
      final l = ordLabels[o.status] ?? o.status;
      counts[l] = (counts[l] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupOrderPage(reqId))),
        child: Row(children: [
          const Icon(Icons.groups_outlined, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subs.first.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${r?.chosen.length ?? subs.length} dari ${r?.workers ?? subs.length} agen terpilih', style: const TextStyle(fontSize: 12, color: g500)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final e in counts.entries.take(3)) Tag('${e.value} ${e.key}', filled: subs.any((o) => o.active && (ordLabels[o.status] ?? o.status) == e.key)),
                if (subs.first.schedAt != null && subs.first.schedAt!.isAfter(DateTime.now()) && subs.any((o) => o.active)) Tag(fdt(subs.first.schedAt!), icon: Icons.event),
              ]),
            ]),
          ),
          Text(rp(total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _ActiveView extends StatefulWidget {
  final List<_Entry> entries;
  const _ActiveView(this.entries);
  @override
  State<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends State<_ActiveView> {
  String seg = 'now';
  @override
  Widget build(BuildContext context) => Live((_) {
        // dihitung ulang tiap detik: order "akan datang" otomatis pindah ke "sekarang" saat waktunya tiba
        final now = DateTime.now();
        final soon = widget.entries.where((e) => e.upcoming(now)).toList();
        final cur = widget.entries.where((e) => !e.upcoming(now)).toList();
        final l = seg == 'now' ? cur : soon;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
            child: Seg({'now': 'Sekarang (${cur.length})', 'soon': 'Akan datang (${soon.length})'}, seg, (v) => setState(() => seg = v)),
          ),
          Expanded(
            child: l.isEmpty
                ? Empty(seg == 'now' ? Icons.hourglass_empty : Icons.event_available_outlined, seg == 'now' ? 'Belum ada order berjalan.' : 'Belum ada order terjadwal.')
                : ListView(padding: const EdgeInsets.all(16), children: [for (final e in l) _entryTile(e)]),
          ),
        ]);
      });
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final all = _entries(s);
    final act = all.where((e) => e.active).toList();
    final his = all.where((e) => !e.active).toList();
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Aktivitas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))),
        const TabBar(tabs: [Tab(text: 'Aktif'), Tab(text: 'Riwayat')]),
        Expanded(
          child: TabBarView(children: [
            _ActiveView(act),
            his.isEmpty ? const Empty(Icons.history, 'Order selesai atau batal akan muncul di sini.') : ListView(padding: const EdgeInsets.all(16), children: [for (final e in his) _entryTile(e)]),
          ]),
        ),
      ]),
    );
  }
}

/// Konfirmasi memilih COD untuk satu atau beberapa order sekaligus.
Future<bool> confirmCod(BuildContext c, AppStore s, List<Ord> l) async {
  final total = l.fold<int>(0, (a, o) => a + o.total);
  final ok = await confirm(
      c, 'Bayar di tempat (COD)?',
      'Kamu membayar tunai ${rp(total)} langsung ke agen setelah pekerjaan selesai.\n\nTanpa perlindungan escrow, jadi sengketa uang tidak bisa dikembalikan platform. Biaya layanan tidak dikenakan.',
      ok: 'Pilih COD');
  if (!ok) return false;
  for (final o in l) {
    s.chooseCod(o);
  }
  if (c.mounted) toast(c, 'Pembayaran COD dipilih. Agen dijadwalkan.');
  return true;
}

// ---------------------------------------------------------------- request / order lebih dari 1 agen
String _cap(String t) => t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1)}';

class GroupOrderPage extends StatelessWidget {
  final String reqId;
  const GroupOrderPage(this.reqId, {super.key});

  Future<void> _start(BuildContext context, AppStore s, Req r) async {
    final n = r.acc.where((a) => a.status == 'agreed').length;
    if (n == 0) {
      toast(context, 'Belum ada agen yang sepakat.');
      return;
    }
    final total = r.chosen.length + n;
    if (total < r.workers) {
      final ok = await confirm(
          context, 'Agen belum cukup',
          'Kamu meminta ${r.workers} agen, baru $total yang sepakat.\n\nMulai order sekarang dengan $n agen? Kamu masih bisa menambah agen setelah order dimulai.',
          ok: 'Mulai dengan $n agen');
      if (!ok || !context.mounted) return;
    }
    s.startGroup(r);
    if (context.mounted) toast(context, 'Order dimulai. $n agen diminta konfirmasi akhir.');
  }

  Future<void> _addFav(BuildContext context, AppStore s, Req r) async {
    final taken = r.acc.where((a) => ['invited', 'agreed', 'selected'].contains(a.status)).map((a) => a.agentId).toSet();
    final favs = s.agents.where((a) => s.favs.contains(a.id) && !taken.contains(a.id)).toList();
    final pick = await sheet<Agent>(context, (x) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(padding: EdgeInsets.all(8), child: Text('Tambah agen favorit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            if (favs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Tidak ada agen favorit yang bisa ditambahkan.', style: TextStyle(color: g500))),
            for (final a in favs)
              ListTile(
                leading: const Avatar(size: 40), title: Text(a.short),
                subtitle: Text('${a.online ? 'Online' : 'Offline'}  |  ~${a.dist.toStringAsFixed(1)} km  |  ${a.cats.map((c) => catOf(c).name.split(' ').first).take(2).join(', ')}'),
                trailing: const Icon(Icons.add_circle_outline), onTap: () => Navigator.pop(x, a),
              ),
          ]),
        ));
    if (pick != null) {
      s.inviteAgent(r, pick);
      if (context.mounted) toast(context, 'Menunggu persetujuan ${pick.short}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = s.reqById(reqId);
    if (r == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Request tidak ditemukan.'));
    final subs = s.orders.where((o) => o.reqId == reqId && o.iAmClient).toList();
    final started = r.chosen.isNotEmpty;
    bool hadOrder(Acc a) => subs.any((o) => o.otherId == a.agentId);
    final accs = r.acc.where((a) => ['invited', 'agreed', 'selected'].contains(a.status)).toList();
    final gone = r.acc.where((a) => a.status == 'declined' || a.status == 'withdrawn').toList();
    final cancelledOrders = gone.where(hadOrder).toList();
    final refused = gone.where((a) => !hadOrder(a)).toList();
    final interest = r.acc.where((a) => a.status == 'accepted').toList();
    final agreed = r.acc.where((a) => a.status == 'agreed').length;
    final shown = [...accs, ...cancelledOrders];
    final open = ['OPEN', 'HAS_ACCEPTORS', 'FULL'].contains(r.status);
    final canAdd = open || r.status == 'LOCKED';
    final editable = !started && (open || r.status == 'EXPIRED' || r.status == 'IN_REVIEW');
    final everAcc = r.acc.map((a) => a.agentId).toSet();
    final nearby = (canAdd && !started)
        ? s.searchAgents(cat: r.cat, maxDist: r.radius, online: true, verified: true, sort: 'jarak').where((a) => !everAcc.contains(a.id) && (catOf(r.cat).risk == 1 || a.level >= 2)).take(6).toList()
        : <Agent>[];
    final pending = subs.where((o) => o.status == 'AGREED').toList();
    final live = subs.where((o) => !['CANCELLED', 'REFUNDED'].contains(o.status)).toList();
    final total = live.fold<int>(0, (a, o) => a + o.total);
    final fee = live.fold<int>(0, (a, o) => a + o.fee);
    final anyLive = subs.any((o) => ['SCHEDULED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'].contains(o.status));
    final enough = r.chosen.length + agreed >= r.workers;
    return Scaffold(
      appBar: AppBar(title: Text('Order ${r.workers} agen'), actions: [
        if (editable)
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(edit: r)));
              if (v == 'cancel' && await confirm(context, 'Batalkan request?', 'Agen yang sudah dipilih akan diberi tahu. Tanpa biaya karena belum ada pembayaran.', ok: 'Batalkan')) {
                s.cancelReq(r);
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Ubah request')), PopupMenuItem(value: 'cancel', child: Text('Batalkan request'))],
          ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Icon(catOf(r.cat).icon, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(r.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [
          Tag(reqLabels[r.status] ?? r.status, filled: true),
          Tag('${started ? r.chosen.length : agreed}/${r.workers} agen ${started ? 'dimulai' : 'sepakat'}', icon: Icons.groups_outlined),
        ]),
        if (open && !started) Padding(padding: const EdgeInsets.only(top: 10), child: Live((_) => Text('Sisa waktu mencari agen: ${clock(r.expires.difference(DateTime.now()))}', style: const TextStyle(color: g700)))),
        if (r.status == 'IN_REVIEW') Padding(padding: const EdgeInsets.only(top: 10), child: Warn('${r.reason}\nBuka Akun > Panel Admin (Simulasi) untuk menyetujui.')),
        const SizedBox(height: 12),
        Box(child: Column(children: [
          Kv('Jadwal', (r.sched == 'date' && r.schedAt != null) ? fdt(r.schedAt!) : 'Sekarang'),
          Kv('Alamat', r.address.isEmpty ? r.area : r.address),
          Kv('Harga per agen', '${rp(r.price)}${unitOf(r.ptype)}'),
          Kv('Agen diminta', '${r.workers} orang'),
          if (live.isNotEmpty) ...[
            Kv('Total agen berjalan', rp(total)),
            Kv('Biaya layanan', rp(fee)),
            const Divider(),
            Kv('Total bayar', rp(total + fee), bold: true),
          ],
        ])),
        const SizedBox(height: 8),
        Text(r.desc, style: const TextStyle(height: 1.4)),
        if (r.status == 'EXPIRED') ...[
          const Section('Belum ada kesepakatan'),
          const Warn('Request kedaluwarsa. Pilih salah satu cara agar lebih mudah dapat agen.'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            obtn('Naikkan harga 10%', () => s.relist(r, addPrice: (r.price * 0.1 / 1000).round() * 1000), icon: Icons.trending_up),
            obtn('Perluas radius +5 km', () => s.relist(r, addRadius: 5), icon: Icons.radar),
            obtn('Perpanjang', () => s.relist(r), icon: Icons.update),
          ]),
        ],
        if (pending.isNotEmpty) ...[
          const Section('Pembayaran'),
          Live((_) => Warn('${pending.length} agen menunggu pembayaran. Batas bayar ${clock(pending.map((o) => o.payBy).reduce((a, b) => a.isBefore(b) ? a : b).difference(DateTime.now()))}.', icon: Icons.timer_outlined)),
          const SizedBox(height: 10),
          full(pbtn('Bayar semua (${pending.length} agen)  ${rp(pending.fold<int>(0, (a, o) => a + o.total + o.fee))}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(pending.map((o) => o.id).toList()))), icon: Icons.lock_outline)),
          const SizedBox(height: 8),
          full(obtn('Bayar di tempat (COD) untuk semua', () => confirmCod(context, s, pending), icon: Icons.payments_outlined)),
        ],
        // ---- 1. Agen ACC: pending, sepakat; setelah order dimulai tampil tombol chat dan order
        Section('Agen ACC (${shown.length})', action: canAdd ? 'Tambah agen favorit' : null, onAction: canAdd ? () => _addFav(context, s, r) : null),
        if (shown.isEmpty) const Text('Belum ada agen. Pilih agen dari daftar "Sedang mencari agen" atau tambahkan dari favorit.', style: TextStyle(color: g500, fontSize: 12.5)),
        for (final a in shown) _GroupAcc(r, a, subs.where((o) => o.otherId == a.agentId).isEmpty ? null : subs.firstWhere((o) => o.otherId == a.agentId)),
        if (!started) ...[
          // ---- 2. Sedang mencari agen: agen yang bisa dipilih
          const Section('Sedang mencari agen'),
          if (interest.isEmpty && nearby.isEmpty)
            const Box(child: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: g700)), SizedBox(width: 12), Expanded(child: Text('Mencari agen terdekat. Agen yang tertarik akan muncul di sini.'))])),
          for (final a in interest) _Candidate(r, s.agentById(a.agentId), a),
          for (final a in nearby) _Candidate(r, a, null),
          // ---- 3. Agen menolak setelah dipilih
          if (refused.isNotEmpty) ...[
            Section('Agen menolak (${refused.length})'),
            for (final a in refused)
              ListTile(
                contentPadding: EdgeInsets.zero, leading: const Avatar(size: 40), title: Text(s.agentById(a.agentId).short),
                subtitle: Text(a.note.isEmpty ? (a.status == 'withdrawn' ? 'Mundur' : 'Menolak') : _cap(a.note)),
                trailing: const Tag('Menolak'),
              ),
          ],
        ],
        if (anyLive) ...[const SizedBox(height: 12), const SosButton()],
        const SizedBox(height: 90),
      ]),
      bottomNavigationBar: (agreed > 0 && canAdd)
          ? Container(
              decoration: const BoxDecoration(color: cW, border: Border(top: BorderSide(color: g300))),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(enough ? 'Agen sudah cukup. Kamu tetap bisa menambah agen.' : 'Baru ${r.chosen.length + agreed} dari ${r.workers} agen sepakat. Tetap bisa mulai.', style: const TextStyle(fontSize: 12, color: g500)),
                    const SizedBox(height: 6),
                    full(pbtn('Mulai order ($agreed agen)', () => _start(context, s, r), icon: Icons.play_arrow)),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}

/// Baris agen yang bisa dipilih (agen yang tertarik, atau agen sekitar).
class _Candidate extends StatelessWidget {
  final Req r;
  final Agent ag;
  final Acc? a;
  const _Candidate(this.r, this.ag, this.a);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final acc = a;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Box(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(ag.id))),
        child: Row(children: [
          const Avatar(size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(ag.short, style: const TextStyle(fontWeight: FontWeight.w700))), const SizedBox(width: 6), if (ag.verified) const Icon(Icons.verified_outlined, size: 16)]),
              Text('${s.ratingOf(ag).toStringAsFixed(1)}  |  ~${ag.dist.toStringAsFixed(1)} km  |  ${acc == null ? 'mulai ${rp(ag.base)}' : '${rp(acc.price)}${unitOf(r.ptype)}'}', style: const TextStyle(fontSize: 12, color: g500)),
            ]),
          ),
          if (acc != null)
            IconButton(
              tooltip: 'Chat',
              onPressed: () {
                final ch = s.chatFor(type: 'order', refId: r.id, otherId: ag.id, otherName: ag.short, otherAgent: true, title: r.title);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
              },
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
            onPressed: () {
              s.inviteAgent(r, ag);
              toast(context, 'Menunggu persetujuan ${ag.short}.');
            },
            child: const Text('Pilih'),
          ),
        ]),
      ),
    );
  }
}

/// Baris di daftar Agen ACC: Pending, Sepakat, atau (setelah order dimulai) tombol chat dan order.
class _GroupAcc extends StatelessWidget {
  final Req r;
  final Acc a;
  final Ord? o;
  const _GroupAcc(this.r, this.a, this.o);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ag = s.agentById(a.agentId);
    final ord = o;
    void openChat() {
      final ch = s.chatFor(type: 'order', refId: r.id, otherId: ag.id, otherName: ag.short, otherAgent: true, title: r.title);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
    }

    Widget tag(Widget t) => Expanded(child: Align(alignment: Alignment.centerLeft, child: t));
    final cancelled = a.status == 'declined' || a.status == 'withdrawn';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(ag.id))),
            child: Row(children: [
              const Avatar(size: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Text(ag.short, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 6), if (ag.verified) const Icon(Icons.verified_outlined, size: 16)]),
                  Row(children: [Stars(s.ratingOf(ag), size: 12), Text('  ${s.ratingOf(ag).toStringAsFixed(1)}  ~${ag.dist.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11.5, color: g500))]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(rp(a.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(unitOf(r.ptype).isEmpty ? 'borongan' : unitOf(r.ptype), style: const TextStyle(fontSize: 11, color: g500)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          if (a.status == 'invited')
            Row(children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: g700)),
              const SizedBox(width: 10),
              tag(const Tag('Pending', icon: Icons.hourglass_top)),
              IconButton.outlined(tooltip: 'Batalkan pilihan', onPressed: () => s.declineAcc(r, a), icon: const Icon(Icons.close)),
            ])
          else if (a.status == 'agreed')
            Row(children: [
              tag(const Tag('Sepakat', icon: Icons.check_circle_outline, filled: true)),
              obtn('Chat', openChat, icon: Icons.chat_bubble_outline),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Keluarkan agen',
                onPressed: () async {
                  if (await confirm(context, 'Keluarkan ${ag.short}?', 'Agen dipindah ke daftar agen menolak/ditolak.', ok: 'Keluarkan')) s.declineAcc(r, a);
                },
                icon: const Icon(Icons.close),
              ),
            ])
          else
            Row(children: [
              tag(Tag(cancelled ? 'Dibatalkan' : (ord == null ? 'Dimulai' : (ordLabels[ord.status] ?? ord.status)), filled: !cancelled)),
              if (!cancelled) ...[obtn('Chat', openChat, icon: Icons.chat_bubble_outline), const SizedBox(width: 8)],
              if (ord != null) obtn('Order', () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(ord.id)))),
            ]),
          if (cancelled && a.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_cap(a.note), style: const TextStyle(fontSize: 12, color: g500))),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- SOS
class SosButton extends StatefulWidget {
  final String orderId;
  const SosButton({this.orderId = '', super.key});
  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController ac = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) _fire();
    });

  void _fire() {
    final sos = context.r.triggerSos(widget.orderId);
    ac.reset();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        icon: const Icon(Icons.sos_outlined, size: 40),
        title: const Text('SOS terkirim'),
        content: Text('${sos.info}.\nTim keamanan Buruhku menerima alarm prioritas dan akan menghubungimu dalam beberapa menit.\n\nJika dalam bahaya langsung, hubungi 110 (Polisi) atau 112 (Darurat).'),
        actions: [FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Mengerti'))],
      ),
    );
  }

  @override
  void dispose() {
    ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => ac.forward(),
        onTapUp: (_) => ac.reset(),
        onTapCancel: () => ac.reset(),
        child: AnimatedBuilder(
          animation: ac,
          builder: (_, __) => Container(
            height: 52, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(border: Border.all(color: g900, width: 2), borderRadius: BorderRadius.circular(8)),
            child: Stack(alignment: Alignment.center, children: [
              Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: ac.value, child: Container(color: g300))),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sos_outlined), SizedBox(width: 8), Text('Tekan dan tahan 3 detik untuk SOS', style: TextStyle(fontWeight: FontWeight.w700))]),
            ]),
          ),
        ),
      );
}

// ---------------------------------------------------------------- halaman order
class OrderPage extends StatefulWidget {
  final String id;
  const OrderPage(this.id, {super.key});
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final pinCtl = TextEditingController();
  static const stepNames = ['Sepakat', 'Dibayar', 'Berangkat', 'Tiba', 'Kerja', 'Selesai', 'Dinilai'];

  int _step(Ord o) {
    switch (o.status) {
      case 'AWAIT_AGENT':
      case 'AGREED':
        return 0;
      case 'SCHEDULED':
        return 1;
      case 'ON_THE_WAY':
        return 2;
      case 'ARRIVED':
        return 3;
      case 'IN_PROGRESS':
        return 4;
      case 'PENDING_CONFIRM':
        return 5;
      case 'COMPLETED':
        return 6;
      case 'REVIEWED':
        return 7;
      default:
        return -1;
    }
  }

  DateTime? _noShowRef(Ord o) => o.status == 'ARRIVED' ? o.arrivedAt : (o.schedAt ?? o.paidAt);
  bool _noShow(Ord o) {
    final r = _noShowRef(o);
    return r != null && DateTime.now().difference(r).inMinutes >= 30;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final o = s.orderById(widget.id);
    if (o == null) return Scaffold(appBar: AppBar(), body: const Empty(Icons.error_outline, 'Order tidak ditemukan.'));
    final cli = o.iAmClient;
    final st = _step(o);
    final chat = s.chatOfOrder(o);
    final live = ['SCHEDULED', 'ON_THE_WAY', 'ARRIVED', 'IN_PROGRESS'].contains(o.status);
    final rq = s.reqById(o.reqId);
    final grp = rq != null && rq.workers > 1 && cli;
    final disp = s.disputeOf(o.disputeId);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail order'), actions: [
        if (o.active || o.status == 'COMPLETED' || o.status == 'REVIEWED')
          PopupMenuButton<String>(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Menu demo',
            onSelected: (v) {
              if (v == 'skip') s.demoSkip(o);
              if (v == 'chg') s.requestChange(o, 50000, 'Pekerjaan lebih banyak dari perkiraan', false);
              if (v == 'noshow') s.demoNoShow(o);
              if (v == 'inv') Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(o.id)));
            },
            itemBuilder: (_) => [
              const PopupMenuItem(enabled: false, child: Text('Menu demo (simulasi)', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'skip', child: Text('Percepat tahap berikutnya')),
              if (cli && o.status == 'IN_PROGRESS') const PopupMenuItem(value: 'chg', child: Text('Agen minta tambahan biaya')),
              const PopupMenuItem(value: 'noshow', child: Text('Simulasi: tidak hadir 30 menit')),
            ],
          ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Icon(catOf(o.cat).icon, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(o.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          Tag(ordLabels[o.status] ?? o.status, filled: true),
          Tag(cli ? 'Kamu klien' : 'Kamu agen', icon: Icons.badge_outlined),
          if (o.cod) const Tag('COD', icon: Icons.payments_outlined),
        ]),
        if (grp)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupOrderPage(o.reqId))), icon: const Icon(Icons.groups_outlined), label: Text('Lihat semua agen (${rq.workers} agen)')),
          ),
        if (st >= 0) ...[
          const SizedBox(height: 14),
          Row(children: [
            for (var i = 0; i < stepNames.length; i++)
              Expanded(
                child: Column(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: i < st ? g900 : cW, border: Border.all(color: i <= st ? g900 : g300, width: i == st ? 3 : 1)),
                    child: i < st ? const Icon(Icons.check, size: 14, color: cW) : null,
                  ),
                  const SizedBox(height: 3),
                  Text(stepNames[i], style: TextStyle(fontSize: 9.5, fontWeight: i == st ? FontWeight.w800 : FontWeight.w400, color: i <= st ? g900 : g500)),
                ]),
              ),
          ]),
        ],
        const SizedBox(height: 14),
        if (o.cod && o.active) Padding(padding: const EdgeInsets.only(bottom: 10), child: Warn(cli ? 'Bayar tunai ${rp(o.total)} ke agen setelah pekerjaan selesai. Tanpa perlindungan escrow.' : 'Order COD: tagih tunai ${rp(o.total)} dari klien setelah selesai. Komisi ${rp(o.commission)} dipotong dari saldomu.', icon: Icons.payments_outlined)),
        ..._statusArea(context, s, o),
        if (o.chg != null) ...[
          const SizedBox(height: 10),
          Box(
            color: g100,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Permintaan tambahan biaya', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('${rp(o.chg!['amount'] as int)}: ${o.chg!['reason']}'),
              const SizedBox(height: 8),
              if (o.chg!['by'] == 'other' && cli)
                Row(children: [
                  Expanded(child: pbtn('Setujui', () => s.respondChange(o, true))),
                  const SizedBox(width: 8),
                  Expanded(child: obtn('Tolak', () => s.respondChange(o, false))),
                ])
              else
                const Text('Menunggu persetujuan pihak lain...', style: TextStyle(color: g500)),
            ]),
          ),
        ],
        if (live) ...[const SizedBox(height: 10), SosButton(orderId: o.id)],
        if (disp != null) ...[
          const Section('Sengketa'),
          Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kv('Jenis', disp.type),
            Kv('Status', disp.status == 'open' ? 'Menunggu tanggapan' : disp.status == 'responded' ? 'Ditanggapi, menunggu admin' : 'Diputuskan'),
            if (disp.response.isNotEmpty) Text(disp.response, style: const TextStyle(color: g700)),
            if (disp.status != 'resolved') const Padding(padding: EdgeInsets.only(top: 6), child: Text('Dana tetap ditahan. Keputusan ada di Akun > Panel Admin (Simulasi).', style: TextStyle(fontSize: 12, color: g500))),
            if (disp.status != 'resolved') ...[
              const SizedBox(height: 10),
              full(obtn('Batalkan sengketa', () async {
                if (await confirm(context, 'Batalkan sengketa?', 'Order dilanjutkan seperti semula. Kamu masih bisa mengajukan masalah lagi nanti.', ok: 'Batalkan sengketa')) s.cancelDispute(disp);
              }, icon: Icons.undo)),
            ],
          ])),
        ],
        const Section('Rincian'),
        Box(child: Column(children: [
          Kv('Jadwal', o.schedAt == null ? 'Fleksibel' : fdt(o.schedAt!)),
          Kv('Alamat', (cli || o.escrow == 'held' || o.escrow == 'released' || o.escrow == 'cod') ? (o.address.isEmpty ? o.area : o.address) : '${o.area} (alamat lengkap muncul setelah dibayar)'),
          Kv('Harga', '${rp(o.unit)}${unitOf(o.ptype)}'),
          if (o.extra > 0) Kv('Tambahan disetujui', rp(o.extra)),
          Kv(cli ? 'Biaya layanan platform' : 'Komisi platform (10%)', rp(cli ? o.fee : o.commission)),
          const Divider(),
          Kv(cli ? 'Total bayar' : 'Pendapatan bersih', rp(cli ? o.total + o.fee : o.net), bold: true),
          Kv('Escrow', {'none': 'Belum dibayar', 'cod': 'Bayar tunai (COD)', 'held': 'Dana ditahan', 'released': 'Dilepas ke agen', 'refunded': 'Dikembalikan', 'split': 'Dibagi 50:50', 'partial': 'Kompensasi sebagian'}[o.escrow] ?? o.escrow),
        ])),
        const Section('Lawan transaksi'),
        Box(
          onTap: cli && o.otherId.startsWith('a') ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentDetail(o.otherId))) : null,
          child: Row(children: [
            const Avatar(size: 44),
            const SizedBox(width: 10),
            Expanded(child: Text(o.otherName, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (chat != null) obtn('Chat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(chat.id))), icon: Icons.chat_bubble_outline),
          ]),
        ),
        if (o.log.isNotEmpty) ...[
          const Section('Riwayat kejadian'),
          for (final l in o.log.reversed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.circle, size: 7, color: g500),
                const SizedBox(width: 8),
                Expanded(child: Text(l.split('|').sublist(1).join('|'), style: const TextStyle(fontSize: 12.5))),
                Text(ftime(DateTime.parse(l.split('|').first)), style: const TextStyle(fontSize: 11, color: g500)),
              ]),
            ),
        ],
        const SizedBox(height: 30),
      ]),
    );
  }

  // ---- area aksi sesuai status & peran ----
  List<Widget> _statusArea(BuildContext context, AppStore s, Ord o) {
    final cli = o.iAmClient;
    switch (o.status) {
      case 'AWAIT_AGENT':
        return cli
            ? [const Warn('Menunggu konfirmasi akhir agen (maks 15 menit). Kalau agen tidak konfirmasi, slot dibuka kembali.', icon: Icons.hourglass_top), const SizedBox(height: 10), obtn('Batalkan', () => _cancel(context, s, o))]
            : [const Warn('Klien memilih kamu. Konfirmasi kesepakatan dalam 15 menit.', icon: Icons.handshake_outlined), const SizedBox(height: 10), full(pbtn('Konfirmasi kesepakatan', () => s.confirmAsAgent(o))), const SizedBox(height: 8), full(obtn('Tolak', () => _cancel(context, s, o)))];
      case 'AGREED':
        return cli
            ? [
                Live((_) => Warn('Bayar dalam ${clock(o.payBy.difference(DateTime.now()))}. Lewat batas, kesepakatan batal otomatis.', icon: Icons.timer_outlined)),
                const SizedBox(height: 10),
                full(pbtn('Bayar sekarang ${rp(o.total + o.fee)}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage([o.id]))), icon: Icons.lock_outline)),
                const SizedBox(height: 8),
                full(obtn('Bayar di tempat (COD)', () => confirmCod(context, s, [o]), icon: Icons.payments_outlined)),
                const SizedBox(height: 8),
                full(obtn('Batalkan (gratis)', () => _cancel(context, s, o))),
              ]
            : [const Warn('Kesepakatan dikonfirmasi. Menunggu klien membayar ke escrow.', icon: Icons.hourglass_top)];
      case 'SCHEDULED':
        if (cli) {
          return [
            const Warn('Dana aman di escrow. Agen akan berangkat sesuai jadwal.', icon: Icons.lock_outline),
            const SizedBox(height: 10),
            if (_noShow(o)) full(pbtn('Agen tidak hadir: batalkan dan refund penuh', () => _cancel(context, s, o, noShow: true))) else full(obtn('Batalkan pesanan', () => _cancel(context, s, o))),
          ];
        }
        return [
          const Warn('Dana klien sudah di escrow. Berangkat saat jadwal tiba.', icon: Icons.lock_outline),
          const SizedBox(height: 10),
          full(pbtn('Berangkat', () => s.depart(o), icon: Icons.directions_walk)),
          const SizedBox(height: 8),
          full(obtn('Batalkan (reputasi turun)', () => _cancel(context, s, o))),
        ];
      case 'ON_THE_WAY':
        if (cli) {
          return [
            Live((_) {
              final n = o.nextAt;
              final p = n == null ? 0.0 : (1 - n.difference(DateTime.now()).inMilliseconds / 8000).clamp(0.0, 1.0);
              return Column(children: [
                FakeMap(h: 150, pin: const Offset(.72, .62), marks: [Offset(.12 + .55 * p, .2 + .38 * p)]),
                const SizedBox(height: 6),
                Text('${o.otherName} menuju lokasimu. Estimasi tiba ${n == null ? '-' : '${n.difference(DateTime.now()).inSeconds.clamp(0, 99)} dtk (demo)'}', style: const TextStyle(fontSize: 12.5, color: g700)),
              ]);
            }),
            const SizedBox(height: 10),
            if (_noShow(o)) full(pbtn('Agen tidak hadir: batalkan dan refund penuh', () => _cancel(context, s, o, noShow: true))) else full(obtn('Batalkan pesanan', () => _cancel(context, s, o))),
          ];
        }
        return [
          const Warn('Lokasi live-mu hanya dibagikan ke klien selama fase berangkat sampai tiba.', icon: Icons.my_location),
          const SizedBox(height: 10),
          full(pbtn('Saya sudah tiba', () async {
            await info(context, 'Check-in lokasi', 'Lokasi GPS terverifikasi: 120 m dari titik kerja (batas 200 m).');
            s.arrive(o);
          }, icon: Icons.pin_drop_outlined)),
          const SizedBox(height: 8),
          full(obtn('Batalkan', () => _cancel(context, s, o))),
        ];
      case 'ARRIVED':
        if (cli) {
          return [
            Box(color: g100, child: Column(children: [
              const Text('PIN kerja', style: TextStyle(color: g500)),
              Text(o.pin.split('').join('  '), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
              const SizedBox(height: 6),
              const Text('Pastikan wajah orang yang datang sesuai foto profil agen, baru tunjukkan PIN ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5)),
            ])),
            const SizedBox(height: 10),
            full(pbtn('Wajah sesuai, mulai pekerjaan', () => s.confirmArrival(o), icon: Icons.verified_user_outlined)),
            const SizedBox(height: 8),
            full(obtn('Orangnya berbeda: laporkan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(target: o.otherName, targetId: o.otherId, orderId: o.id, prefill: 'Orang yang datang tidak sesuai foto profil agen (joki).'))))),
          ];
        }
        return [
          const Warn('Minta PIN kerja 4 digit dari klien (cek chat) untuk memulai.', icon: Icons.pin_outlined),
          const SizedBox(height: 10),
          TF('PIN kerja', pinCtl, type: TextInputType.number, maxLen: 4),
          full(pbtn('Mulai pekerjaan', () {
            if (!s.startWithPin(o, pinCtl.text.trim())) toast(context, 'PIN salah. Minta ulang ke klien.');
          })),
          if (_noShow(o) && o.escrow == 'held') ...[
            const SizedBox(height: 8),
            full(obtn('Klien tidak hadir 30 menit: klaim kompensasi 30%', () async {
              if (await confirm(context, 'Klaim kompensasi?', 'Kamu menerima 30% dari dana escrow, sisanya dikembalikan ke klien.', ok: 'Klaim')) s.claimClientNoShow(o);
            })),
          ],
        ];
      case 'IN_PROGRESS':
        return [
          Live((_) {
            final t = DateTime.now().difference(o.startedAt ?? DateTime.now());
            final hrs = t.inSeconds / 3600;
            return Box(color: g100, child: Column(children: [
              Text(clock(t), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
              Text(o.ptype == 'hourly' ? 'Timer berjalan: ${rp((o.unit * hrs).round())} dari tarif ${rp(o.unit)}/jam' : 'Pekerjaan sedang dikerjakan', style: const TextStyle(color: g700, fontSize: 12.5)),
            ]));
          }),
          const SizedBox(height: 10),
          if (cli)
            full(obtn('Ajukan masalah', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputePage(o.id))), icon: Icons.report_problem_outlined))
          else ...[
            Row(children: [
              Expanded(child: obtn('Foto sebelum/sesudah', () => toast(context, 'Foto bukti ditambahkan (simulasi).'), icon: Icons.photo_camera_outlined)),
              const SizedBox(width: 8),
              Expanded(child: obtn('Ajukan tambahan', () => _changeSheet(context, s, o), icon: Icons.add_card_outlined)),
            ]),
            const SizedBox(height: 8),
            full(pbtn('Pekerjaan selesai', () async {
              final ok = await confirm(context, 'Tandai selesai?', 'Foto hasil pekerjaan akan diunggah (simulasi) dan klien diminta konfirmasi.', ok: 'Selesai');
              if (ok) s.finishJob(o);
            }, icon: Icons.task_alt)),
            const SizedBox(height: 8),
            full(obtn('Ajukan masalah', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputePage(o.id))))),
          ],
        ];
      case 'PENDING_CONFIRM':
        if (cli) {
          return [
            const Text('Foto hasil dari agen', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Row(children: [Expanded(child: Ph(h: 90)), SizedBox(width: 8), Expanded(child: Ph(h: 90))]),
            const SizedBox(height: 8),
            Live((_) => Text('Konfirmasi otomatis dalam ${clock(Duration(hours: 24) - DateTime.now().difference(o.finishedAt ?? DateTime.now()))}', style: const TextStyle(fontSize: 12.5, color: g500))),
            const SizedBox(height: 10),
            full(pbtn('Konfirmasi selesai dan lepas dana', () => s.completeOrder(o), icon: Icons.task_alt)),
            const SizedBox(height: 8),
            full(obtn('Ajukan masalah', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputePage(o.id))))),
          ];
        }
        return [const Warn('Menunggu klien mengonfirmasi hasil (otomatis dalam 24 jam). Dana cair setelah dikonfirmasi.', icon: Icons.hourglass_top), const SizedBox(height: 8), full(obtn('Ajukan masalah', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputePage(o.id)))))];
      case 'COMPLETED':
      case 'REVIEWED':
        final req = s.reqById(o.reqId);
        return [
          Warn(cli ? (o.cod ? 'Pekerjaan selesai. Pembayaran tunai sudah ke agen.' : 'Pekerjaan selesai. Dana sudah dilepas ke agen.') : (o.cod ? 'Pekerjaan selesai. Tunai ${rp(o.total)} diterima, komisi ${rp(o.commission)} dipotong dari saldo.' : 'Pekerjaan selesai. ${rp(o.net)} masuk ke saldo.'), icon: Icons.task_alt),
          const SizedBox(height: 10),
          if (!o.myRev) full(pbtn(cli ? 'Beri rating agen' : 'Beri rating klien', () => Navigator.push(context, MaterialPageRoute(builder: (_) => RatingPage(o.id))), icon: Icons.star_outline)),
          if (!o.myRev) const SizedBox(height: 8),
          if (cli && !o.tipped) full(obtn('Beri tip', () => _tipSheet(context, s, o), icon: Icons.volunteer_activism_outlined)),
          if (cli && !o.tipped) const SizedBox(height: 8),
          full(obtn('Lihat invoice', () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(o.id))), icon: Icons.receipt_outlined)),
          if (cli) ...[
            const SizedBox(height: 8),
            full(obtn('Pesan ulang', () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestFormPage(tpl: {'t': o.title, 'c': o.cat, 'd': req?.desc ?? 'Pekerjaan serupa dengan order sebelumnya.', 'p': o.unit, 'pt': o.ptype}))), icon: Icons.replay)),
            const SizedBox(height: 8),
            full(obtn('Order langsung ke agen yang sama', () async {
              final ch = s.chatFor(type: 'direct', refId: '', otherId: o.otherId, otherName: o.otherName, otherAgent: true);
              final ok = await directOfferSheet(context, ch, s.agentById(o.otherId));
              if (ok == true && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
            })),
          ],
        ];
      case 'DISPUTED':
        return [const Warn('Sengketa berjalan. Dana tetap ditahan sampai admin memutuskan.', icon: Icons.gavel_outlined)];
      case 'CANCELLED':
      case 'REFUNDED':
      case 'RESOLVED':
        return [Warn(o.status == 'RESOLVED' ? 'Sengketa sudah diputuskan admin.' : 'Order ini ${o.status == 'REFUNDED' ? 'dibatalkan dan dana dikembalikan' : 'dibatalkan'}.', icon: Icons.info_outline)];
      default:
        return [];
    }
  }

  Future<void> _cancel(BuildContext context, AppStore s, Ord o, {bool noShow = false}) async {
    String why = 'dibatalkan ${o.iAmClient ? 'klien' : 'agen'}';
    String msg;
    if (o.iAmClient) {
      final sch = o.schedAt;
      final early = sch == null || sch.difference(DateTime.now()).inHours >= 3;
      final started = ['ON_THE_WAY', 'ARRIVED'].contains(o.status);
      msg = o.escrow != 'held'
          ? 'Dibatalkan tanpa biaya.'
          : (noShow || (early && !started)) ? 'Refund 100% (${rp(o.total + o.fee)}).' : 'Kurang dari 3 jam atau agen sudah berangkat: refund parsial 70%, 30% jadi kompensasi agen.';
      if (noShow) why = 'agen tidak hadir 30 menit';
    } else {
      msg = o.escrow == 'held' ? 'Klien mendapat refund 100% dan reputasimu turun.' : 'Dibatalkan tanpa penalti.';
      final a = await askText(context, 'Alasan pembatalan', hint: 'Wajib diisi');
      if (a == null || a.isEmpty) return;
      why = a;
    }
    if (!context.mounted) return;
    if (!await confirm(context, 'Batalkan order?', msg, ok: 'Batalkan')) return;
    final res = s.cancelOrder(o, why, forceFull: noShow);
    if (context.mounted) toast(context, res);
  }

  Future<void> _changeSheet(BuildContext context, AppStore s, Ord o) async {
    final amt = TextEditingController(), why = TextEditingController();
    await sheet<void>(context, (x) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Ajukan tambahan biaya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TF('Nominal tambahan (Rp)', amt, money: true),
            TF('Alasan', why, lines: 2),
            full(pbtn('Kirim ke klien', () {
              final a = money(amt.text);
              if (a < 10000 || why.text.trim().isEmpty) {
                toast(x, 'Isi nominal (min Rp10.000) dan alasan.');
                return;
              }
              s.requestChange(o, a, why.text.trim(), true);
              Navigator.pop(x);
            })),
          ]),
        ));
  }

  Future<void> _tipSheet(BuildContext context, AppStore s, Ord o) async {
    final v = await sheet<int>(context, (x) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Beri tip untuk agen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [for (final a in [5000, 10000, 20000, 50000]) ActionChip(label: Text(rp(a)), onPressed: () => Navigator.pop(x, a))]),
            ]),
          ),
        ));
    if (v != null) s.tip(o, v);
  }
}

// ---------------------------------------------------------------- pembayaran escrow
class PaymentPage extends StatefulWidget {
  final List<String> ids;
  const PaymentPage(this.ids, {super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? method;
  static const groups = {
    'QRIS': ['QRIS'],
    'Virtual Account': ['VA BCA', 'VA Mandiri', 'VA BNI'],
    'E-Wallet': ['GoPay', 'OVO', 'DANA', 'ShopeePay'],
    'Bayar di tempat': ['COD'],
  };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final os = widget.ids.map(s.orderById).whereType<Ord>().where((o) => o.status == 'AGREED').toList();
    if (os.isEmpty) return Scaffold(appBar: AppBar(title: const Text('Pembayaran')), body: const Empty(Icons.info_outline, 'Tidak ada order yang menunggu pembayaran.'));
    final cod = method == 'COD';
    final total = os.fold<int>(0, (a, o) => a + o.total);
    final fee = os.fold<int>(0, (a, o) => a + o.fee);
    final due = os.map((o) => o.payBy).reduce((a, b) => a.isBefore(b) ? a : b);
    final seed = os.first.id.codeUnits.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Box(child: Column(children: [
          Kv('Pekerjaan', os.first.title),
          if (os.length > 1) for (final o in os) Kv('Agen ${o.otherName}', rp(o.total)),
          Kv('Harga kesepakatan', rp(total)),
          Kv('Biaya layanan', rp(cod ? 0 : fee)),
          const Divider(),
          Kv('Total bayar', rp(cod ? total : total + fee), bold: true),
        ])),
        const SizedBox(height: 8),
        Live((_) => Text('Batas bayar: ${clock(due.difference(DateTime.now()))}', style: const TextStyle(color: g700))),
        const SizedBox(height: 4),
        const Warn('Dana ditahan platform (escrow) dan baru dilepas ke agen setelah kamu mengonfirmasi pekerjaan selesai.', icon: Icons.lock_outline),
        for (final g in groups.entries) ...[
          Section(g.key),
          for (final m in g.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                onTap: () => setState(() => method = m),
                border: method == m ? g900 : g300,
                child: Row(children: [
                  Icon(method == m ? Icons.radio_button_checked : Icons.radio_button_off),
                  const SizedBox(width: 10),
                  Text(m == 'COD' ? 'COD (bayar tunai ke agen)' : m, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
        if (method != null) ...[
          const Section('Instruksi'),
          if (cod) const Warn('Bayar tunai langsung ke agen setelah pekerjaan selesai. Tidak ada perlindungan escrow, dan biaya layanan tidak dikenakan.', icon: Icons.payments_outlined)
          else if (method == 'QRIS') Center(child: Column(children: [FakeQr(seed), const SizedBox(height: 6), const Text('Scan dengan aplikasi e-wallet atau mobile banking.', style: TextStyle(color: g500, fontSize: 12.5))]))
          else if (method!.startsWith('VA'))
            Box(child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Nomor Virtual Account', style: TextStyle(color: g500, fontSize: 12)), Text('8077 ${(1000000000 + seed * 7919).toString().substring(0, 10)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))])),
              IconButton(onPressed: () { Clipboard.setData(ClipboardData(text: '8077${1000000000 + seed * 7919}')); toast(context, 'Nomor VA disalin.'); }, icon: const Icon(Icons.copy)),
            ]))
          else
            Text('Permintaan pembayaran dikirim ke aplikasi $method. Buka aplikasinya lalu setujui pembayaran (simulasi).'),
        ],
        const SizedBox(height: 20),
        if (cod)
          full(pbtn('Pilih bayar di tempat (COD)', () async {
            if (await confirmCod(context, s, os) && context.mounted) Navigator.pop(context);
          }, icon: Icons.payments_outlined))
        else ...[
          full(pbtn('Simulasi: pembayaran berhasil', method == null ? null : () {
            for (final o in os) {
              s.payOrder(o, method!);
            }
            Navigator.pop(context);
            toast(context, 'Pembayaran berhasil. Dana ditahan escrow.');
          }, icon: Icons.check_circle_outline)),
          const SizedBox(height: 8),
          full(obtn('Simulasi: pembayaran gagal', method == null ? null : () => info(context, 'Pembayaran gagal', 'Transaksi tidak selesai atau kedaluwarsa. Coba lagi atau ganti metode sebelum batas 30 menit berakhir.'))),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ---------------------------------------------------------------- rating
class RatingPage extends StatefulWidget {
  final String id;
  const RatingPage(this.id, {super.key});
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  int rating = 5;
  final sel = <String>{};
  final cm = TextEditingController();
  bool photo = false;

  @override
  Widget build(BuildContext context) {
    final s = context.r;
    final o = s.orderById(widget.id)!;
    final tags = o.iAmClient ? ['Tepat waktu', 'Rapi', 'Sopan', 'Kuat'] : ['Ramah', 'Deskripsi jelas', 'Bayar cepat'];
    return Scaffold(
      appBar: AppBar(title: Text(o.iAmClient ? 'Nilai agen' : 'Nilai klien')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [const Avatar(size: 64), const SizedBox(height: 6), Text(o.otherName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))])),
        StarPicker(rating, (v) => setState(() => rating = v)),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final t in tags) FilterChip(label: Text(t), selected: sel.contains(t), onSelected: (v) => setState(() => v ? sel.add(t) : sel.remove(t)))]),
        const SizedBox(height: 14),
        TF('Komentar', cm, lines: 3),
        if (o.iAmClient) obtn(photo ? 'Foto ditambahkan' : 'Tambah foto (opsional)', () => setState(() => photo = true), icon: Icons.add_a_photo_outlined),
        const SizedBox(height: 12),
        const Warn('Ulasan dipublikasikan setelah kedua pihak menilai atau 7 hari berlalu (double-blind), supaya tidak saling membalas.', icon: Icons.visibility_off_outlined),
        const SizedBox(height: 16),
        full(pbtn('Kirim ulasan', () {
          s.submitReview(o, rating, sel.toList(), cm.text.trim());
          Navigator.pop(context);
          toast(context, 'Ulasan terkirim. Terima kasih.');
        })),
      ]),
    );
  }
}

// ---------------------------------------------------------------- sengketa
class DisputePage extends StatefulWidget {
  final String id;
  const DisputePage(this.id, {super.key});
  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage> {
  String type = 'Pekerjaan tidak selesai';
  final desc = TextEditingController();
  int ev = 0;
  final key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final s = context.r;
    final o = s.orderById(widget.id)!;
    final types = ['Pekerjaan tidak selesai', 'Kualitas buruk', 'Kerusakan atau barang hilang', 'Tidak hadir', 'Harga tambahan sepihak', 'Lainnya'];
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan masalah')),
      body: Form(
        key: key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Warn('Dana tetap ditahan selama sengketa. Pihak lain punya 48 jam menanggapi, lalu admin memutuskan.', icon: Icons.gavel_outlined),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Jenis masalah'), items: [for (final t in types) DropdownMenuItem(value: t, child: Text(t))], onChanged: (v) => setState(() => type = v ?? type)),
          const SizedBox(height: 12),
          TF('Ceritakan kronologi', desc, lines: 4, validator: (v) => (v ?? '').trim().length < 20 ? 'Minimal 20 karakter' : null),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < ev; i++) const Ph(w: 60, h: 60),
            if (ev < 5) InkWell(onTap: () => setState(() => ev++), child: Container(width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: g500), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.add_a_photo_outlined))),
          ]),
          const SizedBox(height: 20),
          full(pbtn('Kirim sengketa', () async {
            if (!key.currentState!.validate()) return;
            s.openDispute(o, type, desc.text.trim(), ev);
            Navigator.pop(context);
            toast(context, 'Sengketa diajukan. Dana ditahan.');
          })),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- invoice
class InvoicePage extends StatelessWidget {
  final String id;
  const InvoicePage(this.id, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final o = s.orderById(id)!;
    final cli = o.iAmClient;
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BURUHKU', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text('INV/${o.id}', style: const TextStyle(color: g500)),
          const Divider(height: 24),
          Kv('Tanggal', fdt(o.doneAt ?? o.created)),
          Kv('Klien', cli ? (s.name) : o.otherName),
          Kv('Agen', cli ? o.otherName : s.name),
          Kv('Pekerjaan', o.title),
          const Divider(height: 24),
          Kv('Harga ${o.ptype == 'lump' ? 'borongan' : '(${rp(o.unit)}${unitOf(o.ptype)})'}', rp(o.price)),
          if (o.extra > 0) Kv('Tambahan disetujui', rp(o.extra)),
          Kv('Biaya layanan', rp(o.fee)),
          if (!cli) Kv('Komisi platform (10%)', '-${rp(o.commission)}'),
          const Divider(height: 24),
          Kv(cli ? 'Total dibayar' : 'Pendapatan bersih', rp(cli ? o.total + o.fee : o.net), bold: true),
          Kv('Metode', o.payMethod.isEmpty ? '-' : o.payMethod),
        ])),
        const SizedBox(height: 14),
        full(obtn('Unduh PDF (simulasi)', () => toast(context, 'Invoice PDF disimpan (simulasi).'), icon: Icons.download_outlined)),
      ]),
    );
  }
}