import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../store.dart';
import '../ui.dart';
import 'agent.dart';
import 'location.dart';
import 'order.dart';
import 'service.dart';

void _go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

// ---------------------------------------------------------------- tab Akun
class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    Widget tile(IconData i, String t, Widget page, {String? sub}) =>
        ListTile(leading: Icon(i), title: Text(t), subtitle: sub == null ? null : Text(sub), trailing: const Icon(Icons.chevron_right), onTap: () => _go(context, page));
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Avatar(size: 64),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(s.phone, style: const TextStyle(color: g500)),
            const SizedBox(height: 6),
            Tag(s.agentMode ? 'Mode agen' : 'Mode klien', icon: s.agentMode ? Icons.handyman_outlined : Icons.person_outline, filled: true),
          ])),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: k.status == 'approved'
            ? full(pbtn(s.agentMode ? 'Beralih ke mode klien' : 'Beralih ke mode agen', () => s.setMode(!s.agentMode), icon: Icons.swap_horiz))
            : Box(color: g100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Jadi agen Buruhku', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text({'none': 'Dapatkan penghasilan dari pekerjaan harian di sekitarmu.', 'pending': 'Pendaftaran sedang direview admin.', 'rejected': 'Ditolak: ${k.reason}', 'needs_more': 'Perlu data tambahan: ${k.reason}'}[k.status]!, style: const TextStyle(fontSize: 12.5, color: g700)),
                const SizedBox(height: 8),
                if (k.status == 'none' || k.status == 'needs_more' || (k.status == 'rejected' && k.tries < 3)) full(pbtn(k.status == 'none' ? 'Daftar sekarang' : 'Lengkapi pendaftaran', () => _go(context, const KycPage()), icon: Icons.how_to_reg_outlined)),
              ])),
      ),
      const SizedBox(height: 8),
      tile(Icons.person_outline, 'Profil dan alamat', const EditProfilePage()),
      if (k.status == 'approved') tile(Icons.storefront_outlined, 'Tawaran jasa saya', const MyServicesPage(), sub: '${s.mySvcs.length} tawaran'),
      tile(Icons.account_balance_wallet_outlined, 'Dompet dan metode bayar', const WalletPage()),
      ListTile(
        leading: Badge(isLabelVisible: s.unreadNotes > 0, label: Text('${s.unreadNotes}'), backgroundColor: g900, child: const Icon(Icons.notifications_none)),
        title: const Text('Notifikasi'), trailing: const Icon(Icons.chevron_right), onTap: () => _go(context, const NotifPage()),
      ),
      tile(Icons.shield_outlined, 'Keamanan dan SOS', const SafetyPage()),
      tile(Icons.flag_outlined, 'Laporan saya', const MyReportsPage()),
      tile(Icons.settings_outlined, 'Pengaturan', const SettingsPage()),
      tile(Icons.help_outline, 'Pusat bantuan', const HelpPage()),
      tile(Icons.description_outlined, 'Kebijakan dan ketentuan', const PolicyListPage()),
      tile(Icons.admin_panel_settings_outlined, 'Panel Admin (Simulasi)', const AdminPage(), sub: 'Setujui KYC, moderasi, sengketa, laporan'),
      ListTile(
        leading: const Icon(Icons.logout), title: const Text('Keluar'),
        onTap: () async {
          if (await confirm(context, 'Keluar?', 'Data di perangkat ini tetap tersimpan untuk nomor yang sama.', ok: 'Keluar') && context.mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            context.r.logout();
          }
        },
      ),
      const SizedBox(height: 24),
      const Center(child: Text('Buruhku v1.0 (prototype lokal)', style: TextStyle(color: g400, fontSize: 12))),
      const SizedBox(height: 24),
    ]);
  }
}

