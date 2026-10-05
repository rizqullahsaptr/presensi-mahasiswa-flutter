import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mahasiswa/services/session_service.dart';

void main() {
  test(
    'roster follows attendance-only and users-only changes, then cancels both',
    () async {
      final users = StreamController<Object?>.broadcast(sync: true);
      final attendance = StreamController<Object?>.broadcast(sync: true);
      final watchedPaths = <String>[];
      final service = SessionService.withRosterSourcesForTesting((path) {
        watchedPaths.add(path);
        if (path == 'users') return users.stream;
        if (path == 'attendance/s1') return attendance.stream;
        throw StateError('Unexpected watch: $path');
      });
      final iterator = StreamIterator(service.streamKehadiranSesi('s1'));
      addTearDown(() async {
        await iterator.cancel();
        await users.close();
        await attendance.close();
      });

      final initial = iterator.moveNext();
      users.add({
        'u1': {'nama': 'Budi', 'identitas': '123', 'role': 'mahasiswa'},
      });
      attendance.add(null);
      expect(await initial.timeout(const Duration(seconds: 2)), isTrue);
      expect(iterator.current.single.status, 'Alpha');
      expect(iterator.current.single.hasCatatan, isFalse);

      final afterAttendance = iterator.moveNext();
      attendance.add({
        'u1': {'status': 'Hadir'},
      });
      expect(await afterAttendance.timeout(const Duration(seconds: 2)), isTrue);
      expect(iterator.current.single.status, 'Hadir');
      expect(iterator.current.single.hasCatatan, isTrue);

      final afterUsers = iterator.moveNext();
      users.add({
        'u1': {'nama': 'Budi Baru', 'identitas': '456', 'role': 'mahasiswa'},
      });
      expect(await afterUsers.timeout(const Duration(seconds: 2)), isTrue);
      expect(iterator.current.single.nama, 'Budi Baru');
      expect(iterator.current.single.identitas, '456');
      expect(iterator.current.single.status, 'Hadir');

      expect(watchedPaths, ['users', 'attendance/s1']);
      await iterator.cancel();
      expect(users.hasListener, isFalse);
      expect(attendance.hasListener, isFalse);
    },
  );
}
