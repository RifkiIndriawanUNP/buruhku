import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/data/services/photo_service.dart';
import 'package:buruhku/ui/core/dialogs.dart';
import 'package:buruhku/ui/core/store_context.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/ui/core/widgets.dart';

/// Avatar milik pengguna: foto profil bila ada, ikon bawaan bila tidak (atau file hilang).
class MyAvatar extends StatelessWidget {
  const MyAvatar({super.key, this.size = 44});
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.s.profilePhoto;
    if (p.isEmpty) return Avatar(size: size);
    return ClipOval(child: Image.file(File(p), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Avatar(size: size)));
  }
}

/// Foto sementara: tampil bila file masih ada, kalau tidak jatuh ke placeholder.
class TempPhoto extends StatelessWidget {
  const TempPhoto({super.key, this.path, this.w, this.h});
  final String? path;
  final double? w, h;
  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return Ph(w: w, h: h);
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          p,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Ph(w: w, h: h),
        ),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(p), width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Ph(w: w, h: h)));
  }
}

/// Baris foto sementara (kamera/galeri) dengan batas jumlah. Path kosong = foto dari sesi lama.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.paths, required this.onChanged, this.max = 5, this.size = 64});
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final double size;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < paths.length; i++)
          Stack(children: [
            TempPhoto(path: paths[i], w: size, h: size),
            Positioned(right: 0, top: 0, child: GestureDetector(onTap: () => onChanged([...paths]..removeAt(i)), child: const Icon(Icons.cancel, size: 18))),
          ]),
        if (paths.length < max)
          InkWell(
            onTap: () async {
              final p = await pickTempPhoto(context);
              if (p != null) onChanged([...paths, p]);
            },
            child: Container(width: size, height: size, decoration: BoxDecoration(border: Border.all(color: g500), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_a_photo_outlined)),
          ),
      ]);
}

/// Pilih sumber (kamera/galeri) lalu ambil foto sementara. Null bila dibatalkan atau gagal.
Future<String?> pickTempPhoto(BuildContext context, {bool front = false}) async {
  final photos = context.read<PhotoService>();
  final src = await showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (x) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil dengan kamera'), onTap: () => Navigator.pop(x, PhotoSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(x, PhotoSource.gallery)),
      ]),
    ),
  );
  if (src == null) return null;
  try {
    return await photos.pickTemporary(src, front: front);
  } catch (_) {
    if (context.mounted) toast(context, 'Kamera atau galeri tidak bisa dibuka di perangkat ini.');
    return null;
  }
}

/// Ganti atau hapus foto profil (disimpan permanen di penyimpanan privat aplikasi).
/// Mengembalikan true bila foto profil berubah.
Future<bool> changeProfilePhoto(BuildContext context) async {
  final photos = context.read<PhotoService>();
  final state = context.r;
  final has = state.profilePhoto.isNotEmpty;
  final act = await showModalBottomSheet<String>(
    context: context,
    builder: (x) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Ambil dengan kamera'), onTap: () => Navigator.pop(x, 'camera')),
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(x, 'gallery')),
        if (has) ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Hapus foto profil'), onTap: () => Navigator.pop(x, 'remove')),
      ]),
    ),
  );
  if (act == null) return false;
  try {
    final old = state.profilePhoto;
    if (act == 'remove') {
      state.setProfilePhoto('');
      await photos.delete(old);
      return true;
    }
    final path = await photos.pickProfile(act == 'camera' ? PhotoSource.camera : PhotoSource.gallery);
    if (path == null) return false;
    state.setProfilePhoto(path);
    await photos.delete(old);
    return true;
  } catch (_) {
    if (context.mounted) toast(context, 'Kamera atau galeri tidak bisa dibuka di perangkat ini.');
    return false;
  }
}

/// Hapus file foto profil dari penyimpanan (dipanggil saat akun dihapus).
void forgetProfilePhoto(BuildContext context) {
  unawaited(context.read<PhotoService>().delete(context.r.profilePhoto));
}

/// Demo verifikasi wajah: membuka kamera depan, lalu menampilkan hasil PALSU (selalu lolos).
/// Foto selfie tidak disimpan. Mengembalikan true bila "lolos".
Future<bool> runFaceDemo(BuildContext context) async {
  final photos = context.read<PhotoService>();
  String? path;
  try {
    path = await photos.pickTemporary(PhotoSource.camera, front: true);
  } catch (_) {
    if (context.mounted) toast(context, 'Kamera tidak tersedia di perangkat ini.');
    return false;
  }
  if (path == null || !context.mounted) return false;
  final shot = path;
  final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => _FaceDemoDialog(path: shot)) ?? false;
  unawaited(photos.delete(shot));
  return ok;
}

class _FaceDemoDialog extends StatefulWidget {
  const _FaceDemoDialog({required this.path});
  final String path;
  @override
  State<_FaceDemoDialog> createState() => _FaceDemoDialogState();
}

class _FaceDemoDialogState extends State<_FaceDemoDialog> {
  final match = 90 + Random().nextInt(8);
  bool done = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => done = true);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Verifikasi wajah'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipOval(child: Image.file(File(widget.path), width: 140, height: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Avatar(size: 140, icon: Icons.face_outlined))),
          const SizedBox(height: 16),
          if (!done) ...[const CircularProgressIndicator(strokeWidth: 2.5), const SizedBox(height: 12), const Text('Mencocokkan wajah dengan foto KTP...')]
          else ...[const Icon(Icons.check_circle, size: 32), const SizedBox(height: 6), Text('Liveness lolos, kecocokan wajah $match%', textAlign: TextAlign.center)],
          const SizedBox(height: 8),
          Text('Hasil ini simulasi untuk demo. Foto selfie tidak disimpan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: g500)),
        ]),
        actions: [if (done) TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjut'))],
      );
}
