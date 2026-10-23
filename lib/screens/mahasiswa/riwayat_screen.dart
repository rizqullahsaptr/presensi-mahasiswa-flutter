import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

class RiwayatScreen extends StatefulWidget {
  final UserModel user;
  const RiwayatScreen({super.key, required this.user});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  @override
  void initState() {
    super.initState();
    // Muat riwayat saat pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MahasiswaProvider>().muatRiwayat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MahasiswaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.muatRiwayat(),
            tooltip: 'Perbarui',
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(MahasiswaProvider provider) {
    final adaData = provider.riwayat.isNotEmpty;

    if (provider.loadingRiwayat && !adaData) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Memuat riwayat kehadiran...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Kegagalan pembacaan dibedakan dari daftar kosong yang sah.
    if (provider.riwayatError && !adaData) {
      return _RiwayatKosong(
        icon: Icons.wifi_off,
        message:
            'Riwayat kehadiran gagal dimuat. Periksa koneksi internet kamu, '
            'lalu coba lagi.',
        actionLabel: 'Coba Lagi',
        onAction: () => provider.muatRiwayat(),
      );
    }

    if (provider.riwayatError && adaData) {
      return Column(
        children: [
          _RiwayatPeringatan(onRetry: () => provider.muatRiwayat()),
          Expanded(child: _RiwayatList(provider: provider)),
        ],
      );
    }

    if (!adaData) {
      return _RiwayatKosong(
        icon: Icons.inbox_outlined,
        message: 'Belum ada riwayat kehadiran.',
        actionLabel: 'Muat Ulang',
        onAction: () => provider.muatRiwayat(),
      );
    }

    return _RiwayatList(
      provider: provider,
      header: provider.loadingRiwayat
          ? const LinearProgressIndicator(minHeight: 3)
          : null,
    );
  }
}

/// Peringatan saat penyegaran gagal padahal data lama masih tersedia.
class _RiwayatPeringatan extends StatelessWidget {
  final VoidCallback onRetry;

  const _RiwayatPeringatan({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Data terbaru gagal dimuat; daftar di bawah adalah data terakhir '
              'yang tersimpan.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

/// Daftar riwayat dengan tarik-untuk-menyegarkan.
class _RiwayatList extends StatelessWidget {
  final MahasiswaProvider provider;
  final Widget? header;

  const _RiwayatList({required this.provider, this.header});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => provider.muatRiwayat(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.riwayat.length + (header == null ? 0 : 1),
        itemBuilder: (context, i) {
          if (header != null) {
            if (i == 0) return header!;
            i -= 1;
          }
          final item = provider.riwayat[i];
          final sess = item['session'] as SessionModel;
          final att = item['attendance'] as AttendanceModel;
          return _RiwayatCard(session: sess, attendance: att);
        },
      ),
    );
  }
}

/// Keadaan kosong atau gagal, selalu menyediakan tindakan coba lagi.
class _RiwayatKosong extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _RiwayatKosong({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _RiwayatCard extends StatelessWidget {
  final SessionModel session;
  final AttendanceModel attendance;

  const _RiwayatCard({required this.session, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusColors.forStatus(attendance.status);
    final waktu = DateTime.fromMillisecondsSinceEpoch(attendance.waktuPresensi);
    final tanggal =
        '${waktu.day.toString().padLeft(2, '0')}/${waktu.month.toString().padLeft(2, '0')}/${waktu.year}';
    final jam =
        '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          session.judulSesi,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.informasiPertemuan,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '$tanggal · $jam',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            attendance.status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
