import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mahasiswa/utils/validators.dart';
import 'package:presensi_mahasiswa/utils/code_generator.dart';
import 'package:presensi_mahasiswa/models/user_model.dart';
import 'package:presensi_mahasiswa/models/session_model.dart';
import 'package:presensi_mahasiswa/models/attendance_model.dart';

void main() {
  group('Validators Test', () {
    test('Email kosong harus mengembalikan pesan error', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('Email tidak valid harus ditolak', () {
      expect(Validators.email('bukanemail'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
      expect(Validators.email('@domain.com'), isNotNull);
    });

    test('Email valid harus diterima', () {
      expect(Validators.email('mahasiswa@uin-malang.ac.id'), isNull);
      expect(Validators.email('dosen@uin-malang.ac.id'), isNull);
    });

    test('Password minimal 6 karakter', () {
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('rahasia123'), isNull);
    });

    test('Kode presensi harus tepat 6 karakter alfanumerik', () {
      expect(Validators.kodePresensi(null), isNotNull);
      expect(Validators.kodePresensi('ABC'), isNotNull);
      expect(Validators.kodePresensi('ABC1234'), isNotNull);
      expect(Validators.kodePresensi('ABC 12'), isNotNull);
      expect(Validators.kodePresensi('ABC123'), isNull);
      expect(Validators.kodePresensi('XYZ789'), isNull);
    });

    test('Judul sesi dan informasi pertemuan wajib diisi', () {
      expect(Validators.judulSesi(null), isNotNull);
      expect(Validators.judulSesi(''), isNotNull);
      expect(Validators.judulSesi('Pemrograman Mobile'), isNull);

      expect(Validators.informasiPertemuan(null), isNotNull);
      expect(Validators.informasiPertemuan(''), isNotNull);
      expect(Validators.informasiPertemuan('Pertemuan ke-5'), isNull);
    });
  });

  group('CodeGenerator Test', () {
    test('Menghasilkan kode sepanjang tepat 6 karakter', () {
      final code = CodeGenerator.generate();
      expect(code.length, equals(6));
    });

    test(
      'Kode hanya mengandung karakter yang diizinkan (tanpa I, O, 0, 1)',
      () {
        const allowed = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        for (int i = 0; i < 50; i++) {
          final code = CodeGenerator.generate();
          for (final char in code.split('')) {
            expect(
              allowed.contains(char),
              isTrue,
              reason: 'Karakter $char tidak diizinkan',
            );
          }
        }
      },
    );

    test('Dua generasi berturut-turut menghasilkan kode yang berbeda (probabilistik)', () {
      final code1 = CodeGenerator.generate();
      final code2 = CodeGenerator.generate();
      expect(code1, isNot(equals(code2)));
    });
  });

  group('Data Models Serialization Test', () {
    test('UserModel fromMap dan toMap konsisten', () {
      final map = {
        'nama': 'Muhammad Rizqullah Saputra',
        'email': 'rizqullah@uin-malang.ac.id',
        'identitas': '240605110102',
        'role': 'mahasiswa',
      };

      final user = UserModel.fromMap('user_uid_1', map);
      expect(user.uid, equals('user_uid_1'));
      expect(user.nama, equals('Muhammad Rizqullah Saputra'));
      expect(user.identitas, equals('240605110102'));
      expect(user.role, equals('mahasiswa'));
      expect(user.isMahasiswa, isTrue);
      expect(user.isDosen, isFalse);

      final toMapResult = user.toMap();
      expect(toMapResult['nama'], equals('Muhammad Rizqullah Saputra'));
      expect(toMapResult['role'], equals('mahasiswa'));
      expect(
        toMapResult.containsKey('password'),
        isFalse,
        reason: 'Password tidak boleh ada di database model',
      );
    });

    test('SessionModel fromMap dan toMap konsisten', () {
      final map = {
        'judulSesi': 'Pertemuan 1 Pengenalan Flutter',
        'informasiPertemuan': 'Senin, 08:00 - 10:30',
        'lecturerId': 'dosen_uid_1',
        'kodePresensi': 'ABC456',
        'status': 'aktif',
        'waktuDibuat': 1727700000000,
      };

      final session = SessionModel.fromMap('session_id_1', map);
      expect(session.sessionId, equals('session_id_1'));
      expect(session.judulSesi, equals('Pertemuan 1 Pengenalan Flutter'));
      expect(session.kodePresensi, equals('ABC456'));
      expect(session.isAktif, isTrue);

      final toMapResult = session.toMap();
      expect(toMapResult['status'], equals('aktif'));
      expect(toMapResult['kodePresensi'], equals('ABC456'));
    });

    test('AttendanceModel fromMap dan toMap konsisten', () {
      final map = {'status': 'Hadir', 'waktuPresensi': 1727700500000};

      final attendance = AttendanceModel.fromMap('session_1', 'student_1', map);
      expect(attendance.sessionId, equals('session_1'));
      expect(attendance.studentId, equals('student_1'));
      expect(attendance.status, equals('Hadir'));
      expect(attendance.isHadir, isTrue);
      expect(attendance.isIzin, isFalse);

      final toMapResult = attendance.toMap();
      expect(toMapResult['status'], equals('Hadir'));
      expect(toMapResult['sessionId'], equals('session_1'));
    });
  });
}
