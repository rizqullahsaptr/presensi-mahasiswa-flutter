# Presensi Mahasiswa

Aplikasi presensi mahasiswa berbasis mobile menggunakan Flutter dan Firebase Realtime Database. Proyek ini dikembangkan untuk memenuhi tugas mata kuliah **Mobile Programming H Kelompok 2**, Teknik Informatika, UIN Maulana Malik Ibrahim Malang.

---

## 👥 Identitas Tim

- **Dosen Pengampu:** SUPRIYONO, M.Kom
- **Kelas:** Mobile Programming H
- **Kelompok:** 2

| No | Nama | NIM |
|---|---|---|
| 1 | Muhammad Rizqullah Saputra | 240605110102 |
| 2 | Abdul Rochim | 240605110121 |
| 3 | Muhammad Raihan Fitrianto | 240605110255 |

---

## 📱 Ringkasan Fitur

Sesuai spesifikasi **Laporan Tahap 2**, aplikasi ini membagi fungsionalitas berdasarkan 2 role:

### 1. Role Mahasiswa
- Login akun mahasiswa menggunakan Email & Password (Firebase Auth).
- Memasukkan kode presensi 6 karakter (diberikan oleh dosen saat sesi aktif).
- Validasi otomatis: sesi harus aktif, kode cocok, dan mahasiswa belum tercatat pada sesi tersebut.
- Konfirmasi kehadiran berhasil secara real-time (status otomatis: **Hadir**).
- Melihat riwayat presensi yang pernah diikuti beserta statusnya.

### 2. Role Dosen
- Login akun dosen.
- Membuat sesi presensi baru (Judul Sesi + Informasi Pertemuan).
- Sistem menghasilkan kode presensi 6 karakter alfanumerik kapital unik secara acak.
- Menampilkan kode presensi ke mahasiswa.
- Mengontrol status sesi: Buka sesi / Tutup sesi.
- Memantau daftar mahasiswa yang hadir secara real-time.
- Melakukan koreksi status kehadiran per mahasiswa (**Hadir**, **Izin**, **Sakit**, **Alpha**).

---

## 🧱 Arsitektur & Teknologi

- **Framework:** Flutter (Channel stable, Android target)
- **Bahasa:** Dart 3
- **State Management:** Provider
- **Backend / BaaS:**
  - **Firebase Authentication:** Manajemen otentikasi email/password (password tidak pernah disimpan di database).
  - **Firebase Realtime Database:** Penyimpanan profil, sesi presensi, dan data kehadiran secara real-time.
- **Package Name:** `com.kelompok2.mobileproh`

---

## 📂 Struktur Proyek

```
lib/
├── firebase_options.dart         # Konfigurasi Firebase (hasil generate flutterfire)
├── main.dart                     # Entry point & inisialisasi Firebase + Provider
├── models/
│   ├── user_model.dart           # Model data pengguna (Mahasiswa / Dosen)
│   ├── session_model.dart        # Model data sesi presensi
│   └── attendance_model.dart     # Model data kehadiran & status
├── services/
│   ├── auth_service.dart         # Layanan Firebase Auth + sinkronisasi profil
│   └── session_service.dart      # Layanan CRUD sesi, kode, kehadiran, koreksi
├── providers/
│   ├── auth_provider.dart        # State management otentikasi
│   └── session_provider.dart     # State management MahasiswaProvider & DosenProvider
├── routes/
│   └── app_router.dart           # Pengarah layar berbasis role (Mahasiswa / Dosen)
├── screens/
│   ├── auth/
│   │   └── login_screen.dart     # Layar login
│   ├── mahasiswa/
│   │   ├── mahasiswa_shell.dart  # Bottom navigation mahasiswa (IndexedStack)
│   │   ├── dashboard_mahasiswa_screen.dart # Input kode presensi
│   │   ├── detail_sesi_mahasiswa_screen.dart # Detail sesi & konfirmasi
│   │   └── riwayat_screen.dart   # Riwayat presensi
│   └── dosen/
│       ├── dosen_shell.dart      # Bottom navigation dosen (IndexedStack)
│       ├── dashboard_dosen_screen.dart # Dashboard dosen & sesi terbaru
│       ├── buat_sesi_screen.dart # Form pembuatan sesi baru
│       ├── daf_sesi_screen.dart  # Daftar semua sesi
│       └── detail_sesi_dosen_screen.dart # Detail sesi, kode, real-time list, koreksi
├── theme/
│   └── app_theme.dart            # Palet warna sistem & status kehadiran
└── utils/
    ├── code_generator.dart       # Generator kode presensi 6 karakter aman
    └── validators.dart           # Validasi input form
```

---

## 🚀 Menjalankan Proyek

### Prasyarat
- Flutter SDK (>= 3.24.0)
- Java OpenJDK 17+
- Android SDK Platform & Build-tools
- Akun Firebase (untuk tahap produksi/demo)

### Menjalankan Unit Test (Tanpa Kredensial Firebase)
```bash
flutter test
```

### Menjalankan Analisis Statis
```bash
flutter analyze
```

### Konfigurasi Firebase
Baca panduan lengkap di file [FIREBASE_SETUP.md](FIREBASE_SETUP.md).
