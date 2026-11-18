import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

enum PhotoSource { camera, gallery }

/// Pembungkus kamera/galeri perangkat. Layar tidak memanggil plugin langsung,
/// sehingga mudah diganti versi palsu saat test.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  /// Foto SEMENTARA: mengembalikan path apa adanya (cache/galeri), tidak disalin.
  /// Cocok untuk foto request, bukti, dan chat; bisa hilang kapan saja.
  Future<String?> pickTemporary(PhotoSource source, {bool front = false}) async {
    final f = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
      preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
    );
    return f?.path;
  }

  /// Foto PROFIL: disalin ke penyimpanan privat aplikasi (bertahan sampai aplikasi
  /// dihapus atau datanya dibersihkan). Nama file unik agar gambar lama tidak tertahan cache.
  Future<String?> pickProfile(PhotoSource source) async {
    final tmp = await pickTemporary(source, front: source == PhotoSource.camera);
    if (tmp == null) return null;
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/profile');
    await dir.create(recursive: true);
    final dest = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(tmp).copy(dest);
    return dest;
  }

  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
