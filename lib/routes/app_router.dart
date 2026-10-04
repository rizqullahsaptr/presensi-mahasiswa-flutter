import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/mahasiswa/mahasiswa_shell.dart';
import '../screens/dosen/dosen_shell.dart';

/// Router utama berdasarkan auth state + role.
/// Mahasiswa tidak bisa akses dosen dan sebaliknya.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.unauthenticated:
        return const LoginScreen();

      case AuthStatus.authenticated:
        final user = authProvider.user!;
        return _buildRoleShell(user);
    }
  }

  Widget _buildRoleShell(UserModel user) {
    if (user.isMahasiswa) return MahasiswaShell(user: user);
    if (user.isDosen) return DosenShell(user: user);
    // Role tidak valid — tampilkan error + tombol logout
    return const _InvalidRoleScreen();
  }
}

class _InvalidRoleScreen extends StatelessWidget {
  const _InvalidRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Role akun tidak valid.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hubungi administrator untuk memperbaiki data akun Anda.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
