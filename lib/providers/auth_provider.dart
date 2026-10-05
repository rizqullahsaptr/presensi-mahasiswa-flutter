import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  late final StreamSubscription<User?> _authSubscription;
  int _revision = 0;
  bool _disposed = false;
  bool _loginInProgress = false;

  AuthProvider(this._authService) {
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;

  void _onAuthStateChanged(User? firebaseUser) {
    if (_disposed) return;
    if (firebaseUser == null) {
      ++_revision;
      _loginInProgress = false;
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } else if (!_loginInProgress) {
      final revision = ++_revision;
      _loadProfile(revision);
    }
  }

  Future<void> _loadProfile(int revision) async {
    try {
      final profile = await _authService.getCurrentUserProfile();
      if (_disposed || revision != _revision) return;
      if (profile == null) {
        if (_authService.currentUser != null) {
          await _authService.logout();
          if (_disposed || revision != _revision) return;
        }
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _user = profile;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
      }
    } on InvalidUserProfileException catch (e) {
      if (_disposed || revision != _revision) return;
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapError(e.toString());
    } catch (e) {
      if (_disposed || revision != _revision) return;
      // A failed database read must not revoke a valid Firebase session.
      _status = _user == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      _errorMessage = _mapError(e.toString());
    }
    if (!_disposed && revision == _revision) notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final revision = ++_revision;
    _loginInProgress = true;
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final profile = await _authService.login(email, password);
      if (_disposed || revision != _revision) return;
      _user = profile;
      _status = AuthStatus.authenticated;
    } on Exception catch (e) {
      if (_disposed || revision != _revision) return;
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = _mapError(e.toString());
    } finally {
      if (!_disposed && revision == _revision) {
        _loginInProgress = false;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    final revision = ++_revision;
    await _authService.logout();
    if (_disposed || revision != _revision) return;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    _authSubscription.cancel();
    super.dispose();
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
