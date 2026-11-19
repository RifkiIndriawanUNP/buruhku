import 'package:flutter/material.dart';
import 'package:buruhku/ui/account/wallet_view_model.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'agent_profile_page.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  Future<void> _withdraw(BuildContext context, AppState s) async {
    if (s.pin.isEmpty) {
      final p = await askText(context, 'Buat PIN (4-6 digit)', number: true, obscure: true);
      if (p == null || p.length < 4 || p.length > 6) {
        if (p != null && context.mounted) toast(context, 'PIN harus 4-6 digit.');
        return;
      }
      s.pin = p;
      s.notifyListeners();
    }
    if (!context.mounted) return;
    final dests = ['${s.kyc.bank} ${s.kyc.bankNo}', ...s.wallets.map((w) => w.replaceAll('|', ' '))];
    var dest = dests.first;
    final amt = TextEditingController(), pin = TextEditingController();
    String? err;
    await sheet<void>(
      context,
      (x) => StatefulBuilder(
        builder: (ctx, set) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tarik Saldo (${rp(s.balance)})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: dest,
              decoration: const InputDecoration(labelText: 'Tujuan'),
              items: [for (final d in dests) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) => set(() => dest = v ?? dest),
            ),
            const SizedBox(height: 12),
            TF('Nominal (min Rp25.000)', amt, money: true),
            TF('PIN', pin, type: TextInputType.number, obscure: true, maxLen: 6),
            if (err != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(err!, style: const TextStyle(color: kRed))),
            full(pbtn('Tarik Sekarang', () {
              final e = s.withdraw(money(amt.text), dest, pin.text);
              if (e != null) {
                set(() => err = e);
                return;
              }
              Navigator.pop(x);
              toast(context, 'Penarikan diproses (maks H+1).');
            }, icon: Icons.account_balance_outlined)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final wallet = WalletViewModel(s);
    final led = wallet.agentLedger;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: RevealListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, kBarSpace),
        children: [
          Row(
            children: [
              Expanded(child: Text('Pendapatan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: g900))),
              RoundBtn(
                size: 46,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentProfilePage())),
                child: Tooltip(message: 'Profil & pengaturan agen', child: Icon(Icons.tune_rounded, size: 22, color: g900)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hero Wallet Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [g900, g900.withValues(alpha: 0.88)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Saldo Tersedia', style: TextStyle(color: g300, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 13, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('Escrow ${rp(s.held)}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    rp(s.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: s.kyc.status == 'approved' ? () => _withdraw(context, s) : null,
                    icon: const Icon(Icons.south_west_rounded, size: 18),
                    label: const Text('Tarik Saldo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),

          if (s.balance < 0)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Warn('Saldo minus (komisi COD). Terpotong otomatis dari order berikutnya.', icon: Icons.payments_outlined),
            ),

          const SizedBox(height: 12),

          // Ringkasan 1 / 7 / 30 Hari
          Row(
            children: [
              Expanded(child: _EarningPeriodCard('Hari ini', rp(s.earned(const Duration(days: 1))))),
              const SizedBox(width: 8),
              Expanded(child: _EarningPeriodCard('7 hari', rp(s.earned(const Duration(days: 7))))),
              const SizedBox(width: 8),
              Expanded(child: _EarningPeriodCard('30 hari', rp(s.earned(const Duration(days: 30))))),
            ],
          ),

          if (s.payouts.isNotEmpty) ...[
            const Section('Riwayat Penarikan'),
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final p in s.payouts.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.north_east_rounded, size: 18, color: g900),
                      ),
                      title: Text(rp(p.amount), style: TextStyle(fontWeight: FontWeight.w800, color: g900)),
                      subtitle: Text('${p.dest} \u2022 ${fdt(p.at)}', style: TextStyle(fontSize: 12, color: g500)),
                      trailing: Tag(p.status, filled: p.status == 'Berhasil'),
                    ),
                ],
              ),
            ),
          ],

          const Section('Jurnal Transaksi'),
          if (led.isEmpty)
            SoftCard(radius: 20, child: Text('Belum ada transaksi.', style: TextStyle(color: g500)))
          else
            SoftCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final l in led.take(20))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (l.amount >= 0 ? kGreen : kRed).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          l.amount >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                          size: 16,
                          color: l.amount >= 0 ? kGreen : kRed,
                        ),
                      ),
                      title: Text(l.note, style: TextStyle(fontWeight: FontWeight.w600, color: g900)),
                      subtitle: Text(fdt(l.at), style: TextStyle(fontSize: 11.5, color: g500)),
                      trailing: Text(
                        rp(l.amount),
                        style: TextStyle(fontWeight: FontWeight.w800, color: l.amount >= 0 ? kGreen : g900),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EarningPeriodCard extends StatelessWidget {
  final String label;
  final String amount;
  const _EarningPeriodCard(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(amount, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: g900)),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: g500)),
        ],
      ),
    );
  }
}