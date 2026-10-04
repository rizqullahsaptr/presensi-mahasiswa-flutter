import 'dart:math';

/// Generator kode presensi 6 karakter alfanumerik kapital.
/// Contoh: "AB3X7K"
class CodeGenerator {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _rng = Random.secure();

  static String generate({int length = 6}) {
    return List.generate(
      length,
      (_) => _chars[_rng.nextInt(_chars.length)],
    ).join();
  }
}
