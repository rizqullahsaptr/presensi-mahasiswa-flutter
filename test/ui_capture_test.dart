import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:presensi_mahasiswa/models/attendance_model.dart';
import 'package:presensi_mahasiswa/models/session_model.dart';
import 'package:presensi_mahasiswa/models/user_model.dart';
import 'package:presensi_mahasiswa/providers/auth_provider.dart';
import 'package:presensi_mahasiswa/providers/session_provider.dart';
import 'package:presensi_mahasiswa/screens/auth/login_screen.dart';
import 'package:presensi_mahasiswa/screens/dosen/buat_sesi_screen.dart';
import 'package:presensi_mahasiswa/screens/dosen/dashboard_dosen_screen.dart';
import 'package:presensi_mahasiswa/screens/dosen/detail_sesi_dosen_screen.dart';
import 'package:presensi_mahasiswa/screens/mahasiswa/dashboard_mahasiswa_screen.dart';
import 'package:presensi_mahasiswa/screens/mahasiswa/riwayat_screen.dart';
import 'package:presensi_mahasiswa/services/session_service.dart';
import 'package:presensi_mahasiswa/theme/app_theme.dart';

// Deterministic, invented demonstration records. These are NOT Firebase results.
const lecturer = UserModel(
  uid: 'demo-dosen',
  nama: 'Dr. Rina Pratama',
  email: 'rina@example.test',
  identitas: 'Dosen · IF-2026',
  role: 'dosen',
);
const student = UserModel(
  uid: 'demo-mahasiswa',
  nama: 'Alya Putri',
  email: 'alya@example.test',
  identitas: '2310114001',
  role: 'mahasiswa',
);
const active = SessionModel(
  sessionId: 'demo-sesi-1',
  judulSesi: 'Mobile Programming',
  informasiPertemuan: 'Pertemuan 5 · Flutter dan Firebase',
  lecturerId: 'demo-dosen',
  kodePresensi: 'AB3X7K',
  status: 'aktif',
  waktuDibuat: 1791158400000,
  waktuDibuka: 1791159000000,
);
const closed = SessionModel(
  sessionId: 'demo-sesi-2',
  judulSesi: 'Basis Data',
  informasiPertemuan: 'Pertemuan 4 · Query SQL',
  lecturerId: 'demo-dosen',
  kodePresensi: 'ZX8P2Q',
  status: 'ditutup',
  waktuDibuat: 1791072000000,
  waktuDibuka: 1791072600000,
  waktuDitutup: 1791076200000,
);
const roster = <AttendanceEntry>[
  AttendanceEntry(
    studentId: 'demo-mahasiswa',
    nama: 'Alya Putri',
    identitas: '2310114001',
    status: 'Hadir',
    hasCatatan: true,
  ),
  AttendanceEntry(
    studentId: 'demo-bima',
    nama: 'Bima Santoso',
    identitas: '2310114002',
    status: 'Izin',
    hasCatatan: true,
  ),
  AttendanceEntry(
    studentId: 'demo-citra',
    nama: 'Citra Rahma',
    identitas: '2310114003',
    status: 'Sakit',
    hasCatatan: true,
  ),
  AttendanceEntry(
    studentId: 'demo-dani',
    nama: 'Dani Saputra',
    identitas: '2310114004',
    status: 'Alpha',
    hasCatatan: false,
  ),
];

class CaptureSessionService extends SessionService {
  CaptureSessionService() : super.withReaderForTesting((_) async => null);

  // Stable stream identities prevent StreamBuilder resubscription loops.
  final _sessions = Stream<List<SessionModel>>.value([active, closed]);
  final _details = <String, Stream<SessionModel?>>{};
  final _rosters = <String, Stream<List<AttendanceEntry>>>{};

  @override
  Stream<List<SessionModel>> streamSesiDosen(String lecturerId) => _sessions;

  @override
  Stream<SessionModel?> streamSesi(String sessionId) => _details.putIfAbsent(
    sessionId,
    () => Stream.value(sessionId == closed.sessionId ? closed : active),
  );

  @override
  Stream<List<AttendanceEntry>> streamKehadiranSesi(String sessionId) =>
      _rosters.putIfAbsent(sessionId, () => Stream.value(roster));

  @override
  Future<List<Map<String, dynamic>>> getRiwayatMahasiswa(
    String studentId,
  ) async => [
    {
      'session': closed,
      'attendance': const AttendanceModel(
        sessionId: 'demo-sesi-2',
        studentId: 'demo-mahasiswa',
        status: 'Hadir',
        waktuPresensi: 1791073500000,
      ),
    },
    {
      'session': active,
      'attendance': const AttendanceModel(
        sessionId: 'demo-sesi-1',
        studentId: 'demo-mahasiswa',
        status: 'Izin',
        waktuPresensi: 1791159900000,
      ),
    },
  ];

