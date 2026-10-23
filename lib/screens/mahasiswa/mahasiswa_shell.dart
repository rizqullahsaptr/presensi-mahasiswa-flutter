import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/session_service.dart';
import 'dashboard_mahasiswa_screen.dart';
import 'riwayat_screen.dart';

/// Shell mahasiswa dengan bottom navigation: Beranda | Riwayat | Keluar
class MahasiswaShell extends StatefulWidget {
  final UserModel user;
  const MahasiswaShell({super.key, required this.user});

  @override
  State<MahasiswaShell> createState() => _MahasiswaShellState();
}

class _MahasiswaShellState extends State<MahasiswaShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MahasiswaProvider(SessionService(), widget.user),
      child: Builder(
        builder: (context) {
          final screens = [
            DashboardMahasiswaScreen(
              user: widget.user,
              // Pintasan dari beranda ke tab Riwayat — memperjelas akses
              // yang sebelumnya hanya ada pada bilah navigasi bawah.
              onBukaRiwayat: () {
                setState(() => _selectedIndex = 1);
                context.read<MahasiswaProvider>().muatRiwayat();
              },
            ),
            RiwayatScreen(user: widget.user),
          ];

          return Scaffold(
            body: IndexedStack(index: _selectedIndex, children: screens),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) {
                if (i == 2) {
                  // Keluar
                  _confirmLogout(context);
                } else {
                  setState(() => _selectedIndex = i);
                  if (i == 1) {
                    // Muat riwayat saat tab dipilih
                    context.read<MahasiswaProvider>().muatRiwayat();
                  }
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'Riwayat',
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
