import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import 'detail_sesi_dosen_screen.dart';

class BuatSesiScreen extends StatefulWidget {
  const BuatSesiScreen({super.key});

  @override
  State<BuatSesiScreen> createState() => _BuatSesiScreenState();
}

class _BuatSesiScreenState extends State<BuatSesiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _infoCtrl = TextEditingController();

  @override
  void dispose() {
    _judulCtrl.dispose();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final provider = context.read<DosenProvider>();
    final sesi = await provider.buatSesi(
      judulSesi: _judulCtrl.text.trim(),
      informasiPertemuan: _infoCtrl.text.trim(),
    );

    if (!mounted) return;

    if (sesi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal membuat sesi.'),
          backgroundColor: Colors.red,
        ),
      );
      provider.clearError();
      return;
    }

    // Langsung navigasi ke detail sesi yang baru dibuat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: DetailSesiDosenScreen(sessionId: sesi.sessionId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DosenProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Buat Sesi Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Isi informasi sesi presensi yang akan dibuat.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _judulCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Judul Sesi',
                    hintText: 'Contoh: Pemrograman Web — Pertemuan 5',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: Validators.judulSesi,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _infoCtrl,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Informasi Pertemuan',
                    hintText: 'Contoh: Rabu, 8 Oktober 2026 — Kelas H Mobile Programming',
                    prefixIcon: Icon(Icons.info_outline),
                    alignLabelWithHint: true,
                  ),
                  validator: Validators.informasiPertemuan,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: provider.loadingBuatSesi ? null : _submit,
                  child: provider.loadingBuatSesi
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Buat Sesi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