// ---------------------------------------------------------------- profil
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final n = TextEditingController(text: context.r.name);
  late final a = TextEditingController(text: context.r.address);
  late final en = TextEditingController(text: context.r.emName);
  late final ep = TextEditingController(text: context.r.emPhone);
  final key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Profil dan alamat')),
        body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Center(child: Avatar(size: 80)),
            const SizedBox(height: 16),
            TF('Nama', n, validator: (v) => (v ?? '').trim().length < 3 ? 'Minimal 3 huruf' : null),
            TF('Nomor HP', TextEditingController(text: context.r.phone), enabled: false),
            TF('Alamat default', a, lines: 2),
            const SavedPlacesSection(),
            const SizedBox(height: 8),
            const Section('Kontak darurat'),
            TF('Nama', en),
            TF('No. HP', ep, type: TextInputType.phone),
            full(pbtn('Simpan', () {
              if (!key.currentState!.validate()) return;
              context.r.saveProfile(n: n.text.trim(), addr: a.text.trim(), en: en.text.trim(), ep: ep.text.trim());
              Navigator.pop(context);
              toast(context, 'Profil disimpan.');
            })),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- dompet klien
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final led = s.ledger.where((l) => l.role == 'c').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dompet dan metode bayar')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Warn('Pembayaran order selalu lewat escrow. Refund dikembalikan ke metode bayar asal.', icon: Icons.lock_outline),
        Section('E-wallet tersimpan', action: 'Tambah', onAction: () async {
          var w = 'GoPay';
          final no = TextEditingController();
          final ok = await showDialog<bool>(
              context: context,
              builder: (d) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
                    title: const Text('Tambah e-wallet'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(initialValue: w, items: [for (final x in ['GoPay', 'OVO', 'DANA', 'ShopeePay']) DropdownMenuItem(value: x, child: Text(x))], onChanged: (v) => set(() => w = v ?? w)),
                      const SizedBox(height: 10),
                      TextField(controller: no, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor akun')),
                    ]),
                    actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Simpan'))],
                  )));
          if (ok == true && no.text.trim().length >= 8) {
            s.wallets.add('$w|${no.text.trim()}');
            s.notifyListeners();
          }
        }),
        if (s.wallets.isEmpty) const Text('Belum ada e-wallet.', style: TextStyle(color: g500)),
        for (final w in s.wallets)
          ListTile(
            contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_balance_wallet_outlined), title: Text(w.split('|').first), subtitle: Text(w.split('|').last),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () { s.wallets.remove(w); s.notifyListeners(); }),
          ),
        const Section('Riwayat transaksi'),
        if (led.isEmpty) const Text('Belum ada transaksi.', style: TextStyle(color: g500)),
        for (final l in led)
          ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: Icon(l.amount >= 0 ? Icons.south_west : Icons.north_east, size: 18), title: Text(l.note), subtitle: Text(fdt(l.at)), trailing: Text(rp(l.amount), style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

// ---------------------------------------------------------------- notifikasi
class NotifPage extends StatefulWidget {
  const NotifPage({super.key});
  @override
  State<NotifPage> createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  @override
  void initState() {
    super.initState();
    final s = context.r;
    WidgetsBinding.instance.addPostFrameCallback((_) => s.readAllNotes());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: s.notes.isEmpty
          ? const Empty(Icons.notifications_none, 'Belum ada notifikasi.')
          : ListView.separated(
              itemCount: s.notes.length, separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final n = s.notes[i];
                return ListTile(leading: const Icon(Icons.notifications_none), title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(n.body), trailing: Text(ago(n.at), style: const TextStyle(fontSize: 11, color: g500)));
              },
            ),
    );
  }
}

