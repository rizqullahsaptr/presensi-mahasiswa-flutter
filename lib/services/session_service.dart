import 'package:firebase_database/firebase_database.dart';

import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../utils/code_generator.dart';

class SessionService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // ─────────────────────────────────────────
  // DOSEN — membuat sesi
  // ─────────────────────────────────────────

  Future<SessionModel> buatSesi({
    required String lecturerId,
    required String judulSesi,
    required String informasiPertemuan,
  }) async {
    final ref = _db.ref('sessions').push();
    final sessionId = ref.key!;
    final kode = CodeGenerator.generate();
    final now = DateTime.now().millisecondsSinceEpoch;

    final data = SessionModel(
      sessionId: sessionId,
      judulSesi: judulSesi,
      informasiPertemuan: informasiPertemuan,
      lecturerId: lecturerId,
      kodePresensi: kode,
      status: 'ditutup',
      waktuDibuat: now,
    );

    await ref.set(data.toMap());
    return data;
  }

  // ─────────────────────────────────────────
  // DOSEN — buka sesi
  // ─────────────────────────────────────────

  Future<void> bukaSesi(String sessionId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.ref('sessions/$sessionId').update({
      'status': 'aktif',
      'waktuDibuka': now,
    });
  }

  // ─────────────────────────────────────────
  // DOSEN — tutup sesi
  // ─────────────────────────────────────────

  Future<void> tutupSesi(String sessionId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.ref('sessions/$sessionId').update({
      'status': 'ditutup',
      'waktuDitutup': now,
    });
  }

  // ─────────────────────────────────────────
  // DOSEN — stream daftar sesi miliknya
  // ─────────────────────────────────────────

  Stream<List<SessionModel>> streamSesiDosen(String lecturerId) {
    return _db
        .ref('sessions')
        .orderByChild('lecturerId')
        .equalTo(lecturerId)
        .onValue
        .map((event) {
          if (!event.snapshot.exists || event.snapshot.value == null) return [];
          final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final list = map.entries
              .map(
                (e) => SessionModel.fromMap(
                  e.key as String,
                  Map<dynamic, dynamic>.from(e.value as Map),
                ),
              )
              .toList();
          list.sort((a, b) => b.waktuDibuat.compareTo(a.waktuDibuat));
          return list;
        });
  }

  // ─────────────────────────────────────────
  // DOSEN — stream detail satu sesi
  // ─────────────────────────────────────────

  Stream<SessionModel?> streamSesi(String sessionId) {
    return _db.ref('sessions/$sessionId').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return null;
      return SessionModel.fromMap(
        sessionId,
        Map<dynamic, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  // ─────────────────────────────────────────
  // DOSEN — daftar kehadiran untuk detail sesi
  // Mahasiswa belum presensi tampil sebagai Alpha (dihitung di tampilan)
  // ─────────────────────────────────────────

  Stream<List<AttendanceEntry>> streamKehadiranSesi(String sessionId) {
    // Gabungkan users (mahasiswa) + attendance/{sessionId}
    // Menggunakan StreamTransformer manual untuk merge dua query
    return _db
        .ref('users')
        .orderByChild('role')
        .equalTo('mahasiswa')
        .onValue
        .asyncMap((usersEvent) async {
          final Map<String, AttendanceEntry> entries = {};

          if (usersEvent.snapshot.exists && usersEvent.snapshot.value != null) {
            final usersMap = Map<dynamic, dynamic>.from(
              usersEvent.snapshot.value as Map,
            );
            for (final e in usersMap.entries) {
              final uid = e.key as String;
              final u = UserModel.fromMap(
                uid,
                Map<dynamic, dynamic>.from(e.value as Map),
              );
              entries[uid] = AttendanceEntry(
                studentId: uid,
                nama: u.nama,
                identitas: u.identitas,
                status: 'Alpha', // default jika belum ada catatan
                hasCatatan: false,
              );
            }
          }

          // Overlay dengan catatan kehadiran yang sudah ada
          final attSnap = await _db.ref('attendance/$sessionId').get();
          if (attSnap.exists && attSnap.value != null) {
            final attMap = Map<dynamic, dynamic>.from(attSnap.value as Map);
            for (final e in attMap.entries) {
              final studentId = e.key as String;
              final att = AttendanceModel.fromMap(
                sessionId,
                studentId,
                Map<dynamic, dynamic>.from(e.value as Map),
              );
              if (entries.containsKey(studentId)) {
                entries[studentId] = AttendanceEntry(
                  studentId: studentId,
                  nama: entries[studentId]!.nama,
                  identitas: entries[studentId]!.identitas,
                  status: att.status,
                  hasCatatan: true,
                );
              }
            }
          }

          final list = entries.values.toList();
          list.sort((a, b) => a.nama.compareTo(b.nama));
          return list;
        });
  }

  // ─────────────────────────────────────────
  // DOSEN — koreksi status kehadiran
  // Hanya field status yang diubah
  // ─────────────────────────────────────────

  Future<void> koreksiStatus({
    required String sessionId,
    required String studentId,
    required String status, // Hadir | Izin | Sakit | Alpha
  }) async {
    assert(['Hadir', 'Izin', 'Sakit', 'Alpha'].contains(status));
    final now = DateTime.now().millisecondsSinceEpoch;
    // update atau create catatan
    await _db.ref('attendance/$sessionId/$studentId').update({
      'status': status,
      'sessionId': sessionId,
      'studentId': studentId,
      'waktuPresensi': now,
    });
  }

  // ─────────────────────────────────────────
  // MAHASISWA — cari sesi berdasarkan kode
  // ─────────────────────────────────────────

  Future<SessionModel?> cariSesiDenganKode(String kode) async {
    final snap = await _db
        .ref('sessions')
        .orderByChild('kodePresensi')
        .equalTo(kode.trim().toUpperCase())
        .limitToFirst(1)
        .get();
    if (!snap.exists || snap.value == null) return null;
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    final entry = map.entries.first;
    return SessionModel.fromMap(
      entry.key as String,
      Map<dynamic, dynamic>.from(entry.value as Map),
    );
  }

  // ─────────────────────────────────────────
  // MAHASISWA — presensi (atomik, cegah ganda)
  // ─────────────────────────────────────────

  /// Hasil: 'berhasil' | 'sudah_presensi' | 'sesi_tidak_aktif' | 'kode_tidak_valid'
  Future<String> presensi({
    required String kodeInput,
    required String studentId,
  }) async {
    final session = await cariSesiDenganKode(kodeInput);
    if (session == null) return 'kode_tidak_valid';
    if (!session.isAktif) return 'sesi_tidak_aktif';

    final ref = _db.ref('attendance/${session.sessionId}/$studentId');
    final now = DateTime.now().millisecondsSinceEpoch;

    // Transaksi atomik — cegah pengiriman ganda
    String hasil = 'berhasil';
    await ref.runTransaction((currentData) {
      if (currentData != null) {
        // Catatan sudah ada
        hasil = 'sudah_presensi';
        return Transaction.abort();
      }
      return Transaction.success({
        'sessionId': session.sessionId,
        'studentId': studentId,
        'status': 'Hadir',
        'waktuPresensi': now,
      });
    });

    return hasil;
  }

  // ─────────────────────────────────────────
  // MAHASISWA — riwayat kehadiran sendiri
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRiwayatMahasiswa(
    String studentId,
  ) async {
    // Ambil semua sesi, lalu filter yang punya catatan kehadiran studentId ini
    final sessSnap = await _db.ref('sessions').get();
    final result = <Map<String, dynamic>>[];
    if (!sessSnap.exists || sessSnap.value == null) return result;

    final sessMap = Map<dynamic, dynamic>.from(sessSnap.value as Map);
    for (final e in sessMap.entries) {
      final sessionId = e.key as String;
      final attSnap = await _db.ref('attendance/$sessionId/$studentId').get();
      if (attSnap.exists && attSnap.value != null) {
        final att = AttendanceModel.fromMap(
          sessionId,
          studentId,
          Map<dynamic, dynamic>.from(attSnap.value as Map),
        );
        final sess = SessionModel.fromMap(
          sessionId,
          Map<dynamic, dynamic>.from(e.value as Map),
        );
        result.add({'session': sess, 'attendance': att});
      }
    }
    result.sort((a, b) {
      final aTime = (a['attendance'] as AttendanceModel).waktuPresensi;
      final bTime = (b['attendance'] as AttendanceModel).waktuPresensi;
      return bTime.compareTo(aTime);
    });
    return result;
  }
}
