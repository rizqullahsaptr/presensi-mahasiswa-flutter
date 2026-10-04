// Model sesi presensi — node sessions/{sessionId}
class SessionModel {
  final String sessionId;
  final String judulSesi;
  final String informasiPertemuan;
  final String lecturerId;
  final String kodePresensi;
  final String status; // 'aktif' | 'ditutup'
  final int waktuDibuat;
  final int? waktuDibuka;
  final int? waktuDitutup;

  const SessionModel({
    required this.sessionId,
    required this.judulSesi,
    required this.informasiPertemuan,
    required this.lecturerId,
    required this.kodePresensi,
    required this.status,
    required this.waktuDibuat,
    this.waktuDibuka,
    this.waktuDitutup,
  });

  bool get isAktif => status == 'aktif';

  factory SessionModel.fromMap(String sessionId, Map<dynamic, dynamic> map) {
    return SessionModel(
      sessionId: sessionId,
      judulSesi: (map['judulSesi'] as String?) ?? '',
      informasiPertemuan: (map['informasiPertemuan'] as String?) ?? '',
      lecturerId: (map['lecturerId'] as String?) ?? '',
      kodePresensi: (map['kodePresensi'] as String?) ?? '',
      status: (map['status'] as String?) ?? 'ditutup',
      waktuDibuat: (map['waktuDibuat'] as int?) ?? 0,
      waktuDibuka: map['waktuDibuka'] as int?,
      waktuDitutup: map['waktuDitutup'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'judulSesi': judulSesi,
    'informasiPertemuan': informasiPertemuan,
    'lecturerId': lecturerId,
    'kodePresensi': kodePresensi,
    'status': status,
    'waktuDibuat': waktuDibuat,
    if (waktuDibuka != null) 'waktuDibuka': waktuDibuka,
    if (waktuDitutup != null) 'waktuDitutup': waktuDitutup,
  };
}
