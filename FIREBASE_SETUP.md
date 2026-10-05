# Firebase — konfigurasi yang sudah ada dan verifikasi Android

Dokumen ini mencatat keadaan **proyek Firebase yang telah dibuat**, bukan instruksi membuat proyek/akun baru. Jangan menjalankan pembuatan proyek, menambah akun demo lagi, mengimpor ulang profil, atau menerbitkan ulang Security Rules hanya untuk mengikuti panduan ini.

## Konfigurasi saat ini

| Komponen | Nilai/status |
|---|---|
| Firebase project ID | `presensi-mahasiswa-kelompok2` |
| Android application ID | `com.kelompok2.mobileproh.presensi_mahasiswa` |
| Realtime Database | Singapore (`asia-southeast1`); URL di `lib/firebase_options.dart` |
| Authentication | Email/password; akun demo sudah dibuat |
| Profil pengguna | `users/{uid}` sudah disiapkan di Realtime Database |
| Security Rules | Sudah dipublikasikan; **`database.rules.json` adalah rujukan isi aturan** |
| Target konfigurasi aplikasi | Android; opsi Firebase ditulis manual dari `android/app/google-services.json` |

Akun demo yang sudah ada (alamat email dan peran saja, tanpa UID/kredensial):

| Email | Peran |
|---|---|
| `dosen1@test.com` | dosen |
| `mahasiswa1@test.com` | mahasiswa |
| `mahasiswa2@test.com` | mahasiswa |

Profil dalam `firebase_seed_users.json` mencatat data demo tersebut; file itu bukan langkah impor yang harus dijalankan kembali. Autentikasi email/password memakai Firebase Auth, sedangkan profil role dibaca dari `users/{uid}`. Aplikasi tidak menyediakan pendaftaran mandiri.

## Konfigurasi Android yang sudah tersedia

- `android/app/google-services.json` memuat klien untuk application ID di atas; plugin `com.google.gms.google-services` diterapkan di `android/app/build.gradle.kts`.
- `lib/main.dart` menginisialisasi Firebase dengan `DefaultFirebaseOptions.currentPlatform`. `lib/firebase_options.dart` hanya menyediakan opsi Android; platform lain belum dikonfigurasi.
- Upaya `flutterfire configure` tidak berhasil pada alur proyek ini. Nilai `FirebaseOptions` yang ada disusun **manual dari `google-services.json`**, bukan bukti keluaran FlutterFire CLI yang sukses. Status aktualnya adalah konfigurasi manual; komentar source telah diselaraskan.
- Bila perlu *memeriksa* kecocokan (bukan mengganti konfigurasi yang sudah ada): cocokkan `projectId` dengan `project_info.project_id`, `appId` dengan `client[].client_info.mobilesdk_app_id` pada klien ber-`package_name` yang sesuai, `messagingSenderId` dengan `project_info.project_number`, dan `apiKey` dengan `api_key[].current_key` pada klien tersebut. `databaseURL` berasal dari URL Realtime Database regional di Firebase Console/konfigurasi proyek, bukan dari `project_info.firebase_url` jika properti itu tidak ada. Jangan menyalin nilai konfigurasi mentah, berkas JSON, atau kredensial akun ke dokumentasi/laporan.

## Data dan Security Rules

Node aplikasi: `users/{uid}` untuk profil dan indeks `attendanceSessionIds`, `sessions/{sessionId}` untuk sesi, serta `attendance/{sessionId}/{studentId}` untuk catatan kehadiran. Dosen membuat sesi tertutup lalu membukanya; saat aktif sesi memiliki `kodePresensiAktif`, dan saat ditutup field ini dihapus. Mahasiswa mencari sesi berdasarkan field aktif tersebut. Riwayat mahasiswa memanfaatkan indeks pada profil, bukan cache memori semata.

**Jangan gunakan blok aturan salinan dari panduan lama.** Berkas [database.rules.json](database.rules.json) adalah sumber rujukan untuk aturan yang telah dipublikasikan: ia memuat indeks query yang relevan, batasan baca/tulis berdasarkan peran, validasi sesi/kehadiran, dan hak penulisan indeks riwayat. Panduan ini **tidak** menginstruksikan publikasi aturan; bila perlu audit, bandingkan isi berkas dengan tab Rules di Firebase Console sebelum perubahan apa pun. Jangan membuka akses global demi demo.

Generator di `lib/utils/code_generator.dart` menghasilkan **6 karakter alfanumerik kapital** (bukan enam digit). Tidak ada pengecekan keunikan kode secara global; kemiripan kode antar sesi mungkin terjadi. `sessions` ditelusuri dengan `kodePresensiAktif` untuk sesi terbuka, sementara presensi tiap mahasiswa pada satu sesi memakai transaksi untuk mencegah catatan ganda.

## Pemeriksaan lokal

Dari root proyek, gunakan SDK Flutter yang kompatibel dengan `pubspec.yaml`:

```bash
flutter pub get
flutter analyze
flutter test
```

Suite aturan lokal tersedia di `test_rules/` dan menggunakan Firebase Database Emulator (Node.js, Java, dan dependensi npm diperlukan). Runner `npm test` memulai emulator dari `firebase-database-emulator.jar` di folder itu jika belum berjalan:

```bash
cd test_rules
npm install
npm test
```

Hasil unit/widget test, analisis statis, atau uji emulator adalah pemeriksaan kode/aturan lokal; **tidak membuktikan alur Firebase pada perangkat Android**. Catat hasil perintah yang benar-benar dijalankan, jangan mengklaim pengujian yang belum dilakukan.

## Verifikasi Android yang masih tertunda

Lakukan pada perangkat atau emulator Android yang dapat menjangkau Firebase. Pakai kredensial akun demo yang disalurkan secara aman di luar repositori; panduan ini sengaja tidak memuatnya. Langkah berikut adalah **rencana pemeriksaan, bukan hasil E2E yang sudah lulus**:

1. Jalankan `flutter run` dengan target Android, lalu masuk sebagai `dosen1@test.com`. Pastikan profil dan tampilan dosen terbaca.
2. Buat sesi berjudul dan berinformasi pertemuan; periksa status awal tertutup, kemudian buka sesi. Salin kode alfanumerik dari detail sesi.
3. Keluar dan masuk sebagai `mahasiswa1@test.com`. Cari kode sesi aktif, lihat detail, lalu kirim presensi. Periksa status **Hadir** dan riwayat; coba kirim lagi untuk memeriksa penolakan catatan ganda.
4. Ulangi dengan `mahasiswa2@test.com` bila perlu memeriksa lebih dari satu peserta. Kembali ke akun dosen; amati daftar kehadiran dan ubah salah satu status ke **Izin**, **Sakit**, atau **Alpha**, lalu periksa pembaruan riwayat peserta terkait.
5. Tutup sesi sebagai dosen. Pastikan kode yang sudah tidak aktif tidak lagi menemukan sesi terbuka/menolak presensi berikutnya.

Catat hasil nyata dan kegagalan beserta lingkungan perangkat ketika verifikasi dilakukan. Sampai itu selesai, statusnya **Android E2E belum terverifikasi**. Jangan mempublikasikan aturan, membuat ulang akun/proyek, atau memasukkan kata sandi dan rahasia ke repositori untuk menjalankan prosedur ini.
