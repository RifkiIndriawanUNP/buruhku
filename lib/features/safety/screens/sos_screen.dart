import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/box.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan & SOS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppBox(
            color: const Color(0xFFFFEBEE),
            border: Border.all(color: const Color(0xFFFFCDD2)),
            child: Column(
              children: [
                const Icon(Icons.sos, color: AppTheme.danger, size: 64),
                const SizedBox(height: 8),
                const Text('Tombol Darurat',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  _sosSent
                      ? 'SOS terkirim! Lokasi Anda dibagikan ke kontak darurat (demo).\nJika ini bukan latihan, hubungi 110 (Polisi).'
                      : 'Tekan dan tahan tombol di bawah untuk mengirim lokasi darurat ke kontak darurat dan tim keamanan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onLongPress: () {
                    setState(() => _sosSent = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'SOS terkirim (demo). Menampilkan lokasi & tombol panggil polisi.'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.danger.withValues(alpha: .4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'SOS\n(Tahan 3 detik)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                ),
                if (_sosSent) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Demo: memanggil 110 (Polisi)')),
                    ),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.danger),
                    icon: const Icon(Icons.call),
                    label: const Text('Panggil Polisi (110)'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kontak Darurat',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Belum diatur. Anda dapat menambahkan nomor kontak darurat di Profil.',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                SizedBox(height: 10),
                Text('Lokasi demo: ${Env.demoCity} (${Env.demoLat}, ${Env.demoLng})',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laporkan Kejadian',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text(
                  'Penipuan, kekerasan, pelecehan, ancaman — laporkan melalui tombol di detail order atau profil.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}