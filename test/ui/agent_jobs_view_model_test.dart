import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/agent_mode/agent_jobs_view_model.dart';
import '../fake_snapshot_storage.dart';

Ord order(String id, String status, {required bool client}) => Ord(
    id: id, reqId: 'r$id', title: 't', cat: 'Taman', otherId: 'a', otherName: 'A', pin: '1', iAmClient: client, price: 100000, status: status);

void main() {
  test('pekerjaan agen dipisah berjalan/riwayat dan mengabaikan order sebagai klien', () {
    final store = AppState(storage: FakeSnapshotStorage());
    store.orders.addAll([
      order('1', 'IN_PROGRESS', client: false),
      order('2', 'COMPLETED', client: false),
      order('3', 'IN_PROGRESS', client: true),
    ]);
    final vm = AgentJobsViewModel(store);
    expect(vm.active.map((o) => o.id), ['1']);
    expect(vm.history.map((o) => o.id), ['2']);
    store.dispose();
  });
}
