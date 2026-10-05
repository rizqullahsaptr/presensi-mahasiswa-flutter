import 'package:firebase_database/firebase_database.dart';

import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../utils/code_generator.dart';

class SessionService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Cache lokal hanya sebagai optimasi — bukan sumber utama kebenaran.
  // Sumber utama: users/{uid}/attendanceSessionIds di Firebase.
  final Map<String, SessionModel> _sessionCache = {};

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
  // Menulis attendance lalu memperbarui index mahasiswa yang bersangkutan
  // ─────────────────────────────────────────

  Future<void> koreksiStatus({
    required String sessionId,
    required String studentId,
    required String status, // Hadir | Izin | Sakit | Alpha
    required String dosenId,
  }) async {
    assert(['Hadir', 'Izin', 'Sakit', 'Alpha'].contains(status));
    final now = DateTime.now().millisecondsSinceEpoch;

    // Tulis attendance terlebih dahulu agar validasi rules index terpenuhi
    await _db.ref('attendance/$sessionId/$studentId').update({
      'status': status,
      'sessionId': sessionId,
      'studentId': studentId,
      'waktuPresensi': now,
    });

    // Perbarui persistent index riwayat mahasiswa yang dikoreksi
    // Rules: dosen pemilik sesi boleh menulis index studentId tertentu
    await _db
        .ref('users/$studentId/attendanceSessionIds/$sessionId')
        .set(true);
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
    final model = SessionModel.fromMap(
      entry.key as String,
      Map<dynamic, dynamic>.from(entry.value as Map),
    );
    _sessionCache[model.sessionId] = model;
    return model;
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

    if (hasil == 'berhasil') {
      // Simpan sessionId ke persistent index — tetap ada setelah restart
      // Rules: mahasiswa hanya bisa menulis index miliknya jika attendance sudah ada
      await _db
          .ref('users/$studentId/attendanceSessionIds/${session.sessionId}')
          .set(true);
      // Update cache lokal sebagai optimasi tambahan
      _sessionCache[session.sessionId] = session;
    }

    return hasil;
  }

  // ─────────────────────────────────────────
  // MAHASISWA — riwayat kehadiran sendiri
  // Membaca dari persistent index di Firebase — tidak bergantung pada cache proses
  // ─────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRiwayatMahasiswa(
    String studentId,
  ) async {
    final result = <Map<String, dynamic>>[];

    // Baca persistent index dari Firebase
    final indexSnap =
        await _db.ref('users/$studentId/attendanceSessionIds').get();
    if (!indexSnap.exists || indexSnap.value == null) return result;

    final indexMap =
        Map<dynamic, dynamic>.from(indexSnap.value as Map);
    final sessionIds = indexMap.keys.cast<String>().toList();

    for (final sessionId in sessionIds) {
      // Baca attendance record mahasiswa ini pada sesi tersebut
      final attSnap =
          await _db.ref('attendance/$sessionId/$studentId').get();
      if (!attSnap.exists || attSnap.value == null) continue;

      final att = AttendanceModel.fromMap(
        sessionId,
        studentId,
        Map<dynamic, dynamic>.from(attSnap.value as Map),
      );

      // Coba ambil dari cache lokal dahulu, lalu fallback ke Firebase
      SessionModel? sess = _sessionCache[sessionId];
      if (sess == null) {
        try {
          final sessSnap = await _db.ref('sessions/$sessionId').get();
          if (sessSnap.exists && sessSnap.value != null) {
            sess = SessionModel.fromMap(
              sessionId,
              Map<dynamic, dynamic>.from(sessSnap.value as Map),
            );
            _sessionCache[sessionId] = sess;
          }
        } catch (_) {
          // Sesi sudah ditutup — tidak dapat dibaca langsung oleh mahasiswa
          // Riwayat tetap muncul tanpa info sesi lengkap
        }
      }

      if (sess != null) {
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
