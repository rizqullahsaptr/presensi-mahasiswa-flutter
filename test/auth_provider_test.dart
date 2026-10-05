import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mahasiswa/models/user_model.dart';
import 'package:presensi_mahasiswa/providers/auth_provider.dart';
import 'package:presensi_mahasiswa/services/auth_service.dart';

class TestFirebaseUser extends Fake implements User {
  TestFirebaseUser(this.uid);
  @override
  final String uid;
}

class FakeAuthService implements AuthService {
  final events = StreamController<User?>.broadcast(sync: true);
  User? signedInUser;
  Future<UserModel?> Function()? readProfile;
  Future<UserModel> Function()? signIn;
  int logoutCount = 0;

  @override
  Stream<User?> get authStateChanges => events.stream;
  @override
  User? get currentUser => signedInUser;
  @override
  Future<UserModel?> getCurrentUserProfile() => readProfile!();
  @override
  Future<UserModel> login(String email, String password) => signIn!();
  @override
  Future<void> logout() async {
    logoutCount++;
    signedInUser = null;
    events.add(null);
  }

  void emit(User? user) {
    signedInUser = user;
    events.add(user);
  }

  Future<void> close() => events.close();
}

const profile = UserModel(
  uid: 'student',
  nama: 'Student',
  email: 'student@example.test',
  identitas: '123',
  role: 'mahasiswa',
);

Future<void> drain() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test(
    'transient profile read error retains signed-in state and reports error',
    () async {
      final service = FakeAuthService();
      service.readProfile = () async =>
          throw Exception('network-request-failed');
      final provider = AuthProvider(service);
      service.emit(TestFirebaseUser('student'));
      await drain();
      expect(provider.status, AuthStatus.unauthenticated);
      expect(service.currentUser, isNotNull);
      expect(provider.errorMessage, 'Koneksi gagal. Periksa internet Anda.');
      expect(service.logoutCount, 0);
      provider.dispose();
      await service.close();
    },
  );

  test('profile read error retains an already loaded profile', () async {
    final service = FakeAuthService();
    service.readProfile = () async => profile;
    final provider = AuthProvider(service);
    service.emit(TestFirebaseUser('student'));
    await drain();
    expect(provider.status, AuthStatus.authenticated);

    service.readProfile = () async => throw Exception('network-request-failed');
    service.emit(TestFirebaseUser('student'));
    await drain();
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user, profile);
    expect(provider.errorMessage, isNotNull);
    expect(service.logoutCount, 0);
    provider.dispose();
    await service.close();
  });

  test('absent profile signs out an authenticated account', () async {
    final service = FakeAuthService();
    service.readProfile = () async => null;
    final provider = AuthProvider(service);
    service.emit(TestFirebaseUser('student'));
    await drain();
    expect(service.logoutCount, 1);
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
    provider.dispose();
    await service.close();
  });

  test('late profile completion cannot overwrite a later sign-out', () async {
    final service = FakeAuthService();
    final pending = Completer<UserModel?>();
    service.readProfile = () => pending.future;
    final provider = AuthProvider(service);
    service.emit(TestFirebaseUser('student'));
    service.emit(null);
    pending.complete(profile);
    await drain();
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
    provider.dispose();
    await service.close();
  });

  test(
    'login result wins over a pending profile read from an earlier auth event',
    () async {
      final service = FakeAuthService();
      final pending = Completer<UserModel?>();
      service.readProfile = () => pending.future;
      final provider = AuthProvider(service);
      service.emit(TestFirebaseUser('student'));
      final signingIn = Completer<UserModel>();
      service.signIn = () => signingIn.future;
      final login = provider.login(
        'student@example.test',
        'not-a-real-password',
      );
      signingIn.complete(profile);
      await login;
      pending.complete(null);
      await drain();
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, profile);
      expect(service.logoutCount, 0);
      provider.dispose();
      await service.close();
    },
  );

  test('sign-out during login does not suppress later auth events', () async {
    final service = FakeAuthService();
    final signingIn = Completer<UserModel>();
    service.signIn = () => signingIn.future;
    service.readProfile = () async => profile;
    final provider = AuthProvider(service);
    final login = provider.login('student@example.test', 'not-a-real-password');
    service.emit(null);
    signingIn.complete(profile);
    await login;
    service.emit(TestFirebaseUser('student'));
    await drain();
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user, profile);
    provider.dispose();
    await service.close();
  });

  test('dispose cancels auth subscription and ignores late fetch', () async {
    final service = FakeAuthService();
    final pending = Completer<UserModel?>();
    service.readProfile = () => pending.future;
    final provider = AuthProvider(service);
    service.emit(TestFirebaseUser('student'));
    provider.dispose();
    pending.complete(profile);
    service.emit(null);
    await drain();
    expect(provider.status, AuthStatus.loading);
    await service.close();
  });
}
