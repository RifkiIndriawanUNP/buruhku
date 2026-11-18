import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';

/// Jalan pintas ke AppState lewat Provider.
/// `s` ikut mendengarkan perubahan (dipakai di build); `r` hanya membaca (dipakai di callback).
extension StoreCtx on BuildContext {
  AppState get s => watch<AppState>();
  AppState get r => read<AppState>();
}
