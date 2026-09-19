import 'dart:async';
import 'package:flutter/material.dart';
import 'package:augen/augen.dart';
import '../models/models.dart';

class ArCameraScreen extends StatefulWidget {
  final int? arModelId;
  final String? markerImagePath;
  final String? modelUrl;
  final String? modelName;
  final List<ArHotspotData>? hotspots;

  const ArCameraScreen({
    super.key,
    this.arModelId,
    this.markerImagePath,
    this.modelUrl,
    this.modelName,
    this.hotspots,
  });

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  AugenController? _controller;
  bool _isSessionReady = false;
  bool _isImageDetected = false;
  bool _isModelLoaded = false;
  String? _errorMessage;
  String _statusMessage = 'Menginisialisasi AR...';
  List<ArHotspotData> _hotspots = [];

  StreamSubscription? _trackedImagesSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _hotspots = widget.hotspots ?? [];
  }

  @override
  void dispose() {
    _trackedImagesSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _onARViewCreated(AugenController controller) {
    _controller = controller;
    _setupStreams();
    _initializeSession();
  }

  void _setupStreams() {
    _trackedImagesSubscription =
        _controller!.trackedImagesStream.listen((trackedImages) {
      if (!mounted) return;
      for (final trackedImage in trackedImages) {
        if (trackedImage.isTracked && trackedImage.isReliable) {
          setState(() {
            _isImageDetected = true;
            _statusMessage = 'Gambar terdeteksi! Memuat model 3D...';
          });
          _onImageDetected(trackedImage);
        }
      }
    });

    _errorSubscription = _controller!.errorStream.listen((error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error;
        _statusMessage = 'Error: $error';
      });
    });
  }

  Future<void> _initializeSession() async {
    try {
      setState(() {
        _statusMessage = 'Menyiapkan AR session...';
      });

      // Initialize AR session
      await _controller!.initialize(
        const ARSessionConfig(
          planeDetection: false,
          lightEstimation: true,
          autoFocus: true,
        ),
      );

      // Add image target for tracking
      await _controller!.addImageTarget(
        ARImageTarget(
          id: 'learning_image_target',
          name: 'Learning Marker',
          imagePath:
              widget.markerImagePath ?? 'assets/markers/default_marker.png',
          physicalSize: const ImageTargetSize(0.15, 0.15),
        ),
      );

      // Enable image tracking
      await _controller!.setImageTrackingEnabled(true);

      setState(() {
        _isSessionReady = true;
        _statusMessage = 'Arahkan kamera ke gambar marker...';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menginisialisasi AR: $e';
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _onImageDetected(ARTrackedImage trackedImage) async {
    if (_isModelLoaded) return;

    final modelUrl = widget.modelUrl;
    if (modelUrl == null || modelUrl.isEmpty) {
      setState(() {
        _statusMessage =
            'Model 3D belum tersedia. Silakan sinkronisasi konten.';
      });
      return;
    }

    try {
      final contentNode = ARNode.fromModel(
        id: 'learning_model',
        modelPath: modelUrl,
        position: const Vector3(0, 0, 0.05),
        rotation: const Quaternion(0, 0, 0, 1),
        scale: const Vector3(0.1, 0.1, 0.1),
      );

      await _controller!.addNodeToTrackedImage(
        nodeId: 'learning_model',
        trackedImageId: trackedImage.id,
        node: contentNode,
      );

      setState(() {
        _isModelLoaded = true;
        _statusMessage = 'Model 3D berhasil dimuat!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Gagal memuat model: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View
          AugenView(
            onViewCreated: _onARViewCreated,
            config: const ARSessionConfig(
              planeDetection: false,
              lightEstimation: true,
              autoFocus: true,
            ),
          ),

          // Top Status Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.modelName ?? 'AR Viewer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status Indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isModelLoaded
                          ? const Color(0xFF27AE60).withValues(alpha: 0.9)
                          : _isImageDetected
                              ? const Color(0xFFE67E22).withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isModelLoaded
                                ? Colors.white
                                : _isImageDetected
                                    ? Colors.white
                                    : const Color(0xFFE67E22),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hotspot List (above bottom controls, when model loaded)
          if (_isModelLoaded && _hotspots.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 90,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _hotspots.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final h = _hotspots[index];
                    return GestureDetector(
                      onTap: () => _showHotspotDetail(h),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27AE60),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              h.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.info_outline,
                    label: 'Info',
                    onTap: _showInfoPanel,
                  ),
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    onTap: _resetAR,
                  ),
                  _buildControlButton(
                    icon: Icons.camera_alt,
                    label: 'Screenshot',
                    onTap: _takeScreenshot,
                  ),
                ],
              ),
            ),
          ),

          // Center Crosshair (when no image detected)
          if (!_isImageDetected && _isSessionReady)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.center_focus_strong,
                            color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Arahkan ke gambar marker',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Loading Indicator
          if (!_isSessionReady && _errorMessage == null)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A8477)),
            ),

          // Error State
          if (_errorMessage != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Color(0xFFC62828)),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF637080)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isSessionReady = false;
                        });
                        _initializeSession();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A8477),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showInfoPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            Text(
              widget.modelName ?? 'Informasi Model',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Status Gambar',
                _isImageDetected ? 'Terdeteksi' : 'Belum terdeteksi'),
            _buildInfoRow(
                'Status Model', _isModelLoaded ? 'Dimuat' : 'Belum dimuat'),
            if (_hotspots.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Hotspot',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              ..._hotspots.map((hotspot) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.info_outline,
                            color: Color(0xFF0A8477), size: 20),
                      ),
                      title: Text(
                        hotspot.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        hotspot.description ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tutup'),
              ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF637080))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  void _resetAR() {
    setState(() {
      _isImageDetected = false;
      _isModelLoaded = false;
      _statusMessage = 'Arahkan kamera ke gambar marker...';
    });
    _initializeSession();
  }

  Future<void> _takeScreenshot() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot berhasil disimpan'),
        backgroundColor: Color(0xFF0A8477),
      ),
    );
  }
}
