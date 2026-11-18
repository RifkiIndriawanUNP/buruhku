import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:buruhku/config/env.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/data/repositories/safety_repository.dart';
import 'package:buruhku/data/services/local_snapshot_storage.dart';
import 'package:buruhku/data/services/photo_service.dart';
import 'package:buruhku/data/services/snapshot_storage.dart';

/// Service dan repository dibuat sekali, di satu tempat, lalu dibagikan lewat Provider.
/// Untuk pindah ke server, ganti pilihan `storage` di sini saja.
Future<List<SingleChildWidget>> buildProviders() async {
  final SnapshotStorage storage = Env.useApi
      ? throw UnimplementedError('DATA_SOURCE=api belum diimplementasikan (Tahap 4).')
      : LocalSnapshotStorage();
  final store = AppState(storage: storage);
  await store.init();
  return [
    Provider<SnapshotStorage>.value(value: storage),
    Provider<PhotoService>(create: (_) => PhotoService()),
    ChangeNotifierProvider<AppState>(create: (_) => store),
    // Repository per domain: dipakai ViewModel baru. AppState yang memegang dan membuangnya.
    ChangeNotifierProvider<SafetyRepository>.value(value: store.safety),
  ];
}
