import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ar_camera_screen.dart';

class ArHubScreen extends StatefulWidget {
  const ArHubScreen({super.key});

  @override
  State<ArHubScreen> createState() => _ArHubScreenState();
}

class _ArHubScreenState extends State<ArHubScreen> {
  List<dynamic> _models = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final response = await ApiService.arGetPublicModels();
      if (response['success'] == true && mounted) {
        setState(() {
          _models = response['data'] ?? [];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _modelUrl(String? glbPath) {
    if (glbPath == null || glbPath.isEmpty) {
      return 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb';
    }
    if (glbPath.startsWith('http')) return glbPath;
    final base = ApiService.baseUrl.replaceFirst('/api', '');
    return '$base/$glbPath';
  }

  String _imageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final base = ApiService.baseUrl.replaceFirst('/api', '');
    return '$base/$imagePath';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Augmented Reality (AR)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)))
          : RefreshIndicator(
              onRefresh: _loadModels,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildBanner(),
                  const SizedBox(height: 24),
                  const Text(
                    'Katalog Objek 3D Tersedia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
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

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6ABF), Color(0xFF4353A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B6ABF).withValues(alpha: 0.3),
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
                child: const Icon(Icons.view_in_ar, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AR Learning Hub', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Visualisasi Objek 3D Nyata', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Pindai marker gambar pada modul pembelajaran dengan kamera smartphone Anda untuk memunculkan model 3D interaktif secara realtime.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
          ),
        ],
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
          Text('Belum ada model 3D tersedia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF637080))),
          SizedBox(height: 4),
          Text('Admin/guru belum mengupload model 3D', style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1))),
        ],
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, dynamic model) {
    final markers = model['markers'] as List<dynamic>? ?? [];
    final hasMarker = markers.isNotEmpty;
    final modelName = model['model_name'] ?? 'Model 3D';
    final description = model['description'] ?? '';
    final category = model['category'] ?? 'Umum';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArCameraScreen(
              arModelId: model['id'],
              modelName: modelName,
              modelUrl: _modelUrl(model['glb_path']),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model['thumbnail_path'] != null && (model['thumbnail_path'] as String).isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _imageUrl(model['thumbnail_path']),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(Icons.view_in_ar, size: 48, color: Color(0xFFB0B8C1)),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(child: Icon(Icons.view_in_ar, size: 48, color: Color(0xFFB0B8C1))),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF637080))),
                  ),
                  const SizedBox(height: 8),
                  Text(modelName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF637080), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasMarker) ...[
                        Icon(Icons.qr_code_scanner, size: 16, color: const Color(0xFF0A8477)),
                        const SizedBox(width: 4),
                        Text('${markers.length} marker', style: const TextStyle(fontSize: 12, color: Color(0xFF0A8477))),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.view_in_ar, size: 16, color: const Color(0xFF5B6ABF)),
                      const SizedBox(width: 4),
                      Text('Buka AR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF5B6ABF))),
                      const Spacer(),
                      if (hasMarker)
                        IconButton(
                          icon: const Icon(Icons.download, size: 20, color: Color(0xFF637080)),
                          onPressed: () => _downloadMarker(context, markers.first),
                          tooltip: 'Download Marker',
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

  void _downloadMarker(BuildContext context, dynamic marker) {
    final imagePath = marker['image_path'] ?? '';
    if (imagePath.isEmpty) return;

    final url = _imageUrl(imagePath);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Download Marker', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, height: 200, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64)),
            ),
            const SizedBox(height: 12),
            Text('Marker: ${marker['marker_id'] ?? ''}', style: const TextStyle(fontSize: 13, color: Color(0xFF637080))),
            const SizedBox(height: 8),
            const Text('Simpan gambar ini, cetak, lalu arahkan kamera ke gambar tersebut.',
                style: TextStyle(fontSize: 12, color: Color(0xFF637080)), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
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
          const Icon(Icons.info_outline, color: Color(0xFF0A8477), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Petunjuk Pengujian AR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 4),
                Text(
                  'Untuk hasil optimal, jalankan aplikasi di HP Android dengan Google Play Services for AR. Download marker, cetak, lalu arahkan kamera ke marker untuk memunculkan model 3D.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
