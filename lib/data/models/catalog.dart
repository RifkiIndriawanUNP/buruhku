import 'package:flutter/material.dart';

// ---------- kategori ----------
class Cat {
  final String id, name;
  final IconData icon;
  final int risk; // 1 rendah, 2 sensitif (masuk rumah / anak)
  final int lo, hi; // rekomendasi harga borongan
  const Cat(this.id, this.name, this.icon, this.risk, this.lo, this.hi);
}

const cats = <Cat>[
  Cat('clean', 'Cleaning', Icons.cleaning_services_outlined, 2, 50000, 250000),
  Cat('elec', 'Servis Elektronik Ringan', Icons.electrical_services_outlined, 1, 40000, 200000),
  Cat('move', 'Angkat & Pindahan', Icons.local_shipping_outlined, 1, 80000, 500000),
  Cat('garden', 'Taman & Halaman', Icons.yard_outlined, 1, 50000, 300000),
  Cat('repair', 'Perbaikan Rumah Ringan', Icons.handyman_outlined, 1, 75000, 400000),
  Cat('errand', 'Antar-Jemput & Titip', Icons.directions_run, 2, 20000, 150000),
  Cat('laundry', 'Laundry / Setrika', Icons.local_laundry_service_outlined, 1, 30000, 150000),
  Cat('other', 'Lain-lain / Apa Saja', Icons.apps_outlined, 1, 30000, 300000),
];
Cat catOf(String id) => cats.firstWhere((c) => c.id == id, orElse: () => cats.last);

const ptypes = {'lump': 'Borongan', 'hourly': 'Per jam', 'daily': 'Harian'};
String unitOf(String pt) => pt == 'hourly' ? '/jam' : pt == 'daily' ? '/hari' : '';

int totalOf(String ptype, int price, double dur) =>
    ptype == 'lump' ? price : (price * (dur <= 0 ? 1 : dur)).round();
int feeOf(int amt) => (amt * 0.02).round().clamp(2000, 5000).toInt();
List<int> recRange(String cat, String pt) {
  if (pt == 'hourly') return [15000, 50000];
  if (pt == 'daily') return [100000, 250000];
  final c = catOf(cat);
  return [c.lo, c.hi];
}

const ordLabels = {
  'AWAIT_AGENT': 'Menunggu konfirmasi agen',
  'AGREED': 'Menunggu pembayaran',
  'SCHEDULED': 'Dijadwalkan',
  'ON_THE_WAY': 'Agen berangkat',
  'ARRIVED': 'Agen tiba',
  'IN_PROGRESS': 'Sedang dikerjakan',
  'PENDING_CONFIRM': 'Menunggu konfirmasi selesai',
  'COMPLETED': 'Selesai',
  'REVIEWED': 'Selesai & dinilai',
  'CANCELLED': 'Dibatalkan',
  'REFUNDED': 'Dana dikembalikan',
  'DISPUTED': 'Sengketa',
  'RESOLVED': 'Sengketa selesai',
};
const reqLabels = {
  'IN_REVIEW': 'Ditinjau admin',
  'OPEN': 'Mencari agen',
  'HAS_ACCEPTORS': 'Ada agen',
  'FULL': 'Slot penuh',
  'LOCKED': 'Terisi',
  'EXPIRED': 'Kedaluwarsa',
  'CANCELLED': 'Dibatalkan',
  'REJECTED': 'Ditolak',
};

const templates = <Map<String, dynamic>>[
  {'t': 'Nyetrika baju', 'c': 'laundry', 'd': 'Menyetrika satu keranjang baju harian, sekitar 30 potong, sampai rapi.', 'p': 60000, 'pt': 'lump'},
  {'t': 'Bersihkan halaman', 'c': 'garden', 'd': 'Menyapu daun, memangkas rumput dan merapikan halaman depan serta belakang rumah.', 'p': 120000, 'pt': 'lump'},
  {'t': 'Angkat barang', 'c': 'move', 'd': 'Mengangkat lemari dan kardus dari lantai satu ke mobil bak, sekitar 15 barang.', 'p': 150000, 'pt': 'lump'},
  {'t': 'Bersihkan rumah', 'c': 'clean', 'd': 'Menyapu, mengepel dan membersihkan kamar mandi rumah tipe 36 sampai bersih.', 'p': 25000, 'pt': 'hourly'},
  {'t': 'Titip belikan makanan', 'c': 'errand', 'd': 'Membelikan makanan di warung dekat rumah dan mengantarnya ke alamat saya.', 'p': 25000, 'pt': 'lump'},
];