// ---------------------------------------------------------------- pengaturan
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.w800))),
        SwitchListTile(title: const Text('Status order dan pembayaran'), value: s.nOrder, onChanged: (v) { s.nOrder = v; s.notifyListeners(); }),
        SwitchListTile(title: const Text('Pesan chat'), value: s.nChat, onChanged: (v) { s.nChat = v; s.notifyListeners(); }),
        SwitchListTile(title: const Text('Promo dan info'), value: s.nPromo, onChanged: (v) { s.nPromo = v; s.notifyListeners(); }),
        const Divider(),
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text('Keamanan', style: TextStyle(fontWeight: FontWeight.w800))),
        ListTile(
          leading: const Icon(Icons.pin_outlined), title: Text(s.pin.isEmpty ? 'Buat PIN transaksi' : 'Ubah PIN transaksi'), subtitle: const Text('Dipakai untuk menarik saldo'),
          onTap: () async {
            final p = await askText(context, 'PIN baru (4-6 digit)', number: true, obscure: true);
            if (p == null) return;
            if (p.length < 4 || p.length > 6) {
              if (context.mounted) toast(context, 'PIN harus 4 sampai 6 digit.');
              return;
            }
            s.pin = p;
            s.notifyListeners();
            if (context.mounted) toast(context, 'PIN disimpan.');
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint), title: const Text('Biometrik (simulasi)'), value: s.biometric,
          onChanged: (v) async {
            if (!v || await confirm(context, 'Aktifkan biometrik?', 'Pada aplikasi rilis ini memakai sidik jari atau wajah perangkat.', ok: 'Aktifkan')) {
              s.biometric = v;
              s.notifyListeners();
            }
          },
        ),
        const Divider(),
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text('Umum', style: TextStyle(fontWeight: FontWeight.w800))),
        const ListTile(leading: Icon(Icons.language), title: Text('Bahasa'), subtitle: Text('Indonesia (English segera hadir)')),
        const Divider(),
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text('Privasi dan data', style: TextStyle(fontWeight: FontWeight.w800))),
        ListTile(
          leading: const Icon(Icons.download_outlined), title: const Text('Ekspor data saya'), subtitle: const Text('Salinan data akun dalam format JSON'),
          onTap: () {
            final j = s.exportJson();
            showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Ekspor data'),
                content: SizedBox(width: double.maxFinite, height: 320, child: SingleChildScrollView(child: SelectableText(j, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')))),
                actions: [TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: j)); toast(d, 'JSON disalin.'); }, child: const Text('Salin')), FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Tutup'))],
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined), title: const Text('Hapus akun'), subtitle: const Text('Menghapus semua data di perangkat ini'),
          onTap: () async {
            final v = await askText(context, 'Ketik HAPUS untuk konfirmasi', hint: 'HAPUS');
            if (v == 'HAPUS' && context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
              s.deleteAccount();
            } else if (v != null && context.mounted) {
              toast(context, 'Konfirmasi tidak cocok.');
            }
          },
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- keamanan & SOS
class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan dan SOS')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const SosButton(),
        const SizedBox(height: 8),
        const Text('Saat SOS ditekan, lokasi live dibagikan ke kontak darurat dan tim keamanan Buruhku.', style: TextStyle(fontSize: 12.5, color: g500)),
        const Section('Kontak darurat'),
        Box(child: Row(children: [
          const Icon(Icons.contact_phone_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(s.emName.isEmpty ? 'Belum diatur' : '${s.emName}\n${s.emPhone}')),
          TextButton(onPressed: () => _go(context, const EditProfilePage()), child: const Text('Ubah')),
        ])),
        const Section('Tips aman'),
        for (final t in ['Pastikan wajah agen sesuai foto profil sebelum memberi PIN kerja.', 'Bayar hanya lewat escrow Buruhku. Tolak ajakan transfer di luar aplikasi.', 'Jangan bagikan OTP, PIN, atau kode verifikasi ke siapa pun.', 'Untuk pekerjaan di dalam rumah, usahakan ada orang lain di rumah.', 'Laporkan perilaku mencurigakan lewat menu Laporan.'])
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, size: 18), const SizedBox(width: 8), Expanded(child: Text(t))])),
        const Section('Riwayat SOS'),
        if (s.soses.isEmpty) const Text('Belum ada.', style: TextStyle(color: g500)),
        for (final x in s.soses) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.sos_outlined), title: Text(fdt(x.at)), subtitle: Text(x.info), trailing: Tag(x.resolved ? 'Selesai' : 'Ditangani')),
      ]),
    );
  }
}

// ---------------------------------------------------------------- laporan
class ReportPage extends StatefulWidget {
  final String target, targetId, orderId, prefill;
  const ReportPage({this.target = '', this.targetId = '', this.orderId = '', this.prefill = '', super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String cat = 'Penipuan';
  late final desc = TextEditingController(text: widget.prefill);
  late final target = TextEditingController(text: widget.target);
  int ev = 0;
  final key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Buat laporan')),
        body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            DropdownButtonFormField<String>(
              initialValue: cat, decoration: const InputDecoration(labelText: 'Jenis laporan'),
              items: [for (final c in ['Penipuan', 'Pelecehan atau kekerasan', 'Pencurian atau kerusakan', 'Joki atau identitas palsu', 'Perilaku tidak profesional', 'Pelanggaran lain']) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => cat = v ?? cat),
            ),
            const SizedBox(height: 12),
            TF('Pihak yang dilaporkan', target),
            TF('Kronologi', desc, lines: 5, validator: (v) => (v ?? '').trim().length < 15 ? 'Minimal 15 karakter' : null),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < ev; i++) const Ph(w: 60, h: 60),
              if (ev < 5) InkWell(onTap: () => setState(() => ev++), child: Container(width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: g500), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.add_a_photo_outlined))),
            ]),
            const SizedBox(height: 16),
            const Warn('Kasus pelecehan, kekerasan, atau pidana diprioritaskan dan bisa dieskalasi ke Tim Legal untuk pendampingan laporan polisi.', icon: Icons.shield_outlined),
            const SizedBox(height: 16),
            full(pbtn('Kirim laporan', () async {
              if (!key.currentState!.validate()) return;
              final r = context.r.fileReport(cat: cat, desc: desc.text.trim(), target: target.text.trim(), orderId: widget.orderId, evid: ev);
              Navigator.pop(context);
              await info(context, 'Laporan diterima', 'Nomor tiket ${r.no}. Tim Trust & Safety menanggapi maksimal 1x24 jam.');
            })),
          ]),
        ),
      );
}

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan saya'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _go(context, const ReportPage()))]),
      body: s.reports.isEmpty
          ? const Empty(Icons.flag_outlined, 'Belum ada laporan. Laporkan pengguna atau pesan yang mencurigakan.')
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final r in s.reports)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(r.no, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Tag(r.status, filled: r.status == 'Diterima')]),
                    Text('${r.cat}${r.target.isEmpty ? '' : ' - ${r.target}'}', style: const TextStyle(color: g700)),
                    const SizedBox(height: 4),
                    Text(r.desc, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (r.action.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Tindakan: ${r.action}', style: const TextStyle(fontSize: 12.5, color: g700))),
                    Text(ago(r.at), style: const TextStyle(fontSize: 11, color: g500)),
                  ])),
                ),
            ]),
    );
  }
}

