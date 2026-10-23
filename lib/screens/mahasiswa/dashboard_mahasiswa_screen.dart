import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'detail_sesi_mahasiswa_screen.dart';

class DashboardMahasiswaScreen extends StatefulWidget {
  final UserModel user;

  /// Pintasan menuju tab Riwayat Kehadiran pada shell mahasiswa.
  /// Dua responden uji kegunaan tidak menemukan menu Riwayat sendiri,
  /// sehingga pintasan ini ditambahkan pada beranda tanpa membuat fitur baru.
  final VoidCallback? onBukaRiwayat;

  const DashboardMahasiswaScreen({
    super.key,
    required this.user,
    this.onBukaRiwayat,
  });

  @override
  State<DashboardMahasiswaScreen> createState() =>
      _DashboardMahasiswaScreenState();
}

class _DashboardMahasiswaScreenState extends State<DashboardMahasiswaScreen> {
  final _kodeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _kodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cariSesi() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<MahasiswaProvider>();
    await provider.cariSesi(_kodeCtrl.text.trim().toUpperCase());

    if (!mounted) return;
    final status = provider.presensiStatus;
    final sesi = provider.sesiDitemukan;

    if (status == PresensiStatus.idle && sesi != null) {
      // Kode valid & sesi aktif — buka detail sesi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: DetailSesiMahasiswaScreen(
              session: sesi,
              kode: _kodeCtrl.text.trim().toUpperCase(),
            ),
          ),
        ),
      ).then((_) {
        provider.resetPresensiStatus();
        _kodeCtrl.clear();
      });
    } else {
      _showStatusDialog(status, sesi?.judulSesi);
    }
  }

  void _showStatusDialog(PresensiStatus status, String? judulSesi) {
    String title, message;
    IconData icon;
    Color iconColor;

    switch (status) {
      case PresensiStatus.kodeError:
        title = 'Kode Tidak Ditemukan';
        message =
            'Kode yang kamu masukkan tidak valid. Kode presensi terdiri dari '
            '6 karakter huruf atau angka, misalnya AB3X7K. Periksa kembali '
            'kode dari dosen.';
        icon = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case PresensiStatus.sesiTidakAktif:
        title = 'Sesi Sudah Ditutup';
        message = judulSesi != null
            ? 'Sesi "$judulSesi" sudah ditutup oleh dosen, sehingga kodenya '
                  'tidak dapat dipakai lagi. Hubungi dosen bila kamu perlu '
                  'mencatat kehadiran.'
            : 'Sesi sudah ditutup oleh dosen, sehingga kodenya tidak dapat '
                  'dipakai lagi. Hubungi dosen bila kamu perlu mencatat '
                  'kehadiran.';
        icon = Icons.lock_outline;
        iconColor = Colors.orange;
        break;
      case PresensiStatus.koneksiError:
        title = 'Koneksi Gagal';
        message =
            'Tidak dapat terhubung ke server. Periksa koneksi internet kamu, '
            'lalu tekan Coba Lagi.';
        icon = Icons.wifi_off;
        iconColor = Colors.grey;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          if (status == PresensiStatus.koneksiError)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<MahasiswaProvider>().resetPresensiStatus();
                _cariSesi();
              },
              child: const Text('Coba Lagi'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MahasiswaProvider>().resetPresensiStatus();
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();
    final isLoading = provider.presensiStatus == PresensiStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  widget.user.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info mahasiswa
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.user.identitas,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Pintasan menuju Riwayat Kehadiran — selalu terlihat pada
              // beranda. Dua responden uji kegunaan tidak menemukan menu
              // Riwayat sendiri pada bilah navigasi bawah.
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.history, color: AppTheme.primary),
                  ),
                  title: const Text(
                    'Riwayat Kehadiran',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Lihat catatan presensi kamu pada sesi sebelumnya.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onBukaRiwayat,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Masukkan Kode Presensi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Kode terdiri dari 6 karakter huruf atau angka. Minta kode dari '
                'dosen pengampu kelas, lalu tekan Cari Sesi.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),

              Form(
                key: _formKey,
                // Pesan validasi mengikuti isi kolom terbaru, sehingga
                // peringatan tidak tertinggal pada kolom yang sudah diisi.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  controller: _kodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _cariSesi(),
                  style: const TextStyle(
                    letterSpacing: 4,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Kode Presensi',
                    hintText: 'AB3X7K',
                    helperText: '6 karakter, contoh: AB3X7K',
                    hintStyle: TextStyle(
                      letterSpacing: 2,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: Validators.kodePresensi,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _cariSesi,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Cari Sesi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
