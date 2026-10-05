import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../utils/code_generator.dart';

class SessionService {
  late final FirebaseDatabase _db;
  final Future<Object?> Function(String path)? _readForTesting;
  final Stream<Object?> Function(String path)? _watchRosterForTesting;

  SessionService()
    : _readForTesting = null,
      _watchRosterForTesting = null,
      _db = FirebaseDatabase.instance;

  @visibleForTesting
  SessionService.withReaderForTesting(
    Future<Object?> Function(String path) read,
  ) : _readForTesting = read,
      _watchRosterForTesting = null;

  @visibleForTesting
  SessionService.withRosterSourcesForTesting(
    Stream<Object?> Function(String path) watch,
  ) : _watchRosterForTesting = watch,
      _readForTesting = null;

  Stream<Object?> _watchRoster(String path) {
    if (_watchRosterForTesting != null) return _watchRosterForTesting(path);
    if (path == 'users') {
      return _db
          .ref('users')
          .orderByChild('role')
          .equalTo('mahasiswa')
          .onValue
          .map((event) => event.snapshot.value);
    }
    return _db.ref(path).onValue.map((event) => event.snapshot.value);
  }

  Future<Object?> _readValue(String path) async {
    if (_readForTesting != null) return _readForTesting(path);
    final snapshot = await _db.ref(path).get();
    return snapshot.value;
  }

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
    final session = await _db.ref('sessions/$sessionId').get();
    if (!session.exists || session.child('kodePresensi').value == null) {
      throw StateError(
        'Sesi tidak ditemukan atau kode presensi tidak tersedia',
      );
    }
    await _db.ref('sessions/$sessionId').update({
      'status': 'aktif',
      'kodePresensiAktif': session.child('kodePresensi').value,
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
      'kodePresensiAktif': null,
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
    late final StreamController<List<AttendanceEntry>> controller;
    StreamSubscription<Object?>? usersSubscription;
    StreamSubscription<Object?>? attendanceSubscription;
    Object? usersValue;
    Object? attendanceValue;
    var hasUsers = false;
    var hasAttendance = false;

    void emitRoster() {
      if (!hasUsers || !hasAttendance) return;
      final entries = <String, AttendanceEntry>{};
      if (usersValue != null) {
        final usersMap = Map<dynamic, dynamic>.from(usersValue as Map);
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
            status: 'Alpha',
            hasCatatan: false,
          );
        }
      }
      if (attendanceValue != null) {
        final attMap = Map<dynamic, dynamic>.from(attendanceValue as Map);
        for (final e in attMap.entries) {
          final studentId = e.key as String;
          final att = AttendanceModel.fromMap(
            sessionId,
            studentId,
            Map<dynamic, dynamic>.from(e.value as Map),
          );
          final student = entries[studentId];
          if (student != null) {
            entries[studentId] = AttendanceEntry(
              studentId: studentId,
              nama: student.nama,
              identitas: student.identitas,
              status: att.status,
              hasCatatan: true,
            );
          }
        }
      }
      final list = entries.values.toList();
      list.sort((a, b) => a.nama.compareTo(b.nama));
      controller.add(list);
    }

    controller = StreamController<List<AttendanceEntry>>(
      onListen: () {
        usersSubscription = _watchRoster('users').listen((value) {
          usersValue = value;
          hasUsers = true;
          emitRoster();
        }, onError: controller.addError);
        attendanceSubscription = _watchRoster('attendance/$sessionId')
            .listen((value) {
              attendanceValue = value;
              hasAttendance = true;
              emitRoster();
            }, onError: controller.addError);
      },
      onPause: () {
        usersSubscription?.pause();
        attendanceSubscription?.pause();
      },
      onResume: () {
        usersSubscription?.resume();
        attendanceSubscription?.resume();
      },
      onCancel: () async {
        await Future.wait([
          if (usersSubscription != null) usersSubscription!.cancel(),
          if (attendanceSubscription != null) attendanceSubscription!.cancel(),
        ]);
      },
    );
    return controller.stream;
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
    await _db.ref('users/$studentId/attendanceSessionIds/$sessionId').set(true);
  }

  // ─────────────────────────────────────────
  // MAHASISWA — cari sesi berdasarkan kode
  // ─────────────────────────────────────────

  Future<SessionModel?> cariSesiDenganKode(String kode) async {
    final snap = await _db
        .ref('sessions')
        .orderByChild('kodePresensiAktif')
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
    final indexValue = await _readValue(
      'users/$studentId/attendanceSessionIds',
    );
    if (indexValue == null) return result;

    final indexMap = Map<dynamic, dynamic>.from(indexValue as Map);
    final sessionIds = indexMap.keys.cast<String>().toList();

    for (final sessionId in sessionIds) {
      // Baca attendance record mahasiswa ini pada sesi tersebut
      final attValue = await _readValue('attendance/$sessionId/$studentId');
      if (attValue == null) continue;

      final att = AttendanceModel.fromMap(
        sessionId,
        studentId,
        Map<dynamic, dynamic>.from(attValue as Map),
      );

      // Status sesi dapat berubah setelah dibuka; baca data terbaru dari Firebase.
      final sessValue = await _readValue('sessions/$sessionId');
      final SessionModel? sess = sessValue == null
          ? null
          : SessionModel.fromMap(
              sessionId,
              Map<dynamic, dynamic>.from(sessValue as Map),
            );

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
