import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_model.dart';

class InvalidUserProfileException implements Exception {
  const InvalidUserProfileException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Login dengan email dan password via Firebase Authentication.
  /// Password tidak pernah disimpan manual ke Realtime Database.
  Future<UserModel> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    return _fetchUserProfile(uid);
  }

  /// Ambil profil dari node users/{uid}.
  /// Lempar exception jika profil tidak ditemukan atau role tidak valid.
  Future<UserModel> _fetchUserProfile(String uid) async {
    final snap = await _db.ref('users/$uid').get();
    if (!snap.exists || snap.value == null) {
      await _auth.signOut();
      throw const InvalidUserProfileException(
        'Profil pengguna tidak ditemukan. Hubungi administrator.',
      );
    }
    final value = snap.value;
    if (value is! Map ||
        value['nama'] is! String ||
        value['email'] is! String ||
        value['identitas'] is! String ||
        value['role'] is! String) {
      await _auth.signOut();
      throw const InvalidUserProfileException('Profil pengguna tidak valid.');
    }
    final user = UserModel.fromMap(uid, value);
    if (user.role != 'mahasiswa' && user.role != 'dosen') {
      await _auth.signOut();
      throw InvalidUserProfileException('Role tidak valid: ${user.role}');
    }
    return user;
  }

  /// Ambil profil pengguna yang sedang login (dipakai saat app restart).
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchUserProfile(user.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
