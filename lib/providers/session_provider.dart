import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';
import '../services/session_service.dart';

// ─────────────────────────────────────────
// Provider Mahasiswa
// ─────────────────────────────────────────

enum PresensiStatus {
  idle,
  loading,
  berhasil,
  sudahPresensi,
  sesiTidakAktif,
  kodeError,
  koneksiError,
}

class MahasiswaProvider extends ChangeNotifier {
  final SessionService _service;
  final UserModel user;

  MahasiswaProvider(this._service, this.user);

  PresensiStatus _presensiStatus = PresensiStatus.idle;
  List<Map<String, dynamic>> _riwayat = [];
  bool _loadingRiwayat = false;
  SessionModel? _sesiDitemukan; // sesi yang ditemukan saat mahasiswa input kode

  PresensiStatus get presensiStatus => _presensiStatus;
  List<Map<String, dynamic>> get riwayat => List.unmodifiable(_riwayat);
  bool get loadingRiwayat => _loadingRiwayat;
  SessionModel? get sesiDitemukan => _sesiDitemukan;

  void resetPresensiStatus() {
    _presensiStatus = PresensiStatus.idle;
    _sesiDitemukan = null;
    notifyListeners();
  }

  Future<void> cariSesi(String kode) async {
    _presensiStatus = PresensiStatus.loading;
    _sesiDitemukan = null;
    notifyListeners();

    try {
      final sess = await _service.cariSesiDenganKode(kode);
      if (sess == null) {
        _presensiStatus = PresensiStatus.kodeError;
      } else if (!sess.isAktif) {
        _presensiStatus = PresensiStatus.sesiTidakAktif;
        _sesiDitemukan = sess;
      } else {
        _sesiDitemukan = sess;
        _presensiStatus = PresensiStatus.idle; // lanjut ke detail sesi
      }
    } catch (_) {
      _presensiStatus = PresensiStatus.koneksiError;
    }
    notifyListeners();
  }

  Future<void> presensi(String kode) async {
    _presensiStatus = PresensiStatus.loading;
    notifyListeners();

    try {
      final hasil = await _service.presensi(
        kodeInput: kode,
        studentId: user.uid,
      );
      switch (hasil) {
        case 'berhasil':
          _presensiStatus = PresensiStatus.berhasil;
          break;
        case 'sudah_presensi':
          _presensiStatus = PresensiStatus.sudahPresensi;
          break;
        case 'sesi_tidak_aktif':
          _presensiStatus = PresensiStatus.sesiTidakAktif;
          break;
        default:
          _presensiStatus = PresensiStatus.kodeError;
      }
    } catch (_) {
      _presensiStatus = PresensiStatus.koneksiError;
    }
    notifyListeners();
  }

  Future<void> muatRiwayat() async {
    _loadingRiwayat = true;
    notifyListeners();
    try {
      _riwayat = await _service.getRiwayatMahasiswa(user.uid);
    } catch (_) {
      _riwayat = [];
    }
    _loadingRiwayat = false;
    notifyListeners();
  }
}

// ─────────────────────────────────────────
// Provider Dosen
// ─────────────────────────────────────────

class DosenProvider extends ChangeNotifier {
  final SessionService _service;
  final UserModel user;

  DosenProvider(this._service, this.user);

  bool _loadingBuatSesi = false;
  bool _loadingAksi = false; // buka/tutup/koreksi
  String? _errorMessage;

  bool get loadingBuatSesi => _loadingBuatSesi;
  bool get loadingAksi => _loadingAksi;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Stream daftar sesi — langsung dari service
  Stream<List<SessionModel>> get streamSesi =>
      _service.streamSesiDosen(user.uid);

  // Stream detail satu sesi
  Stream<SessionModel?> streamDetailSesi(String sessionId) =>
      _service.streamSesi(sessionId);

  // Stream daftar kehadiran
  Stream<List<AttendanceEntry>> streamKehadiran(String sessionId) =>
      _service.streamKehadiranSesi(sessionId);

  Future<SessionModel?> buatSesi({
    required String judulSesi,
    required String informasiPertemuan,
  }) async {
    _loadingBuatSesi = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final sesi = await _service.buatSesi(
        lecturerId: user.uid,
        judulSesi: judulSesi,
        informasiPertemuan: informasiPertemuan,
      );
      _loadingBuatSesi = false;
      notifyListeners();
      return sesi;
    } catch (e) {
      _errorMessage = 'Gagal membuat sesi. Periksa koneksi.';
      _loadingBuatSesi = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> bukaSesi(String sessionId) async {
    _loadingAksi = true;
    notifyListeners();
    try {
      await _service.bukaSesi(sessionId);
      _loadingAksi = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal membuka sesi.';
      _loadingAksi = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tutupSesi(String sessionId) async {
    _loadingAksi = true;
    notifyListeners();
    try {
      await _service.tutupSesi(sessionId);
      _loadingAksi = false;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Gagal menutup sesi.';
      _loadingAksi = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> koreksiStatus({
    required String sessionId,
    required String studentId,
    required String status,
  }) async {
    try {
      await _service.koreksiStatus(
        sessionId: sessionId,
        studentId: studentId,
        status: status,
        dosenId: user.uid,
      );
      return true;
    } catch (_) {
      _errorMessage = 'Gagal mengoreksi status.';
      notifyListeners();
      return false;
    }
  }
}
