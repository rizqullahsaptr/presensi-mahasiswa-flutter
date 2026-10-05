# Panduan Konfigurasi Firebase Manual

Dokumen ini berisi panduan langkah demi langkah untuk mengonfigurasi Firebase pada proyek **Presensi Mahasiswa** (`com.kelompok2.mobileproh.presensi_mahasiswa`).

> **PENTING:** Seluruh kode aplikasi sudah siap dan tidak bergantung pada nilai hardcoded. Anda hanya perlu mengikuti langkah-langkah di bawah untuk menghubungkan proyek ke Firebase Console Anda sendiri.

---

## 1. Buat Proyek di Firebase Console

1. Buka [Firebase Console](https://console.firebase.google.com/).
2. Klik **Add project** (Tambah Proyek).
3. Masukkan nama proyek, misalnya: `presensi-mahasiswa-kelompok2`.
4. Nonaktifkan Google Analytics (opsional, untuk menyederhanakan).
5. Klik **Create project** dan tunggu hingga selesai.

---

## 2. Aktifkan Firebase Authentication

1. Di menu samping kiri, pilih **Build** > **Authentication**.
2. Klik **Get Started**.
3. Di tab **Sign-in method**, pilih **Email/Password**.
4. Aktifkan toggle **Email/Password** (opsi Email link tidak perlu).
5. Klik **Save**.

---

## 3. Aktifkan Firebase Realtime Database

1. Di menu samping kiri, pilih **Build** > **Realtime Database**.
2. Klik **Create Database**.
3. Pilih lokasi database (disarankan: `Singapore (asia-southeast1)` untuk latensi terbaik dari Indonesia).
4. Pilih **Start in locked mode**, lalu klik **Enable**.
5. Buka tab **Rules**, lalu ganti seluruh isi aturan dengan isi file `database.rules.json` yang ada di root proyek ini:
   ```json
   {
     "rules": {
       "users": {
         ".read": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'dosen'",
         ".indexOn": ["role"],
         "$uid": {
           ".read": "auth != null && auth.uid === $uid",
           ".write": false,
           ".validate": "newData.hasChildren(['nama', 'email', 'identitas', 'role']) && newData.child('nama').isString() && newData.child('email').isString() && newData.child('identitas').isString() && (newData.child('role').val() === 'mahasiswa' || newData.child('role').val() === 'dosen')"
         }
       },
       "sessions": {
         ".read": "auth != null && ((query.orderByChild === 'lecturerId' && query.equalTo === auth.uid) || (query.orderByChild === 'kodePresensi' && query.equalTo != null))",
         ".indexOn": ["lecturerId", "kodePresensi", "status"],
         "$sessionId": {
           ".read": "auth != null && (data.child('lecturerId').val() === auth.uid || (root.child('users').child(auth.uid).child('role').val() === 'mahasiswa' && data.child('status').val() === 'aktif'))",
           ".write": "auth != null && root.child('users').child(auth.uid).child('role').val() === 'dosen' && ((!data.exists() && newData.child('lecturerId').val() === auth.uid) || (data.exists() && data.child('lecturerId').val() === auth.uid && newData.child('lecturerId').val() === data.child('lecturerId').val()))",
           ".validate": "newData.hasChildren(['judulSesi', 'informasiPertemuan', 'lecturerId', 'kodePresensi', 'status', 'waktuDibuat']) && newData.child('judulSesi').isString() && newData.child('judulSesi').val().length > 0 && newData.child('informasiPertemuan').isString() && newData.child('lecturerId').isString() && newData.child('kodePresensi').isString() && newData.child('kodePresensi').val().length === 6 && (newData.child('status').val() === 'aktif' || newData.child('status').val() === 'ditutup') && newData.child('waktuDibuat').isNumber() && (!newData.hasChild('waktuDibuka') || newData.child('waktuDibuka').isNumber()) && (!newData.hasChild('waktuDitutup') || newData.child('waktuDitutup').isNumber())"
         }
       },
       "attendance": {
         "$sessionId": {
           ".read": "auth != null && root.child('sessions').child($sessionId).child('lecturerId').val() === auth.uid",
           ".indexOn": ["studentId", "status"],
           "$studentId": {
             ".read": "auth != null && auth.uid === $studentId",
             ".write": "auth != null && newData.exists() && ((auth.uid === $studentId && root.child('users').child(auth.uid).child('role').val() === 'mahasiswa' && !data.exists() && root.child('sessions').child($sessionId).child('status').val() === 'aktif' && newData.child('status').val() === 'Hadir') || (root.child('users').child(auth.uid).child('role').val() === 'dosen' && root.child('sessions').child($sessionId).child('lecturerId').val() === auth.uid))",
             ".validate": "newData.hasChildren(['sessionId', 'studentId', 'status', 'waktuPresensi']) && newData.child('sessionId').val() === $sessionId && newData.child('studentId').val() === $studentId && (newData.child('status').val() === 'Hadir' || newData.child('status').val() === 'Izin' || newData.child('status').val() === 'Sakit' || newData.child('status').val() === 'Alpha') && newData.child('waktuPresensi').isNumber()"
           }
         }
       }
     }
   }
   ```
6. Klik **Publish**.

---

## 4. Konfigurasi FlutterFire CLI (Direkomendasikan)

Cara paling cepat dan resmi untuk menghubungkan Flutter ke Firebase:

1. Di terminal komputer Anda, pasang Firebase CLI (jika belum ada):
   ```bash
   npm install -g firebase-tools
   ```
2. Login ke akun Google Anda:
   ```bash
   firebase login
   ```
3. Pasang FlutterFire CLI via Dart:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Pindah ke direktori proyek:
   ```bash
   cd presensi_mahasiswa
   ```
5. Jalankan konfigurasi otomatis:
   ```bash
   flutterfire configure
   ```
   - Pilih proyek Firebase yang telah Anda buat di Langkah 1.
   - Pilih platform: **Android**.
   - Biarkan CLI mendaftarkan aplikasi dan memperbarui `lib/firebase_options.dart` serta mengunduh `android/app/google-services.json` secara otomatis.

---

## 5. Cara Manual Alternatif (Jika tanpa FlutterFire CLI)

Jika tidak menggunakan FlutterFire CLI:

1. Di Firebase Console, klik icon **Android** untuk menambahkan aplikasi.
2. Masukkan Package Name: `com.kelompok2.mobileproh.presensi_mahasiswa`
3. Masukkan App Nickname: `Presensi Mahasiswa`
4. Unduh file `google-services.json`, lalu letakkan di:
   ```
   presensi_mahasiswa/android/app/google-services.json
   ```
5. Buka `lib/firebase_options.dart`, gantikan konstanta `android` dengan nilai dari `google-services.json`:
   - `apiKey`: ambil dari `client[0].api_key[0].current_key`
   - `appId`: ambil dari `client[0].client_info.mobilesdk_app_id`
   - `messagingSenderId`: ambil dari `project_info.project_number`
   - `projectId`: ambil dari `project_info.project_id`
   - `databaseURL`: URL Realtime Database Anda (misal `https://<project-id>-default-rtdb.asia-southeast1.firebasedatabase.app`)

---

## 6. Menyiapkan Akun Demo Awal

Karena pendaftaran akun tidak dibuka bebas untuk umum (sesuai spesifikasi Tahap 2 di mana pengguna dibuat oleh institusi), Anda dapat membuat akun demo pertama kali melalui **Firebase Console**:

### Akun Dosen
1. Buka **Authentication** > **Users** > **Add user**.
   - Email: `dosen@uin-malang.ac.id`
   - Password: buat password minimal 6 karakter.
   - Salin **User UID** yang terbentuk.
2. Buka **Realtime Database** > **Data**.
3. Tambahkan node `users/<UID_DOSEN>`:
   ```json
   {
     "nama": "SUPRIYONO, M.Kom",
     "email": "dosen@uin-malang.ac.id",
     "identitas": "198001012005011001",
     "role": "dosen"
   }
   ```

### Akun Mahasiswa
1. Buka **Authentication** > **Users** > **Add user**.
   - Email: `rizqullah@student.uin-malang.ac.id`
   - Password: buat password minimal 6 karakter.
   - Salin **User UID** yang terbentuk.
2. Buka **Realtime Database** > **Data**.
3. Tambahkan node `users/<UID_MAHASISWA>`:
   ```json
   {
     "nama": "Muhammad Rizqullah Saputra",
     "email": "rizqullah@student.uin-malang.ac.id",
     "identitas": "240605110102",
     "role": "mahasiswa"
   }
   ```

---

## 7. Contoh Struktur Data JSON Lengkap (3 Node Utama)

Berikut adalah contoh snapshot pohon data Realtime Database yang valid:

```json
{
  "users": {
    "uid_dosen_001": {
      "nama": "SUPRIYONO, M.Kom",
      "email": "dosen@uin-malang.ac.id",
      "identitas": "198001012005011001",
      "role": "dosen"
    },
    "uid_mhs_001": {
      "nama": "Muhammad Rizqullah Saputra",
      "email": "rizqullah@student.uin-malang.ac.id",
      "identitas": "240605110102",
      "role": "mahasiswa"
    }
  },
  "sessions": {
    "-O_sessionId12345": {
      "judulSesi": "Pertemuan 1 - Pengantar Mobile Programming",
      "informasiPertemuan": "Ruang Lab Komputer 301, Gedung Saintek",
      "lecturerId": "uid_dosen_001",
      "kodePresensi": "A7X9K2",
      "status": "aktif",
      "waktuDibuat": 1728100000000,
      "waktuDibuka": 1728100010000,
      "waktuDitutup": null
    }
  },
  "attendance": {
    "-O_sessionId12345": {
      "uid_mhs_001": {
        "sessionId": "-O_sessionId12345",
        "studentId": "uid_mhs_001",
        "status": "Hadir",
        "waktuPresensi": 1728100050000
      }
    }
  }
}
```

---

## 8. Skenario Pengujian Setelah Firebase Aktif

Setelah menghubungkan aplikasi ke Firebase dan membuat akun demo, lakukan pengujian fungsional end-to-end berikut:

1. **Uji Login Dosen**:
   - Masukkan email dan password Dosen.
   - Verifikasi bahwa aplikasi masuk ke tampilan Dosen (`DosenShell`) dengan judul dan identitas yang benar.
2. **Uji Pembuatan Sesi**:
   - Pada halaman Dosen, tekan tombol **Buat Sesi Baru**.
   - Masukkan Judul Sesi dan Informasi Pertemuan (misal: "Pertemuan 1").
   - Tekan **Simpan & Buka Sesi**.
   - Verifikasi bahwa sesi muncul di daftar sesi aktif dan sebuah **Kode Presensi 6 Karakter** alfanumerik kapital terbuat.
3. **Uji Login Mahasiswa**:
   - Logout dari akun Dosen, login menggunakan akun Mahasiswa.
   - Verifikasi bahwa aplikasi masuk ke tampilan Mahasiswa (`MahasiswaShell`).
4. **Uji Pengisian Presensi Mahasiswa**:
   - Masukkan kode presensi 6 karakter dari sesi aktif dosen.
   - Tekan **Cari Sesi**, periksa dialog konfirmasi detail pertemuan.
   - Tekan **Kirim Kehadiran**.
   - Verifikasi bahwa muncul pesan sukses dan status langsung tercatat sebagai **Hadir**.
5. **Uji Validasi Duplikasi Kehadiran**:
   - Coba masukkan kembali kode presensi yang sama dengan akun mahasiswa yang sama.
   - Verifikasi bahwa sistem menolak dengan pesan *"Anda sudah melakukan presensi pada sesi ini"*.
6. **Uji Riwayat Kehadiran Mahasiswa**:
   - Pindah ke tab **Riwayat**.
   - Verifikasi bahwa sesi yang baru saja dihadiri tampil di daftar riwayat dengan badge hijau **Hadir**.
7. **Uji Pemantauan Real-time & Koreksi Status oleh Dosen**:
   - Logout dan login kembali sebagai Dosen.
   - Buka sesi yang tadi di tab **Daftar Sesi** atau Dashboard.
   - Verifikasi nama mahasiswa muncul secara real-time pada daftar hadir.
   - Ketuk mahasiswa tersebut, lakukan koreksi status menjadi **Izin**, **Sakit**, atau **Alpha**.
   - Simpan dan verifikasi perubahan status langsung terbarui di database.
8. **Uji Penutupan Sesi oleh Dosen**:
   - Tekan tombol **Tutup Sesi**.
   - Coba lakukan presensi ulang dengan kode sesi tersebut dari sisi Mahasiswa; verifikasi sistem menolak dengan pesan *"Sesi presensi sudah ditutup"*.
