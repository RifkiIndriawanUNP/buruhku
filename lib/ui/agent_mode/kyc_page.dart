import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});
  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  int step = 0;
  final keys = List.generate(6, (_) => GlobalKey<FormState>());
  final name = TextEditingController(), nik = TextEditingController(), addr = TextEditingController();
  final emN = TextEditingController(), emP = TextEditingController(), bankNo = TextEditingController(), holder = TextEditingController();
  DateTime? birth;
  bool a1 = false, a2 = false, a3 = false;
  static const steps = ['Data diri', 'Dokumen', 'SKCK', 'Keahlian', 'Rekening', 'Setuju'];

  @override
  void initState() {
    super.initState();
    final s = context.r;
    final k = s.kyc;
    name.text = k.name.isEmpty ? s.name : k.name;
    nik.text = k.nik;
    addr.text = k.addr.isEmpty ? s.address : k.addr;
    emN.text = k.emName.isEmpty ? s.emName : k.emName;
    emP.text = k.emPhone.isEmpty ? s.emPhone : k.emPhone;
    bankNo.text = k.bankNo;
    holder.text = k.bankHolder;
  }

  Future<void> _liveness(Kyc k) async {
    if (await runFaceDemo(context) && mounted) setState(() => k.selfie = true);
  }

  bool _next(AppState s) {
    final k = s.kyc;
    if (!(keys[step].currentState?.validate() ?? true)) return false;
    switch (step) {
      case 0:
        if (birth == null) { toast(context, 'Pilih tanggal lahir.'); return false; }
        final n = DateTime.now();
        final age = n.year - birth!.year - ((n.month < birth!.month || (n.month == birth!.month && n.day < birth!.day)) ? 1 : 0);
        if (age < 18) { toast(context, 'Usia minimal 18 tahun.'); return false; }
        if (context.r.profilePhoto.isNotEmpty) k.photo = true;
        if (!k.photo) { toast(context, 'Ambil foto profil dulu.'); return false; }
        k.name = name.text.trim();
        k.nik = nik.text.trim();
        k.birth = fdate(birth!);
        k.addr = addr.text.trim();
        k.emName = emN.text.trim();
        k.emPhone = emP.text.trim();
        break;
      case 1:
        if (!k.ktp || !k.selfie) { toast(context, 'Foto KTP & selfie wajib.'); return false; }
        break;
      case 3:
        if (k.cats.isEmpty) { toast(context, 'Pilih min 1 keahlian.'); return false; }
        break;
      case 4:
        if (holder.text.trim().toLowerCase() != k.name.toLowerCase()) { toast(context, 'Nama rekening harus sama dengan KTP.'); return false; }
        k.bankNo = bankNo.text.trim();
        k.bankHolder = holder.text.trim();
        break;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final k = s.kyc;
    Widget body;
    switch (step) {
      case 0:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TF('Nama sesuai KTP', name, validator: (v) => (v ?? '').trim().length < 3 ? 'Wajib diisi' : null),
            TF('NIK (16 digit)', nik, type: TextInputType.number, maxLen: 16, validator: (v) => (v ?? '').length != 16 ? 'Harus 16 digit' : null),
            obtn(birth == null ? 'Tanggal lahir' : fdate(birth!), () async {
              final d = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1950), lastDate: DateTime.now());
              if (d != null) setState(() => birth = d);
            }, icon: Icons.cake_outlined),
            const SizedBox(height: 12),
            TF('Alamat domisili', addr, lines: 2, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
            TF('Nama kontak darurat', emN, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
            TF('No. HP kontak darurat', emP, type: TextInputType.phone, validator: (v) => (v ?? '').trim().length < 9 ? 'Nomor tidak valid' : null),
            Row(children: [
              const MyAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: obtn(
                  context.s.profilePhoto.isNotEmpty ? 'Ganti foto profil' : 'Ambil foto profil',
                  () async {
                    if (await changeProfilePhoto(context)) setState(() => k.photo = context.r.profilePhoto.isNotEmpty);
                  },
                  icon: context.s.profilePhoto.isNotEmpty ? Icons.check : Icons.photo_camera_outlined,
                ),
              ),
            ]),
          ]),
        );
        break;
      case 1:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Foto KTP', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Ph(h: 130, icon: Icons.badge_outlined),
            const SizedBox(height: 8),
            obtn(k.ktp ? 'KTP cocok dengan NIK' : 'Foto KTP', () => setState(() => k.ktp = true), icon: k.ktp ? Icons.check : Icons.photo_camera_outlined),
            const SizedBox(height: 16),
            const Text('Selfie + Liveness', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Center(child: Avatar(size: 96, icon: Icons.face_outlined)),
            const SizedBox(height: 8),
            obtn(k.selfie ? 'Liveness lolos (94%)' : 'Verifikasi Wajah', () => _liveness(k), icon: k.selfie ? Icons.check : Icons.face_retouching_natural_outlined),
            const SizedBox(height: 12),
            const Warn('Data terenkripsi, hanya untuk verifikasi.', icon: Icons.lock_outline),
          ]),
        );
        break;
      case 2:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('SKCK (Opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Tanpa SKCK: Level L1 (maks Rp500rb). Dengan SKCK + 5 order: Level L2 (akses kategori sensitif).', style: TextStyle(height: 1.4)),
            const SizedBox(height: 16),
            const Ph(h: 110, icon: Icons.description_outlined),
            const SizedBox(height: 8),
            obtn(k.skck ? 'SKCK terunggah' : 'Unggah SKCK', () => setState(() => k.skck = !k.skck), icon: k.skck ? Icons.check : Icons.upload_file),
          ]),
        );
        break;
      case 3:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Keahlian (maks 5)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in cats)
                FilterChip(
                  avatar: CatIcon(c, size: 22),
                  label: Text(c.name),
                  selected: k.cats.contains(c.id),
                  onSelected: (v) => setState(() {
                    if (v && k.cats.length >= 5) { toast(context, 'Maksimal 5 keahlian.'); return; }
                    v ? k.cats.add(c.id) : k.cats.remove(c.id);
                  }),
                ),
            ]),
            const SizedBox(height: 16),
            Text('Radius: ${k.radius.round()} km', style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(value: k.radius, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => k.radius = v)),
            Text('Jam kerja: ${two(k.fromH)}:00 – ${two(k.toH)}:00', style: const TextStyle(fontWeight: FontWeight.w700)),
            RangeSlider(
              values: RangeValues(k.fromH.toDouble(), k.toH.toDouble()),
              min: 0,
              max: 24,
              divisions: 24,
              onChanged: (v) => setState(() {
                k.fromH = v.start.round();
                k.toH = v.end.round();
              }),
            ),
          ]),
        );
        break;
      case 4:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            DropdownButtonFormField<String>(
              initialValue: k.bank,
              decoration: const InputDecoration(labelText: 'Bank / E-Wallet'),
              items: [for (final b in ['BCA', 'Mandiri', 'BNI', 'BRI', 'GoPay', 'DANA', 'OVO']) DropdownMenuItem(value: b, child: Text(b))],
              onChanged: (v) => setState(() => k.bank = v ?? k.bank),
            ),
            const SizedBox(height: 12),
            TF('Nomor rekening / akun', bankNo, type: TextInputType.number, validator: (v) => (v ?? '').trim().length < 6 ? 'Nomor tidak valid' : null),
            TF('Nama pemilik', holder, validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null),
            const Warn('Nama pemilik harus sesuai KTP.', icon: Icons.account_balance_outlined),
          ]),
        );
        break;
      default:
        body = SoftCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kv('Nama', k.name),
            Kv('NIK', k.nik),
            Kv('Keahlian', k.cats.map((c) => catOf(c).name).join(', ')),
            Kv('Radius', '${k.radius.round()} km'),
            Kv('Rekening', '${k.bank} ${k.bankNo}'),
            Kv('SKCK', k.skck ? 'Ada' : 'Tidak ada (L1)'),
            const SizedBox(height: 8),
            CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a1, onChanged: (v) => setState(() => a1 = v ?? false), title: const Text('Setuju Syarat & Ketentuan Agen')),
            CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a2, onChanged: (v) => setState(() => a2 = v ?? false), title: const Text('Setuju Kode Etik & Larangan')),
            CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: a3, onChanged: (v) => setState(() => a3 = v ?? false), title: const Text('Setuju Kebijakan Privasi')),
          ]),
        );
    }
    return AppScaffold(
      appBar: PageBar(title: Text('Daftar Agen (${step + 1}/${steps.length}): ${steps[step]}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(color: i <= step ? kGreen : g200, borderRadius: BorderRadius.circular(3)),
                ),
              ),
          ]),
        ),
        Expanded(child: Form(key: keys[step], child: RevealListView(padding: kPagePad, children: [body]))),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              if (step > 0) Expanded(child: obtn('Kembali', () => setState(() => step--))),
              if (step > 0) const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: pbtn(step == steps.length - 1 ? 'Kirim' : 'Lanjut', () {
                  if (!_next(s)) return;
                  if (step == steps.length - 1) {
                    if (!(a1 && a2 && a3)) { toast(context, 'Setujui semua persyaratan.'); return; }
                    s.submitKyc();
                    Navigator.pop(context);
                    info(context, 'Terkirim', 'Data masuk antrean review admin (maks 1x24 jam).');
                  } else {
                    setState(() => step++);
                  }
                }),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}