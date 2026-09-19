import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/debug/ar_debug_log.dart';
import '../models/models.dart';
import '../services/ar_content_resolver.dart';
import '../services/ar_engine_controller.dart';
import '../services/ar_service.dart';
import '../services/content_sync_service.dart';
import '../widgets/ar_engine_view.dart';
import 'model_viewer_screen.dart';

enum _ScannerPhase {
  checking,
  permissionRequired,
  arCoreInstallRequired,
  unsupported,
  reading,
  error,
}

class ArScannerScreen extends StatefulWidget {
  final int? preferredModelId;

  const ArScannerScreen({super.key, this.preferredModelId});

  @override
  State<ArScannerScreen> createState() => _ArScannerScreenState();
}

class _ArScannerScreenState extends State<ArScannerScreen> {
  ArEngineController? _engine;

  _ScannerPhase _phase = _ScannerPhase.checking;
  String _statusMessage = 'Memeriksa kesiapan AR...';
  String? _errorMessage;
  bool _sessionReady = false;
  int _registeredTargets = 0;

  ArContentItem? _detectedItem;
  String? _detectedMarkerId;
  final Set<String> _markersWithoutModel = <String>{};

  @override
  void initState() {
    super.initState();
    ArDebugLog.log(
        'Scanner opened (preferredModelId=${widget.preferredModelId})');
    _preflight();
  }

