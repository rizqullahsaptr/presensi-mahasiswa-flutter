/// Validasi input form aplikasi
class Validators {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
    final re = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!re.hasMatch(v.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password tidak boleh kosong';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? kodePresensi(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Kode presensi tidak boleh kosong';
    }
    final trimmed = v.trim();
    if (trimmed.length != 6) {
      return 'Kode presensi harus 6 karakter';
    }
    final re = RegExp(r'^[A-Za-z0-9]{6}$');
    if (!re.hasMatch(trimmed)) {
      return 'Kode presensi hanya boleh berupa alfanumerik';
    }
    return null;
  }

  static String? judulSesi(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Judul sesi tidak boleh kosong';
    }
    return null;
  }

  static String? informasiPertemuan(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Informasi pertemuan tidak boleh kosong';
    }
    return null;
  }
}