// ---------------------------------------------------------------- bantuan
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  static const faq = [
    ['Bagaimana cara kerja pembayaran?', 'Kamu bayar ke escrow Buruhku setelah memilih agen. Dana baru dilepas ke agen setelah kamu mengonfirmasi pekerjaan selesai atau otomatis 24 jam kemudian.'],
    ['Kapan saya bisa membatalkan dan dapat refund?', 'Sebelum bayar gratis. Setelah bayar: lebih dari 3 jam sebelum jadwal refund 100%. Kurang dari 3 jam atau agen sudah berangkat refund 70% (30% kompensasi agen). Agen tidak hadir 30 menit: refund 100%.'],
    ['Apa itu PIN kerja?', 'PIN 4 digit yang ditunjukkan klien saat agen tiba. Kerja baru dimulai setelah PIN cocok, supaya tidak ada joki.'],
    ['Apa yang terjadi kalau hasil kerja bermasalah?', 'Ajukan masalah dari halaman order. Dana tetap ditahan, pihak lain menanggapi, lalu admin memutuskan.'],
    ['Pekerjaan apa yang dilarang?', 'Ilegal, berbahaya (panjat tower, listrik tegangan tinggi, bahan kimia), penagihan paksa, jasa seksual, dan pekerjaan yang butuh sertifikasi profesional.'],
    ['Berapa biaya untuk agen?', 'Komisi platform 10% dari nilai order. Biaya layanan klien Rp2.000 sampai Rp5.000 per order.'],
  ];
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sub = TextEditingController(), body = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat bantuan')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Box(color: g100, child: const Row(children: [Icon(Icons.sos_outlined, size: 28), SizedBox(width: 12), Expanded(child: Text('Darurat: Polisi 110, Ambulans 118, Darurat 112. Di aplikasi pakai tombol SOS.'))])),
        const Section('Pertanyaan umum'),
        for (final f in faq) ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(f[0], style: const TextStyle(fontWeight: FontWeight.w600)), children: [Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(f[1], style: const TextStyle(height: 1.4))))]),
        const Section('Hubungi kami'),
        TF('Subjek', sub),
        TF('Pesan', body, lines: 3),
        full(pbtn('Kirim tiket', () {
          if (sub.text.trim().isEmpty || body.text.trim().length < 10) {
            toast(context, 'Isi subjek dan pesan (min 10 karakter).');
            return;
          }
          final t = s.createTicket(sub.text.trim(), body.text.trim());
          sub.clear();
          body.clear();
          toast(context, 'Tiket ${t.no} dibuat.');
        })),
        if (s.tickets.isNotEmpty) ...[
          const Section('Tiket saya'),
          for (final t in s.tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(t.no, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Tag(t.status, filled: t.status == 'Dijawab')]),
                Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (t.reply.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Balasan: ${t.reply}', style: const TextStyle(fontSize: 12.5, color: g700))),
              ])),
            ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------- kebijakan
