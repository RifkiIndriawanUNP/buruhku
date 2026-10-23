import 'package:flutter/material.dart';
import '../../../app/services.dart'; // <-- 3 ../
import '../../../app/theme.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../core/widgets/tombol.dart';
import '../../../data/models/user.dart';
import '../../agent_mode/screens/agent_dashboard_screen.dart';
import '../../safety/screens/sos_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: StreamBuilder<User?>(
        stream: Services.auth.authStateChanges,
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) return const Center(child: CircularProgressIndicator());
          final isAgent = user.roles.contains(UserRole.agent);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppBox(
                child: Row(
                  children: [
                    InitialAvatar(name: user.fullName, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(user.phone,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: user.roles
                                .map((r) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        r == UserRole.client ? 'Klien' : 'Agen',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isAgent)
                _Tile(
                  icon: Icons.badge_outlined,
                  title: 'Mode Agen',
                  subtitle: 'Lihat dashboard, request masuk, pendapatan',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AgentDashboardScreen()),
                  ),
                )
              else
                _Tile(
                  icon: Icons.work_outline,
                  title: 'Daftar Jadi Agen',
                  subtitle: 'Dapatkan penghasilan dari pekerjaan harian',
                  onTap: () async {
                    await Services.auth.becomeAgent();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Selamat! Anda sekarang bisa menerima order sebagai agen (demo).'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              _Tile(
                icon: Icons.sos_outlined,
                title: 'Keamanan & SOS',
                subtitle: 'Tombol darurat, berbagi lokasi, lapor polisi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                ),
              ),
              _Tile(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Buruhku MVP v0.1 — mode lokal',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Buruhku'),
                    content: const Text(
                      'MVP Stage 1 — semua data disimpan di memori (hilang saat aplikasi ditutup). '
                      'Login: nomor HP apa saja + OTP 123456.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              WireButton(
                label: 'Keluar',
                icon: Icons.logout,
                color: AppTheme.danger,
                onTap: () async {
                  await Services.auth.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AppBox(
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}