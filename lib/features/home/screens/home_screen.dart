import 'package:flutter/material.dart';
import '../../../app/env.dart';
import '../../../app/services.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/box.dart';
import '../../../data/models/agent.dart';
// TAMBAHKAN IMPORT INI (Error method CategoryScreen tidak ditemukan)
import 'agent_profile_screen.dart'; 
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _cats = [
    ('cleaning', 'Bersih-bersih', Icons.cleaning_services_outlined),
    ('repair', 'Perbaikan Ringan', Icons.handyman_outlined),
    ('moving', 'Angkat & Pindah', Icons.local_shipping_outlined),
    ('garden', 'Taman & Halaman', Icons.grass_outlined),
    ('laundry', 'Setrika / Laundry', Icons.local_laundry_service_outlined),
    ('pickup', 'Antar-Jemput', Icons.delivery_dining_outlined),
  ];

  final _search = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final user = Services.auth.currentUser;
    final agents = Services.requests.nearbyAgents('cleaning',
        lat: Env.demoLat, lng: Env.demoLng);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    Env.demoCity,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Hai, ${user?.fullName ?? 'Pengguna'} 👋',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Apa yang bisa kami bantu hari ini?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari jasa atau agen…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Kategori Jasa',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: _cats
                  .where((c) =>
                      _query.isEmpty || c.$2.toLowerCase().contains(_query))
                  .map((c) => _CategoryTile(
                        id: c.$1,
                        label: c.$2,
                        icon: c.$3,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(
                              categoryId: c.$1,
                              categoryName: c.$2,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Agen Terdekat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryScreen(
                        categoryId: 'cleaning',
                        categoryName: 'Bersih-bersih',
                      ),
                    ),
                  ),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (agents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Belum ada agen tersedia')),
              )
            else
              ...agents.take(4).map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AgentRow(agent: a),
                    ),
                  ),
            const SizedBox(height: 12),
            AppBox(
              color: const Color(0xFFFFF6E5),
              border: Border.all(color: const Color(0xFFFFE0A3)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFB26B00)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dana ditahan (escrow) hingga pekerjaan selesai. Pembayaran di luar aplikasi tidak dilindungi.',
                      style: TextStyle(color: Colors.brown.shade800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  final Agent agent;
  const _AgentRow({required this.agent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AgentProfileScreen(agent: agent)),
      ),
      borderRadius: BorderRadius.circular(14),
      child: AppBox(
        child: Row(
          children: [
            InitialAvatar(name: agent.displayName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(agent.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (agent.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, size: 14, color: Colors.blue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '⭐ ${agent.ratingAvg.toStringAsFixed(1)} · ${agent.jobsCompleted} job · ${agent.distanceFrom(Env.demoLat, Env.demoLng).toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}