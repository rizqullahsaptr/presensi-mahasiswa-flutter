import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:presensi_mahasiswa/models/session_model.dart';
import 'package:presensi_mahasiswa/models/user_model.dart';
import 'package:presensi_mahasiswa/providers/session_provider.dart';
import 'package:presensi_mahasiswa/screens/mahasiswa/dashboard_mahasiswa_screen.dart';
import 'package:presensi_mahasiswa/screens/dosen/buat_sesi_screen.dart';
import 'package:presensi_mahasiswa/services/session_service.dart';
import 'package:presensi_mahasiswa/theme/app_theme.dart';

const student = UserModel(
  uid: 'u-mahasiswa',
  nama: 'Mahasiswa Demo',
  email: 'mahasiswa@example.test',
  identitas: 'M001',
  role: 'mahasiswa',
);

const dosen = UserModel(
  uid: 'u-dosen',
  nama: 'Dosen Demo',
  email: 'dosen@example.test',
  identitas: 'D001',
  role: 'dosen',
);

class FakeSessionService extends SessionService {
  FakeSessionService() : super.withReaderForTesting((_) async => null);

  @override
  Future<SessionModel?> cariSesiDenganKode(String kode) async => null;
}

void main() {
  testWidgets('pesan validasi kode hilang setelah kolom diisi', (tester) async {
    final provider = MahasiswaProvider(FakeSessionService(), student);
    await tester.pumpWidget(
      ChangeNotifierProvider<MahasiswaProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: const DashboardMahasiswaScreen(user: student),
        ),
      ),
    );

    // Kirim form kosong -> pesan validasi muncul.
    await tester.tap(find.text('Cari Sesi'));
    await tester.pumpAndSettle();
    expect(find.text('Kode presensi tidak boleh kosong'), findsOneWidget);

    // Isi kolom -> pesan harus hilang tanpa menekan tombol lagi.
    await tester.enterText(find.byType(TextFormField), 'AB3X7K');
    await tester.pumpAndSettle();
    expect(find.text('Kode presensi tidak boleh kosong'), findsNothing);

    // Kosongkan lagi -> pesan muncul kembali.
    await tester.enterText(find.byType(TextFormField), '');
    await tester.pumpAndSettle();
    expect(find.text('Kode presensi tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('pesan validasi judul sesi hilang setelah kolom diisi', (
    tester,
  ) async {
    final provider = DosenProvider(FakeSessionService(), dosen);
    await tester.pumpWidget(
      ChangeNotifierProvider<DosenProvider>.value(
        value: provider,
        child: MaterialApp(theme: AppTheme.theme, home: const BuatSesiScreen()),
      ),
    );

    await tester.tap(find.text('Buat Sesi'));
    await tester.pumpAndSettle();
    expect(find.text('Judul sesi tidak boleh kosong'), findsOneWidget);
    expect(find.text('Informasi pertemuan tidak boleh kosong'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Praktikum RC03');
    await tester.pumpAndSettle();
    expect(find.text('Judul sesi tidak boleh kosong'), findsNothing);
    // Kolom kedua belum diisi, jadi pesannya tetap tampil.
    expect(find.text('Informasi pertemuan tidak boleh kosong'), findsOneWidget);
  });
}