  @override
  void dispose() {
    _engine?.dispose();
    _engine = null;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pre-flight: ARCore state + camera permission
  // ---------------------------------------------------------------------------

  Future<void> _preflight() async {
    setState(() => _phase = _ScannerPhase.checking);

    final availability = await ARService.checkAvailability();
    ArDebugLog.log('[AR] ARCore state: ${availability.name}');

    switch (availability) {
      case ArCoreAvailability.unsupported:
        ArDebugLog.log('Device unsupported: fallback to 3D viewer');
        setState(() {
          _phase = _ScannerPhase.unsupported;
          _statusMessage =
              'Perangkat ini tidak mendukung AR. Anda dapat melihat model 3D sebagai alternatif.';
        });
        return;
      case ArCoreAvailability.supportedNotInstalled:
        ArDebugLog.log('ARCore not installed: prompting install');
        setState(() {
          _phase = _ScannerPhase.arCoreInstallRequired;
          _statusMessage = 'Google Play Services for AR perlu diinstal.';
        });
        return;
      case ArCoreAvailability.unknown:
        setState(() {
          _phase = _ScannerPhase.error;
          _errorMessage =
              'Status ARCore tidak dapat ditentukan pada perangkat ini.';
          _statusMessage = 'Tidak dapat memeriksa dukungan AR.';
        });
        return;
      case ArCoreAvailability.supportedInstalled:
        break;
    }

    final granted = await ARService.hasCameraPermission();
    ArDebugLog.log('[AR] Camera permission: $granted');
    if (!granted) {
      ArDebugLog.log('Camera permission not granted: requesting');
      final status = await ARService.requestCameraPermission();
      ArDebugLog.log('Camera permission result: ${status.name}');
      if (!status.isGranted) {
        setState(() {
          _phase = _ScannerPhase.permissionRequired;
          _statusMessage = 'Izin kamera dibutuhkan untuk pemindaian marker AR.';
        });
        return;
      }
    }

    if (!mounted) return;
    ArDebugLog.log('Pre-flight passed; building AR view');
    setState(() {
      _phase = _ScannerPhase.reading;
      _statusMessage = 'Menyiapkan AR session...';
    });
  }

  Future<void> _installArCore() async {
    ArDebugLog.log('Requesting ARCore install');
    setState(() {
      _phase = _ScannerPhase.checking;
      _statusMessage = 'Menginstal ARCore...';
    });
    final requested = await ARService.requestInstall();
    ArDebugLog.log('ARCore install requested: $requested');
    ARService.resetCache();
    await _preflight();
  }

  Future<void> _requestPermissionAgain() async {
    await _preflight();
  }

  // ---------------------------------------------------------------------------
  // AR view setup (Opsi 3: native engine)
  // ---------------------------------------------------------------------------

  void _onARViewCreated() {
    ArDebugLog.log('Native AR view created');
    _engine = ArEngineController();
    _setupEvents();
    _registerAndConfigure();
  }

  Future<void> _registerAndConfigure() async {
    try {
      if (!ArContentResolver.isContentLoaded) {
        await ArContentResolver.refreshContent();
      }

      final items = ArContentResolver.content;
      final markers = <ArEngineMarker>[];
      final models = <String, String>{};
      _markersWithoutModel.clear();
      var registered = 0;

      for (final item in items) {
        for (final marker in item.markers) {
          if (marker.imageUrl == null && marker.imagePath == null) {
            ArDebugLog.log('Skip marker ${marker.markerId} (no image defined)');
            continue;
          }

          final cachedPath =
              await ContentSyncService.getCachedMarkerPath(marker.id);
          final imagePath = cachedPath ?? 'assets/markers/default_marker.png';

          markers.add(
            ArEngineMarker(
              name: marker.markerId,
              imagePath: imagePath,
              widthMeters: 0.15,
            ),
          );
          registered++;

          final glbPath =
              await ContentSyncService.getCachedModelPath(item.id) ??
                  await ArContentResolver.resolveLocalModelPath(item.id);
          if (glbPath == null || glbPath.isEmpty) {
            _markersWithoutModel.add(marker.markerId);
            ArDebugLog.log(
              'Marker ${marker.markerId}: GLB not cached yet (model ${item.id})',
            );
          } else {
            models[marker.markerId] = glbPath;
          }

          ArDebugLog.log(
            'Image target prepared: name=${marker.markerId} '
            'image=${imagePath.startsWith('assets') ? 'asset' : 'cached'} '
            'model=${item.id}',
          );
        }
      }

      ArDebugLog.log('Image target registration: $registered target(s), '
          '${models.length} model(s) mapped to GLB local');

      await _engine!.configure(
        markers: markers,
        modelsByMarker: models,
        scaleToUnits: 0.2,
      );

      if (!mounted) return;
      setState(() => _registeredTargets = registered);
      ArDebugLog.log('Native engine configured');
    } catch (e) {
      ArDebugLog.error('Engine configure failed: $e');
      if (mounted) {
        setState(() {
          _phase = _ScannerPhase.error;
          _errorMessage = 'Gagal menyiapkan mesin AR: $e';
          _statusMessage = 'Terjadi kendala saat menyiapkan AR.';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Detection resolution (RC-6: resolveByMarkerId on detection)
  // ---------------------------------------------------------------------------

  void _setupEvents() {
    _engine!.events.listen(_onEngineEvent, onError: (Object _) {});
  }

  void _onEngineEvent(ArEngineEvent event) {
    switch (event.name) {
      case 'configured':
        ArDebugLog.log(
            '[AR] Image target registration confirmed: ${event.markerCount} target(s)');
        break;
      case 'sessionCreated':
        ArDebugLog.log('[AR] AR session initialized (native engine)');
        if (mounted) {
          setState(() {
            _sessionReady = true;
            _statusMessage = 'Arahkan kamera ke gambar marker...';
          });
        }
        break;
      case 'sessionFailed':
        ArDebugLog.error('[AR] session failed: ${event.message}');
        _onSessionFailed(event.message);
        break;
      case 'trackedAugmentedImage':
        ArDebugLog.log(
            '[AR] Marker detected: ${event.markerName} state=${event.trackingState}');
        if (event.isDetected) {
          final markerId = event.markerName;
          if (markerId != null &&
              (markerId != _detectedMarkerId || _detectedItem == null)) {
            _resolveMarker(markerId);
          }
        } else if (event.isLost && event.markerName == _detectedMarkerId) {
          _onTrackingLost('scanned_model_${_detectedItem?.id}');
        }
        break;
      case 'cameraTrackingStateChanged':
        ArDebugLog.log(
            '[AR] Camera tracking: ${event.payload['reason'] ?? 'LOST'}');
        break;
    }
  }

  Future<void> _resolveMarker(String markerId) async {
    ArDebugLog.log('Mapping resolution: marker=$markerId');

    final item = ArContentResolver.resolveByMarkerId(markerId);
    if (item == null) {
      ArDebugLog.error(
          'Mapping resolution failed: no content for marker $markerId');
      setState(() {
        _detectedMarkerId = markerId;
        _statusMessage = 'Marker terdeteksi namun belum terhubung ke model.';
      });
      return;
    }

    ArDebugLog.log(
      'Mapping resolved: marker $markerId -> model ${item.id} '
      '(${item.modelName}, v${item.version})',
    );

    if (_markersWithoutModel.contains(markerId)) {
      ArDebugLog.error('Model GLB resolution: not cached for marker $markerId');
      setState(() {
        _detectedMarkerId = markerId;
        _detectedItem = item;
        _statusMessage =
            'Model 3D belum terunduh. Sinkronkan konten dulu, lalu pindai ulang.';
      });
      return;
    }

    final glbPath = await ContentSyncService.getCachedModelPath(item.id) ??
        await ArContentResolver.resolveLocalModelPath(item.id);
    ArDebugLog.log('Model GLB resolution. Cached GLB path: $glbPath');

    ArDebugLog.log(
        'Placement attempt: native renderer maps marker $markerId -> '
        '${item.id} glb=$glbPath');

    if (!mounted) return;
    setState(() {
      _detectedMarkerId = markerId;
      _detectedItem = item;
      _statusMessage = 'Marker terdeteksi! Model 3D tampil di atas marker.';
    });
  }

  void _onTrackingLost(String nodeId) {
    ArDebugLog.log('Tracking lost handled for $nodeId; re-scan ready');
    if (!mounted) return;
    setState(() {
      _detectedMarkerId = null;
      _detectedItem = null;
      _statusMessage = 'Marker hilang dari pandangan. Pindai ulang marker.';
    });
  }

  void _onSessionFailed(String message) {
    ArDebugLog.error('AR session failed: $message');
    if (!mounted) return;
    final lower = message.toLowerCase();
    if (lower.contains('unsupported') || lower.contains('not supported')) {
      setState(() {
        _phase = _ScannerPhase.unsupported;
        _statusMessage =
            'Perangkat tidak mendukung AR saat ini. Gunakan mode 3D.';
      });
      return;
    }
    setState(() {
      _phase = _ScannerPhase.error;
      _errorMessage = message;
      _statusMessage = 'AR tidak dapat berjalan. Gunakan mode 3D.';
    });
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _open3dViewer([ArContentItem? item]) async {
    final target = item ?? _detectedItem;
    if (target == null) {
      final items = ArContentResolver.content;
      if (items.isEmpty) {
        _showMessage('Belum ada konten AR yang tersinkron.');
        return;
      }
      _openViewer(items.first);
      return;
    }
    _openViewer(target);
  }

  Future<void> _openViewer(ArContentItem item) async {
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

  void _reset() {
    _engine?.dispose();
    _engine = null;
    setState(() {
      _detectedMarkerId = null;
      _detectedItem = null;
      _errorMessage = null;
      _sessionReady = false;
      _registeredTargets = 0;
      _phase = _ScannerPhase.checking;
      _statusMessage = 'Memeriksa kesiapan AR...';
    });
    ArDebugLog.log('Scanner reset');
    _preflight();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _ScannerPhase.checking:
        return _buildLoadingScreen(_statusMessage);
      case _ScannerPhase.permissionRequired:
        return _buildMessageScreen(
          icon: Icons.no_photography_outlined,
          title: 'Izin kamera dibutuhkan',
          message: _statusMessage,
          primaryLabel: 'Beri Izin',
          onPrimary: _requestPermissionAgain,
          secondaryLabel: 'Lihat Model 3D',
          onSecondary: () => _open3dViewer(),
        );
      case _ScannerPhase.arCoreInstallRequired:
        return _buildMessageScreen(
          icon: Icons.smartphone,
          title: 'ARCore belum terpasang',
          message: _statusMessage,
          primaryLabel: 'Instal ARCore',
          onPrimary: _installArCore,
          secondaryLabel: 'Lihat Model 3D',
          onSecondary: () => _open3dViewer(),
        );
      case _ScannerPhase.unsupported:
        return _buildMessageScreen(
          icon: Icons.phonelink_erase,
          title: 'Perangkat tidak mendukung AR',
          message: _statusMessage,
          primaryLabel: 'Lihat Model 3D',
          onPrimary: () => _open3dViewer(),
          secondaryLabel: 'Ulangi Pemeriksaan',
          onSecondary: _reset,
        );
      case _ScannerPhase.error:
        return _buildMessageScreen(
          icon: Icons.error_outline,
          title: 'AR tidak dapat berjalan',
          message: _errorMessage ?? _statusMessage,
          primaryLabel: 'Coba Lagi',
          onPrimary: _reset,
          secondaryLabel: 'Lihat Model 3D',
          onSecondary: () => _open3dViewer(),
        );
      case _ScannerPhase.reading:
        return _buildArView();
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0A8477)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageScreen({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimary,
    required String secondaryLabel,
    required VoidCallback onSecondary,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Pemindai AR',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: const Color(0xFFF9A825)),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF637080)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPrimary,
                  icon: const Icon(Icons.view_in_ar),
                  label: Text(primaryLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8477),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ArEngineView(onCreated: _onARViewCreated),
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
                    Colors.black.withValues(alpha: 0.75),
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
                          'Pemindai Marker AR',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildStatusPill(),
                  if (_registeredTargets > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '$_registeredTargets image target terdaftar'
                      '${_detectedItem != null ? ' — aktif: $_detectedMarkerId' : ''}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_sessionReady && _detectedItem == null)
            Center(
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.center_focus_strong,
                            color: Colors.white, size: 34),
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
          if (_detectedItem != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF27AE60), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Marker "$_detectedMarkerId" terhubung ke '
                            '"${_detectedItem!.modelName}"',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _open3dViewer(_detectedItem),
                      icon: const Icon(Icons.view_in_ar),
                      label: const Text('Lihat Model 3D'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A8477),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_detectedItem == null && _sessionReady)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 14,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControl(
                      icon: Icons.refresh, label: 'Reset', onTap: _reset),
                  _buildControl(
                      icon: Icons.view_in_ar,
                      label: 'Mode 3D',
                      onTap: () => _open3dViewer()),
                ],
              ),
            ),
          if (!_sessionReady && _phase == _ScannerPhase.reading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0A8477)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    Color color;
    if (_detectedItem != null) {
      color = const Color(0xFF27AE60);
    } else if (_registeredTargets > 0) {
      color = const Color(0xFFE67E22);
    } else {
      color = Colors.black.withValues(alpha: 0.6);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
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
    );
  }

  Widget _buildControl({
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
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
