import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      icon: Icons.handshake_outlined,
      title: 'Buruhku',
      subtitle:
          'Temukan orang yang siap membantu pekerjaan kasar/serabutan di sekitar Anda — atau sebaliknya, dapatkan penghasilan harian saat menganggur.',
    ),
    _Slide(
      icon: Icons.verified_user_outlined,
      title: 'Aman & Terlindungi',
      subtitle:
          'Agen diverifikasi KTP + selfie. Dana ditahan (escrow) hingga pekerjaan selesai. Rating dua arah, tombol SOS, dan pelaporan resmi.',
    ),
    _Slide(
      icon: Icons.bolt_outlined,
      title: 'Cara Kerja',
      subtitle:
          'Tulis judul, deskripsi, harga penawaran. Agen yang tertarik menekan ACC. Negosiasi lewat chat, pilih agen terbaik, bayar, selesai.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _slides[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    widget.onDone();
                  } else {
                    _ctrl.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(_page == _slides.length - 1 ? 'Mulai' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: AppTheme.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}