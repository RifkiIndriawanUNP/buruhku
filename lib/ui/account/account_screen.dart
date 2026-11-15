import 'package:flutter/material.dart';
import 'package:buruhku/ui/account/admin_view_model.dart';
import 'package:buruhku/ui/account/wallet_view_model.dart';
import 'package:flutter/services.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/agent_mode/agent_screen.dart';
import 'package:buruhku/ui/location/location_screen.dart';
import 'package:buruhku/ui/chat/chat_screen.dart';
import 'package:buruhku/ui/order/order_screen.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/ui/service/service_screen.dart';

void _go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

// ---------------------------------------------------------------- tab Akun
const _bgGray = kBgGray;
const _subGray = kSubGray;

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final unread = s.unreadNotes;

    final agentCard = Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: k.status == 'approved'
          ? full(pbtn(s.agentMode ? 'Beralih ke mode klien' : 'Beralih ke mode agen', () => s.setMode(!s.agentMode), icon: Icons.swap_horiz))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Jadi agen Buruhku', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text({'none': 'Dapatkan penghasilan dari pekerjaan harian di sekitarmu.', 'pending': 'Pendaftaran sedang direview admin.', 'rejected': 'Ditolak: ${k.reason}', 'needs_more': 'Perlu data tambahan: ${k.reason}'}[k.status]!, style: const TextStyle(fontSize: 13.5, color: _subGray)),
              if (k.status == 'none' || k.status == 'needs_more' || (k.status == 'rejected' && k.tries < 3)) ...[
                const SizedBox(height: 10),
                full(pbtn(k.status == 'none' ? 'Daftar sekarang' : 'Lengkapi pendaftaran', () => _go(context, const KycPage()), icon: Icons.how_to_reg_outlined)),
              ],
            ]),
    );

    return ColoredBox(
      color: _bgGray,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: ListView(padding: const EdgeInsets.only(top: 20, bottom: kBarSpace), children: [
          // ---- kepala profil
          Center(
            child: GestureDetector(
              onTap: () => _go(context, const EditProfilePage()),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const MyAvatar(size: 100),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: kBlue, shape: BoxShape.circle, border: Border.all(color: _bgGray, width: 3)),
                    child: const Icon(Icons.camera_alt, size: 17, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(s.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, height: 1.2, color: g900))),
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('${s.phone} \u2022 ${s.agentMode ? 'Mode agen' : 'Mode klien'}', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: _subGray))),
          const SizedBox(height: 20),
          agentCard,

          // ---- akun
          SetGroup([
            SetRow(Icons.person, const Color(0xFF2F9BF0), 'Profil dan alamat', () => _go(context, const EditProfilePage()), sub: 'Nama, nomor HP, alamat'),
            if (k.status == 'approved') SetRow(Icons.storefront, const Color(0xFFF5A12B), 'Tawaran jasa saya', () => _go(context, const MyServicesPage()), sub: '${s.mySvcs.length} tawaran'),
            SetRow(Icons.account_balance_wallet, const Color(0xFF34B866), 'Dompet dan metode bayar', () => _go(context, const WalletPage()), sub: 'Saldo, e-wallet, rekening'),
          ]),

          // ---- pengaturan
          SetGroup([
            SetRow(Icons.notifications, const Color(0xFFEF4F5F), 'Notifikasi', () => _go(context, const NotifPage()), sub: unread > 0 ? '$unread belum dibaca' : 'Order dan sistem', badge: unread > 0 ? Badge(label: Text('$unread'), backgroundColor: kGreen) : null),
            SetRow(Icons.shield, const Color(0xFF8A63E8), 'Keamanan dan SOS', () => _go(context, const SafetyPage()), sub: 'Kontak darurat, tombol SOS'),
            SetRow(Icons.flag, const Color(0xFFFF7A45), 'Laporan saya', () => _go(context, const MyReportsPage()), sub: 'Laporan dan tindak lanjut'),
            SetRow(Icons.settings, const Color(0xFF8E8E93), 'Pengaturan', () => _go(context, const SettingsPage()), sub: 'PIN, biometrik, privasi, data'),
          ]),

          // ---- bantuan
          SetGroup([
            SetRow(Icons.help, const Color(0xFF22B8CF), 'Pusat bantuan', () => _go(context, const HelpPage()), sub: 'Pertanyaan umum dan kontak'),
            SetRow(Icons.description, const Color(0xFF4C6EF5), 'Kebijakan dan ketentuan', () => _go(context, const PolicyListPage()), sub: 'Syarat layanan dan privasi'),
            SetRow(Icons.admin_panel_settings, const Color(0xFFD6409F), 'Panel Admin (Simulasi)', () => _go(context, const AdminPage()), sub: 'Setujui KYC, moderasi, sengketa, laporan'),
          ]),

          // ---- keluar
          SetGroup([
            SetRow(Icons.logout, const Color(0xFFEF4F5F), 'Keluar', titleColor: const Color(0xFFE5484D), () async {
              if (await confirm(context, 'Keluar?', 'Data di perangkat ini tetap tersimpan untuk nomor yang sama.', ok: 'Keluar') && context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                context.r.logout();
              }
            }),
          ]),
          const SizedBox(height: 8),
          const Center(child: Text('Buruhku v1.0 (prototype lokal)', style: TextStyle(color: g400, fontSize: 12))),
        ]),
      ),
    );
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
        appBar: PageBar(title: const Text('Profil dan alamat')),
        body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Center(child: Column(children: [
              const MyAvatar(size: 80),
              TextButton.icon(onPressed: () => changeProfilePhoto(context), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Ubah foto profil')),
            ])),
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
    final led = WalletViewModel(s).clientLedger;
    return Scaffold(
      appBar: PageBar(title: const Text('Dompet dan metode bayar')),
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
  int tab = 0; // 0 semua, 1 order, 2 sistem
  late final Set<String> _fresh; // notifikasi yang belum dibaca saat halaman dibuka

  @override
  void initState() {
    super.initState();
    final s = context.r;
    _fresh = s.notes.where((n) => !n.read).map((n) => n.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => s.readAllNotes());
  }

  String _day(DateTime d) {
    final n = DateTime.now();
    final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    return diff <= 0 ? 'Hari ini' : (diff == 1 ? 'Kemarin' : 'Lebih lama');
  }

  /// Notifikasi order membuka order terkait. Notifikasi request membuka order bila sudah
  /// terbentuk (grup bila lebih dari satu agen), kalau belum membuka detail request.
  void _open(Note n) {
    final s = context.r;
    final id = n.refId ?? '';
    Widget? page;
    switch (n.refType) {
      case 'order':
        if (s.orderById(id) != null) page = OrderPage(id);
        break;
      case 'request':
        if (s.reqById(id) != null) {
          final os = s.orders.where((o) => o.reqId == id && o.iAmClient).toList();
          page = os.length > 1 ? GroupOrderPage(id) : (os.length == 1 ? OrderPage(os.first.id) : ReqDetailPage(id));
        }
        break;
      case 'chat':
        if (s.chats.any((c) => c.id == id)) page = ChatPage(id);
        break;
    }
    if (page == null) {
      toast(context, 'Data terkait sudah tidak tersedia.');
      return;
    }
    final p = page;
    Navigator.push(context, MaterialPageRoute(builder: (_) => p));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final list = s.notes.where((n) => tab == 0 || (tab == 1 ? n.isOrder : !n.isOrder)).toList();
    final rows = <Widget>[];
    String? last;
    for (final n in list) {
      final d = _day(n.at);
      if (d != last) {
        last = d;
        rows.add(Padding(padding: EdgeInsets.only(bottom: 12, top: rows.isEmpty ? 0 : 4), child: Text(d, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3DBE7A)))));
      }
      rows.add(_NoteRow(n, fresh: _fresh.contains(n.id), onTap: n.isOrder ? () => _open(n) : null));
    }
    return Scaffold(
      body: SafeArea(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.25,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
            Row(children: [
              RoundBtn(size: 48, onTap: () => Navigator.maybePop(context), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
              const Expanded(child: Center(child: Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900)))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 18),
            PillTabs(labels: const ['Semua', 'Order', 'Sistem'], index: tab, onChanged: (i) => setState(() => tab = i)),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, fit: StackFit.passthrough, children: [...previous, if (current != null) current]),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim), child: child)),
              child: SoftCard(
              key: ValueKey(tab),
              radius: 28,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: list.isEmpty
                  ? Padding(padding: const EdgeInsets.only(bottom: 12), child: Empty(Icons.notifications_none, tab == 1 ? 'Belum ada notifikasi order.' : (tab == 2 ? 'Belum ada notifikasi sistem.' : 'Belum ada notifikasi.')))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final Note n;
  final bool fresh;
  final VoidCallback? onTap;
  const _NoteRow(this.n, {required this.fresh, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            n.isOrder
                ? const AvatarPh(46)
                : Container(width: 46, height: 46, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDADADA)), child: const Icon(Icons.notifications_none, size: 24, color: Color(0xFF9A9CA5))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25, color: g900))),
                  if (fresh) ...[const SizedBox(width: 6), Container(width: 8, height: 8, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle))],
                ]),
                const SizedBox(height: 2),
                Text.rich(TextSpan(style: const TextStyle(fontSize: 14, height: 1.3, color: g900), children: [
                  TextSpan(text: n.body),
                  TextSpan(text: ' \u2022 ${ago(n.at)}', style: const TextStyle(color: g500)),
                ])),
              ]),
            ),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- pengaturan
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget sw(bool v, ValueChanged<bool> f) => Switch(value: v, onChanged: f);
    return Scaffold(
      appBar: PageBar(title: const Text('Pengaturan')),
      body: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        const SetTitle('Notifikasi'),
        SetGroup([
          SetRow(Icons.shopping_bag, const Color(0xFFF5A12B), 'Status order dan pembayaran', null, badge: sw(s.nOrder, (v) { s.nOrder = v; s.notifyListeners(); })),
          SetRow(Icons.chat_bubble, const Color(0xFF2F9BF0), 'Pesan chat', null, badge: sw(s.nChat, (v) { s.nChat = v; s.notifyListeners(); })),
          SetRow(Icons.campaign, const Color(0xFFEF4F5F), 'Promo dan info', null, badge: sw(s.nPromo, (v) { s.nPromo = v; s.notifyListeners(); })),
        ]),
        const SetTitle('Keamanan'),
        SetGroup([
          SetRow(Icons.pin, const Color(0xFF8A63E8), s.pin.isEmpty ? 'Buat PIN transaksi' : 'Ubah PIN transaksi', () async {
            final p = await askText(context, 'PIN baru (4-6 digit)', number: true, obscure: true);
            if (p == null) return;
            if (p.length < 4 || p.length > 6) {
              if (context.mounted) toast(context, 'PIN harus 4 sampai 6 digit.');
              return;
            }
            s.pin = p;
            s.notifyListeners();
            if (context.mounted) toast(context, 'PIN disimpan.');
          }, sub: 'Dipakai untuk menarik saldo'),
          SetRow(Icons.fingerprint, const Color(0xFF34B866), 'Biometrik (simulasi)', null,
              badge: sw(s.biometric, (v) async {
                if (!v || await confirm(context, 'Aktifkan biometrik?', 'Pada aplikasi rilis ini memakai sidik jari atau wajah perangkat.', ok: 'Aktifkan')) {
                  s.biometric = v;
                  s.notifyListeners();
                }
              })),
        ]),
        const SetTitle('Umum'),
        SetGroup([
          SetRow(Icons.language, const Color(0xFF22B8CF), 'Bahasa', null, sub: 'Indonesia (English segera hadir)'),
        ]),
        const SetTitle('Privasi dan data'),
        SetGroup([
          SetRow(Icons.download, const Color(0xFF4C6EF5), 'Ekspor data saya', () {
            final j = s.exportJson();
            showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Ekspor data'),
                content: SizedBox(width: double.maxFinite, height: 320, child: SingleChildScrollView(child: SelectableText(j, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')))),
                actions: [TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: j)); toast(d, 'JSON disalin.'); }, child: const Text('Salin')), FilledButton(onPressed: () => Navigator.pop(d), child: const Text('Tutup'))],
              ),
            );
          }, sub: 'Salinan data akun dalam format JSON'),
          SetRow(Icons.delete_forever, const Color(0xFFEF4F5F), 'Hapus akun', titleColor: kRed, () async {
            final v = await askText(context, 'Ketik HAPUS untuk konfirmasi', hint: 'HAPUS');
            if (v == 'HAPUS' && context.mounted) {
              forgetProfilePhoto(context);
              Navigator.of(context).popUntil((r) => r.isFirst);
              s.deleteAccount();
            } else if (v != null && context.mounted) {
              toast(context, 'Konfirmasi tidak cocok.');
            }
          }, sub: 'Menghapus semua data di perangkat ini'),
        ]),
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
      appBar: PageBar(title: const Text('Keamanan dan SOS')),
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
  List<String> evPaths = [];
  final key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: PageBar(title: const Text('Buat laporan')),
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
            PhotoStrip(paths: evPaths, size: 60, onChanged: (l) => setState(() { evPaths = l; ev = l.length; })),
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
      appBar: PageBar(title: const Text('Laporan saya'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _go(context, const ReportPage()))]),
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
      appBar: PageBar(title: const Text('Pusat bantuan')),
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
        appBar: PageBar(title: const Text('Kebijakan dan ketentuan')),
        body: ListView(children: [SetGroup([for (final k in _policies.keys) SetRow(Icons.description, const Color(0xFF4C6EF5), k, () => _go(context, PolicyPage(k)), badge: const Icon(Icons.chevron_right, color: g400))])]),
      );
}

class PolicyPage extends StatelessWidget {
  final String title;
  const PolicyPage(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: PageBar(title: Text(title)),
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
    final vm = AdminViewModel(s);
    final review = vm.reviewQueue;
    final reps = vm.openReports;
    final disps = vm.openDisputes;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: PageBar(title: const Text('Panel Admin (Simulasi)'), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'KYC'), Tab(text: 'Moderasi'), Tab(text: 'Laporan'), Tab(text: 'Sengketa'), Tab(text: 'SOS'), Tab(text: 'Statistik')])),
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
              Kv('Request dibuat', '${vm.requestsCreated}'),
              Kv('Order total', '${vm.ordersTotal}'),
              Kv('Order selesai', '${vm.ordersDone}'),
              Kv('GMV selesai', rp(vm.gmv)),
              Kv('Pendapatan platform', rp(vm.platformRevenue)),
              Kv('Sengketa', '${vm.disputesTotal}'),
              Kv('Laporan', '${vm.reportsTotal}'),
              Kv('Alarm SOS', '${vm.sosTotal}'),
              Kv('Agen simulasi', '${vm.agentCount}'),
            ])),
          ]),
        ]),
      ),
    );
  }
}
