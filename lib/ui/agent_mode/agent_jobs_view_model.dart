import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Daftar pekerjaan di Mode Agen: berjalan, riwayat, dan yang menunggu keputusan klien.
class AgentJobsViewModel {
  AgentJobsViewModel(this._store);
  final AppState _store;

  List<Ord> get _mine => _store.orders.where((o) => !o.iAmClient).toList();
  List<Ord> get active => _mine.where((o) => o.active).toList();
  List<Ord> get history => _mine.where((o) => !o.active).toList();
  List<Req> get waitingForClient =>
      _store.reqs.where((r) => !r.mine && r.acc.any((a) => a.agentId == 'me' && a.status == 'accepted')).toList();
}
