import 'package:flutter/material.dart';
import 'package:buruhku/ui/core/theme.dart';
import 'package:buruhku/utils/formatters.dart';

// Potongan UI yang dipakai bersama oleh kartu jasa dan kartu agen.

const kBlue = Color(0xFF2AABEE); // lencana terverifikasi
const kNavy = Color(0xFF1A2B5F); // bintang & ikon statistik
const kSeeAll = Color(0xFF4CC585); // teks "Lihat semua"
const kPeach = Color(0xFFFFCCBC); // tag jenis harga
const kPh = Color(0xFFE4E5E9); // latar placeholder foto
const kPhIcon = Color(0xFFB4B6BE);

// Jarak baku. Pakai konstanta ini, jangan angka lepas, supaya semua kartu terasa sama rapatnya.
const kGapXs = 4.0; // antar baris teks kecil
const kGapSm = 8.0; // antar elemen dalam satu kartu
const kGapMd = 12.0; // antar blok dalam satu kartu
const kCardGap = 12.0; // antar kartu putih (SoftCard) di daftar vertikal
const kTileGap = 10.0; // antar kartu garis (Box) di daftar vertikal

/// Rupiah dengan spasi: "Rp 63.000".
String rpSp(num n) => rp(n).replaceFirst('Rp', 'Rp ');

/// Foto jasa sementara (placeholder abu-abu) atau foto online jika url tersedia.
class PhotoPlaceholder extends StatelessWidget {
  final double height;
  final double radius;
  final String? url;
  const PhotoPlaceholder({required this.height, this.radius = 14, this.url, super.key});
  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          url!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _loading(),
        ),
      );
    }
    return _fallback();
  }

  Widget _loading() => Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: kPh, borderRadius: BorderRadius.circular(radius)),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: kNavy),
        ),
      );

  Widget _fallback() => Container(
        height: height,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: kPh, borderRadius: BorderRadius.circular(radius)),
        child: const Icon(Icons.image_outlined, color: kPhIcon, size: 30),
      );
}

/// Foto profil sementara (lingkaran) atau avatar online jika url tersedia.
class AvatarPh extends StatelessWidget {
  final double size;
  final String? url;
  const AvatarPh(this.size, {this.url, super.key});
  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDADADA)),
        child: Icon(Icons.person, size: size * 0.6, color: Colors.white70),
      );
}

/// Pil kecil untuk kategori / jenis harga. Tinggi tetap, teks satu baris.
class CatTag extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize, height;
  const CatTag(this.text, this.color, {this.fontSize = 10, this.height = 20, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Color.lerp(color, Colors.black, .18)!, width: .8),
          ),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(text, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: g900, height: 1.1)),
            ),
          ),
        ),
      );
}

class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({this.size = 16, super.key});
  @override
  Widget build(BuildContext context) => Icon(Icons.verified, size: size, color: kBlue);
}

/// Kartu putih: garis tipis + bayangan lembut. Dipakai oleh kartu jasa, kartu agen, dan tile kategori.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;
  const SoftCard({required this.child, this.padding = const EdgeInsets.all(12), this.radius = 22, this.onTap, this.shadow = true, super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFFDCDDE1)),
            boxShadow: shadow ? const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))] : null,
          ),
          child: child,
        ),
      );
}

/// Tombol bulat bergaris (lonceng, hati).
class RoundBtn extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  final bool shadow;
  const RoundBtn({required this.size, required this.child, this.onTap, this.shadow = false, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: SoftCard(radius: size / 2, padding: EdgeInsets.zero, onTap: onTap, shadow: shadow, child: Center(child: child)),
      );
}

/// Tombol pil bergaris dengan teks satu baris (mengecil otomatis bila sempit).
class PillBtn extends StatelessWidget {
  final String label;
  final double height;
  final VoidCallback? onTap;
  const PillBtn(this.label, {this.height = 38, this.onTap, super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: SoftCard(
          radius: height / 2,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onTap: onTap,
          shadow: false,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: g900, height: 1.2)),
            ),
          ),
        ),
      );
}
