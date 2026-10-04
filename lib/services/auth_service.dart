import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/user_model.dart';

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
      throw Exception(
        'Profil pengguna tidak ditemukan. Hubungi administrator.',
      );
    }
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final user = UserModel.fromMap(uid, map);
    if (user.role != 'mahasiswa' && user.role != 'dosen') {
      await _auth.signOut();
      throw Exception('Role tidak valid: ${user.role}');
    }
    return user;
  }

  /// Ambil profil pengguna yang sedang login (dipakai saat app restart).
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchUserProfile(user.uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
