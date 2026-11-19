import 'dart:math' as math;
import 'dart:ui';
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
import 'package:buruhku/ui/core/theme.dart';

void _go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

// ---------------------------------------------------------------- tab Akun
Color get _bgGray => kBgGray;
Color get _subGray => kSubGray;

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});
  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _openAvatarOverlay(BuildContext context, String name) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, anim, _) => FadeTransition(
          opacity: anim,
          child: _ProfilePhotoOverlay(name: name),
        ),
      ),
    );
  }

  void _snapHeaderIfNeeded(double topPad) {
    if (!_scrollCtrl.hasClients) return;
    final maxExtent = topPad + 188.0;
    final minExtent = topPad + 54.0;
    final collapseRange = maxExtent - minExtent;
    final offset = _scrollCtrl.offset;

    if (offset > 0 && offset < collapseRange) {
      final target = offset > collapseRange * 0.45 ? collapseRange : 0.0;
      Future.microtask(() {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  List<Widget> _buildStaggeredItems(List<Widget> src, int epoch, {int startIndex = 3}) {
    final out = <Widget>[];
    var i = startIndex;
    for (final w in src) {
      if (w is SizedBox && w.child == null) {
        out.add(w);
      } else if (w is SelfReveal) {
        final count = w.revealCount;
        out.add(
          Reveal(
            delay: RevealItem.step * math.min(i, RevealItem.maxSteps),
            trigger: epoch,
            child: w,
          ),
        );
        i += count;
      } else {
        out.add(
          Reveal(
            delay: RevealItem.step * math.min(i++, RevealItem.maxSteps),
            trigger: epoch,
            child: w,
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    final unread = s.unreadNotes;
    final topPad = MediaQuery.paddingOf(context).top;
    final epoch = RevealEpoch.of(context);

    final agentCard = Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(22)),
      child: k.status == 'approved'
          ? full(pbtn(s.agentMode ? 'Beralih ke mode klien' : 'Beralih ke mode agen', () => s.setMode(!s.agentMode), icon: Icons.swap_horiz))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Jadi agen Buruhku', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                {
                  'none': 'Dapatkan penghasilan dari pekerjaan harian di sekitarmu.',
                  'pending': 'Pendaftaran sedang direview admin.',
                  'rejected': 'Ditolak: ${k.reason}',
                  'needs_more': 'Perlu data tambahan: ${k.reason}',
                }[k.status]!,
                style: TextStyle(fontSize: 13, color: _subGray),
              ),
              if (k.status == 'none' || k.status == 'needs_more' || (k.status == 'rejected' && k.tries < 3)) ...[
                const SizedBox(height: 12),
                full(pbtn(k.status == 'none' ? 'Daftar sekarang' : 'Lengkapi pendaftaran', () => _go(context, const KycPage()), icon: Icons.how_to_reg_outlined)),
              ],
            ]),
    );

    final rawItems = <Widget>[
      agentCard,

      // ---- akun
      SetGroup([
        SetRow(Icons.person, const Color(0xFF2F9BF0), 'Profil dan alamat', () => _go(context, const EditProfilePage()), sub: 'Nama, nomor HP, alamat'),
        if (k.status == 'approved') SetRow(Icons.storefront, const Color(0xFFF5A12B), 'Tawaran jasa saya', () => _go(context, const MyServicesPage()), sub: '${s.mySvcs.length} tawaran'),
        SetRow(Icons.account_balance_wallet, const Color(0xFF34B866), 'Dompet dan metode bayar', () => _go(context, const WalletPage()), sub: 'Saldo, e-wallet, rekening'),
      ]),

      // ---- pengaturan
      SetGroup([
        SetRow(Icons.brightness_medium, const Color(0xFF8A63E8), 'Tampilan', () => _pickTheme(context), sub: ThemeController.label(ThemeController.instance.mode)),
        SetRow(Icons.notifications, const Color(0xFFEF4F5F), 'Notifikasi', () => _go(context, const NotifPage()), sub: unread > 0 ? '$unread belum dibaca' : 'Order dan sistem', badge: unread > 0 ? Badge(label: Text('$unread'), backgroundColor: kGreen) : null),
        SetRow(Icons.shield, const Color(0xFF8A63E8), 'Keamanan dan SOS', () => _go(context, const SafetyPage()), sub: 'Kontak darurat, tombol SOS'),
        SetRow(Icons.flag, const Color(0xFFFF7A45), 'Laporan saya', () => _go(context, const MyReportsPage()), sub: 'Laporan dan tindak lanjut'),
        SetRow(Icons.settings, const Color(0xFF8E8E93), 'Pengaturan lainnya', () => _go(context, const SettingsPage()), sub: 'PIN, biometrik, privasi, data'),
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
      Center(child: Text('Buruhku v1.0 (prototype lokal)', style: TextStyle(color: g400, fontSize: 12))),
    ];

    final staggeredItems = _buildStaggeredItems(rawItems, epoch, startIndex: 3);

    // Avatar di-cache sekali agar tidak re-layout setiap frame scroll
    final staticAvatar = RepaintBoundary(
      child: GestureDetector(
        onTap: () => _openAvatarOverlay(context, s.name),
        child: Hero(
          tag: 'profile_avatar_hero',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: cW, shape: BoxShape.circle),
            child: const MyAvatar(size: 100),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: _bgGray,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.25,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) {
              _snapHeaderIfNeeded(topPad);
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _TelegramProfileHeaderDelegate(
                  topPadding: topPad,
                  name: s.name,
                  subtitle: '${s.phone} \u2022 ${s.agentMode ? 'Mode agen' : 'Mode klien'}',
                  epoch: epoch,
                  bgColor: _bgGray,
                  avatarChild: staticAvatar,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 12, bottom: kBarSpace),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(staggeredItems),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1x GPU BackdropFilter ringan untuk header akun
class _AccountGlassBlur extends StatelessWidget {
  final Color bgColor;
  const _AccountGlassBlur({required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 0.82, 1.0],
            colors: [
              Colors.black,
              Colors.black,
              Color(0x66000000),
              Colors.transparent,
            ],
          ).createShader(rect),
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10.0,
                sigmaY: 10.0,
                tileMode: TileMode.clamp,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.65, 1.0],
                    colors: [
                      bgColor.withValues(alpha: 0.72),
                      bgColor.withValues(alpha: 0.35),
                      bgColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Delegate header teroptimasi GPU:
/// - Avatar memakai Transform.scale murni (tanpa re-layout & tanpa ImageFilter.blur per-frame)
/// - Top bar memakai 1x BackdropFilter saat mulai di-scroll
class _TelegramProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final String name;
  final String subtitle;
  final int epoch;
  final Color bgColor;
  final Widget avatarChild;

  static const double _blurTail = 22.0;

  _TelegramProfileHeaderDelegate({
    required this.topPadding,
    required this.name,
    required this.subtitle,
    required this.epoch,
    required this.bgColor,
    required this.avatarChild,
  });

  @override
  double get maxExtent => topPadding + 188.0;

  @override
  double get minExtent => topPadding + 54.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseRange = maxExtent - minExtent;
    final t = (shrinkOffset / collapseRange).clamp(0.0, 1.0);
    final overscroll = shrinkOffset < 0 ? -shrinkOffset : 0.0;

    // 1. Transisi Avatar (murni transformasi matriks GPU, 0 re-layout)
    final avatarT = (t / 0.65).clamp(0.0, 1.0);
    final curvedAvatarT = Curves.easeInCubic.transform(avatarT);
    final baseScale = 1.0 + (overscroll * 0.0025).clamp(0.0, 0.25);
    final scaleX = lerpDouble(baseScale, 0.20, curvedAvatarT)!;
    final scaleY = lerpDouble(baseScale, 0.28, curvedAvatarT)!;
    final avatarTop = lerpDouble(topPadding + 12.0, topPadding - 32.0, curvedAvatarT)!;
    final avatarOpacity = (1.0 - Curves.easeInExpo.transform(avatarT)).clamp(0.0, 1.0);

    // 2. Transisi Nama
    final titleScale = lerpDouble(1.0, 18.0 / 26.0, t)!;
    final expandedTitleTop = topPadding + 124.0;
    final collapsedTitleTop = topPadding + (54.0 - (26.0 * 1.2)) / 2;
    final titleTop = lerpDouble(expandedTitleTop, collapsedTitleTop, Curves.easeOutCubic.transform(t))!;

    // 3. Transisi Nomor HP & Mode (hilang di 45% awal scroll)
    final subT = (t / 0.45).clamp(0.0, 1.0);
    final subOpacity = (1.0 - Curves.easeOutCubic.transform(subT)).clamp(0.0, 1.0);
    final subTop = titleTop + (26.0 * 1.2 * titleScale) + lerpDouble(4.0, -4.0, subT)!;

    // 4. Opacity Glass Blur
    final glassOpacity = ((t - 0.15) / 0.45).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Latar 1x Glass Blur (hanya dirender saat mulai di-scroll)
        if (glassOpacity > 0.01)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: -_blurTail,
            child: Opacity(
              opacity: glassOpacity,
              child: _AccountGlassBlur(bgColor: bgColor),
            ),
          ),

        // Avatar dengan Transform.scale ringan di GPU
        if (avatarOpacity > 0.01)
          Positioned(
            top: avatarTop,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                ignoring: t > 0.35,
                child: Opacity(
                  opacity: avatarOpacity,
                  child: Transform.scale(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    child: Reveal(
                      delay: Duration.zero,
                      trigger: epoch,
                      child: avatarChild,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Nama Pengguna (pakai Transform.scale agar teks tidak di-relayout tiap frame)
        Positioned(
          top: titleTop,
          left: 24,
          right: 24,
          child: IgnorePointer(
            child: Transform.scale(
              scale: titleScale,
              child: Reveal(
                delay: RevealItem.step * 1,
                trigger: epoch,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: g900,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Nomor telepon & Mode (hilang ketika di-scroll)
        if (subOpacity > 0.01)
          Positioned(
            top: subTop,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: Opacity(
                opacity: subOpacity,
                child: Reveal(
                  delay: RevealItem.step * 2,
                  trigger: epoch,
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.2,
                      color: g700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _TelegramProfileHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.name != name ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.epoch != epoch ||
        oldDelegate.bgColor != bgColor;
  }
}

/// Overlay layar penuh untuk memperbesar foto profil ketika diklik
class _ProfilePhotoOverlay extends StatelessWidget {
  final String name;
  const _ProfilePhotoOverlay({required this.name});

  @override
  Widget build(BuildContext context) {
    final diameter = MediaQuery.sizeOf(context).width * 0.84;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Hero(
                      tag: 'profile_avatar_hero',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cW,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: MyAvatar(size: diameter),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
  Widget build(BuildContext context) => AppScaffold(
        underBar: true,
        appBar: PageBar(title: const Text('Profil dan alamat')),
        body: Form(
          key: key,
          child: RevealListView(padding: pageListPad(context), children: [
            SetCard(
              child: Column(children: [
                const MyAvatar(size: 84),
                TextButton.icon(onPressed: () => changeProfilePhoto(context), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Ubah foto profil')),
              ]),
            ),
            const SetTitle('Data diri'),
            SetCard(
              child: Column(children: [
                TF('Nama', n, validator: (v) => (v ?? '').trim().length < 3 ? 'Minimal 3 huruf' : null),
                TF('Nomor HP', TextEditingController(text: context.r.phone), enabled: false),
                TF('Alamat default', a, lines: 2),
              ]),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SavedPlacesSection()),
            const SetTitle('Kontak darurat'),
            SetCard(
              child: Column(children: [
                TF('Nama', en),
                TF('No. HP', ep, type: TextInputType.phone),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: full(pbtn('Simpan', () {
                if (!key.currentState!.validate()) return;
                context.r.saveProfile(n: n.text.trim(), addr: a.text.trim(), en: en.text.trim(), ep: ep.text.trim());
                Navigator.pop(context);
                toast(context, 'Profil disimpan.');
              })),
            ),
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Dompet dan metode bayar')),
      body: RevealListView(padding: pageListPad(context), children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8), child: Warn('Pembayaran order selalu lewat escrow. Refund dikembalikan ke metode bayar asal.', icon: Icons.lock_outline)),
        SetHead('E-wallet tersimpan', action: 'Tambah', onAction: () async {
          var w = 'GoPay';
          final no = TextEditingController();
          final ok = await showDialog<bool>(
              context: context,
              builder: (d) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
                    title: const Text('Tambah e-wallet'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      DropdownButtonFormField<String>(initialValue: w, items: [for (final x in ['GoPay', 'OVO', 'DANA', 'ShopeePay']) DropdownMenuItem(value: x, child: Text(x))], onChanged: (v) => set(() => w = v ?? w)),
                      const SizedBox(height: 12),
                      TextField(controller: no, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Nomor akun')),
                    ]),
                    actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Simpan'))],
                  )));
          if (ok == true && no.text.trim().length >= 8) {
            s.wallets.add('$w|${no.text.trim()}');
            s.notifyListeners();
          }
        }),
        if (s.wallets.isEmpty)
          SetCard(child: Text('Belum ada e-wallet.', style: TextStyle(color: g500)))
        else
          SetGroup([
            for (final w in s.wallets)
              SetRow(Icons.account_balance_wallet, const Color(0xFF4C6EF5), w.split('|').first, null,
                  sub: w.split('|').last, badge: IconButton(icon: Icon(Icons.delete_outline, color: g500), onPressed: () { s.wallets.remove(w); s.notifyListeners(); })),
          ]),
        const SetTitle('Riwayat transaksi'),
        if (led.isEmpty)
          SetCard(child: Text('Belum ada transaksi.', style: TextStyle(color: g500)))
        else
          SetGroup([
            for (final l in led)
              SetRow(l.amount >= 0 ? Icons.south_west : Icons.north_east, l.amount >= 0 ? const Color(0xFF34B866) : const Color(0xFFEF4F5F), l.note, null,
                  sub: fdt(l.at), badge: Text(rp(l.amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          ]),
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
          child: RevealListView(padding: kPagePad, children: [
            Row(children: [
              RoundBtn(size: 48, onTap: () => Navigator.maybePop(context), child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: g900)),
              Expanded(child: Center(child: Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.2, color: g900)))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: 16),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
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

(IconData, Color) _sysStyle(String title) {
  final t = title.toLowerCase();
  bool has(List<String> k) => k.any(t.contains);
  if (has(['selamat datang'])) return (Icons.waving_hand, const Color(0xFFF5A12B));
  if (has(['verifikasi', 'pendaftaran', 'data tambahan', 'skck'])) return (Icons.verified_user, const Color(0xFF8A63E8));
  if (has(['penarikan', 'saldo'])) return (Icons.account_balance_wallet, const Color(0xFF34B866));
  if (has(['pembayaran', 'cod'])) return (Icons.payments, const Color(0xFF34B866));
  if (has(['tiket', 'tanggapan'])) return (Icons.support_agent, const Color(0xFF22B8CF));
  if (has(['sengketa'])) return (Icons.gavel, const Color(0xFFD6409F));
  if (has(['offline'])) return (Icons.power_settings_new, const Color(0xFF8E8E93));
  if (has(['pekerjaan selesai'])) return (Icons.task_alt, const Color(0xFF34B866));
  if (has(['tawaran jasa'])) return (Icons.storefront, const Color(0xFFFF7A45));
  if (has(['request'])) return (Icons.assignment, const Color(0xFF4C6EF5));
  if (has(['agen', 'klien'])) return (Icons.person, const Color(0xFF2F9BF0));
  return (Icons.notifications, const Color(0xFFEF4F5F));
}

class _NoteRow extends StatelessWidget {
  final Note n;
  final bool fresh;
  final VoidCallback? onTap;
  const _NoteRow(this.n, {required this.fresh, this.onTap});

  String? _agentPhoto(AppState s) {
    String? agentId;
    switch (n.refType) {
      case 'order':
        final o = s.orderById(n.refId ?? '');
        if (o != null && o.iAmClient) agentId = o.otherId;
      case 'request':
        final r = s.reqById(n.refId ?? '');
        if (r != null) {
          final acc = s.activeAcc(r);
          agentId = acc.isNotEmpty ? acc.last.agentId : (r.chosen.isNotEmpty ? r.chosen.last : null);
        }
      case 'chat':
        final c = s.chatById(n.refId ?? '');
        if (c != null && c.otherAgent) agentId = c.otherId;
    }
    if (agentId == null) return null;
    final ag = s.agentById(agentId);
    return ag.id == agentId ? ag.avatarUrl : null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget lead;
    if (n.isOrder) {
      lead = AvatarPh(46, url: _agentPhoto(context.s));
    } else {
      final (icon, color) = _sysStyle(n.title);
      lead = Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 24, color: Colors.white),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25, color: g900))),
                if (fresh) ...[const SizedBox(width: 6), Container(width: 8, height: 8, decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle))],
              ]),
              const SizedBox(height: 2),
              Text.rich(TextSpan(style: TextStyle(fontSize: 14, height: 1.3, color: g900), children: [
                TextSpan(text: n.body),
                TextSpan(text: ' \u2022 ${ago(n.at)}', style: TextStyle(color: g500)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- pengaturan
Future<void> _pickTheme(BuildContext context) async {
  final c = ThemeController.instance;
  final v = await sheet<AppThemeMode>(context, (x) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(8), child: Text('Tampilan', style: TextStyle(fontWeight: FontWeight.w700))),
          for (final m in AppThemeMode.values)
            ListTile(
              leading: Icon(m == AppThemeMode.system ? Icons.brightness_auto : m == AppThemeMode.light ? Icons.light_mode : Icons.dark_mode),
              title: Text(ThemeController.label(m)),
              trailing: m == c.mode ? const Icon(Icons.check, color: kGreen) : null,
              onTap: () => Navigator.pop(x, m),
            ),
        ]),
      ));
  if (v != null) await c.set(v);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    Widget sw(bool v, ValueChanged<bool> f) => Switch(value: v, onChanged: f);
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Pengaturan')),
      body: RevealListView(padding: pageListPad(context), children: [
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
          SetRow(Icons.dark_mode, const Color(0xFF8A63E8), 'Tampilan', () => _pickTheme(context), sub: ThemeController.label(ThemeController.instance.mode)),
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Keamanan dan SOS')),
      body: RevealListView(padding: pageListPad(context), children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 8), child: SosButton()),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text('Saat SOS ditekan, lokasi live dibagikan ke kontak darurat dan tim keamanan Buruhku.', style: TextStyle(fontSize: 13, color: g500)),
        ),
        const SetTitle('Kontak darurat'),
        SetGroup([
          SetRow(Icons.contact_phone, const Color(0xFFEF4F5F), s.emName.isEmpty ? 'Belum diatur' : s.emName, () => _go(context, const EditProfilePage()),
              sub: s.emName.isEmpty ? 'Ketuk untuk menambahkan' : s.emPhone, badge: Icon(Icons.chevron_right, color: g400)),
        ]),
        const SetTitle('Tips aman'),
        SetCard(
          child: Column(children: [
            for (final t in ['Pastikan wajah agen sesuai foto profil sebelum memberi PIN kerja.', 'Bayar hanya lewat escrow Buruhku. Tolak ajakan transfer di luar aplikasi.', 'Jangan bagikan OTP, PIN, atau kode verifikasi ke siapa pun.', 'Untuk pekerjaan di dalam rumah, usahakan ada orang lain di rumah.', 'Laporkan perilaku mencurigakan lewat menu Laporan.'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle, size: 18, color: kGreen), const SizedBox(width: 8), Expanded(child: Text(t, style: const TextStyle(fontSize: 14, height: 1.35)))]),
              ),
          ]),
        ),
        const SetTitle('Riwayat SOS'),
        if (s.soses.isEmpty)
          SetCard(child: Text('Belum ada.', style: TextStyle(color: g500)))
        else
          SetGroup([for (final x in s.soses) SetRow(Icons.sos, const Color(0xFFEF4F5F), fdt(x.at), null, sub: x.info, badge: Tag(x.resolved ? 'Selesai' : 'Ditangani'))]),
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
  Widget build(BuildContext context) => AppScaffold(
        underBar: true,
        appBar: PageBar(title: const Text('Buat laporan')),
        body: Form(
          key: key,
          child: RevealListView(padding: pageListPad(context), children: [
            SetCard(
              child: Column(children: [
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  decoration: const InputDecoration(labelText: 'Jenis laporan'),
                  items: [for (final c in ['Penipuan', 'Pelecehan atau kekerasan', 'Pencurian atau kerusakan', 'Joki atau identitas palsu', 'Perilaku tidak profesional', 'Pelanggaran lain']) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => setState(() => cat = v ?? cat),
                ),
                const SizedBox(height: 12),
                TF('Pihak yang dilaporkan', target),
                TF('Kronologi', desc, lines: 5, validator: (v) => (v ?? '').trim().length < 15 ? 'Minimal 15 karakter' : null),
              ]),
            ),
            const SetTitle('Bukti (opsional)'),
            SetCard(child: PhotoStrip(paths: evPaths, size: 60, onChanged: (l) => setState(() { evPaths = l; ev = l.length; }))),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Warn('Kasus pelecehan, kekerasan, atau pidana diprioritaskan dan bisa dieskalasi ke Tim Legal untuk pendampingan laporan polisi.', icon: Icons.shield_outlined),
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: full(pbtn('Kirim laporan', () async {
                  if (!key.currentState!.validate()) return;
                  final r = context.r.fileReport(cat: cat, desc: desc.text.trim(), target: target.text.trim(), orderId: widget.orderId, evid: ev);
                  Navigator.pop(context);
                  await info(context, 'Laporan diterima', 'Nomor tiket ${r.no}. Tim Trust & Safety menanggapi maksimal 1x24 jam.');
                }))),
          ]),
        ),
      );
}

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Laporan saya'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _go(context, const ReportPage()))]),
      body: s.reports.isEmpty
          ? const Empty(Icons.flag_outlined, 'Belum ada laporan. Laporkan pengguna atau pesan yang mencurigakan.')
          : RevealListView(padding: pageListPad(context), children: [
              for (final r in s.reports)
                SetCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text(r.no, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Tag(r.status, filled: r.status == 'Diterima')]),
                    Text('${r.cat}${r.target.isEmpty ? '' : ' - ${r.target}'}', style: TextStyle(color: g700)),
                    const SizedBox(height: 4),
                    Text(r.desc, maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (r.action.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Tindakan: ${r.action}', style: TextStyle(fontSize: 13, color: g700))),
                    Text(ago(r.at), style: TextStyle(fontSize: 11, color: g500)),
                  ]),
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
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Pusat bantuan')),
      body: RevealListView(padding: pageListPad(context), children: [
        SetCard(child: const Row(children: [Icon(Icons.sos, size: 28, color: Color(0xFFEF4F5F)), SizedBox(width: 12), Expanded(child: Text('Darurat: Polisi 110, Ambulans 118, Darurat 112. Di aplikasi pakai tombol SOS.'))])),
        const SetTitle('Pertanyaan umum'),
        SetCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(children: [for (final f in faq) ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(f[0], style: const TextStyle(fontWeight: FontWeight.w600)), children: [Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(f[1], style: const TextStyle(height: 1.4))))])]),
          ),
        ),
        const SetTitle('Hubungi kami'),
        SetCard(
          child: Column(children: [
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
          ]),
        ),
        if (s.tickets.isNotEmpty) ...[
          const SetTitle('Tiket saya'),
          for (final t in s.tickets)
            SetCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(t.no, style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Tag(t.status, filled: t.status == 'Dijawab')]),
                Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (t.reply.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Balasan: ${t.reply}', style: TextStyle(fontSize: 13, color: g700))),
              ]),
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
  Widget build(BuildContext context) => AppScaffold(
        underBar: true,
        appBar: PageBar(title: const Text('Kebijakan dan ketentuan')),
        body: RevealListView(padding: pageListPad(context), children: [SetGroup([for (final k in _policies.keys) SetRow(Icons.description, const Color(0xFF4C6EF5), k, () => _go(context, PolicyPage(k)), badge: Icon(Icons.chevron_right, color: g400))])]),
      );
}

class PolicyPage extends StatelessWidget {
  final String title;
  const PolicyPage(this.title, {super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
        underBar: true,
        appBar: PageBar(title: Text(title)),
        body: RevealListView(padding: pageListPad(context), children: [SetCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_policies[title] ?? '', style: const TextStyle(height: 1.5)), const SizedBox(height: 16), Text('Versi prototype: isi final perlu ditinjau konsultan hukum.', style: TextStyle(color: g500, fontSize: 12))]))]),
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
      child: AppScaffold(
        underBar: true,
        appBar: PageBar(title: const Text('Panel Admin (Simulasi)'), bottom: const TabBar(isScrollable: true, tabs: [Tab(text: 'KYC'), Tab(text: 'Moderasi'), Tab(text: 'Laporan'), Tab(text: 'Sengketa'), Tab(text: 'SOS'), Tab(text: 'Statistik')])),
        body: TabBarView(children: [
          // KYC
          (k.status == 'pending' || k.status == 'needs_more')
              ? RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
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
              : Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 48), child: Empty(Icons.how_to_reg_outlined, 'Tidak ada antrean KYC. Status pendaftaranmu: ${k.status}.')),
          // moderasi
          review.isEmpty
              ? Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 48), child: const Empty(Icons.rule, 'Tidak ada request yang menunggu tinjauan.'))
              : RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
                  for (final r in review)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(r.desc),
                        const SizedBox(height: 4),
                        Text(r.reason, style: TextStyle(fontSize: 13, color: g700)),
                        const SizedBox(height: 8),
                        Row(children: [Expanded(child: pbtn('Setujui', () => s.adminApproveReq(r))), const SizedBox(width: 8), Expanded(child: obtn('Hapus', () => s.adminRejectReq(r)))]),
                      ])),
                    ),
                ]),
          // laporan
          reps.isEmpty
              ? Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 48), child: const Empty(Icons.flag_outlined, 'Tidak ada laporan baru.'))
              : RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
                  for (final r in reps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r.no}: ${r.cat}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Terlapor: ${r.target.isEmpty ? '-' : r.target}', style: TextStyle(color: g700)),
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
              ? Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 48), child: const Empty(Icons.gavel_outlined, 'Tidak ada sengketa terbuka.'))
              : RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
                  for (final d in disps)
                    Builder(builder: (_) {
                      final o = s.orderById(d.orderId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Box(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${o?.title ?? d.orderId}  (${o == null ? '' : rp(o.total)})', style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(d.type, style: TextStyle(color: g700)),
                          Text(d.desc),
                          if (d.response.isNotEmpty) Text('Tanggapan: ${d.response}', style: TextStyle(fontSize: 13, color: g500)),
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
              ? Padding(padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kBarH + 48), child: const Empty(Icons.sos_outlined, 'Tidak ada alarm SOS.'))
              : RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
                  for (final x in s.soses)
                    ListTile(leading: const Icon(Icons.sos_outlined), title: Text('${fdt(x.at)}${x.orderId.isEmpty ? '' : '  |  ${x.orderId}'}'), subtitle: Text(x.info), trailing: x.resolved ? const Tag('Selesai') : FilledButton(onPressed: () => s.resolveSos(x), child: const Text('Selesaikan'))),
                ]),
          // statistik
          RevealListView(padding: underBarPad(context, kPagePad, extra: 48), children: [
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