const _policies = {
  'Syarat & Ketentuan': 'Buruhku adalah platform yang mempertemukan pemberi kerja dan tenaga harian. Buruhku bukan pemberi kerja dan tidak menjamin hasil, tetapi menyediakan verifikasi identitas, escrow, dan penyelesaian sengketa.\n\nPengguna wajib berusia 18 tahun ke atas, memberi data yang benar, dan tidak memakai platform untuk kegiatan ilegal.\n\nPembayaran order wajib melalui escrow. Transaksi di luar platform tidak dilindungi.',
  'Kebijakan Privasi': 'Data KTP dan selfie hanya dipakai untuk verifikasi identitas dan disimpan terenkripsi. Alamat lengkap klien baru terlihat oleh agen setelah pembayaran. Nomor HP disamarkan di chat. Kamu dapat mengekspor atau menghapus data dari menu Pengaturan.',
  'Kebijakan Refund & Pembatalan': 'Batal sebelum bayar: gratis.\nBatal lebih dari 3 jam sebelum jadwal: refund 100%.\nBatal kurang dari 3 jam atau agen sudah berangkat: refund 70%, 30% kompensasi agen.\nAgen tidak hadir 30 menit: refund 100% dan reputasi agen turun.\nKlien tidak hadir 30 menit: agen mendapat kompensasi 30%.',
  'Kode Etik Agen': 'Agen wajib datang sendiri (dilarang joki), bekerja jujur, sopan, menjaga barang dan privasi klien, tidak meminta bayaran di luar aplikasi, dan tidak membatalkan sepihak tanpa alasan kuat.',
  'Pedoman Komunitas': 'Dilarang: pelecehan, kekerasan, diskriminasi, penipuan, ujaran kebencian, dan meminta transfer di luar aplikasi. Pelanggaran ditindak mulai peringatan, suspend, hingga blokir permanen dan eskalasi hukum.',
  'Daftar Larangan Pekerjaan': 'Dilarang: narkoba/judi, penagihan paksa, pekerjaan berbahaya (panjat tower, listrik tegangan tinggi, bahan kimia), jasa seksual, pekerjaan yang butuh sertifikasi profesional (medis, listrik besar), serta tindakan melanggar hukum lainnya.',
};

class PolicyListPage extends StatelessWidget {
  const PolicyListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Kebijakan dan ketentuan')),
        body: ListView(children: [for (final k in _policies.keys) ListTile(title: Text(k), trailing: const Icon(Icons.chevron_right), onTap: () => _go(context, PolicyPage(k)))]),
      );
}

class PolicyPage extends StatelessWidget {
  final String title;
  const PolicyPage(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(16), children: [Text(_policies[title] ?? '', style: const TextStyle(height: 1.5)), const SizedBox(height: 16), const Text('Versi prototype: isi final perlu ditinjau konsultan hukum.', style: TextStyle(color: g500, fontSize: 12))]),
      );
}