// ---------- saran jasa per kategori (kartu horizontal di form request) ----------
const catSuggest = <String, List<Map<String, dynamic>>>{
  'clean': [
    {'t': 'Bersihkan rumah', 'c': 'clean', 'd': 'Menyapu, mengepel dan membersihkan kamar mandi rumah tipe 36 sampai bersih.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Sapu halaman', 'c': 'clean', 'd': 'Menyapu halaman depan dan belakang rumah serta membuang sampah daun.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Ngepel teras dan lantai', 'c': 'clean', 'd': 'Mengepel teras dan seluruh lantai rumah sampai bersih dan tidak licin.', 'p': 50000, 'pt': 'lump'},
    {'t': 'Bersihkan kaca dan jendela', 'c': 'clean', 'd': 'Membersihkan kaca, jendela dan pintu kaca bagian dalam dan luar rumah.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Bersihkan kamar mandi', 'c': 'clean', 'd': 'Menyikat lantai, dinding, kloset dan bak mandi sampai bersih dan wangi.', 'p': 60000, 'pt': 'lump'},
  ],
  'elec': [
    {'t': 'Pasang kipas angin', 'c': 'elec', 'd': 'Memasang kipas angin dinding atau plafon yang sudah saya sediakan.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Ganti lampu dan fitting', 'c': 'elec', 'd': 'Mengganti beberapa lampu dan fitting yang mati di dalam rumah.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Pasang stop kontak', 'c': 'elec', 'd': 'Memasang atau mengganti stop kontak dan saklar di beberapa ruangan.', 'p': 70000, 'pt': 'lump'},
    {'t': 'Cek kulkas atau mesin cuci', 'c': 'elec', 'd': 'Memeriksa kulkas atau mesin cuci yang bermasalah dan perbaikan ringan.', 'p': 100000, 'pt': 'lump'},
    {'t': 'Pasang TV di dinding', 'c': 'elec', 'd': 'Memasang bracket dan TV di dinding ruang keluarga dengan rapi.', 'p': 100000, 'pt': 'lump'},
  ],
  'move': [
    {'t': 'Angkat barang', 'c': 'move', 'd': 'Mengangkat lemari dan kardus dari lantai satu ke mobil bak, sekitar 15 barang.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Bantu pindahan rumah', 'c': 'move', 'd': 'Membantu mengemas dan memindahkan perabot rumah ke tempat tinggal baru.', 'p': 300000, 'pt': 'lump'},
    {'t': 'Angkat galon dan gas', 'c': 'move', 'd': 'Mengangkat galon air dan tabung gas ke dalam rumah sampai ke dapur.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Bongkar muat barang', 'c': 'move', 'd': 'Membongkar dan memuat barang dagangan dari dan ke mobil pengangkut.', 'p': 35000, 'pt': 'hourly'},
    {'t': 'Pindah kasur dan lemari', 'c': 'move', 'd': 'Memindahkan kasur dan lemari antar ruangan atau antar lantai dengan aman.', 'p': 120000, 'pt': 'lump'},
  ],
  'garden': [
    {'t': 'Bersihkan halaman', 'c': 'garden', 'd': 'Menyapu daun, memangkas rumput dan merapikan halaman depan serta belakang rumah.', 'p': 120000, 'pt': 'lump'},
    {'t': 'Pangkas rumput', 'c': 'garden', 'd': 'Memangkas rumput halaman dengan mesin atau gunting sampai rata dan rapi.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Pangkas pagar tanaman', 'c': 'garden', 'd': 'Merapikan pagar tanaman dan membuang sisa pangkasan dari area rumah.', 'p': 90000, 'pt': 'lump'},
    {'t': 'Tanam dan pindah tanaman', 'c': 'garden', 'd': 'Menanam bibit atau memindahkan tanaman pot ke bedengan di halaman.', 'p': 70000, 'pt': 'lump'},
    {'t': 'Siram dan rawat tanaman', 'c': 'garden', 'd': 'Menyiram, memupuk dan merawat tanaman hias di taman selama beberapa jam.', 'p': 30000, 'pt': 'hourly'},
  ],
  'repair': [
    {'t': 'Benerin genteng bocor', 'c': 'repair', 'd': 'Mengganti beberapa genteng yang bocor dan memeriksa titik rembesan air.', 'p': 250000, 'pt': 'lump'},
    {'t': 'Cat dinding', 'c': 'repair', 'd': 'Mengecat ulang dinding satu ruangan, cat dan peralatan sudah disediakan.', 'p': 200000, 'pt': 'lump'},
    {'t': 'Perbaiki pintu dan engsel', 'c': 'repair', 'd': 'Memperbaiki pintu yang macet, engsel longgar dan kunci yang seret.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Tambal plafon bocor', 'c': 'repair', 'd': 'Menambal plafon yang rusak akibat bocor lalu merapikan dan mengecatnya.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Perbaiki keran dan saluran', 'c': 'repair', 'd': 'Mengganti keran bocor dan membersihkan saluran air yang tersumbat ringan.', 'p': 100000, 'pt': 'lump'},
  ],
  'errand': [
    {'t': 'Titip belikan makanan', 'c': 'errand', 'd': 'Membelikan makanan di warung dekat rumah dan mengantarnya ke alamat saya.', 'p': 25000, 'pt': 'lump'},
    {'t': 'Antar paket', 'c': 'errand', 'd': 'Mengantar paket atau dokumen ke alamat tujuan di sekitar kota ini.', 'p': 30000, 'pt': 'lump'},
    {'t': 'Belikan galon dan gas', 'c': 'errand', 'd': 'Membelikan galon air dan gas elpiji lalu mengantarnya sampai ke rumah.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Antre dan urus berkas', 'c': 'errand', 'd': 'Mengantre dan mengurus berkas sederhana di kantor atau loket pelayanan.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Ambil pesanan di toko', 'c': 'errand', 'd': 'Mengambil pesanan di toko lalu mengantarnya ke alamat saya dengan aman.', 'p': 30000, 'pt': 'lump'},
  ],
  'laundry': [
    {'t': 'Nyetrika baju', 'c': 'laundry', 'd': 'Menyetrika satu keranjang baju harian, sekitar 30 potong, sampai rapi.', 'p': 60000, 'pt': 'lump'},
    {'t': 'Cuci dan jemur baju', 'c': 'laundry', 'd': 'Mencuci baju satu keranjang lalu menjemurnya sampai kering dan rapi.', 'p': 50000, 'pt': 'lump'},
    {'t': 'Lipat dan susun baju', 'c': 'laundry', 'd': 'Melipat baju bersih dan menyusunnya ke dalam lemari dengan rapi.', 'p': 40000, 'pt': 'lump'},
    {'t': 'Cuci karpet atau sprei', 'c': 'laundry', 'd': 'Mencuci karpet atau sprei ukuran besar sampai bersih dan wangi.', 'p': 80000, 'pt': 'lump'},
    {'t': 'Setrika seragam sekolah', 'c': 'laundry', 'd': 'Menyetrika seragam sekolah beberapa anak sampai rapi dan siap dipakai.', 'p': 50000, 'pt': 'lump'},
  ],
  'other': [
    {'t': 'Bantu atur gudang', 'c': 'other', 'd': 'Menata dan membersihkan gudang kecil, membuang barang bekas yang tak terpakai.', 'p': 120000, 'pt': 'lump'},
    {'t': 'Jaga stand atau toko', 'c': 'other', 'd': 'Menjaga stand atau toko selama beberapa jam saat pemilik sedang keluar.', 'p': 30000, 'pt': 'hourly'},
    {'t': 'Bantu acara keluarga', 'c': 'other', 'd': 'Membantu menyiapkan kursi, tenda dan membereskan tempat setelah acara selesai.', 'p': 150000, 'pt': 'lump'},
    {'t': 'Bantu masak dan cuci piring', 'c': 'other', 'd': 'Membantu menyiapkan masakan dan mencuci piring untuk acara di rumah.', 'p': 25000, 'pt': 'hourly'},
    {'t': 'Tenaga serabutan harian', 'c': 'other', 'd': 'Tenaga harian untuk berbagai pekerjaan ringan yang akan dijelaskan di lokasi.', 'p': 150000, 'pt': 'daily'},
  ],
};
