import 'package:buruhku/data/services/snapshot_storage.dart';

/// Storage palsu untuk test: tanpa berkas, tanpa jeda.
class FakeSnapshotStorage implements SnapshotStorage {
  @override
  Future<Map<String, dynamic>?> load() async => null;

  @override
  Future<void> save(Map<String, dynamic> data) async {}
}
