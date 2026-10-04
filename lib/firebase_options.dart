// File ini adalah TEMPLATE / PLACEHOLDER.
//
// JANGAN memasukkan API key atau credential sungguhan ke dalam repository.
//
// Untuk menghasilkan konfigurasi Firebase yang valid dan resmi:
// 1. Pasang FlutterFire CLI: `dart pub global activate flutterfire_cli`
// 2. Jalankan: `flutterfire configure --project=<ID_PROYEK_FIREBASE_ANDA>`
// 3. File ini akan ditimpa secara otomatis oleh FlutterFire CLI dengan kredensial asli.
//
// File ini disiapkan agar proyek dapat dianalisis secara statis (flutter analyze)
// tanpa menimbulkan compilation error pada Firebase.initializeApp().

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

  // Placeholder options untuk compile-time check.
  // Nilai-nilai ini BUKAN credential asli dan tidak akan berfungsi untuk runtime.
  // Gantikan dengan menjalankan `flutterfire configure`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER-API-KEY-JALANKAN-FLUTTERFIRE-CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'placeholder-project-id',
    databaseURL: 'https://placeholder-project-id-default-rtdb.firebaseio.com',
  );
}
