import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/auth/auth_screen.dart';
import 'package:buruhku/ui/shell/app_shell.dart';

class BuruhkuApp extends StatelessWidget {
  const BuruhkuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Buruhku',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Root(),
      );
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool done = false;
  bool _wasLoggedIn = false; // untuk mendeteksi saat pengguna baru saja keluar

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() {
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_wasLoggedIn && !s.loggedIn) {
      // Baru logout: tampilkan splash lagi, lalu lanjut ke Login.
      _wasLoggedIn = false;
      done = false;
      _startSplash();
    }
    if (s.loggedIn) _wasLoggedIn = true;
    if (!done) return const Splash();
    if (!s.loggedIn) return s.onboarded ? const LoginPage() : const Onboarding();
    if (s.name.isEmpty) return const ProfileSetup();
    return const Shell();
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final art = (w * .92).clamp(240.0, 380.0);
    return Scaffold(
      body: SafeArea(
        child: Center(
          // Animasi masuk satu kali (fade + membesar sedikit), jadi tidak mengganggu pumpAndSettle di test.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(opacity: v, child: Transform.scale(scale: .94 + .06 * v, child: child)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(
                'assets/images/splash_illustration.png',
                width: art,
                height: art,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(color: g900, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.handyman, color: cW, size: 52),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Buruhku', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Siap mengerjakan apa pun yang disuruh', style: TextStyle(color: g500)),
            ]),
          ),
        ),
      ),
    );
  }
}
