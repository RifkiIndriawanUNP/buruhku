import 'package:flutter/material.dart';
import 'package:buruhku/ui/account/wallet_view_model.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/service/service_screen.dart';

/// Alias agar pemanggilan lama [AgentSettingsPage] tetap kompatibel.
typedef AgentSettingsPage = AgentProfilePage;

class AgentProfilePage extends StatelessWidget {
  const AgentProfilePage({super.key});

  Widget _stat(Widget top, String label) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          top,
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: g500)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final ok = k.status == 'approved';
    final lv = s.myLevel;
    final wallet = WalletViewModel(s);
    final revs = wallet.agentReviews;
    final svcs = s.mySvcs;
    final lvl = lv == 0 ? 'Belum Verifikasi' : {1: 'L1 Baru', 2: 'L2 Terpercaya', 3: 'L3 Premium'}[lv]!;
    final levelSub = lv == 1
        ? 'Maks Rp500.000 / order'
        : (lv == 2 ? 'Akses semua kategori & nominal' : (lv == 3 ? 'Prioritas order' : 'Lengkapi KYC dulu'));
    final svcW = (MediaQuery.sizeOf(context).width * .564).clamp(200.0, 260.0).toDouble();
    final val = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: g900);
    String? svcLabel(Rev r) => r.svcId.isEmpty ? null : s.svcById(r.svcId)?.title;

    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Profil Agen')),
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: RevealListView(
          padding: pageListPad(context),
          children: [
            // 1. Kepala Profil Agen (Gaya AgentDetail)
            DetailCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    GestureDetector(
                      onTap: () => changeProfilePhoto(context),
                      child: const MyAvatar(size: 84),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: k.online ? kGreen : g400,
                          shape: BoxShape.circle,
                          border: Border.all(color: cW, width: 3),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                            s.name.isEmpty ? 'Mitra Buruhku' : s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: g900),
                          ),
                        ),
                        if (ok) ...[const SizedBox(width: 4), const VerifiedBadge(size: 20)],
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        k.online ? 'Online' : 'Offline',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: k.online ? kGreen : g500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        Tag(lvl, icon: Icons.shield_outlined),
                        if (s.myJobs >= 50 && s.myRating >= 4.7) const Tag('Terpercaya', icon: Icons.workspace_premium_outlined),
                        if (s.myRating >= 4.5) const Tag('Tepat waktu', icon: Icons.schedule),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    _stat(
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, size: 16, color: kStar),
                        const SizedBox(width: 4),
                        Text(s.myRating == 0 ? 'Baru' : s.myRating.toStringAsFixed(1), style: val),
                      ]),
                      '${revs.length} ulasan',
                    ),
                    _stat(Text('${s.myJobs}', style: val), 'Order selesai'),
                    _stat(Text('${k.radius.round()} km', style: val), 'Radius'),
                  ]),
                ),
              ]),
            ),

            // 2. Kartu Level & Reputasi Mitra
            DetailCard(
              title: 'Level & Reputasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.military_tech_rounded, color: kGreen, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lvl, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: g900)),
                            Text(levelSub, style: TextStyle(fontSize: 12, color: g500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Kv('Order selesai', '${s.myJobs} order'),
                  Kv('Rating', s.myRating == 0 ? 'Baru' : '${s.myRating.toStringAsFixed(2)} \u2605'),
                  Kv('Penerimaan', '${(s.acceptRate * 100).round()}%'),
                  Kv('Batal sepihak', '${s.penalty}x'),
                  if (lv == 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Syarat Level L2', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: g900)),
                              const Spacer(),
                              Text('${s.myJobs.clamp(0, 5)}/5 order', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kGreen)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (s.myJobs / 5).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: g200,
                              color: kGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Unggah SKCK + selesaikan 5 order untuk kategori sensitif.', style: TextStyle(fontSize: 11.5, color: g500)),
                        ],
                      ),
                    ),
                  ],
                  if (ok && !k.skck) ...[
                    const SizedBox(height: 12),
                    full(obtn('Unggah SKCK (Level L2)', () => s.uploadSkck(), icon: Icons.upload_file_rounded)),
                  ],
                ],
              ),
            ),

            // 3. Tawaran Jasa Saya (Bisa kelola & tambah langsung)
            // 3. Tawaran Jasa Saya (Bisa kelola & tambah langsung)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Row(
                children: [
                  Text('Tawaran Jasa (${svcs.length})', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: g900)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyServicesPage())),
                    child: const Text('Kelola', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            if (svcs.isEmpty)
              DetailCard(
                child: Row(
                  children: [
                    Expanded(child: Text('Belum ada tawaran jasa.', style: TextStyle(color: g500))),
                    obtn('Buat Jasa', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceEditPage())), icon: Icons.add_rounded),
                  ],
                ),
              )
            else
              HScroll([
                for (final v in svcs) ServiceCard(v, width: svcW),
              ]),

            const SizedBox(height: 8),

            // 4. Pengaturan Operasional & Keahlian
            DetailCard(
              title: 'Pengaturan Operasional',
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Status Online', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(k.online ? 'Terima request baru' : 'Offline', style: TextStyle(fontSize: 12, color: g500)),
                    value: k.online,
                    onChanged: ok ? (v) => s.setOnline(v) : null,
                  ),
                  Divider(height: 1, thickness: 1, color: kLine),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Order Langsung', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Terima order dari tawaran jasa & chat', style: TextStyle(fontSize: 12, color: g500)),
                    value: k.directOk,
                    onChanged: (v) {
                      k.directOk = v;
                      s.notifyListeners();
                    },
                  ),
                ],
              ),
            ),

            DetailCard(
              title: 'Keahlian',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    FilterChip(
                      avatar: CatIcon(c, size: 22),
                      label: Text(c.name),
                      selected: k.cats.contains(c.id),
                      onSelected: (v) {
                        if (v && k.cats.length >= 5) { toast(context, 'Maksimal 5 keahlian.'); return; }
                        if (!v && k.cats.length == 1) { toast(context, 'Minimal 1 keahlian.'); return; }
                        v ? k.cats.add(c.id) : k.cats.remove(c.id);
                        s.notifyListeners();
                      },
                    ),
                ],
              ),
            ),

            DetailCard(
              title: 'Radius & Jam Kerja',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Radius', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Tag('${k.radius.round()} km', filled: true),
                    ],
                  ),
                  Slider(value: k.radius, min: 1, max: 20, divisions: 19, onChanged: (v) { k.radius = v; s.notifyListeners(); }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Jam aktif', style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Tag('${two(k.fromH)}:00 – ${two(k.toH)}:00'),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(k.fromH.toDouble(), k.toH.toDouble()),
                    min: 0,
                    max: 24,
                    divisions: 24,
                    onChanged: (v) {
                      k.fromH = v.start.round();
                      k.toH = v.end.round();
                      s.notifyListeners();
                    },
                  ),
                ],
              ),
            ),

            DetailCard(
              title: 'Rekening Pencairan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kv('Bank / E-Wallet', k.bank),
                  Kv('No. rekening', k.bankNo),
                  Kv('Atas nama', k.bankHolder),
                  const SizedBox(height: 8),
                  Text('Ubah rekening hubungi Pusat Bantuan.', style: TextStyle(fontSize: 12, color: g500)),
                ],
              ),
            ),

            // 5. Ulasan Klien
            DetailCard(
              title: 'Ulasan',
              action: revs.length > 3 ? 'Lihat semua' : null,
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewListPage(
                    title: 'Ulasan Saya',
                    rating: s.myRating,
                    revs: revs,
                    svcLabel: svcLabel,
                  ),
                ),
              ),
              child: revs.isEmpty
                  ? Text('Belum ada ulasan.', style: TextStyle(color: g500))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ReviewSummary(rating: s.myRating, revs: revs),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 1, color: kLine)),
                      ReviewList(revs.take(3).toList(), svcLabel: svcLabel),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}