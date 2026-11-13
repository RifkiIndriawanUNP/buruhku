import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Riwayat saldo untuk klien (role 'c') dan agen (role 'a'), serta ulasan yang diterima agen.
class WalletViewModel {
  WalletViewModel(this._store);
  final AppState _store;

  List<Led> get clientLedger => _store.ledger.where((l) => l.role == 'c').toList();
  List<Led> get agentLedger => _store.ledger.where((l) => l.role == 'a').toList();
  List<Rev> get agentReviews => _store.revs.where((v) => v.aboutId == 'me' && v.pub).toList();
}
