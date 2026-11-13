import 'package:flutter/foundation.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/domain/models/models.dart';

/// Filter dan urutan daftar agen. Hasilnya dihitung ulang dari repository.
class AgentListViewModel extends ChangeNotifier {
  AgentListViewModel({required AppState store, this.cat, String sort = 'relevansi'})
      : _store = store,
        _sort = sort {
    _store.addListener(notifyListeners);
  }

  final AppState _store;
  final String? cat;

  double _maxDist = 15, _minRating = 0;
  bool _verified = false, _online = false;
  String _sort;

  double get maxDist => _maxDist;
  double get minRating => _minRating;
  bool get verified => _verified;
  bool get online => _online;
  String get sort => _sort;

  set maxDist(double v) => _update(() => _maxDist = v);
  set minRating(double v) => _update(() => _minRating = v);
  set verified(bool v) => _update(() => _verified = v);
  set online(bool v) => _update(() => _online = v);
  set sort(String v) => _update(() => _sort = v);

  List<Agent> get agents => _store.searchAgents(
      cat: cat, maxDist: _maxDist, minRating: _minRating, verified: _verified, online: _online, sort: _sort);

  void _update(VoidCallback f) {
    f();
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}
