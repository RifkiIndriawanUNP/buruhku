import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/chat/chat_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';
import 'agent_profile_page.dart';
import 'kyc_page.dart';

class IncomingTab extends StatefulWidget {
  const IncomingTab({super.key});
  @override
  State<IncomingTab> createState() => _IncomingTabState();
}

class _IncomingTabState extends State<IncomingTab> {
  int _tabIndex = 0; // 0 = Request sekitar, 1 = Order langsung

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final ok = k.status == 'approved';
    final l = ok ? s.incoming : <Req>[];
    final dl = ok ? s.incomingDirect : <DirectReq>[];
    final activeSvcs = s.mySvcs.where((x) => x.active).length;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: RevealListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, kBarSpace),
        children: [
          // 1. Header Agen (Bisa diklik menuju Profil & Pengaturan Agen)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentProfilePage())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const MyAvatar(size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      s.name.isEmpty ? 'Mitra Buruhku' : s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.2, color: g900),
                                    ),
                                  ),
                                  if (ok) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(size: 17),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, size: 18, color: g500),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ok
                                    ? 'Profil Agen \u2022 ${s.myLevel == 1 ? 'Level L1' : (s.myLevel == 2 ? 'Level L2' : 'Level L3')}'
                                    : 'Profil Agen \u2022 Belum Verifikasi',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: g500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RoundBtn(
                size: 48,
                onTap: () => s.setMode(false),
                child: Tooltip(
                  message: 'Mode klien',
                  child: Icon(Icons.swap_horiz, size: 24, color: g900),
                ),
              ),
            ],
          ),

          if (!ok) _kycBanner(context, s),

          if (ok) ...[
            const SizedBox(height: 16),

            // 2. Kartu Status Online / Offline
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: k.online ? kGreen : g200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      k.online ? Icons.wifi_tethering_rounded : Icons.power_settings_new_rounded,
                      color: k.online ? Colors.white : g700,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: k.online ? kGreen : g400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              k.online ? 'Status Online' : 'Status Offline',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: g900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          k.online ? 'Radius ${k.radius.round()} km' : 'Aktifkan untuk terima order',
                          style: TextStyle(fontSize: 12, color: g500),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: k.online,
                    activeThumbColor: kGreen,
                    onChanged: (v) => s.setOnline(v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Ringkasan 3 Kolom: Hari Ini, Rating, & Tawaran Jasa
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.payments_outlined,
                    iconColor: kGreen,
                    label: 'Hari ini',
                    value: rp(s.earned(const Duration(days: 1))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: kStar,
                    label: 'Rating',
                    value: s.myRating == 0 ? 'Baru' : s.myRating.toStringAsFixed(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFFF5A12B),
                    label: 'Tawaran Jasa',
                    value: '$activeSvcs/${s.mySvcs.length}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyServicesPage())),
                  ),
                ),
              ],
            ),

            if (s.penalty > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Warn('${s.penalty}x pembatalan sepihak. Hindari batal order.'),
              ),

            const SizedBox(height: 18),

            // 4. Header & PillTabs Pekerjaan Masuk
            Row(
              children: [
                Text('Pekerjaan Masuk', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: g900)),
                const Spacer(),
                if (k.online)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l.length + dl.length} order',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            PillTabs(
              labels: ['Request Sekitar (${l.length})', 'Order Langsung (${dl.length})'],
              index: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 12),

            // 5. List Request / Order Langsung
            if (_tabIndex == 0) ...[
              if (!k.online)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Empty(Icons.cloud_off_rounded, 'Kamu sedang Offline. Aktifkan status di atas.'),
                )
              else if (l.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Empty(Icons.inbox_outlined, 'Belum ada request masuk.'),
                )
              else
                for (final r in l) _IncomingReqCard(req: r),
            ] else ...[
              if (dl.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Empty(Icons.bolt_outlined, 'Belum ada order langsung.'),
                )
              else
                for (final d in dl) _DirectCard(d),
            ],
          ],
        ],
      ),
    );
  }

  Widget _kycBanner(BuildContext context, AppState s) {
    final k = s.kyc;
    final msg = {
      'none': 'Verifikasi KTP dan selfie untuk mulai terima order.',
      'pending': 'Data sedang direview admin (maks 1x24 jam).',
      'rejected': 'Ditolak: ${k.reason}',
      'needs_more': 'Butuh data tambahan: ${k.reason}',
    }[k.status]!;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SoftCard(
        radius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.verified_user_outlined, size: 30, color: kGreen),
            ),
            const SizedBox(height: 12),
            Text(
              k.status == 'pending' ? 'Menunggu Verifikasi' : 'Aktivasi Akun Agen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: g900),
            ),
            const SizedBox(height: 6),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, height: 1.4, color: g700)),
            const SizedBox(height: 16),
            if (k.status == 'none' || k.status == 'needs_more' || (k.status == 'rejected' && k.tries < 3))
              full(
                pbtn(
                  k.status == 'none' ? 'Daftar Agen' : 'Lengkapi Data',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KycPage())),
                  icon: Icons.how_to_reg_outlined,
                ),
              ),
            if (k.status == 'rejected' && k.tries >= 3)
              Text('Batas daftar ulang (3x) tercapai.', style: TextStyle(color: g500)),
            const SizedBox(height: 10),
            full(obtn('Ke Mode Klien', () => s.setMode(false))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              if (onTap != null) ...[
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: g400),
              ],
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: g900)),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: g500)),
        ],
      ),
    );
  }
}