  @override
  Future<SessionModel?> cariSesiDenganKode(String kode) async =>
      kode == active.kodePresensi ? active : null;

  @override
  Future<String> presensi({
    required String kodeInput,
    required String studentId,
  }) async => 'berhasil';
}

// LoginScreen reads AuthProvider, but constructing AuthService contacts Firebase.
// Implement its UI-facing contract here instead of initializing Firebase.
class CaptureAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  AuthStatus get status => AuthStatus.unauthenticated;
  @override
  UserModel? get user => null;
  @override
  String? get errorMessage => null;
  @override
  bool get isLoading => false;
  @override
  Future<void> login(String email, String password) async {}
  @override
  Future<void> logout() async {}
}

Future<void> loadCaptureFonts() async {
  // flutter_test uses Ahem by default; load real Flutter text and icon fonts.
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? 'C:/src/flutter/flutter';
  final fonts = <(String, String)>[
    (
      'Roboto',
      '$sdk/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/Roboto/Roboto-Regular.ttf',
    ),
    (
      'MaterialIcons',
      '$sdk/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf',
    ),
  ];
  for (final (family, path) in fonts) {
    final loader = FontLoader(family);
    final data = File(path).readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.sublistView(Uint8List.fromList(data))),
    );
    await loader.load();
  }
}

void main() {
  final captures = <(String, String)>[
    ('01-login', 'PresensiIN'),
    ('02-lecturer-dashboard', 'Buat Sesi Baru'),
    ('03-session-form', 'Judul Sesi'),
    ('04-active-detail-code', 'AB3X7K'),
    ('05-attendance-roster-status', 'Koreksi Status — Alya Putri'),
    ('06-student-dashboard', 'Masukkan Kode Presensi'),
    ('07-code-entry', 'Cari Sesi'),
    ('08-history', 'Riwayat Kehadiran'),
    ('09-closed-detail', 'Ditutup'),
    ('10-validation', 'Kode presensi tidak boleh kosong'),
  ];
  for (final (name, visibleText) in captures) {
    testWidgets('render production widget: $name', (tester) async {
      await loadCaptureFonts();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final service = CaptureSessionService();
      final dosen = DosenProvider(service, lecturer);
      final mahasiswa = MahasiswaProvider(service, student);
      final auth = CaptureAuthProvider();
      final key = GlobalKey();

      Widget child;
      switch (name) {
        case '01-login':
          child = ChangeNotifierProvider<AuthProvider>.value(
            value: auth,
            child: const LoginScreen(),
          );
        case '02-lecturer-dashboard':
          child = ChangeNotifierProvider<DosenProvider>.value(
            value: dosen,
            child: const DashboardDosenScreen(user: lecturer),
          );
        case '03-session-form':
          child = ChangeNotifierProvider<DosenProvider>.value(
            value: dosen,
            child: const BuatSesiScreen(),
          );
        case '04-active-detail-code':
        case '05-attendance-roster-status':
          child = ChangeNotifierProvider<DosenProvider>.value(
            value: dosen,
            child: const DetailSesiDosenScreen(sessionId: 'demo-sesi-1'),
          );
        case '06-student-dashboard':
        case '07-code-entry':
        case '10-validation':
          child = ChangeNotifierProvider<MahasiswaProvider>.value(
            value: mahasiswa,
            child: const DashboardMahasiswaScreen(user: student),
          );
        case '08-history':
          child = ChangeNotifierProvider<MahasiswaProvider>.value(
            value: mahasiswa,
            child: const RiwayatScreen(user: student),
          );
        default:
          child = ChangeNotifierProvider<DosenProvider>.value(
            value: dosen,
            child: const DetailSesiDosenScreen(sessionId: 'demo-sesi-2'),
          );
      }

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: AppTheme.theme.copyWith(
              textTheme: AppTheme.theme.textTheme.apply(fontFamily: 'Roboto'),
              primaryTextTheme: AppTheme.theme.primaryTextTheme.apply(
                fontFamily: 'Roboto',
              ),
            ),
            home: child,
            debugShowCheckedModeBanner: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      if (name == '05-attendance-roster-status') {
        await tester.tap(find.byTooltip('Koreksi Status').first);
        await tester.pumpAndSettle();
      } else if (name == '07-code-entry') {
        await tester.enterText(find.byType(TextFormField), 'AB3X7K');
        await tester.pump();
      } else if (name == '10-validation') {
        await tester.tap(find.text('Cari Sesi'));
        await tester.pumpAndSettle();
      }
      expect(find.text(visibleText), findsWidgets);
      if (name == '10-validation') {
        final error = tester.getRect(find.text(visibleText));
        expect(error.top, lessThan(844));
        expect(error.bottom, lessThan(844));
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      expect(boundary.size, const Size(390, 844));
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes, isNotNull);
        final images = Directory('deliverables/screenshots')
          ..createSync(recursive: true);
        File('${images.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      debugPrint('CAPTURED $name');
    });
  }
}
