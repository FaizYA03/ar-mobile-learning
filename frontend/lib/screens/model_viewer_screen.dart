import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../models/models.dart';
import '../config/api_config.dart';

class ModelViewerScreen extends StatefulWidget {
  final int? arModelId;
  final String? modelUrl;
  final String? modelName;
  final List<ArHotspotData>? hotspots;

  const ModelViewerScreen({
    super.key,
    this.arModelId,
    this.modelUrl,
    this.modelName,
    this.hotspots,
  });

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  ArHotspotData? _selectedHotspot;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final url = _resolveModelUrl(widget.modelUrl);
    final hotspots = widget.hotspots ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.modelName ?? 'Model 3D',
          style: const TextStyle(
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.three_g_mobiledata,
                    size: 18, color: Color(0xFF5B6ABF)),
                const SizedBox(width: 4),
                Text(
                  'Mode 3D',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B6ABF),
                  ),
                ),
                if (hotspots.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A8477).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${hotspots.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A8477),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: url.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.view_in_ar,
                        size: 48, color: Color(0xFFB0B8C1)),
                    const SizedBox(height: 12),
                    const Text(
                      'Model 3D belum tersedia di perangkat.',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF637080)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Silakan lakukan sinkronisasi konten terlebih dahulu.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        ModelViewer(
                          src: url,
                          alt: widget.modelName ?? 'Model 3D',
                          ar: false,
                          autoRotate: true,
                          cameraControls: true,
                          disableZoom: false,
                          backgroundColor: const Color(0xFFE8EDF2),
                          innerModelViewerHtml: _buildHotspotHtml(hotspots),
                          relatedJs: _buildHotspotJs(hotspots),
                          onWebViewCreated: (_) {
                            if (mounted) setState(() => _isLoading = false);
                          },
                          javascriptChannels: {
                            JavascriptChannel(
                              'HotspotChannel',
                              onMessageReceived: (message) {
                                try {
                                  final data = jsonDecode(message.message);
                                  final hotspotId = data['id'] as int;
                                  final hotspot = hotspots.firstWhere(
                                    (h) => h.id == hotspotId,
                                  );
                                  if (mounted) {
                                    setState(() => _selectedHotspot = hotspot);
                                    _showHotspotDetail(hotspot);
                                  }
                                } catch (_) {}
                              },
                            ),
                          },
                        ),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0A8477),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (hotspots.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.place,
                            size: 18, color: Color(0xFF0A8477)),
                        const SizedBox(width: 6),
                        Text(
                          'Hotspot (${hotspots.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• Ketuk titik pada model untuk info',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: hotspots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) =>
                          _buildHotspotChip(hotspots[index]),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE9ECEF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.modelName ?? 'Model 3D',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.touch_app,
                              size: 16, color: Color(0xFF637080)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Geser untuk memutar, cubit untuk zoom, double-tap untuk reset',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFFF9A825)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perangkat ini tidak mendukung AR. Model ditampilkan dalam mode 3D interaktif.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _resolveModelUrl(String? glbPath) {
    if (glbPath == null || glbPath.isEmpty) return '';
    if (glbPath.startsWith('http://') || glbPath.startsWith('https://')) {
      return glbPath;
    }
    if (glbPath.startsWith('file:///')) return glbPath;
    if (glbPath.startsWith('/')) return 'file://$glbPath';
    if (RegExp(r'^[A-Za-z]:\\').hasMatch(glbPath)) return 'file:///$glbPath';
    final base = ApiConfig.baseHost;
    if (glbPath.startsWith('storage/')) {
      return '${base.endsWith('/') ? base : '$base/'}$glbPath';
    }
    return '${base.endsWith('/') ? base : '$base/'}storage/$glbPath';
  }

  String _buildHotspotHtml(List<ArHotspotData> hotspots) {
    if (hotspots.isEmpty) return '';
    final buffer = StringBuffer();
    for (final h in hotspots) {
      final pos = '${h.positionX}m ${h.positionY}m ${h.positionZ}m';
      buffer.writeln(
        '<button slot="hotspot-${h.id}" data-position="$pos" '
        'data-visibility-attribute="visible" '
        'style="width:28px;height:28px;border-radius:50%;background:rgba(10,132,119,0.85);'
        'border:3px solid white;box-shadow:0 2px 8px rgba(0,0,0,0.3);cursor:pointer;'
        'display:flex;align-items:center;justify-content:center;'
        'transition:transform 0.15s ease;">'
        '<svg width="12" height="12" viewBox="0 0 24 24" fill="white">'
        '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z"/>'
        '</svg>'
        '</button>',
      );
    }
    return buffer.toString();
  }

  String _buildHotspotJs(List<ArHotspotData> hotspots) {
    if (hotspots.isEmpty) return '';
    final ids = hotspots.map((h) => h.id).join(',');
    return '''
document.addEventListener('DOMContentLoaded', function() {
  var ids = [$ids];
  ids.forEach(function(id) {
    var btn = document.querySelector('[slot="hotspot-' + id + '"]');
    if (btn) {
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        if (window.HotspotChannel) {
          window.HotspotChannel.postMessage(JSON.stringify({id: id}));
        }
      });
    }
  });
});
''';
  }

  Widget _buildHotspotChip(ArHotspotData hotspot) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHotspot = hotspot);
        _showHotspotDetail(hotspot);
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedHotspot?.id == hotspot.id
                ? const Color(0xFF0A8477)
                : const Color(0xFFE9ECEF),
            width: _selectedHotspot?.id == hotspot.id ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A8477),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hotspot.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hotspot.description ?? 'Ketuk untuk info',
              style: const TextStyle(fontSize: 10, color: Color(0xFF637080)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showHotspotDetail(ArHotspotData hotspot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D5D8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place,
                      color: Color(0xFF0A8477), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotspot.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (hotspot.description != null &&
                          hotspot.description!.isNotEmpty)
                        Text(
                          hotspot.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF637080),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildPositionInfo('X', hotspot.positionX.toStringAsFixed(2)),
                  const SizedBox(width: 16),
                  _buildPositionInfo('Y', hotspot.positionY.toStringAsFixed(2)),
                  const SizedBox(width: 16),
                  _buildPositionInfo('Z', hotspot.positionZ.toStringAsFixed(2)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B6ABF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Skala ${hotspot.hotspotScale.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B6ABF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfo(String axis, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          axis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A8477),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
