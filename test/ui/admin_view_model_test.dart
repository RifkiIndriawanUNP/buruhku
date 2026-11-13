import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';
import 'package:buruhku/ui/account/admin_view_model.dart';
import '../fake_snapshot_storage.dart';

Ord order(String id, String status, int price) => Ord(
    id: id, reqId: 'r$id', title: 't', cat: 'Taman', otherId: 'a', otherName: 'A', pin: '1', iAmClient: true, price: price, fee: 3000, status: status);

void main() {
  late AppState store;
  late AdminViewModel vm;

  setUp(() {
    store = AppState(storage: FakeSnapshotStorage());
    vm = AdminViewModel(store);
  });
  tearDown(() => store.dispose());

  test('GMV dan pendapatan platform hanya menghitung order selesai', () {
    store.orders.addAll([order('1', 'COMPLETED', 100000), order('2', 'REVIEWED', 200000), order('3', 'IN_PROGRESS', 500000)]);
    expect(vm.ordersTotal, 3);
    expect(vm.ordersDone, 2);
    expect(vm.gmv, 300000);
    expect(vm.platformRevenue, 2 * 3000 + 10000 + 20000);
  });

  test('antrean laporan hanya berisi yang berstatus Diterima', () {
    final a = store.fileReport(cat: 'Penipuan', desc: 'a');
    final b = store.fileReport(cat: 'Pelecehan', desc: 'b');
    store.adminTriage(a, 'warn');
    expect(vm.reportsTotal, 2);
    expect(vm.openReports, [b]);
  });
}
