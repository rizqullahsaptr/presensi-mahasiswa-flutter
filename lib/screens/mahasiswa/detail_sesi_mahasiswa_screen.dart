import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

/// Detail sesi dari sudut pandang mahasiswa.
/// Menampilkan info sesi + tombol Presensi Sekarang.
class DetailSesiMahasiswaScreen extends StatelessWidget {
  final SessionModel session;
  final String kode;

  const DetailSesiMahasiswaScreen({
    super.key,
    required this.session,
    required this.kode,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();
    final status = provider.presensiStatus;

    if (status == PresensiStatus.berhasil) {
      return _PresensiSuksesScreen(judulSesi: session.judulSesi);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detail Sesi')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sesi Aktif',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.judulSesi,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.informasiPertemuan,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.key_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Kode: ',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          Text(
                            kode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pesan error jika ada
              if (status == PresensiStatus.sudahPresensi)
                _InfoBanner(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  message: 'Kamu sudah melakukan presensi pada sesi ini.',
                )
              else if (status == PresensiStatus.koneksiError)
                _InfoBanner(
                  icon: Icons.wifi_off,
                  color: Colors.grey,
                  message: 'Koneksi gagal. Periksa internet dan coba lagi.',
                ),

              const Spacer(),

              if (status != PresensiStatus.sudahPresensi) ...[
                const Text(
                  'Dengan menekan tombol di bawah, kehadiran kamu akan dicatat sebagai Hadir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: status == PresensiStatus.loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Presensi Sekarang'),
                  onPressed: status == PresensiStatus.loading
                      ? null
                      : () => context.read<MahasiswaProvider>().presensi(kode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PresensiSuksesScreen extends StatelessWidget {
  final String judulSesi;
  const _PresensiSuksesScreen({required this.judulSesi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: StatusColors.hadir,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Presensi Berhasil!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kehadiran kamu pada "$judulSesi" telah tercatat sebagai Hadir.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Kembali ke dashboard (pop 2 screen: detail + lanjut)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
