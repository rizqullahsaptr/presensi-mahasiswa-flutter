# Panduan Konfigurasi Firebase Manual

Dokumen ini berisi panduan langkah demi langkah untuk mengonfigurasi Firebase pada proyek **Presensi Mahasiswa** (`com.kelompok2.mobileproh`).

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
         "$uid": {
           ".read": "auth != null",
           ".write": "auth != null && auth.uid == $uid",
           ".validate": "newData.hasChildren(['nama', 'email', 'identitas', 'role']) && (newData.child('role').val() == 'mahasiswa' || newData.child('role').val() == 'dosen')"
         }
       },
       "sessions": {
         ".read": "auth != null",
         "$sessionId": {
           ".write": "auth != null && (!data.exists() || data.child('lecturerId').val() == auth.uid)",
           ".validate": "newData.hasChildren(['judulSesi', 'informasiPertemuan', 'lecturerId', 'kodePresensi', 'status', 'waktuDibuat'])"
         },
         ".indexOn": ["lecturerId", "kodePresensi", "status"]
       },
       "attendance": {
         "$sessionId": {
           ".read": "auth != null",
           "$studentId": {
             ".write": "auth != null && (auth.uid == $studentId || root.child('sessions').child($sessionId).child('lecturerId').val() == auth.uid)",
             ".validate": "newData.hasChildren(['sessionId', 'studentId', 'status', 'waktuPresensi']) && (newData.child('status').val() == 'Hadir' || newData.child('status').val() == 'Izin' || newData.child('status').val() == 'Sakit' || newData.child('status').val() == 'Alpha')"
           }
         },
         ".indexOn": ["studentId", "status"]
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
2. Masukkan Package Name: `com.kelompok2.mobileproh`
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

Setelah langkah ini selesai, aplikasi siap dijalankan dengan `flutter run` pada perangkat atau emulator Android.
