/// Tempat AppState menyimpan dan memuat seluruh datanya (satu snapshot JSON).
///
/// Sekarang hanya ada implementasi lokal (`LocalSnapshotStorage`). Untuk
/// terhubung ke server/database, buat implementasi baru tanpa mengubah AppState.
abstract class SnapshotStorage {
  /// Mengembalikan snapshot terakhir, atau null jika belum ada / rusak.
  Future<Map<String, dynamic>?> load();

  Future<void> save(Map<String, dynamic> data);
}
