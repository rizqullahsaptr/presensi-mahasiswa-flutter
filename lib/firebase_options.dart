// File generated from google-services.json — do not edit manually.
// To regenerate, run: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDttO8EN9PujK6ZHApcAcNkaC1Cn_DY5yM',
    appId: '1:788355927149:android:63e715c683b4efdee40364',
    messagingSenderId: '788355927149',
    projectId: 'presensi-mahasiswa-kelompok2',
    databaseURL: 'https://presensi-mahasiswa-kelompok2-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'presensi-mahasiswa-kelompok2.firebasestorage.app',
  );
}
