/// Konfigurasi sumber data. Diatur lewat --dart-define saat menjalankan app:
///
///   flutter run                                         -> data lokal (default)
///   flutter run --dart-define=DATA_SOURCE=api \
///               --dart-define=API_URL=https://api.contoh.com
class Env {
  static const dataSource = String.fromEnvironment('DATA_SOURCE', defaultValue: 'local');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static bool get useApi => dataSource == 'api';
}
