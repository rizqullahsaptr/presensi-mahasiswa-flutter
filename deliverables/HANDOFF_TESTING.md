# Panduan Verifikasi Lanjutan — Presensi Mahasiswa

Dokumen ini membedakan pengujian otomatis dari pengujian pada perangkat Android. Screenshot di `screenshots/` berasal dari render widget produksi dalam lingkungan pengujian Flutter; **bukan** bukti aplikasi terpasang atau digunakan pada perangkat Android.

## Lingkungan dan proyek

- Flutter SDK dan Android SDK/Android Studio terpasang; jalankan `flutter doctor -v`.
- Buka folder proyek `presensi_mahasiswa` (bukan folder `deliverables`). Jika menggunakan ZIP source, ekstrak terlebih dahulu.
- Project Firebase yang sudah ada: `presensi-mahasiswa-kelompok2`.
- Package Android: `com.kelompok2.mobileproh.presensi_mahasiswa`.
- Realtime Database: `https://presensi-mahasiswa-kelompok2-default-rtdb.asia-southeast1.firebasedatabase.app`.
- Pastikan `android/app/google-services.json` dan `lib/firebase_options.dart` berasal dari project yang sama. Jangan memasukkan password ke source atau laporan. Security Rules sudah dipublikasikan; jangan menggantinya hanya untuk mencoba aplikasi.

## Jalankan pada perangkat Android

Di terminal proyek:

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Gunakan perangkat Android fisik dengan USB debugging atau emulator yang benar-benar menampilkan launcher dan merespons input. `flutter devices` saja belum membuktikan emulator siap; pada laptop sebelumnya AVD `Small_Phone` mengalami ANR pada Pixel Launcher/System UI. APK debug hasil build tersedia terpisah sebagai `app-debug.apk`, tetapi keberhasilan build **bukan** bukti instalasi atau uji perangkat. Jangan jalankan target Windows/web untuk menggantikan pengujian Android.

## Akun demo

| Role | Email |
|---|---|
| Dosen | `dosen1@test.com` |
| Mahasiswa 1 | `mahasiswa1@test.com` |
| Mahasiswa 2 | `mahasiswa2@test.com` |

Masukkan password secara pribadi pada aplikasi, tidak melalui chat, source code, screenshot, atau catatan hasil. Ketiga profil telah dibuat pada `users/{uid}`; jangan ubah role menjadi nilai selain `dosen` atau `mahasiswa`.

## Checklist pengujian langsung — belum diverifikasi

Catat untuk **setiap** langkah: tanggal/waktu, perangkat dan Android API, akun (tanpa password), ekspektasi, hasil aktual, lulus/gagal, dan path screenshot. Jangan tandai lulus sebelum benar-benar diamati.

- [ ] Login dosen dan pastikan dashboard menampilkan profil dosen; coba form login kosong/salah dan amati pesan.
- [ ] Buat sesi baru; buka sesi dan catat kode enam karakter alfanumerik kapital. Generator tidak menjamin keunikan global; bila ada kode sama pada sesi aktif lain, catat sebagai temuan dan jangan lanjutkan presensi yang ambigu.
- [ ] Periksa daftar mahasiswa: mahasiswa kedua yang belum presensi tampil **Alpha** sebagai status bawaan (belum tentu ada record `attendance`).
- [ ] Logout dosen; login mahasiswa pertama; uji kode tidak valid dan kode valid pada sesi aktif.
- [ ] Presensi mahasiswa pertama → **Hadir**, lalu ulangi pada sesi sama → harus ditolak sebagai presensi ganda.
- [ ] Logout mahasiswa pertama; login dosen; buka detail sesi dan koreksi mahasiswa pertama/dua melalui **Hadir, Izin, Sakit, Alpha**. Verifikasi nilai akhir serta status awal mahasiswa kedua.
- [ ] Tutup sesi; sebagai mahasiswa, pastikan kode sesi ditutup tidak dapat dipakai untuk presensi baru.
- [ ] Buka Riwayat mahasiswa yang sudah mempunyai catatan; tutup dan buka kembali aplikasi, lalu periksa riwayat sesi ditutup tetap tampil.
- [ ] Verifikasi logout, loading, empty state, teks nama panjang, dan tidak ada overflow layar pada perangkat yang dipakai.

Catatan penting: koreksi dosen terhadap mahasiswa kedua akan membuat catatan presensi dan mengubah kondisi uji status **Alpha bawaan**. Ambil buktinya **sebelum** koreksi. Kode sesi adalah data pengujian, bukan password, tetapi jangan bagikan jika sesi masih aktif.

## Bukti yang perlu diambil

Ambil screenshot **langsung dari perangkat** (terpisah dari `screenshots/` hasil widget test) untuk: login, dashboard dosen/mahasiswa, form sesi, kode sesi aktif, daftar kehadiran dan Alpha bawaan, input kode valid/tidak valid, pesan presensi ganda, tiap status koreksi, sesi ditutup, serta riwayat setelah restart. Beri nama file dan cantumkan perangkat/tanggal pada catatan. Hindari screenshot yang menampilkan password saat mengetik.

## Pengujian otomatis (jalankan ulang jika source berubah)

```bash
dart format lib test
flutter pub get
flutter analyze
flutter test
cd test_rules
npm test
cd ..
flutter build apk --debug
```

`npm test` memakai Firebase Local Emulator Suite dan Rules Unit Testing SDK untuk menguji `database.rules.json`; ini **bukan** Firebase produksi. `flutter test` tidak membuktikan Security Rules terpublikasi atau login langsung berhasil. Bandingkan hasil nyata dengan laporan Tahap 3 dan catat kegagalan apa adanya.
