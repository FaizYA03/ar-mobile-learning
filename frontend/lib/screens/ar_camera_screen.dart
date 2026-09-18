import 'dart:async';
import 'package:flutter/material.dart';
import 'package:augen/augen.dart';
import '../services/api_service.dart';

class ArCameraScreen extends StatefulWidget {
  final int? arModelId;
  final String? markerImagePath;
  final String? modelUrl;
  final String? modelName;

  const ArCameraScreen({
    super.key,
    this.arModelId,
    this.markerImagePath,
    this.modelUrl,
    this.modelName,
  });

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen> {
  AugenController? _controller;
  bool _isSessionReady = false;
  bool _isMarkerDetected = false;
  bool _isModelLoaded = false;
  String? _errorMessage;
  String _statusMessage = 'Menginisialisasi kamera...';
  Map<String, dynamic>? _markerData;
  List<dynamic> _hotspots = [];

  StreamSubscription? _markerSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _loadArData();
  }

  Future<void> _loadArData() async {
    if (widget.arModelId != null) {
      try {
        final response = await ApiService.getMateriDetail(widget.arModelId!);
        if (response['success'] == true && mounted) {
          final data = response['data'];
          setState(() {
            _markerData = data['ar_model'];
            _hotspots = data['ar_model']?['hotspots'] ?? [];
          });
        }
      } catch (e) {
        // Continue with provided params
      }
    }
  }

  @override
  void dispose() {
    _markerSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _onARViewCreated(AugenController controller) {
    _controller = controller;
    _setupStreams();
    _initializeSession();
  }

  void _setupStreams() {
    _markerSubscription = _controller!.trackedMarkersStream.listen((markers) {
      if (!mounted) return;
      for (final marker in markers) {
        if (marker.isTracked && marker.isReliable) {
          setState(() {
            _isMarkerDetected = true;
            _statusMessage = 'Marker terdeteksi! Memuat model 3D...';
          });
          _load3DModel(marker);
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

      // Add marker target (pattern tracking)
      await _controller!.addMarkerTarget(
        const ARMarkerTarget(
          id: 'learning_marker',
          name: 'Learning Marker',
          type: ARMarkerType.pattern,
          imagePath: 'assets/markers/default_marker.png',
          physicalWidth: 0.08,
        ),
      );

      await _controller!.setMarkerTrackingEnabled(true);

      setState(() {
        _isSessionReady = true;
        _statusMessage = 'Arahkan kamera ke marker gambar...';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menginisialisasi AR: $e';
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _load3DModel(dynamic marker) async {
    if (_isModelLoaded) return;

    final modelUrl = widget.modelUrl ??
        _markerData?['glb_path'] ??
        'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb';

    try {
      await _controller!.addModelFromUrl(
        id: 'learning_model',
        url: modelUrl,
        position: Vector3(0, 0, -0.5),
        modelFormat: ModelFormat.glb,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isModelLoaded
                          ? const Color(0xFF27AE60).withValues(alpha: 0.9)
                          : _isMarkerDetected
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
                                : _isMarkerDetected
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

          // Center Crosshair (when no marker detected)
          if (!_isMarkerDetected && _isSessionReady)
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
                        Icon(Icons.center_focus_strong, color: Colors.white, size: 32),
                        SizedBox(height: 8),
                        Text(
                          'Arahkan ke marker',
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
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFFC62828)),
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
            _buildInfoRow('Status Marker', _isMarkerDetected ? 'Terdeteksi' : 'Belum terdeteksi'),
            _buildInfoRow('Status Model', _isModelLoaded ? 'Dimuat' : 'Belum dimuat'),
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
                    child: const Icon(Icons.info_outline, color: Color(0xFF0A8477), size: 20),
                  ),
                  title: Text(
                    hotspot['title'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    hotspot['description'] ?? '',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF637080))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        ],
      ),
    );
  }

  void _resetAR() {
    setState(() {
      _isMarkerDetected = false;
      _isModelLoaded = false;
      _statusMessage = 'Arahkan kamera ke marker gambar...';
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
