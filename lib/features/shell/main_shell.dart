// lib/features/shell/main_shell.dart
import 'package:flutter/material.dart';
import '../../app/services.dart';
import '../../core/widgets/liquid_glass_nav_bar.dart';
import '../account/screens/account_screen.dart';
import '../chat/screens/chat_list_screen.dart';
import '../history/screens/history_screen.dart';
import '../home/screens/home_screen.dart';
import '../request/screens/create_request_screen.dart';
import '../request/screens/my_requests_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  /// Bottom sheet dari tombol `+` di nav bar
  void _showCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Buat Request Baru'),
              subtitle: const Text('Tulis judul, deskripsi, dan harga penawaran'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateRequestScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('Request Saya'),
              subtitle: const Text('Lihat request aktif & agen yang menyetujui'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyRequestsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ★ 4 tab — "Request" tidak lagi jadi tab; aksesnya via tombol +
    final pages = <Widget>[
      const HomeScreen(),
      const HistoryScreen(),
      const ChatListScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      extendBody: true, // ★ penting agar blur lensa punya konten di belakangnya
      body: IndexedStack(index: _idx, children: pages),
      // floatingActionButton dihapus — sekarang ada di nav bar
      bottomNavigationBar: LiquidGlassNavBar(
        selectedIndex: _idx,
        onItemSelected: (i) => setState(() => _idx = i),
        onCreatePressed: _showCreateSheet,
      ),
    );
  }
}