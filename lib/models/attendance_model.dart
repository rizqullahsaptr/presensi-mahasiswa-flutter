// Model catatan kehadiran — node attendance/{sessionId}/{studentId}
// Status valid: Hadir, Izin, Sakit, Alpha
class AttendanceModel {
  final String sessionId;
  final String studentId;
  final String status; // 'Hadir' | 'Izin' | 'Sakit' | 'Alpha'
  final int waktuPresensi;

  const AttendanceModel({
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.waktuPresensi,
  });

  factory AttendanceModel.fromMap(
    String sessionId,
    String studentId,
    Map<dynamic, dynamic> map,
  ) {
    return AttendanceModel(
      sessionId: sessionId,
      studentId: studentId,
      status: (map['status'] as String?) ?? 'Alpha',
      waktuPresensi: (map['waktuPresensi'] as int?) ?? 0,
    );
  }

  bool get isHadir => status == 'Hadir';
  bool get isIzin => status == 'Izin';
  bool get isSakit => status == 'Sakit';
  bool get isAlpha => status == 'Alpha';

  Map<String, dynamic> toMap() => {
    'sessionId': sessionId,
    'studentId': studentId,
    'status': status,
    'waktuPresensi': waktuPresensi,
  };
}

// Kelas bantuan untuk menampilkan data kehadiran mahasiswa di Detail Sesi Dosen
// Mahasiswa yang belum memiliki catatan ditampilkan dengan status Alpha (default)
class AttendanceEntry {
  final String studentId;
  final String nama;
  final String identitas; // NIM
  final String status; // default 'Alpha' jika belum ada catatan
  final bool
  hasCatatan; // false = belum presensi, status dihitung dari tampilan

  const AttendanceEntry({
    required this.studentId,
    required this.nama,
    required this.identitas,
    required this.status,
    required this.hasCatatan,
  });
}
