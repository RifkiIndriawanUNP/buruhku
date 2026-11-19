import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/account/account_screen.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final pc = PageController();
  int i = 0;
  static const slides = [
    ['assets/images/onboarding_1.png', 'Apa itu Buruhku?', 'Tempat bertemunya orang yang butuh bantuan tenaga dengan buruh harian yang siap bekerja. Tulis pekerjaan apa saja, harga bisa ditawar.'],
    ['assets/images/onboarding_2.png', 'Aman dan terpercaya', 'Agen diverifikasi KTP dan selfie. Uangmu ditahan escrow sampai pekerjaan selesai. Ada tombol SOS dan jalur lapor resmi.'],
    ['assets/images/onboarding_3.png', 'Cara kerjanya', 'Buat request, agen terdekat menekan ACC, kamu pilih lewat chat dan harga, bayar ke escrow, lalu nilai hasilnya.'],
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => context.r.finishOnboarding(), child: const Text('Lewati'))),
            Expanded(
              child: PageView(
                controller: pc,
                onPageChanged: (v) => setState(() => i = v),
                children: [
                  for (final s in slides)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Flexible(
                          child: Image.asset(
                            s[0],
                            width: 300,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Ph(w: 220, h: 220, icon: Icons.handyman_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(s[1], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text(s[2], textAlign: TextAlign.center, style: TextStyle(color: g700, height: 1.4)),
                      ]),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < slides.length; k++)
                Container(margin: const EdgeInsets.all(4), width: k == i ? 22 : 8, height: 8,
                    decoration: BoxDecoration(color: k == i ? kGreen : g300, borderRadius: BorderRadius.circular(4))),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: full(pbtn(i == slides.length - 1 ? 'Mulai' : 'Lanjut', () {
                if (i == slides.length - 1) {
                  context.r.finishOnboarding();
                } else {
                  pc.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                }
              })),
            ),
          ]),
        ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ctl = TextEditingController();
  final key = GlobalKey<FormState>();

  void _send() {
    if (!key.currentState!.validate()) return;
    var d = ctl.text.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('0')) d = d.substring(1);
    if (d.startsWith('62')) d = d.substring(2);
    final s = context.r;
    if (s.otpLocked) {
      toast(context, 'Akun dikunci sementara. Coba lagi sebentar lagi.');
      return;
    }
    s.requestOtp('+62$d');
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpPage()));
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    const radius = BorderRadius.all(Radius.circular(18));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Column(children: [
                  // Ilustrasi di atas, kartu putih membulat di bawah.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Image.asset(
                          'assets/images/splash_illustration.png',
                          width: (w * .82).clamp(240.0, 340.0).toDouble(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(width: 96, height: 96, decoration: BoxDecoration(color: g900, borderRadius: BorderRadius.circular(24)), child: Icon(Icons.handyman, color: cW, size: 52)),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(color: cW, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                    child: SafeArea(
                      top: false,
                      child: Form(
                        key: key,
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Masuk ke Buruhku', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: g900)),
                          const SizedBox(height: 6),
                          Text('Masukkan nomor HP, kami kirim kode OTP.', style: TextStyle(fontSize: 15, color: g500)),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: ctl,
                            keyboardType: TextInputType.phone,
                            maxLength: 13,
                            onFieldSubmitted: (_) => _send(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '81234567890',
                              filled: true,
                              fillColor: cBg,
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 18, right: 10),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Text('+62', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 12),
                                  Container(width: 1.5, height: 24, color: kLine),
                                ]),
                              ),
                              border: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
                              enabledBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
                              focusedBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: kGreen, width: 2)),
                              errorBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: kRed, width: 1.5)),
                              focusedErrorBorder: const OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: kRed, width: 2)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'Nomor HP minimal 9 digit' : null,
                          ),
                          const SizedBox(height: 16),
                          full(pbtn('Kirim kode OTP', _send, icon: Icons.arrow_forward_rounded)),
                          const SizedBox(height: 14),
                          Center(child: Text('Satu nomor untuk satu akun.', style: TextStyle(fontSize: 12.5, color: g500))),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final ctl = TextEditingController();
  String? err;

  void _verify(AppState s) {
    final e = s.checkOtp(ctl.text.trim());
    if (e != null) {
      setState(() => err = e);
      return;
    }
    s.completeLogin();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AppScaffold(
      underBar: true,
      appBar: PageBar(title: const Text('Verifikasi')),
      body: ListView(padding: underBarPad(context, const EdgeInsets.fromLTRB(24, 12, 24, 24)), children: [
        const Icon(Icons.mark_email_unread_outlined, size: 44, color: kGreen),
        const SizedBox(height: 14),
        Text('Masukkan kode', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: g900)),
        const SizedBox(height: 6),
        Text('Kode 6 digit dikirim ke ${s.pendingPhone}', style: TextStyle(fontSize: 15, color: g500)),
        const SizedBox(height: 28),
        OtpBoxes(ctl: ctl, error: err != null, onChanged: (_) => setState(() => err = null)),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(err!, style: const TextStyle(fontSize: 13, color: kRed, fontWeight: FontWeight.w600))),
        const SizedBox(height: 18),
        // Mode demo: ketuk untuk mengisi kode otomatis.
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              ctl.text = s.otp;
              err = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: cW, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.science_outlined, size: 16, color: g500),
                const SizedBox(width: 6),
                Text('Demo: kode ${s.otp} (ketuk untuk isi)', style: TextStyle(fontSize: 13, color: g700)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 24),
        full(pbtn('Verifikasi', () => _verify(s))),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () {
            s.requestOtp(s.pendingPhone);
            setState(() {
              err = null;
              ctl.clear();
            });
            toast(context, 'Kode baru dikirim.');
          },
          child: const Text('Kirim ulang kode'),
        ),
        Center(child: Text('Jangan bagikan kode ke siapa pun.', style: TextStyle(fontSize: 12.5, color: g500))),
      ]),
    );
  }
}

