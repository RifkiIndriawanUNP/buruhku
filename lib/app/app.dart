import 'package:flutter/material.dart';
import '../features/shell/main_shell.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import 'router.dart';
import 'services.dart';
import 'theme.dart';

class BuruhkuApp extends StatefulWidget {
  const BuruhkuApp({super.key});

  @override
  State<BuruhkuApp> createState() => _BuruhkuAppState();
}

class _BuruhkuAppState extends State<BuruhkuApp> {
  @override
  void initState() {
    super.initState();
    Services.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Buruhku',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const _Root(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _onboarded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Services.auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user != null) return const MainShell();
        if (!_onboarded) {
          return OnboardingScreen(
            onDone: () => setState(() => _onboarded = true),
          );
        }
        return const LoginScreen();
      },
    );
  }
}