// ---------------------------------------------------------------- panel admin (simulasi)
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final review = s.reqs.where((r) => r.mine && r.status == 'IN_REVIEW').toList();
    final reps = s.reports.where((r) => r.status == 'Diterima').toList();
    final disps = s.disputes.where((d) => d.status != 'resolved' && d.status != 'cancelled').toList();
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(title: const Text('Panel Admin (Simulasi)'), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'KYC'), Tab(text: 'Moderasi'), Tab(text: 'Laporan'), Tab(text: 'Sengketa'), Tab(text: 'SOS'), Tab(text: 'Statistik')])),
        body: TabBarView(children: [
          // KYC
          (k.status == 'pending' || k.status == 'needs_more')
              ? ListView(padding: const EdgeInsets.all(16), children: [
                  Box(child: Column(children: [
                    Kv('Nama', k.name), Kv('NIK', k.nik), Kv('Lahir', k.birth), Kv('Alamat', k.addr),
                    Kv('Kontak darurat', '${k.emName} ${k.emPhone}'), Kv('KTP', k.ktp ? 'Terunggah' : '-'), Kv('Selfie liveness', k.selfie ? 'Lolos 94%' : '-'),
                    Kv('SKCK', k.skck ? 'Ada' : 'Tidak ada'), Kv('Keahlian', k.cats.map((c) => catOf(c).name).join(', ')), Kv('Rekening', '${k.bank} ${k.bankNo} a.n. ${k.bankHolder}'),
                  ])),
                  const SizedBox(height: 12),
                  full(pbtn('Setujui', () => s.adminKyc('approve'), icon: Icons.check)),
                  const SizedBox(height: 8),
                  full(obtn('Tolak', () async {
                    final r = await askText(context, 'Alasan penolakan', hint: 'mis. Foto KTP buram');
                    if (r != null) s.adminKyc('reject', r);
                  })),
                  const SizedBox(height: 8),
                  full(obtn('Minta data tambahan', () async {
                    final r = await askText(context, 'Data yang diminta', hint: 'mis. Selfie dengan KTP');
                    if (r != null) s.adminKyc('more', r);
                  })),
                ])
              : Empty(Icons.how_to_reg_outlined, 'Tidak ada antrean KYC. Status pendaftaranmu: ${k.status}.'),
          // moderasi
          review.isEmpty
              ? const Empty(Icons.rule, 'Tidak ada request yang menunggu tinjauan.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final r in review)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(r.desc),
                        const SizedBox(height: 4),
                        Text(r.reason, style: const TextStyle(fontSize: 12.5, color: g700)),
                        const SizedBox(height: 8),
                        Row(children: [Expanded(child: pbtn('Setujui', () => s.adminApproveReq(r))), const SizedBox(width: 8), Expanded(child: obtn('Hapus', () => s.adminRejectReq(r)))]),
                      ])),
                    ),
                ]),
          // laporan
          reps.isEmpty
              ? const Empty(Icons.flag_outlined, 'Tidak ada laporan baru.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final r in reps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r.no}: ${r.cat}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Terlapor: ${r.target.isEmpty ? '-' : r.target}', style: const TextStyle(color: g700)),
                        Text(r.desc),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, children: [
                          OutlinedButton(onPressed: () => s.adminTriage(r, 'warn'), child: const Text('Peringatan')),
                          OutlinedButton(onPressed: () => s.adminTriage(r, 'suspend'), child: const Text('Suspend')),
                          FilledButton(onPressed: () => s.adminTriage(r, 'legal'), child: const Text('Eskalasi legal')),
                        ]),
                      ])),
                    ),
                ]),
          // sengketa
          disps.isEmpty
              ? const Empty(Icons.gavel_outlined, 'Tidak ada sengketa terbuka.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final d in disps)
                    Builder(builder: (_) {
                      final o = s.orderById(d.orderId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${o?.title ?? d.orderId}  (${o == null ? '' : rp(o.total)})', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(d.type, style: const TextStyle(color: g700)),
                          Text(d.desc),
                          if (d.response.isNotEmpty) Text('Tanggapan: ${d.response}', style: const TextStyle(fontSize: 12.5, color: g500)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, children: [
                            OutlinedButton(onPressed: () => s.resolveDispute(d, 'release'), child: const Text('Lepas ke agen')),
                            OutlinedButton(onPressed: () => s.resolveDispute(d, 'refund'), child: const Text('Refund penuh')),
                            FilledButton(onPressed: () => s.resolveDispute(d, 'split'), child: const Text('Bagi 50:50')),
                          ]),
                        ])),
                      );
                    }),
                ]),
          // SOS
          s.soses.isEmpty
              ? const Empty(Icons.sos_outlined, 'Tidak ada alarm SOS.')
              : ListView(padding: const EdgeInsets.all(16), children: [
                  for (final x in s.soses)
                    ListTile(leading: const Icon(Icons.sos_outlined), title: Text('${fdt(x.at)}${x.orderId.isEmpty ? '' : '  |  ${x.orderId}'}'), subtitle: Text(x.info), trailing: x.resolved ? const Tag('Selesai') : FilledButton(onPressed: () => s.resolveSos(x), child: const Text('Selesaikan'))),
                ]),
          // statistik
          ListView(padding: const EdgeInsets.all(16), children: [
            Box(child: Column(children: [
              Kv('Request dibuat', '${s.reqs.where((r) => r.mine).length}'),
              Kv('Order total', '${s.orders.length}'),
              Kv('Order selesai', '${s.orders.where((o) => o.status == 'COMPLETED' || o.status == 'REVIEWED').length}'),
              Kv('GMV selesai', rp(s.orders.where((o) => o.status == 'COMPLETED' || o.status == 'REVIEWED').fold(0, (a, o) => a + o.total))),
              Kv('Pendapatan platform', rp(s.orders.where((o) => o.status == 'COMPLETED' || o.status == 'REVIEWED').fold(0, (a, o) => a + o.fee + o.commission))),
              Kv('Sengketa', '${s.disputes.length}'),
              Kv('Laporan', '${s.reports.length}'),
              Kv('Alarm SOS', '${s.soses.length}'),
              Kv('Agen simulasi', '${s.agents.length}'),
            ])),
          ]),
        ]),
      ),
    );
  }
}
