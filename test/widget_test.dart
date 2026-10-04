import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_mahasiswa/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  test('AppTheme palet warna dan status konsisten dengan Tahap 2', () {
    expect(StatusColors.hadir, equals(const Color(0xFF2E7D32)));
    expect(StatusColors.izin, equals(const Color(0xFF1565C0)));
    expect(StatusColors.sakit, equals(const Color(0xFFF57F17)));
    expect(StatusColors.alpha, equals(const Color(0xFFC62828)));

    expect(StatusColors.forStatus('Hadir'), equals(StatusColors.hadir));
    expect(StatusColors.forStatus('Izin'), equals(StatusColors.izin));
    expect(StatusColors.forStatus('Sakit'), equals(StatusColors.sakit));
    expect(StatusColors.forStatus('Alpha'), equals(StatusColors.alpha));
    // Default fallback untuk status tidak dikenal adalah alpha
    expect(StatusColors.forStatus('unknown'), equals(StatusColors.alpha));
  });
}