/// Kolom kode OTP: satu kotak per angka. Input asli tersembunyi di atas kotak supaya keyboard dan tempel kode tetap bekerja.
class OtpBoxes extends StatefulWidget {
  final TextEditingController ctl;
  final int length;
  final bool error;
  final ValueChanged<String>? onChanged;
  const OtpBoxes({required this.ctl, this.length = 6, this.error = false, this.onChanged, super.key});
  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _f = FocusNode();

  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.ctl.addListener(_rebuild);
    _f.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.ctl.removeListener(_rebuild);
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.ctl.text;
    final cur = text.length.clamp(0, widget.length - 1);
    return GestureDetector(
      onTap: _f.requestFocus,
      child: SizedBox(
        height: 62,
        child: Stack(children: [
          Row(children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cW,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.error ? kRed : (_f.hasFocus && i == cur ? kGreen : Colors.transparent),
                      width: 2,
                    ),
                  ),
                  child: Text(i < text.length ? text[i] : '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: g900)),
                ),
              ),
            ],
          ]),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.ctl,
                focusNode: _f,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: widget.onChanged,
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});
  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final key = GlobalKey<FormState>();
  final n = TextEditingController(), a = TextEditingController(), en = TextEditingController(), ep = TextEditingController();
  bool agree = false;

  @override
  Widget build(BuildContext context) => AppScaffold(
        underBar: true,
        appBar: PageBar(title: const Text('Lengkapi profil')),
        body: Form(
          key: key,
          child: ListView(padding: pagePad(context), children: [
            Center(child: Column(children: [
              Stack(children: [
                const MyAvatar(size: 88),
                if (context.s.profilePhoto.isNotEmpty) Positioned(right: 0, bottom: 0, child: Icon(Icons.check_circle, color: g900)),
              ]),
              TextButton.icon(onPressed: () => changeProfilePhoto(context), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Ambil foto')),
            ])),
            TF('Nama lengkap', n, validator: (v) => (v ?? '').trim().length < 3 ? 'Nama minimal 3 huruf' : null),
            TF('Alamat default (opsional)', a, lines: 2,
                suffix: IconButton(icon: const Icon(Icons.my_location), onPressed: () => setState(() => a.text = 'Jl. Melati No. 5, Palabuhanratu'))),
            const Section('Kontak darurat (opsional)'),
            TF('Nama kontak darurat', en),
            TF('No. HP kontak darurat', ep, type: TextInputType.phone),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: agree,
              onChanged: (v) => setState(() => agree = v ?? false),
              title: const Text('Saya setuju dengan Syarat & Kebijakan Privasi'),
              subtitle: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPage('Kebijakan Privasi'))),
                child: const Text('Baca kebijakan', style: TextStyle(decoration: TextDecoration.underline)),
              ),
            ),
            const SizedBox(height: 8),
            full(pbtn('Simpan dan lanjut', () async {
              if (!key.currentState!.validate()) return;
              if (!agree) {
                toast(context, 'Setujui syarat dan kebijakan dulu.');
                return;
              }
              final s = context.r;
              await confirm(context, 'Izin lokasi', 'Buruhku memakai lokasi untuk mencari agen dan pekerjaan terdekat.', ok: 'Izinkan', cancel: 'Nanti');
              if (!context.mounted) return;
              await confirm(context, 'Izin notifikasi', 'Kami kirim kabar soal order, chat, dan pembayaran.', ok: 'Izinkan', cancel: 'Nanti');
              s.saveProfile(n: n.text.trim(), addr: a.text.trim(), en: en.text.trim(), ep: ep.text.trim());
            })),
          ]),
        ),
      );
}