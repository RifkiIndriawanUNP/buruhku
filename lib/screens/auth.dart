import 'package:flutter/material.dart';
import '../store.dart';
import '../ui.dart';
import 'account.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final pc = PageController();
  int i = 0;
  static const slides = [
    [Icons.handyman_outlined, 'Apa itu Buruhku?', 'Tempat bertemunya orang yang butuh bantuan tenaga dengan buruh harian yang siap bekerja. Tulis pekerjaan apa saja, harga bisa ditawar.'],
    [Icons.verified_user_outlined, 'Aman dan terpercaya', 'Agen diverifikasi KTP dan selfie. Uangmu ditahan escrow sampai pekerjaan selesai. Ada tombol SOS dan jalur lapor resmi.'],
    [Icons.route_outlined, 'Cara kerjanya', 'Buat request, agen terdekat menekan ACC, kamu pilih lewat chat dan harga, bayar ke escrow, lalu nilai hasilnya.'],
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
                        Ph(w: 220, h: 220, icon: s[0] as IconData),
                        const SizedBox(height: 32),
                        Text(s[1] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Text(s[2] as String, textAlign: TextAlign.center, style: const TextStyle(color: g700, height: 1.4)),
                      ]),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var k = 0; k < slides.length; k++)
                Container(margin: const EdgeInsets.all(4), width: k == i ? 22 : 8, height: 8,
                    decoration: BoxDecoration(color: k == i ? g900 : g300, borderRadius: BorderRadius.circular(4))),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Form(
            key: key,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              const SizedBox(height: 40),
              Container(width: 64, height: 64, decoration: BoxDecoration(color: g900, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.handyman, color: cW)),
              const SizedBox(height: 20),
              const Text('Masuk ke Buruhku', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Masukkan nomor HP. Kami kirim kode OTP untuk verifikasi.', style: TextStyle(color: g500)),
              const SizedBox(height: 28),
              TF('Nomor HP', ctl, prefix: '+62 ', type: TextInputType.phone, maxLen: 13, hint: '81234567890',
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return d.length < 9 ? 'Nomor HP minimal 9 digit' : null;
                  }),
              full(pbtn('Kirim OTP', () {
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
              }, icon: Icons.sms_outlined)),
              const SizedBox(height: 16),
              const Warn('Satu nomor HP untuk satu akun. Jangan bagikan kode OTP ke siapa pun, termasuk yang mengaku dari Buruhku.', icon: Icons.lock_outline),
            ]),
          ),
        ),
      );
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final ctl = TextEditingController();
  String? err;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Kode dikirim ke ${s.pendingPhone}', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Box(color: g100, child: Row(children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Mode demo: kode OTP kamu ${s.otp}')),
        ])),
        const SizedBox(height: 20),
        TextField(
          controller: ctl, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 10),
          decoration: InputDecoration(counterText: '', errorText: err, hintText: '------'),
        ),
        const SizedBox(height: 12),
        full(pbtn('Verifikasi', () {
          final e = s.checkOtp(ctl.text.trim());
          if (e != null) {
            setState(() => err = e);
            return;
          }
          s.completeLogin();
          Navigator.of(context).popUntil((r) => r.isFirst);
        })),
        TextButton(onPressed: () {
          s.requestOtp(s.pendingPhone);
          setState(() => err = null);
          toast(context, 'Kode baru dikirim.');
        }, child: const Text('Kirim ulang kode')),
      ]),
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
  bool agree = false, photo = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Lengkapi profil')),
        body: Form(
          key: key,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(child: Column(children: [
              Stack(children: [
                const Avatar(size: 88),
                if (photo) const Positioned(right: 0, bottom: 0, child: Icon(Icons.check_circle, color: g900)),
              ]),
              TextButton.icon(onPressed: () => setState(() => photo = true), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Ambil foto')),
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
