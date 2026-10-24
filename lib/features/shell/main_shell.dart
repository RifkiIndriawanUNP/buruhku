import 'package:flutter/material.dart';
import '../../app/services.dart';
import '../../core/widgets/liquid_glass_nav_bar.dart';
import '../account/screens/account_screen.dart';
import '../history/screens/history_screen.dart';
import '../home/screens/home_screen.dart';
import '../request/screens/create_request_screen.dart';
import '../chat/screens/active_orders_screen.dart'; // File baru

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    if (Services.auth.currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      const CreateRequestScreen(),
      const ActiveOrdersScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: LiquidGlassNavBar(
        selectedIndex: _idx,
        onItemSelected: (i) => setState(() => _idx = i),
      ),
    );
  }
}