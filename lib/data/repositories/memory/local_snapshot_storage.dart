import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buruhku/data/repositories/snapshot_storage.dart';

/// Penyimpanan lokal di perangkat (SharedPreferences). Perilakunya sama
/// dengan sebelumnya: satu kunci `buruhku_v1` berisi JSON seluruh data.
class LocalSnapshotStorage implements SnapshotStorage {
  static const _key = 'buruhku_v1';
  SharedPreferences? _p;

  Future<SharedPreferences> _prefs() async => _p ??= await SharedPreferences.getInstance();

  @override
  Future<Map<String, dynamic>?> load() async {
    final raw = (await _prefs()).getString(_key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    await (await _prefs()).setString(_key, jsonEncode(data));
  }
}
