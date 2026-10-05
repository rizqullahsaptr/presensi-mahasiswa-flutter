import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Opsi Android disusun dari konfigurasi proyek yang tersedia;
  // lihat FIREBASE_SETUP.md untuk asal dan langkah verifikasinya.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PresensiApp());
}

class PresensiApp extends StatelessWidget {
  const PresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(AuthService()),
      child: MaterialApp(
        title: 'PresensiIN',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const AppRouter(),
      ),
    );
  }
}
