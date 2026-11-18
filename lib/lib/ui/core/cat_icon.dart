import 'package:flutter/material.dart';
import 'package:buruhku/domain/models/catalog.dart';

/// Ikon kategori jasa berupa gambar (assets/icons/<id>.png).
/// Kalau file gambarnya belum ada, otomatis memakai ikon Material milik kategori.
class CatIcon extends StatelessWidget {
  final Cat cat;
  final double size;
  const CatIcon(this.cat, {this.size = 24, super.key});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icons/${cat.id}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => Icon(cat.icon, size: size),
      );
}

const _catShort = <String, String>{
  'clean': 'Cleaning',
  'elec': 'Service Elektronik',
  'move': 'Angkat & Pindahan',
  'garden': 'Taman & Halaman',
  'repair': 'Perbaikan Rumah',
  'errand': 'Antar Jemput',
  'laundry': 'Laundry/ Setrika',
  'other': 'Jasa Lain/ Request',
};

// Warna tag per kategori, diambil dari warna dominan ikonnya.
const _catColor = <String, Color>{
  'clean': Color(0xFF6EC1F5),
  'elec': Color(0xFFFFA726),
  'move': Color(0xFFFF8A50),
  'garden': Color(0xFF6CCB7A),
  'repair': Color(0xFF9C8CF0),
  'errand': Color(0xFFFF6F9C),
  'laundry': Color(0xFF7C9CF5),
  'other': Color(0xFFC77DDB),
};

extension CatUi on Cat {
  /// Nama pendek untuk label di bawah ikon Beranda.
  String get short => _catShort[id] ?? name;

  /// Warna tag kategori.
  Color get color => _catColor[id] ?? const Color(0xFFBDBDBD);
}
