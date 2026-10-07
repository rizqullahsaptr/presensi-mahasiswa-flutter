// Konfigurasi Android dari google-services.json; Web memakai SDK config Firebase
// resmi untuk Web App preview di project yang sama.
// Upaya flutterfire configure sebelumnya tidak berhasil; cocokkan ulang nilai
// dengan aplikasi Firebase terdaftar sebelum mengubah konfigurasi.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCqtlmVkk9-JXH6TI83Iq4Fg0XAQTU7lqg",
    appId: "1:788355927149:web:0914b25b3cec439fe40364",
    messagingSenderId: "788355927149",
    projectId: "presensi-mahasiswa-kelompok2",
    authDomain: "presensi-mahasiswa-kelompok2.firebaseapp.com",
    databaseURL: "https://presensi-mahasiswa-kelompok2-default-rtdb.asia-southeast1.firebasedatabase.app",
    storageBucket: "presensi-mahasiswa-kelompok2.firebasestorage.app",
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDttO8EN9PujK6ZHApcAcNkaC1Cn_DY5yM',
    appId: '1:788355927149:android:63e715c683b4efdee40364',
    messagingSenderId: '788355927149',
    projectId: 'presensi-mahasiswa-kelompok2',
    databaseURL: 'https://presensi-mahasiswa-kelompok2-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'presensi-mahasiswa-kelompok2.firebasestorage.app',
  );
}
