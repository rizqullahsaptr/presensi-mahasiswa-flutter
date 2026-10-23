import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mahasiswa/models/user_model.dart';
import 'package:presensi_mahasiswa/providers/session_provider.dart';
import 'package:presensi_mahasiswa/services/session_service.dart';

const student = UserModel(
  uid: 'u-mahasiswa',
  nama: 'Mahasiswa Demo',
  email: 'mahasiswa@example.test',
  identitas: 'M001',
  role: 'mahasiswa',
);

/// Service yang dapat diatur: gagal, kosong, atau berisi satu catatan.
class RiwayatService extends SessionService {
  RiwayatService(this.mode) : super.withReaderForTesting((_) async => null);

  final String mode; // 'gagal' | 'kosong' | 'gagal-sekali' | 'data'
  int panggilan = 0;

  @override
  Future<List<Map<String, dynamic>>> getRiwayatMahasiswa(
    String studentId,
  ) async {
    panggilan++;
    switch (mode) {
      case 'gagal':
        throw Exception('network-request-failed');
      case 'gagal-sekali':
        if (panggilan == 1) throw Exception('network-request-failed');
        return [];
      default:
        return [];
    }
  }
}

/// Service yang menggantung tanpa pernah selesai, untuk menguji batas waktu.
class RiwayatMenggantungService extends SessionService {
  RiwayatMenggantungService() : super.withReaderForTesting((_) async => null);

  @override
  Future<List<Map<String, dynamic>>> getRiwayatMahasiswa(String studentId) =>
      Completer<List<Map<String, dynamic>>>().future;
}

void main() {
  test(
    'kegagalan pembacaan ditandai sebagai galat, bukan daftar kosong',
    () async {
      final provider = MahasiswaProvider(RiwayatService('gagal'), student);
      await provider.muatRiwayat();
      expect(provider.loadingRiwayat, isFalse);
      expect(provider.riwayatError, isTrue);
      expect(provider.riwayat, isEmpty);
    },
  );

  test('daftar kosong yang sah tidak ditandai sebagai galat', () async {
    final provider = MahasiswaProvider(RiwayatService('kosong'), student);
    await provider.muatRiwayat();
    expect(provider.riwayatError, isFalse);
    expect(provider.riwayat, isEmpty);
  });

  test(
    'percobaan ulang setelah galat memulihkan keadaan tanpa galat',
    () async {
      final service = RiwayatService('gagal-sekali');
      final provider = MahasiswaProvider(service, student);
      await provider.muatRiwayat();
      expect(provider.riwayatError, isTrue);
      await provider.muatRiwayat();
      expect(provider.riwayatError, isFalse);
      expect(service.panggilan, 2);
    },
  );

  test(
    'pemuatan yang menggantung berakhir sebagai galat, bukan tanpa akhir',
    () async {
      final provider = MahasiswaProvider(
        RiwayatMenggantungService(),
        student,
        riwayatTimeout: const Duration(milliseconds: 300),
      );
      final selesai = provider.muatRiwayat();
      expect(provider.loadingRiwayat, isTrue);
      await selesai.timeout(const Duration(seconds: 10));
      expect(provider.loadingRiwayat, isFalse);
      expect(provider.riwayatError, isTrue);
    },
  );
}
