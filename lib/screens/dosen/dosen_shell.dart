import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/session_service.dart';
import 'dashboard_dosen_screen.dart';
import 'daftar_sesi_screen.dart';

/// Shell dosen dengan bottom navigation: Beranda | Sesi | Keluar
class DosenShell extends StatefulWidget {
  final UserModel user;
  const DosenShell({super.key, required this.user});

  @override
  State<DosenShell> createState() => _DosenShellState();
}

class _DosenShellState extends State<DosenShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DosenProvider(SessionService(), widget.user),
      child: Builder(
        builder: (context) {
          final screens = [
            DashboardDosenScreen(user: widget.user),
            DafSesiScreen(user: widget.user),
          ];

          return Scaffold(
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) {
                if (i == 2) {
                  _confirmLogout(context);
                } else {
                  setState(() => _selectedIndex = i);
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  activeIcon: Icon(Icons.list_alt),
                  label: 'Sesi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.logout),
                  label: 'Keluar',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
