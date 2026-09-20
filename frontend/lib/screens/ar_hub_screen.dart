import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/ar_service.dart';
import '../services/ar_content_resolver.dart';
import '../services/content_sync_service.dart';
import 'ar_diagnostic_screen.dart';
import 'ar_scanner_screen.dart';
import 'ar_uco_scanner_screen.dart';
import 'model_viewer_screen.dart';

class ArHubScreen extends StatefulWidget {
  const ArHubScreen({super.key});

  @override
  State<ArHubScreen> createState() => _ArHubScreenState();
}

class _ArHubScreenState extends State<ArHubScreen> {
  List<ArContentItem> _models = [];
  bool _isLoading = true;
  ArCoreAvailability _availability = ArCoreAvailability.unknown;
  bool _isSyncing = false;
  String _syncStatus = '';

  bool get _isAR => _availability == ArCoreAvailability.supportedInstalled;

  @override
  void initState() {
    super.initState();
    _detectARSupport();
    _loadModels();
  }

  Future<void> _detectARSupport() async {
    final availability = await ARService.checkAvailability();
    if (mounted) setState(() => _availability = availability);
  }

  Future<void> _loadModels() async {
    setState(() => _isLoading = true);

    if (!ArContentResolver.isContentLoaded) {
      await ArContentResolver.refreshContent();
    }

    if (mounted) {
      setState(() {
        _models = ArContentResolver.content;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncContent() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'Menyinkronkan konten...';
    });

    try {
      final result = await ContentSyncService.sync();
      await ContentSyncService.applyDownloads(
        result,
        onProgress: (completed, total, assetType) {
          if (mounted) {
            setState(() {
              _syncStatus = 'Mengunduh aset $completed/$total ($assetType)...';
            });
          }
        },
      );
      await ArContentResolver.refreshContent();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'content_last_sync', DateTime.now().millisecondsSinceEpoch);
      if (result.manifest != null) {
        final modelCount =
            result.manifest!.items.where((i) => i.assetType == 'model').length;
        await prefs.setInt('cached_ar_model_count', modelCount);
      }

      if (mounted) {
        setState(() {
          _models = ArContentResolver.content;
          _isSyncing = false;
          if (result.status == SyncStatus.upToDate) {
            _syncStatus = 'Konten sudah terbaru';
          } else if (result.status == SyncStatus.needsUpdate) {
            _syncStatus = 'Diperbarui: ${result.downloadedAssets} aset';
          } else {
            _syncStatus = result.error ?? 'Sinkronisasi gagal';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Gagal menyinkronkan';
        });
      }
    }
  }

  String _resolveModelUrl(ArContentItem model) {
    final base = ApiService.baseUrl.replaceFirst('/api', '');
    if (model.glbUrl != null && model.glbUrl!.isNotEmpty) {
      final url = model.glbUrl!;
      if (url.startsWith('http')) return url;
      if (url.startsWith('/')) return '$base$url';
      return '$base/storage/$url';
    }
    if (model.glbPath != null && model.glbPath!.isNotEmpty) {
      return '$base/storage/${model.glbPath}';
    }
    return '';
  }

  String _resolveImageUrl(ArContentItem model) {
    final base = ApiService.baseUrl.replaceFirst('/api', '');
    if (model.thumbnailUrl != null && model.thumbnailUrl!.isNotEmpty) {
      final url = model.thumbnailUrl!;
      if (url.startsWith('http')) return url;
      if (url.startsWith('/')) return '$base$url';
      return '$base/storage/$url';
    }
    if (model.thumbnailPath != null && model.thumbnailPath!.isNotEmpty) {
      return '$base/storage/${model.thumbnailPath}';
    }
    return '';
  }

  Future<void> _openModel(ArContentItem model) async {
    final url = _resolveModelUrl(model);
    if (url.isEmpty) return;

    final localPath = await ContentSyncService.getCachedModelPath(model.id);
    final displayUrl = localPath ?? url;

    if (!mounted) return;

    if (_isAR) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArScannerScreen(preferredModelId: model.id),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModelViewerScreen(
            arModelId: model.id,
            modelName: model.modelName,
            modelUrl: displayUrl,
            hotspots: model.hotspots,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Augmented Reality (AR)',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined,
                color: Color(0xFF637080)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArDiagnosticScreen(),
                ),
              );
            },
            tooltip: 'Diagnostik AR',
          ),
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF637080)),
              onPressed: _syncContent,
              tooltip: 'Sinkronkan konten',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A8477)))
          : RefreshIndicator(
              onRefresh: () async {
                await _syncContent();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBanner(),
                  const SizedBox(height: 12),
                  _buildArUcoCard(),
                  if (_syncStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSyncStatusCard(),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Katalog Objek 3D Tersedia',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 14),
                  if (_models.isEmpty)
                    _buildEmptyState()
                  else
                    ..._models.map((model) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildModelCard(context, model),
                        )),
                  const SizedBox(height: 24),
                  _buildTipsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Icon(
            _isSyncing ? Icons.sync : Icons.check_circle_outline,
            size: 16,
            color:
                _isSyncing ? const Color(0xFFF9A825) : const Color(0xFF0A8477),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _syncStatus,
              style: const TextStyle(fontSize: 12, color: Color(0xFF637080)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final isAR = _isAR;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAR
              ? [const Color(0xFF5B6ABF), const Color(0xFF4353A4)]
              : [const Color(0xFF637080), const Color(0xFF4A5568)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isAR ? const Color(0xFF5B6ABF) : const Color(0xFF637080))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAR ? Icons.view_in_ar : Icons.three_g_mobiledata,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAR ? 'AR Learning Hub' : '3D Learning Hub',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAR
                          ? 'Visualisasi Objek 3D Nyata'
                          : 'Model 3D Interaktif',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAR ? 'AR' : '3D',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isAR
                ? 'Pindai marker gambar pada modul pembelajaran dengan kamera smartphone Anda untuk memunculkan model 3D interaktif secara realtime.'
                : 'Perangkat Anda mendukung tampilan model 3D interaktif. Geser untuk memutar, cubit untuk zoom.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildArUcoCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ArUcoScannerScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A8477),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A8477).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OpenCV ArUco Scanner',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Deteci marker ArUco dengan OpenCV',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.view_in_ar, size: 48, color: Color(0xFFB0B8C1)),
          SizedBox(height: 12),
          Text('Belum ada model 3D tersedia',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF637080))),
          SizedBox(height: 4),
          Text('Admin/guru belum mengupload model 3D',
              style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1))),
        ],
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, ArContentItem model) {
    final hasMarker = model.markers.isNotEmpty;
    final imageUrl = _resolveImageUrl(model);

    return GestureDetector(
      onTap: () => _openModel(model),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(Icons.view_in_ar,
                        size: 48, color: Color(0xFFB0B8C1)),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                    child: Icon(Icons.view_in_ar,
                        size: 48, color: Color(0xFFB0B8C1))),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(model.category ?? 'Umum',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF637080))),
                  ),
                  const SizedBox(height: 8),
                  Text(model.modelName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  if (model.description != null &&
                      model.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(model.description!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF637080),
                            height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasMarker) ...[
                        Icon(Icons.qr_code_scanner,
                            size: 16, color: const Color(0xFF0A8477)),
                        const SizedBox(width: 4),
                        Text('${model.markers.length} marker',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF0A8477))),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        _isAR ? Icons.view_in_ar : Icons.three_g_mobiledata,
                        size: 16,
                        color: const Color(0xFF5B6ABF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isAR ? 'Buka AR' : 'Lihat 3D',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5B6ABF)),
                      ),
                      const Spacer(),
                      Text(
                        'v${model.version}',
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFB0B8C1)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final isAR = _isAR;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAR ? Icons.info_outline : Icons.three_g_mobiledata,
            color: const Color(0xFF0A8477),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAR ? 'Petunjuk Pengujian AR' : 'Mode 3D Interaktif',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 4),
                Text(
                  isAR
                      ? 'Untuk hasil optimal, jalankan aplikasi di HP Android dengan Google Play Services for AR. Download marker, cetak, lalu arahkan kamera ke marker untuk memunculkan model 3D.'
                      : 'Perangkat Anda tidak mendukung AR. Anda tetap dapat melihat dan berinteraksi dengan model 3D dalam mode 3D interaktif. Geser untuk memutar, cubit untuk zoom.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
