import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import 'buat_sesi_screen.dart';
import 'detail_sesi_dosen_screen.dart';

class DashboardDosenScreen extends StatelessWidget {
  final UserModel user;
  const DashboardDosenScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard Dosen'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  user.nama,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info dosen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nama,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.identitas,
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
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Buat Sesi Baru'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const BuatSesiScreen(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sesi Terbaru',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Daftar sesi (stream, max 5 terbaru di dashboard)
            Expanded(
              child: StreamBuilder<List<SessionModel>>(
                stream: provider.streamSesi,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Koneksi gagal: ${snap.error}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  final list = (snap.data ?? []).take(5).toList();
                  if (list.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada sesi.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _SesiCard(
                      session: list[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: provider,
                            child: DetailSesiDosenScreen(
                              sessionId: list[i].sessionId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SesiCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onTap;
  const _SesiCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAktif = session.isAktif;
    final statusColor = isAktif ? Colors.green : AppTheme.textSecondary;
    final statusLabel = isAktif ? 'Aktif' : 'Ditutup';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          session.judulSesi,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          session.informasiPertemuan,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
