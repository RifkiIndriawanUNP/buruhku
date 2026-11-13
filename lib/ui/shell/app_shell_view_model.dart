import 'package:flutter/foundation.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Logika kerangka aplikasi: mode, tab aktif, badge pesan, dan toast notifikasi.
class AppShellViewModel extends ChangeNotifier {
  AppShellViewModel({required AppState store}) : _store = store {
    _store.addListener(notifyListeners);
  }

  final AppState _store;

  bool get agentMode => _store.agentMode;
  int get tab => _store.tab.clamp(0, 4).toInt();
  int get unreadChats => _store.unreadChats;

  void goTab(int i) => _store.goTab(i);

  /// Mengambil notifikasi yang menunggu ditampilkan (sekali saja), atau null.
  Note? takeToast() {
    final n = _store.toastNote;
    _store.toastNote = null;
    return n;
  }

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}
