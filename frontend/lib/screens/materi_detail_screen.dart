import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/api_service.dart';
import 'ar_camera_screen.dart';
import 'quiz_list_screen.dart';

class MateriDetailScreen extends StatefulWidget {
  final int materiId;

  const MateriDetailScreen({super.key, required this.materiId});

  @override
  State<MateriDetailScreen> createState() => _MateriDetailScreenState();
}

class _MateriDetailScreenState extends State<MateriDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _materi;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getMateriDetail(widget.materiId);
      if (response['success'] == true && mounted) {
        setState(() {
          _materi = response['data'];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat materi';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Detail Materi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _materi == null ? null : _buildBottomActions(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }

    if (_errorMessage != null || _materi == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Color(0xFFC62828)),
              const SizedBox(height: 14),
              Text(_errorMessage ?? 'Data tidak ditemukan', textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _fetchDetail,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final judul = _materi!['judul'] ?? '';
    final tpAtp = _materi!['tp_atp'] ?? {};
    final ringkasan = _materi!['ringkasan'] ?? '';
    final konten = _materi!['konten'] ?? '';
    final arModel = _materi!['ar_model'];
    final menit = _materi!['estimasi_menit'] ?? 15;
    final gambarCover = _materi!['gambar_cover_url'] ?? _materi!['gambar_cover'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (gambarCover != null && gambarCover.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFE8F5F3),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                gambarCover.startsWith('http')
                    ? gambarCover
                    : '${ApiService.baseUrl.replaceFirst('/api', '')}/storage/$gambarCover',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.menu_book_outlined, size: 48, color: Color(0xFF0A8477)),
                ),
              ),
            ),
          // TP Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tpAtp['kode'] ?? 'TP',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0A8477)),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Estimasi $menit Menit Baca',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            judul,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E), height: 1.3),
          ),
          const SizedBox(height: 16),

          // Ringkasan box
          if (ringkasan.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0A8477).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF0A8477), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ringkasan,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF075A51), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // AR Card if available
          if (arModel != null) _buildArModelBanner(arModel),

          // Content body
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: _renderFormattedContent(konten),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildArModelBanner(Map<String, dynamic> arModel) {
    final modelName = arModel['model_name'] ?? 'Model 3D';
    final desc = arModel['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6ABF), Color(0xFF4353A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5B6ABF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.view_in_ar, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Objek Interaktif 3D / AR', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(modelName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showArPreviewDialog(arModel);
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Preview Model 3D'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4353A4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArPreviewDialog(Map<String, dynamic> arModel) {
    final glbPath = arModel['glb_path'] ?? '';
    String modelUrl = '';
    if (glbPath.isNotEmpty) {
      if (glbPath.startsWith('http')) {
        modelUrl = glbPath;
      } else {
        modelUrl = '${ApiService.baseUrl.replaceFirst('/api', '')}/storage/$glbPath';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(
                children: [
                  const Icon(Icons.view_in_ar, color: Color(0xFF5B6ABF)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(arModel['model_name'] ?? 'Model 3D', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: modelUrl.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.view_in_ar, size: 48, color: Color(0xFFB0B8C1)),
                          SizedBox(height: 8),
                          Text(
                            'Model 3D belum tersedia',
                            style: TextStyle(fontSize: 13, color: Color(0xFF637080)),
                          ),
                        ],
                      ),
                    )
                  : ModelViewer(
                      src: modelUrl,
                      autoRotate: true,
                      cameraControls: true,
                    ),
            ),
            if (arModel['description'] != null && (arModel['description'] as String).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(arModel['description'], style: const TextStyle(fontSize: 12, color: Color(0xFF637080)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArCameraScreen(
                              arModelId: arModel['id'],
                              modelName: arModel['model_name'],
                              modelUrl: modelUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_in_ar, size: 16),
                      label: const Text('Buka AR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B6ABF),
                        side: const BorderSide(color: Color(0xFF5B6ABF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderFormattedContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 10));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            trimmed.substring(3),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
          ),
        ));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(
            trimmed.substring(4),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0A8477)),
          ),
        ));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0A8477))),
              Expanded(
                child: Text(
                  trimmed.substring(2).replaceAll('**', ''),
                  style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF333E4C)),
                ),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        final match = RegExp(r'^(\d+\.) (.*)').firstMatch(trimmed);
        final num = match?.group(1) ?? '';
        final text = match?.group(2) ?? trimmed;
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$num ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0A8477))),
              Expanded(
                child: Text(
                  text.replaceAll('**', ''),
                  style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF333E4C)),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            trimmed.replaceAll('**', ''),
            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF333E4C)),
          ),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizListScreen(isTab: false)),
              );
            },
            icon: const Icon(Icons.quiz_outlined, size: 20),
            label: const Text('Uji Pemahaman (Kerjakan Quiz)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A8477),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}