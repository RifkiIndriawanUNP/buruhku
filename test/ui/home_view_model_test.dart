import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/home/home_view_model.dart';
import '../fake_snapshot_storage.dart';

void main() {
  late AppState store;
  late HomeViewModel viewModel;

  setUp(() {
    store = AppState(storage: FakeSnapshotStorage());
    viewModel = HomeViewModel(store: store);
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  test('agen terpopuler diurutkan dari pekerjaan terbanyak, maksimal 8', () {
    final jobs = viewModel.popularAgents.map((a) => a.jobs).toList();
    expect(jobs.length, lessThanOrEqualTo(8));
    expect(jobs, [...jobs]..sort((a, b) => b.compareTo(a)));
  });

  test('agen terdekat diurutkan dari jarak terkecil', () {
    final d = viewModel.nearbyAgents.map((a) => a.dist).toList();
    expect(d, [...d]..sort());
  });

  test('Beranda ikut berubah saat lokasi diatur lewat ViewModel', () {
    var dipanggil = 0;
    viewModel.addListener(() => dipanggil++);
    viewModel.setAddress('Jl. Kenanga No. 5');
    expect(viewModel.address, 'Jl. Kenanga No. 5');
    expect(dipanggil, 1);
  });
}
