import 'package:flutter/material.dart';
import '../core/debug/ar_debug_log.dart';
import '../services/ar_content_resolver.dart';
import '../services/ar_diagnostics_service.dart';
import 'model_viewer_screen.dart';

class ArDiagnosticScreen extends StatefulWidget {
  const ArDiagnosticScreen({super.key});

  @override
  State<ArDiagnosticScreen> createState() => _ArDiagnosticScreenState();
}

class _ArDiagnosticScreenState extends State<ArDiagnosticScreen> {
  late Future<ArDiagnosticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = ArDiagnosticsService.collect();
  }

  void _retry() {
    setState(() {
      _future = ArDiagnosticsService.collect();
    });
  }

  Future<void> _open3dViewer() async {
    final items = ArContentResolver.content;
    if (items.isEmpty) {
      _showMessage('Belum ada konten AR yang tersinkron.');
      return;
    }
    final item = items.first;
    final url = await ArContentResolver.resolveModelUrl(item.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelViewerScreen(
          modelUrl: url,
          modelName: item.modelName,
          hotspots: item.hotspots,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Diagnostik AR',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<ArDiagnosticsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState();
          }
          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFC62828)),
          const SizedBox(height: 12),
          const Text(
            'Gagal mengumpulkan diagnostik.',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Ulangi'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ArDiagnosticsData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummary(data),
          const SizedBox(height: 16),
          _buildInfoCard(data),
          const SizedBox(height: 16),
          _buildLogCard(),
          const SizedBox(height: 16),
          _buildActionCard(),
          const SizedBox(height: 16),
          _buildSupportCard(),
        ],
      ),
    );
  }

  Widget _buildSummary(ArDiagnosticsData data) {
    final color =
        data.isArReady ? const Color(0xFF0A8477) : const Color(0xFFF9A825);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            data.isArReady ? Icons.view_in_ar : Icons.adb,
            size: 32,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.isArReady ? 'Mode AR siap digunakan' : 'AR tidak siap',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.isArReady
                      ? 'Perangkat mendukung ARCore dan izin kamera tersedia.'
                      : 'Perangkat belum siap menjalankan AR. Gunakan mode 3D sebagai alternatif.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF637080),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ArDiagnosticsData data) {
    final device = data.deviceInfo;
    return _card(
      title: 'Informasi Perangkat & AR',
      children: [
        _row(
          'Device',
          device == null
              ? 'Tidak terdeteksi'
              : '${device.manufacturer} ${device.model}',
        ),
        _row(
          'Android / API',
          device == null
              ? 'Unknown'
              : '${device.androidVersion} (API ${device.sdkInt})',
        ),
        _row(
          'Camera Permission',
          data.cameraPermissionGranted ? 'Granted' : 'Not granted',
          valueColor: data.cameraPermissionGranted
              ? const Color(0xFF0A8477)
              : const Color(0xFFC62828),
        ),
        _row('ARCore State', data.arCoreLabel),
        _row(
          'AR Session',
          data.isArReady ? 'READY' : 'BLOCKED',
          valueColor: data.isArReady
              ? const Color(0xFF0A8477)
              : const Color(0xFFF9A825),
        ),
        _row('Image Targets', '${data.activeMarkerCount} marker aktif'),
        _row('AR Content Count', '${data.arContentCount} model'),
        _row('Cache Models', '${data.cachedModelCount} GLB'),
        _row('Cache Markers', '${data.cachedMarkerCount} gambar'),
        _row(
          'API Status',
          data.apiStatus,
          valueColor: data.apiStatus == 'online'
              ? const Color(0xFF0A8477)
              : const Color(0xFFC62828),
        ),
        _row(
          'Content Version',
          'lokal ${data.localContentVersion} / remote ${data.remoteContentVersion}',
          valueColor: data.localContentVersion == data.remoteContentVersion
              ? const Color(0xFF0A8477)
              : const Color(0xFFF9A825),
        ),
        _row(
          'Last Sync',
          data.lastSync == null ? 'Belum pernah' : _formatTime(data.lastSync!),
        ),
        if (data.syncErrors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.syncErrors
                  .map(
                    (e) => Text(
                      '⚠ $e',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC62828),
                        height: 1.3,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLogCard() {
    final entries = ArDebugLog.entries;
    return _card(
      title: 'Log AR (debug)',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              ArDebugLog.clear();
              setState(() {});
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
      children: entries.isEmpty
          ? const [
              Text(
                'Belum ada log AR.',
                style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1)),
              ),
            ]
          : [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Color(0xFF8BFAAD),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
    );
  }

  Widget _buildActionCard() {
    return _card(
      title: 'Tindakan',
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Ulangi Pemeriksaan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _open3dViewer,
                icon: const Icon(Icons.view_in_ar),
                label: const Text('Buka Model 3D'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportCard() {
    return _card(
      title: 'Catatan',
      children: const [
        Text(
          'Jika ARCore menampilkan SUPPORTED_NOT_INSTALLED, silakan instal '
          'Google Play Services for AR, lalu ulangi pemeriksaan. '
          'Jika perangkat tidak mendukung ARCore, gunakan mode 3D interaktif.',
          style: TextStyle(fontSize: 12, color: Color(0xFF637080), height: 1.4),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color valueColor = const Color(0xFF101426),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF637080),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