class _IncomingReqCard extends StatelessWidget {
  final Req req;
  const _IncomingReqCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final c = catOf(req.cat);
    final accCount = s.activeAcc(req).length;
    final unit = unitOf(req.ptype);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingDetailPage(req.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: c.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: CatIcon(c, size: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25, color: g900),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: g500),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${req.area} \u2022 ${req.dist.toStringAsFixed(1)} km \u2022 ${ago(req.created)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: g500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rp(req.price), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: g900)),
                    Text(
                      unit.isEmpty ? 'borongan' : unit.replaceFirst('/', 'per '),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: g500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: kLine),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Tag('${req.workers} orang', icon: Icons.group_outlined),
                      Tag('Slot $accCount/${req.quota}'),
                      Tag(req.clientRating.toStringAsFixed(1), icon: Icons.star_rounded),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Detail', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kGreen)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kGreen),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectCard extends StatelessWidget {
  final DirectReq d;
  const _DirectCard(this.d);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final data = d.msg.data;
    final mine = data['svcId'] != null && s.mySvcs.any((x) => x.id == data['svcId']);
    final pt = data['ptype'] as String;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Avatar(size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.chat.otherName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: g900)),
                Text(ago(d.msg.at), style: TextStyle(fontSize: 11.5, color: g500)),
              ]),
            ),
            if (mine) const Tag('Dari tawaranmu', icon: Icons.storefront_outlined, filled: true),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: g900)),
                if ((data['desc'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data['desc'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: g700)),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.event_outlined, size: 15, color: g500),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('${data['when']} \u2022 Alamat tampil setelah dibayar', style: TextStyle(fontSize: 12, color: g500)),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Penawaran', style: TextStyle(fontSize: 11, color: g500)),
                  Text('${rp(data['price'] as int)}${unitOf(pt)}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: g900)),
                ],
              ),
              const Spacer(),
              RoundBtn(
                size: 40,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(d.chat.id))),
                child: Tooltip(message: 'Chat', child: Icon(Icons.chat_bubble_outline, size: 20, color: g900)),
              ),
              const SizedBox(width: 8),
              RoundBtn(
                size: 40,
                onTap: () async {
                  if (await confirm(context, 'Tolak order?', 'Order ini akan ditolak.', ok: 'Tolak')) {
                    s.rejectDirect(d.chat, d.msg);
                  }
                },
                child: const Tooltip(message: 'Tolak', child: Icon(Icons.close_rounded, size: 20, color: kRed)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: obtn('Tawar', () async {
                final v = await askText(context, 'Tawar harga${unitOf(pt)}', hint: 'Nominal Rupiah', money: true);
                final p = money(v ?? '');
                if (v == null) return;
                if (p < 15000) {
                  if (context.mounted) toast(context, 'Minimal Rp15.000.');
                  return;
                }
                s.respondOffer(d.chat, d.msg, 'counter', counter: p);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: pbtn('Terima', () {
                final err = s.acceptDirect(d.chat, d.msg);
                toast(context, err ?? 'Order diterima.');
              }, icon: Icons.check_rounded),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- detail request (agen)
class IncomingDetailPage extends StatelessWidget {
  final String id;
  const IncomingDetailPage(this.id, {super.key});

  Future<void> _acc(BuildContext context, AppState s, Req r) async {
    var counter = false;
    final price = TextEditingController(text: fmtNum(r.price));
    final note = TextEditingController();
    final res = await sheet<bool>(
      context,
      (x) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('ACC Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            PillTabs(
              labels: ['Terima ${rp(r.price)}', 'Ajukan Harga'],
              index: counter ? 1 : 0,
              onChanged: (i) => set(() => counter = i == 1),
            ),
            const SizedBox(height: 14),
            if (counter) TF('Harga kamu (Rp${unitOf(r.ptype)})', price, money: true),
            TF('Catatan (opsional)', note, lines: 2),
            full(pbtn('Kirim ACC', () => Navigator.pop(x, true), icon: Icons.send_rounded)),
          ]),
        ),
      ),
    );
    if (res != true || !context.mounted) return;
    final p = counter ? money(price.text) : null;
    if (counter && (p == null || p < 15000)) {
      toast(context, 'Minimal Rp15.000.');
      return;
    }
    final err = s.agentAccept(r, counter: p, note: note.text.trim());
    if (err != null) {
      toast(context, err);
      return;
    }
    final c = s.chatFor(type: 'order', refId: r.id, otherId: 'c:${r.clientName}', otherName: r.clientName, otherAgent: false, title: r.title);
    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(c.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = s.reqById(id);
    if (r == null) return AppScaffold(appBar: PageBar(), body: const Empty(Icons.error_outline, 'Request tidak ditemukan.'));
    final mine = r.acc.where((a) => a.agentId == 'me').toList();
    final myAcc = mine.isEmpty ? null : mine.last;
    final rec = recRange(r.cat, r.ptype);
    final c = catOf(r.cat);
    final netEstimate = (r.unitTotal * .9).round();

    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Detail Request')),
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: RevealListView(
          padding: pagePad(context),
          children: [
            DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(color: c.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: CatIcon(c, size: 30)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25, color: g900)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                CatTag(c.name, c.color, height: 22),
                                CatTag(ptypes[r.ptype] ?? '', kPeach, height: 22),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bersih diterima (90%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: g700)),
                              const SizedBox(height: 2),
                              Text(rp(netEstimate), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGreen)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Tarif klien', style: TextStyle(fontSize: 11.5, color: g500)),
                            Text('${rp(r.price)}${unitOf(r.ptype)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: g900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Deskripsi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: g500)),
                  const SizedBox(height: 4),
                  Text(r.desc, style: TextStyle(fontSize: 14, height: 1.45, color: g900)),
                ],
              ),
            ),

            DetailCard(
              title: 'Rincian',
              child: Column(
                children: [
                  Kv('Klien', '${r.clientName} (\u2605 ${r.clientRating.toStringAsFixed(1)})'),
                  Kv('Area', '${r.area} \u2022 ${r.dist.toStringAsFixed(1)} km'),
                  Kv('Alamat', 'Tampil setelah bayar'),
                  if (r.ptype != 'lump') Kv('Total kotor', rp(r.unitTotal)),
                  Kv('Tenaga', '${r.workers} orang'),
                  Kv('Jadwal', (r.sched == 'date' && r.schedAt != null) ? fdt(r.schedAt!) : 'Sekarang'),
                  Kv('Slot ACC', '${s.activeAcc(r).length}/${r.quota}'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Tarif wajar: ${rp(rec[0])} – ${rp(rec[1])}${unitOf(r.ptype)}',
                style: TextStyle(fontSize: 12.5, color: g500),
              ),
            ),

            if (c.risk > 1)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Warn('Kategori sensitif: butuh SKCK & min Level L2.', icon: Icons.shield_outlined),
              ),

            const SizedBox(height: 16),

            if (myAcc != null && myAcc.status == 'accepted') ...[
              const Warn('ACC terkirim. Menunggu dipilih klien.', icon: Icons.hourglass_top),
              const SizedBox(height: 12),
              full(pbtn('Chat Klien', () {
                final ch = s.chatFor(type: 'order', refId: r.id, otherId: 'c:${r.clientName}', otherName: r.clientName, otherAgent: false, title: r.title);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(ch.id)));
              }, icon: Icons.chat_bubble_outline)),
              const SizedBox(height: 8),
              full(obtn('Tarik ACC', () {
                s.withdrawAcc(r);
                Navigator.pop(context);
              })),
            ] else if (myAcc != null)
              Warn('Status ACC: ${myAcc.status == 'selected' ? 'dipilih klien' : 'tidak lanjut'}.', icon: Icons.info_outline)
            else
              Row(
                children: [
                  Expanded(
                    child: obtn('Tolak', () {
                      s.agentReject(r);
                      Navigator.pop(context);
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: pbtn('ACC / Tawar', () => _acc(context, s, r), icon: Icons.check_rounded),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}