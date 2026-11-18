/// Konfigurasi sumber data dan peta. Diatur lewat --dart-define saat menjalankan app:
///
///   flutter run                                         -> data lokal (default)
///   flutter run --dart-define=DATA_SOURCE=api \
///               --dart-define=API_URL=https://api.contoh.com
class Env {
  static const dataSource = String.fromEnvironment('DATA_SOURCE', defaultValue: 'local');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static bool get useApi => dataSource == 'api';

  // ---- peta ----
  /// Titik pusat demo: lokasi default klien, pusat agen simulasi, dan pusat kamera.
  /// Ganti dua angka ini untuk memindahkan seluruh demo ke kota lain.
  static const mapLat = -6.9878;
  static const mapLng = 106.5517;
  static const mapZoom = 14.0;

  /// Server tile. Server publik OpenStreetMap hanya untuk prototype dan demo kecil.
  /// Sebelum rilis, ganti ke penyedia tile lain (--dart-define=TILE_URL=...).
  static const tileUrl = String.fromEnvironment('TILE_URL', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

  /// Wajib sama dengan applicationId aplikasi (lihat android/app/build.gradle),
  /// supaya trafik app ini dikenali oleh server tile.
  static const tileUserAgent = String.fromEnvironment('TILE_USER_AGENT', defaultValue: 'com.example.buruhku');
}
