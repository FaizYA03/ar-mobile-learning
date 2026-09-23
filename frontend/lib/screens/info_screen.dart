import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_config_service.dart';

/// Layar Bantuan / Tentang — isi dari CMS (cache), fallback default.
/// Dipakai semua role dari tombol profil yang sebelumnya mati.
class InfoScreen extends StatelessWidget {
  final bool showHelp;

  const InfoScreen.help({super.key}) : showHelp = true;
  const InfoScreen.about({super.key}) : showHelp = false;

  @override
  Widget build(BuildContext context) {
    final config = AppConfigService.config;
    final isHelp = showHelp;
    final title = isHelp ? 'Bantuan' : 'Tentang';
    final body = isHelp
        ? (config?.helpContent.isNotEmpty == true
            ? config!.helpContent
            : 'Belum ada panduan. Hubungi admin melalui kontak di bawah.')
        : (config?.aboutContent.isNotEmpty == true
            ? config!.aboutContent
            : 'AR Mobile Learning — media pembelajaran Informatika berbasis Augmented Reality.');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                body,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Color(0xFF1A1A2E)),
              ),
            ),
            if (isHelp) ...[
              const SizedBox(height: 16),
              _contactCard(
                context,
                icon: Icons.email_outlined,
                label: 'Email',
                value: config?.contactEmail ?? '',
                onTap: () => _openEmail(context, config?.contactEmail ?? ''),
              ),
              const SizedBox(height: 10),
              _contactCard(
                context,
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                value: config?.contactWa ?? '',
                onTap: () => _openWa(context, config?.contactWa ?? ''),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Buka aplikasi email via Intent/URL-scheme.
  /// Gagal (tidak ada app mail) → salin alamat + snackbar.
  static Future<void> _openEmail(BuildContext context, String email) async {
    try {
      if (await launchUrl(Uri(scheme: 'mailto', path: email))) return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tidak bisa membuka email, alamat disalin.')),
      );
    }
  }

  /// Buka chat WhatsApp. Gagal (WA tidak terinstal) → salin nomor.
  /// Pure helper untuk nomor agar bisa di-unit-test.
  static String waUrl(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return 'https://wa.me/$digits';
  }

  static Future<void> _openWa(BuildContext context, String number) async {
    try {
      if (await launchUrl(Uri.parse(waUrl(number)),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: number));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('WhatsApp tidak ditemukan, nomor disalin.')),
      );
    }
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0A8477)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF637080))),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const Text('Ketuk untuk membuka',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0A8477))),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: Color(0xFFB0B8C1)),
          ],
        ),
      ),
    );
  }
}
