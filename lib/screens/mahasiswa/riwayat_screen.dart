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
    if (provider.loadingRiwayat) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.riwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada riwayat kehadiran.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => provider.muatRiwayat(),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.muatRiwayat(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: provider.riwayat.length,
        itemBuilder: (context, i) {
          final item = provider.riwayat[i];
          final sess = item['session'] as SessionModel;
          final att = item['attendance'] as AttendanceModel;
          return _RiwayatCard(session: sess, attendance: att);
        },
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
