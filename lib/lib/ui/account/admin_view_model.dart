import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Antrean moderasi dan statistik platform untuk Panel Admin.
/// Dihitung dari data repository setiap layar digambar, tanpa state sendiri.
class AdminViewModel {
  AdminViewModel(this._store);
  final AppState _store;

  List<Req> get reviewQueue => _store.reqs.where((r) => r.mine && r.status == 'IN_REVIEW').toList();
  List<Rep> get openReports => _store.reports.where((r) => r.status == 'Diterima').toList();
  List<Disp> get openDisputes => _store.disputes.where((d) => d.status != 'resolved' && d.status != 'cancelled').toList();

  Iterable<Ord> get _done => _store.orders.where((o) => o.status == 'COMPLETED' || o.status == 'REVIEWED');

  int get requestsCreated => _store.reqs.where((r) => r.mine).length;
  int get ordersTotal => _store.orders.length;
  int get ordersDone => _done.length;
  int get gmv => _done.fold(0, (a, o) => a + o.total);
  int get platformRevenue => _done.fold(0, (a, o) => a + o.fee + o.commission);
  int get disputesTotal => _store.disputes.length;
  int get reportsTotal => _store.reports.length;
  int get sosTotal => _store.soses.length;
  int get agentCount => _store.agents.length;
}
