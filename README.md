# Buruhku (Flutter, 100% lokal)

Prototype aplikasi marketplace buruh harian berdasarkan dokumen *Analisis Sistem Buruhku*.
Tidak ada backend: semua data disimpan di perangkat (`shared_preferences`) dan lawan transaksi
(agen, klien, admin, payment gateway) disimulasikan di `lib/store.dart`. UI sengaja berupa wireframe grayscale + ikon.

## Menjalankan
Butuh Flutter 3.27+ (Dart 3.x).

```bash
cd buruhku
flutter create . --project-name buruhku   # membuat folder android/ios/web (lib & pubspec tidak diganti)
flutter pub get
flutter run
```

## Alur demo cepat
1. Onboarding, lalu masuk dengan nomor HP apa saja. Kode OTP demo tampil di layar. Lengkapi profil.
2. **Klien:** Beranda > Buat request (atau pilih template). Dalam hitungan detik agen simulasi menekan ACC.
   Buka Request > detail, chat/tawar, lalu **Pilih** agen, **Bayar** (simulasi QRIS/VA/e-wallet),
   dan ikuti status: berangkat, tiba, PIN, bekerja, selesai, konfirmasi, rating, tip, invoice.
   Ikon labu di halaman order = menu demo (percepat tahap, agen minta tambahan, simulasi tidak hadir 30 menit).
3. **Agen:** Akun > Daftar sekarang (wizard KYC 6 langkah), lalu Akun > **Panel Admin (Simulasi)** > KYC > Setujui.
   Beralih ke Mode Agen: terima request masuk, ACC/tawar, konfirmasi kesepakatan, berangkat, check-in,
   masukkan PIN dari chat, selesai, tarik saldo (buat PIN dulu).
4. **Sengketa/Laporan/SOS:** ajukan masalah dari order, laporkan pengguna, tahan tombol SOS 3 detik,
   lalu putuskan di Panel Admin (Simulasi).

## Struktur
```
lib/
  main.dart            entry, splash, routing berbasis state
  models.dart          kategori, Req/Ord/Chat/Msg/Kyc/dst + JSON
  seed.dart            36 agen dummy + request masuk simulasi
  store.dart           state, persistensi, aturan bisnis, simulasi lawan transaksi
  ui.dart              tema grayscale + widget wireframe (Box, Ph, FakeMap, FakeQr, BottomBar)
  screens/
    auth.dart          onboarding, login, OTP, profil awal
    shell.dart         navigasi, beranda, daftar/filter agen, detail agen, pencarian
    request.dart       form request, daftar request, detail + pilih agen
    chat.dart          daftar chat, negosiasi (kartu penawaran), share WA/e-wallet, deteksi penipuan
    order.dart         riwayat, order lifecycle, pembayaran escrow, rating, sengketa, invoice, SOS
    agent.dart         mode agen, KYC wizard, pendapatan, withdraw
    account.dart       akun, pengaturan, dompet, notifikasi, laporan, bantuan, kebijakan, panel admin
```

## Catatan
- Kode ditulis tanpa bisa dikompilasi di lingkungan pembuatnya. Jika `flutter analyze` memunculkan error kecil, kirim log-nya.
- Foto, peta, GPS, QR, OTP, dan pembayaran adalah placeholder/simulasi. Integrasi nyata (Maps, payment gateway, FCM, SMS)
  menggantikan bagian terkait di `store.dart`.

## Perubahan versi 1.1
1. **Lokasi tersimpan:** Akun > Lokasi tersimpan (tambah, ubah, hapus, jadikan alamat utama; maks 10).
2. **Pesan:** submenu **Semua** di paling kiri, sebelum Order dan Langsung (klien dan agen).
3. **Order langsung:** jadwal **Sekarang** atau **Tanggal & jam** (date + time picker), plus pilih lokasi tersimpan.
4. **Aktivitas** (dulu Riwayat): di tab Aktif ada **Sekarang** dan **Akan datang**. Order terjadwal pindah otomatis ke Sekarang saat waktunya tiba.
5. **Request dan order:**
   - lokasi dari daftar tersimpan, ketik manual, atau titik di peta;
   - kartu saran jasa mengikuti kategori yang dipilih di Beranda, selain itu menampilkan jasa populer;
   - jadwal fleksibel dihapus;
   - tombol **Pilih agen** di dalam chat negosiasi;
   - pembayaran **COD** (tanpa escrow dan tanpa biaya layanan; komisi 10% agen dipotong dari saldonya);
   - order lebih dari 1 agen tampil sebagai satu kartu grup di Aktivitas, dengan halaman **Order N agen** sendiri;
   - **Batalkan sengketa** mengembalikan order ke status sebelumnya.
6. **Input uang** otomatis diberi titik ribuan (10.000, 1.000.000) di semua kolom nominal.
7. Tombol **Beralih ke mode agen** di Beranda (jika sudah terdaftar agen) dan ikon beralih ke mode klien di tab Masuk.

File baru: `lib/screens/location.dart`.
Jika sebelumnya sudah menjalankan versi 1.0, data lama tetap terbaca. Untuk mencoba seed baru, hapus data aplikasi.
