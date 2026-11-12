import 'package:buruhku/data/repositories/memory/local_snapshot_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buruhku/app/app.dart';
import 'package:buruhku/data/repositories/memory/app_store.dart';

void main() {
  testWidgets('Aplikasi tampil (splash Buruhku)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(storage: LocalSnapshotStorage());
    await store.init();
    await tester.pumpWidget(StoreScope(store: store, child: const BuruhkuApp()));
    expect(find.text('Buruhku'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    store.dispose();
  });
}
