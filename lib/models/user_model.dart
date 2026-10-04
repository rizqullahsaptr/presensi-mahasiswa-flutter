// Model profil pengguna — data dari node users/{uid}
// Password TIDAK disimpan di sini maupun di Realtime Database
class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String identitas; // NIM untuk mahasiswa, identitas dosen
  final String role; // 'mahasiswa' | 'dosen'

  const UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.identitas,
    required this.role,
  });

  bool get isMahasiswa => role == 'mahasiswa';
  bool get isDosen => role == 'dosen';

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> map) {
    return UserModel(
      uid: uid,
      nama: (map['nama'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      identitas: (map['identitas'] as String?) ?? '',
      role: (map['role'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'nama': nama,
    'email': email,
    'identitas': identitas,
    'role': role,
  };
}
