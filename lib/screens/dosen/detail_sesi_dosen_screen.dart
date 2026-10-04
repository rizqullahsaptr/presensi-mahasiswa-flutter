import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/session_model.dart';
import '../../models/attendance_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

class DetailSesiDosenScreen extends StatelessWidget {
  final String sessionId;
  const DetailSesiDosenScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detail Sesi')),
      body: StreamBuilder<SessionModel?>(
        stream: provider.streamDetailSesi(sessionId),
        builder: (context, sessSnap) {
          if (sessSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = sessSnap.data;
          if (session == null) {
            return const Center(child: Text('Sesi tidak ditemukan.'));
          }
          return _DetailBody(session: session, provider: provider);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final SessionModel session;
  final DosenProvider provider;
  const _DetailBody({required this.session, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info sesi + kode
        _SesiInfoCard(session: session, provider: provider),

        // Daftar mahasiswa
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Daftar Kehadiran',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<AttendanceEntry>>(
            stream: provider.streamKehadiran(session.sessionId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat: ${snap.error}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              final entries = snap.data ?? [];
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada mahasiswa terdaftar.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: entries.length,
                itemBuilder: (ctx, i) => _MahasiswaRow(
                  entry: entries[i],
                  session: session,
                  provider: provider,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SesiInfoCard extends StatelessWidget {
  final SessionModel session;
  final DosenProvider provider;
  const _SesiInfoCard({required this.session, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isAktif = session.isAktif;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.judulSesi,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.informasiPertemuan,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAktif
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAktif
                          ? Colors.green.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: isAktif ? Colors.green : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAktif ? 'Aktif' : 'Ditutup',
                        style: TextStyle(
                          color: isAktif
                              ? Colors.green.shade700
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Kode presensi — hanya tampil saat sesi aktif
            if (isAktif) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kode Presensi',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          session.kodePresensi,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.primary),
                      tooltip: 'Salin kode',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: session.kodePresensi),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kode disalin'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Tombol buka/tutup sesi
            if (!isAktif)
              ElevatedButton.icon(
                icon: provider.loadingAksi
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Buka Sesi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: provider.loadingAksi
                    ? null
                    : () => provider.bukaSesi(session.sessionId),
              )
            else
              OutlinedButton.icon(
                icon: provider.loadingAksi
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_circle_outlined, color: Colors.red),
                label: const Text(
                  'Tutup Sesi',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: provider.loadingAksi
                    ? null
                    : () => _confirmTutup(context),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmTutup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tutup Sesi'),
        content: const Text(
          'Setelah ditutup, kode tidak dapat digunakan lagi. Yakin menutup sesi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.tutupSesi(session.sessionId);
            },
            child: const Text('Tutup', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MahasiswaRow extends StatelessWidget {
  final AttendanceEntry entry;
  final SessionModel session;
  final DosenProvider provider;

  const _MahasiswaRow({
    required this.entry,
    required this.session,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusColors.forStatus(entry.status);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          entry.nama,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          entry.identitas,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                entry.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Koreksi hanya tersedia saat sesi aktif
            if (session.isAktif)
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                tooltip: 'Koreksi Status',
                onPressed: () => _showKoreksiDialog(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showKoreksiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _KoreksiStatusDialog(
        entry: entry,
        session: session,
        provider: provider,
      ),
    );
  }
}

class _KoreksiStatusDialog extends StatefulWidget {
  final AttendanceEntry entry;
  final SessionModel session;
  final DosenProvider provider;

  const _KoreksiStatusDialog({
    required this.entry,
    required this.session,
    required this.provider,
  });

  @override
  State<_KoreksiStatusDialog> createState() => _KoreksiStatusDialogState();
}

class _KoreksiStatusDialogState extends State<_KoreksiStatusDialog> {
  late String _selected;
  bool _loading = false;

  final _options = ['Hadir', 'Izin', 'Sakit', 'Alpha'];

  @override
  void initState() {
    super.initState();
    _selected = widget.entry.status;
  }

  Future<void> _simpan() async {
    setState(() => _loading = true);
    final ok = await widget.provider.koreksiStatus(
      sessionId: widget.session.sessionId,
      studentId: widget.entry.studentId,
      status: _selected,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status ${widget.entry.nama} diubah menjadi $_selected.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan koreksi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Koreksi Status — ${widget.entry.nama}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options
            .map(
              (s) =>
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: Text(
                      s,
                      style: TextStyle(
                        color: StatusColors.forStatus(s),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: s,
                    // ignore: deprecated_member_use
                    groupValue: _selected,
                    // ignore: deprecated_member_use
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _selected = v!),
                  ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _simpan,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
