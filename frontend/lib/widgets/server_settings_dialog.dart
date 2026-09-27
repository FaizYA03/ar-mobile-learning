import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/server_config_service.dart';

/// Dialog pengaturan URL server + helper pesan error koneksi.
///
/// Dipakai di Login & Register agar IP LAN (HP fisik) bisa diganti
/// tanpa rebuild: `http://<LAN_IP>:8000/api`.
class ServerSettingsDialog {
  static Future<void> show(BuildContext context) async {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    String? testResult;
    bool testing = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> runTest() async {
              setLocal(() {
                testing = true;
                testResult = null;
              });
              final msg = await testConnection(controller.text.trim());
              setLocal(() {
                testing = false;
                testResult = msg;
              });
            }

            return AlertDialog(
              title: const Text('Pengaturan Server'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Production (VPS):\nhttps://api.arlearning.my.id/api\n\nHanya untuk development lokal (tanpa VPS) pakai IP LAN laptop, contoh:\nhttp://192.168.1.10:8000/api',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Base URL API',
                        hintText: 'http://<LAN_IP>:8000/api',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aktif (${ApiConfig.source}): ${ApiConfig.baseUrl}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF637080)),
                    ),
                    if (testing) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Menguji koneksi...',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ],
                    if (testResult != null) ...[
                      const SizedBox(height: 12),
                      Text(testResult!, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
                TextButton(
                  onPressed: testing
                      ? null
                      : () async {
                          await ServerConfigService.clearOverride();
                          controller.text = ApiConfig.baseUrl;
                          setLocal(() {
                            testResult =
                                'Dikembalikan ke default:\n${ApiConfig.baseUrl}';
                          });
                        },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: testing ? null : runTest,
                  child: const Text('Tes'),
                ),
                ElevatedButton(
                  onPressed: testing
                      ? null
                      : () async {
                          final ok = await ServerConfigService.saveOverride(
                              controller.text.trim());
                          if (!ctx.mounted) return;
                          if (!ok) {
                            setLocal(() {
                              testResult =
                                  'Format salah. Contoh valid:\nhttp://192.168.1.10:8000/api';
                            });
                            return;
                          }
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Server diganti ke ${ApiConfig.baseUrl}'),
                              ),
                            );
                          }
                        },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  /// Uji koneksi ke kandidat base URL.
  /// GET `$candidate/login` sengaja dipakai: respons apa pun
  /// (405/422/200) = server reachable; hanya socket/timeout = gagal.
  static Future<String> testConnection(String candidate) async {
    final normalized = ApiConfig.normalizeBaseUrl(candidate);
    if (normalized == null) {
      return 'Format salah. Contoh: http://192.168.1.10:8000/api';
    }
    try {
      final res = await http
          .get(Uri.parse('$normalized/login'))
          .timeout(const Duration(seconds: 8));
      return 'Server reachable (HTTP ${res.statusCode}). Silakan Simpan.';
    } on TimeoutException {
      return 'Timeout: server tidak menjawab dalam 8 dtk. Jika pakai VPS, cek koneksi internet/DNS. Jika development lokal, cek IP & php artisan serve --host=0.0.0.0.';
    } on SocketException catch (e) {
      return 'Tidak bisa tersambung: ${e.message}. Jika pakai VPS pastikan ada koneksi internet (coba buka https://api.arlearning.my.id/up di browser HP).';
    } catch (e) {
      return 'Gagal: $e';
    }
  }

  /// Pesan error login/register yang diagnostik (tidak generik).
  static String friendlyConnectionError(Object e) {
    final base = ApiConfig.baseUrl;
    if (e is TimeoutException) {
      return 'Timeout ke $base. Jika VPS: cek koneksi internet HP. Jika lokal: pastikan `php artisan serve --host=0.0.0.0 --port=8000` berjalan dan HP satu WiFi dengan laptop.';
    }
    if (e is SocketException) {
      // App debug tanpa --dart-define mengarah ke emulator/loopback.
      if (base.contains('10.0.2.2') || base.contains('127.0.0.1')) {
        return 'App mengarah ke $base (bukan VPS). Jalankan dengan flutter run --dart-define=API_BASE_URL=https://api.arlearning.my.id/api, atau ketuk ikon server dan isi URL VPS. Detail: ${e.message}';
      }
      return 'Gagal terhubung ke $base. Jika VPS: cek internet/DNS (coba https://api.arlearning.my.id/up di browser HP). Detail: ${e.message}';
    }
    if (e is FormatException) {
      return 'Respons server tidak valid dari $base. Pastikan backend Laravel berjalan. Detail: ${e.message}';
    }
    if (e is http.ClientException) {
      return 'Gagal terhubung ke $base. Detail: ${e.message}';
    }
    return 'Gagal terhubung ke $base. Pastikan server berjalan. Detail: $e';
  }
}
