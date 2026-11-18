part of 'app_state.dart';

/// Dasar semua repository/service: memegang AppState (sumber kebenaran data bersama)
/// dan meneruskan notifyListeners agar layar tersegarkan dan data tersimpan.
abstract class RepoBase {
  RepoBase(this.hub);
  final AppState hub;

  void notifyListeners() => hub.notifyListeners(); // ignore: invalid_use_of_protected_member
}
