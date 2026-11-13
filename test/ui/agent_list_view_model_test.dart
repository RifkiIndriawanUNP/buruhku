import 'package:flutter_test/flutter_test.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/agents/agent_list_view_model.dart';
import '../fake_snapshot_storage.dart';

void main() {
  late AppState store;
  late AgentListViewModel viewModel;

  setUp(() {
    store = AppState(storage: FakeSnapshotStorage());
    viewModel = AgentListViewModel(store: store);
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  test('filter terverifikasi hanya menyisakan agen terverifikasi', () {
    viewModel.verified = true;
    expect(viewModel.agents.every((a) => a.verified), isTrue);
  });

  test('filter jarak membatasi hasil', () {
    viewModel.maxDist = 3;
    expect(viewModel.agents.every((a) => a.dist <= 3), isTrue);
  });

  test('mengubah filter memberi tahu pendengar', () {
    var dipanggil = 0;
    viewModel.addListener(() => dipanggil++);
    viewModel.online = true;
    expect(dipanggil, 1);
  });
}
