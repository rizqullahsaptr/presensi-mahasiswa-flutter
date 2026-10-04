import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _init();
  }

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      } else {
        // Coba fetch profil; jika gagal (no role/profile), logout
        final profile = await _authService.getCurrentUserProfile();
        if (profile == null) {
          await _authService.logout();
          _status = AuthStatus.unauthenticated;
          _user = null;
        } else {
          _status = AuthStatus.authenticated;
          _user = profile;
        }
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      _user = await _authService.login(email, password);
      _status = AuthStatus.authenticated;
    } on Exception catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapError(e.toString());
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _mapError(String raw) {
    if (raw.contains('invalid-email')) return 'Format email tidak valid.';
    if (raw.contains('user-not-found')) return 'Akun tidak ditemukan.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Email atau password salah.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Koneksi gagal. Periksa internet Anda.';
    }
    if (raw.contains('Profil pengguna tidak ditemukan')) {
      return 'Profil pengguna tidak ditemukan. Hubungi administrator.';
    }
    if (raw.contains('Role tidak valid')) return 'Role akun tidak valid.';
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
