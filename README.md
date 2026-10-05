# Presensi Mahasiswa

Aplikasi Flutter untuk presensi mahasiswa dengan Firebase Authentication dan Firebase Realtime Database. Proyek tugas **Mobile Programming H, Kelompok 2**, Teknik Informatika, UIN Maulana Malik Ibrahim Malang.

## Tim

- Dosen pengampu: SUPRIYONO, M.Kom
- Muhammad Rizqullah Saputra — 240605110102
- Abdul Rochim — 240605110121
- Muhammad Raihan Fitrianto — 240605110255

## Status proyek

Proyek Firebase **`presensi-mahasiswa-kelompok2` sudah ada**, bukan proyek yang perlu dibuat ulang. Aplikasi Android terdaftar dengan application ID **`com.kelompok2.mobileproh.presensi_mahasiswa`** dan Realtime Database berada di **Singapore (`asia-southeast1`)**. Firebase Authentication menggunakan email/password; tiga akun demo beserta profil `users/{uid}` sudah disiapkan. Lihat [FIREBASE_SETUP.md](FIREBASE_SETUP.md) untuk rincian konfigurasi yang sudah ada dan cara verifikasi tanpa membuat ulang akun atau menerbitkan ulang aturan.

`lib/firebase_options.dart` disusun **secara manual dari `android/app/google-services.json`** setelah `flutterfire configure` tidak berhasil; jangan menyebutnya keluaran sukses FlutterFire CLI. Inisialisasi aplikasi menggunakan `DefaultFirebaseOptions.currentPlatform` untuk Android. **Verifikasi end-to-end pada perangkat/emulator Android masih tertunda**; pengujian unit/widget dan Security Rules tidak menggantikannya.

## Fitur yang diimplementasikan

- **Dosen:** masuk dengan akun yang sudah ada; membuat sesi berjudul dan berinformasi pertemuan (awalnya tertutup), membuka/menutup sesi, melihat daftar sesi serta kehadiran, dan mengoreksi status menjadi **Hadir**, **Izin**, **Sakit**, atau **Alpha**.
- **Mahasiswa:** masuk dengan akun yang sudah ada; mencari sesi aktif memakai kode **6 karakter alfanumerik kapital**, mengirim presensi **Hadir**, serta melihat riwayat dari indeks `users/{uid}/attendanceSessionIds`.
- Kode dibuat acak dari alfabet terbatas di `lib/utils/code_generator.dart`. **Tidak ada pemeriksaan keunikan global** sebelum sesi dibuat; jangan menganggap benturan kode mustahil. Pencarian memakai `kodePresensiAktif` yang hanya ada saat sesi aktif. Transaksi pada catatan kehadiran mencegah pengiriman ganda untuk mahasiswa/sesi yang sama.

## Teknologi dan struktur

- Flutter/Dart; state management Provider.
- Firebase Auth untuk autentikasi, Realtime Database untuk `users`, `sessions`, dan `attendance`.
- `lib/firebase_options.dart`: konfigurasi Android manual; `lib/main.dart`: inisialisasi Firebase.
- `lib/models/`, `lib/services/`, `lib/providers/`: model, akses Firebase, dan state.
- `lib/screens/auth/`, `lib/screens/dosen/`, `lib/screens/mahasiswa/`: layar sesuai peran.
- `lib/routes/`, `lib/theme/`, `lib/utils/`: navigasi, tema, generator kode, dan validasi.
- `database.rules.json`: rujukan Security Rules yang telah dipublikasikan; `test_rules/`: pengujian aturan dengan Database Emulator.

## Menjalankan dan memeriksa

Gunakan Flutter SDK yang kompatibel dengan `pubspec.yaml`, Android SDK, dan Java untuk build/pengujian aturan. Dari root proyek:

```bash
flutter pub get
flutter analyze
flutter test
```

Untuk suite Security Rules lokal (memerlukan Node.js, Java, dependensi `test_rules/`, dan `firebase-database-emulator.jar` yang digunakan runner):

```bash
cd test_rules
npm install
npm test
```

Perintah di atas menjalankan pemeriksaan lokal; **bukan bukti bahwa alur login/presensi telah diuji pada Android**. Pengujian Android yang masih perlu dilakukan: jalankan aplikasi pada perangkat/emulator, masuk dengan akun demo yang sudah dibuat, buat lalu buka sesi sebagai dosen, cari kode sebagai mahasiswa, catat kehadiran, cek riwayat/koreksi, dan tutup sesi. Detail langkah dan batasannya ada di [FIREBASE_SETUP.md](FIREBASE_SETUP.md). Jangan mencantumkan kata sandi atau berkas kredensial dalam laporan.
