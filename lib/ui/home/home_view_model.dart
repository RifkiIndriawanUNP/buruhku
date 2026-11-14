import 'package:flutter/foundation.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Menyiapkan isi Beranda: agen terdekat, terpopuler, jasa sekitar, dan lokasi aktif.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required AppState store}) : _store = store {
    _refresh();
    _store.addListener(_onStoreChange);
  }

  final AppState _store;
  late List<Agent> _nearbyAgents;
  late List<Agent> _popularAgents;
  late List<Svc> _nearbyServices;

  void _refresh() {
    _nearbyAgents = _store.searchAgents(sort: 'jarak').take(8).toList();
    final l = [..._store.agents]..sort((a, b) => b.jobs.compareTo(a.jobs));
    _popularAgents = l.take(8).toList();
    _nearbyServices = _store.svcsNear().take(8).toList();
  }

  void _onStoreChange() {
    _refresh();
    notifyListeners();
  }

  List<Agent> get nearbyAgents => _nearbyAgents;
  List<Agent> get popularAgents => _popularAgents;
  List<Svc> get nearbyServices => _nearbyServices;

  String get address => _store.address;
  int get unreadNotes => _store.unreadNotes;
  bool get canSwitchToAgent => _store.kyc.status == 'approved';

  void setAddress(String v) => _store.setAddress(v);
  void switchToAgentMode() => _store.setMode(true);

  @override
  void dispose() {
    _store.removeListener(_onStoreChange);
    super.dispose();
  }
}
