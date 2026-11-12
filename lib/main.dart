import 'package:flutter/material.dart';
import 'package:buruhku/app/app.dart';
import 'package:buruhku/app/env.dart';
import 'package:buruhku/data/repositories/memory/app_store.dart';
import 'package:buruhku/data/repositories/memory/local_snapshot_storage.dart';
import 'package:buruhku/data/repositories/snapshot_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SnapshotStorage storage = Env.useApi
      ? throw UnimplementedError('DATA_SOURCE=api belum diimplementasikan (Tahap 4).')
      : LocalSnapshotStorage();
  final store = AppStore(storage: storage);
  await store.init();
  runApp(StoreScope(store: store, child: const BuruhkuApp()));
}
