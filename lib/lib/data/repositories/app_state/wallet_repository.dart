part of 'app_state.dart';

/// Dompet agen: saldo, payout, penalti.
class WalletRepository extends RepoBase {
  WalletRepository(super.hub);

  // ---- akses ke state bersama & domain lain (lewat AppState) ----
  String get pin => hub.pin;
  set pin(String v) => hub.pin = v;
  Kyc get kyc => hub.kyc;
  set kyc(Kyc v) => hub.kyc = v;
  List<Ord> get orders => hub.orders;
  set orders(List<Ord> v) => hub.orders = v;
  List<Led> get ledger => hub.ledger;
  set ledger(List<Led> v) => hub.ledger = v;
  List<Rev> get revs => hub.revs;
  set revs(List<Rev> v) => hub.revs = v;
  List<Payout> get payouts => hub.payouts;
  set payouts(List<Payout> v) => hub.payouts = v;
  int get balance => hub.balance;
  set balance(int v) => hub.balance = v;
  int get declines => hub.declines;
  set declines(int v) => hub.declines = v;
  int get accepts => hub.accepts;
  set accepts(int v) => hub.accepts = v;
  String nid(String p) => hub.nid(p);
  void notify(String t, String b) => hub.notify(t, b);

  // ================= dompet agen =================
  int get held => orders.where((o) => !o.iAmClient && o.escrow == 'held').fold(0, (a, o) => a + o.net);
  String? withdraw(int amount, String dest, String pinIn) {
    if (pin.isEmpty || pinIn != pin) return 'PIN salah.';
    if (amount < 25000) return 'Minimal penarikan Rp25.000.';
    if (amount > balance) return 'Saldo tidak cukup.';
    balance -= amount;
    ledger.insert(0, Led(id: nid('L'), role: 'a', type: 'payout', amount: -amount, note: 'Tarik saldo ke $dest'));
    payouts.insert(0, Payout(id: nid('P'), amount: amount, dest: dest));
    notify('Penarikan diproses', '${rp(amount)} ke $dest (maks H+1).');
    notifyListeners();
    return null;
  }

  int earned(Duration d) {
    final from = DateTime.now().subtract(d);
    return ledger.where((l) => l.role == 'a' && (l.type == 'release' || l.type == 'fee' || l.type == 'cod') && l.at.isAfter(from)).fold(0, (a, l) => a + l.amount);
  }

  int get myJobs => orders.where((o) => !o.iAmClient && ['COMPLETED', 'REVIEWED'].contains(o.status)).length;
  double get myRating {
    final l = revs.where((v) => v.aboutId == 'me' && v.pub).toList();
    return l.isEmpty ? 0.0 : l.fold<int>(0, (a, v) => a + v.rating) / l.length;
  }

  int get myLevel {
    if (kyc.status != 'approved') return 0;
    if (kyc.skck && myJobs >= 5 && myRating >= 4.0) return (myJobs >= 50 && myRating >= 4.7) ? 3 : 2;
    return 1;
  }

  double get acceptRate => (accepts + declines) == 0 ? 1.0 : accepts / (accepts + declines);
}
