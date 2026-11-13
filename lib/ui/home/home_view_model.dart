import 'package:flutter/foundation.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Menyiapkan isi Beranda: agen terdekat, terpopuler, jasa sekitar, dan lokasi aktif.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required AppState store}) : _store = store {
    _store.addListener(notifyListeners);
  }

  final AppState _store;

  List<Agent> get nearbyAgents => _store.searchAgents(sort: 'jarak').take(8).toList();

  List<Agent> get popularAgents {
    final l = [..._store.agents]..sort((a, b) => b.jobs.compareTo(a.jobs));
    return l.take(8).toList();
  }

  List<Svc> get nearbyServices => _store.svcsNear().take(8).toList();

  String get address => _store.address;
  int get unreadNotes => _store.unreadNotes;
  bool get canSwitchToAgent => _store.kyc.status == 'approved';

  void setAddress(String v) => _store.setAddress(v);
  void switchToAgentMode() => _store.setMode(true);

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}
