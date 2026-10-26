import 'package:flutter/material.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.init();
  runApp(StoreScope(store: store, child: const BuruhkuApp()));
}

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
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (!done) return const Splash();
    if (!s.loggedIn) return s.onboarded ? const LoginPage() : const Onboarding();
    if (s.name.isEmpty) return const ProfileSetup();
    return const Shell();
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(color: g900, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.handyman, color: cW, size: 52),
            ),
            const SizedBox(height: 16),
            const Text('Buruhku', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Siap mengerjakan apa pun yang disuruh', style: TextStyle(color: g500)),
          ]),
        ),
      );
}
