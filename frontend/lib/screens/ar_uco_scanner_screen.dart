import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/debug/ar_debug_log.dart';
import '../models/models.dart';
import '../screens/model_viewer_screen.dart';
import '../services/ar_camera_projector.dart';
import '../services/ar_uco_service.dart';
import '../services/ar_content_resolver.dart';
import '../services/content_sync_service.dart';
import '../widgets/ar_hotspot_speech_bubble.dart';

class ArUcoScannerScreen extends StatefulWidget {
  const ArUcoScannerScreen({super.key});

  @override
  State<ArUcoScannerScreen> createState() => _ArUcoScannerScreenState();
}

class _ArUcoScannerScreenState extends State<ArUcoScannerScreen>
    with WidgetsBindingObserver {
  ArUcoService? _service;
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isResolving = false;
  List<ArUcoResult> _detectedMarkers = [];
  String? _manualMarkerId;
  bool _showManualInput = false;

  ArResolveResult? _arResolve;
  String? _arModelSrc;
  String? _arModelName;
  ModelAnchor? _arAnchor;
  ModelAnchor? _arHeldAnchor;
  bool _arMarkerLost = false;
  Size _previewSize = Size.zero;
  int _arLastLogMs = 0;
  WebViewController? _arWebViewController;
  bool _showDebug = false;

  // --- State hotspot / penjelasan interaktif pada 3D model ---
  // Data hotspot diambil bersama hasil resolve (`ArResolveResult.hotspots`)
  // dari backend. Posisi layar hotspot dihitung dari fraksi proyeksi yang
  // dilaporkan WebView model-viewer (anchor) + anchor marker (cek Task 13:
  // hanya dimuat sekali per resolve, tidak per frame).
  int? _selectedHotspotId;
  final Map<int, Offset> _hotspotProjections = {};
  bool _hotspotsLoading = false;
  bool _hotspotsError = false;
  Timer? _hotspotsTimer;

  static const String _arInitialOrbit = '0deg 75deg 105%';
  static const String _arInitialTarget = '0m 0m 0m';
  static const String _arInitialFov = '45deg';

  bool _cameraPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hotspotsTimer?.cancel();
    _service?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _service?.stopScanning();
    } else if (state == AppLifecycleState.resumed && _isScanning) {
      _service?.startScanning();
    }
  }

  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.camera.status;
    ArDebugLog.log('Camera permission status: ${status.name}');

    if (status.isGranted || status.isLimited) {
      await _initService();
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
      }
      return;
    }

    final requested = await Permission.camera.request();
    ArDebugLog.log('Camera permission after request: ${requested.name}');

    if (requested.isGranted || requested.isLimited) {
      await _initService();
    } else {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
      }
    }
  }

  Future<void> _initService() async {
    try {
      _service = ArUcoService();
      await _service!.initialize();
      ArDebugLog.log(
          'Camera initialized: format=${_service!.frameFormatLabel}, '
          'sensorOrientation=${_service!.sensorOrientation}, '
          'nativeReady=${_service!.nativeLibraryReady}');
      ArDebugLog.log('Refreshing AR content...');
      await ArContentResolver.refreshContent();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (ArContentResolver.isContentLoaded) {
          ArDebugLog.log(
              'Content loaded: ${ArContentResolver.contentCount} models');
        } else {
          ArDebugLog.log('No cached content available, will resolve via API');
        }
        if (!_service!.nativeLibraryReady) {
          final errorMsg = _service!.nativeLibraryError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'OpenCV native library not loaded. ArUco detection unavailable.'
                  '${errorMsg != null ? '\n$errorMsg' : ''}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        // Masuk layar ini = niat scan: langsung mulai tanpa tekan tombol.
        if (!_isScanning) _toggleScanning();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera initialization failed: $e')),
        );
      }
    }
  }

  Future<void> _reinitService() async {
    _service?.resultsNotifier.removeListener(_onResultsChanged);
    await _service?.dispose();
    if (mounted) {
      setState(() {
        _service = null;
        _isInitialized = false;
        _isScanning = false;
        _detectedMarkers = [];
        _cameraPermissionDenied = false;
      });
    }
    await _checkPermissionAndInit();
  }

  void _toggleScanning() {
    if (_isScanning) {
      _service?.stopScanning();
      if (mounted) {
        setState(() {
          _isScanning = false;
          _detectedMarkers = [];
        });
      }
      _service?.resultsNotifier.removeListener(_onResultsChanged);
    } else {
      _service?.startScanning();
      _service?.resultsNotifier.addListener(_onResultsChanged);
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    }
  }

  void _onResultsChanged() {
    if (!mounted) return;
    final markers = _service!.resultsNotifier.value;
    final arActive = _arResolve != null;
    List<Offset>? previewCorners;
    ModelAnchor? newAnchor;

    if (arActive && markers.isNotEmpty) {
      previewCorners = _mapPreviewCorners(markers.first.corners);
      if (previewCorners != null && previewCorners.isNotEmpty) {
        final raw = previewCorners.map((p) => [p.dx, p.dy]).toList();
        final footprint = ArCameraProjector.computeMarkerFootprint(raw);
        newAnchor = ArCameraProjector.computeModelAnchor(
          footprint,
          previewW: _previewSize.width,
          previewH: _previewSize.height,
          modelScale: 1.6,
          liftFactor: 0.8,
        );
      }
    }

    setState(() {
      _detectedMarkers = markers;
      if (arActive) {
        if (newAnchor != null && newAnchor.isValid) {
          // Marker terdeteksi: simpan posisi terkini sekaligus "last known".
          _arAnchor = newAnchor;
          _arHeldAnchor = newAnchor;
          _arMarkerLost = false;
        } else {
          // Marker hilang / di luar kamera / footprint tidak valid:
          // model tetap di posisi terakhir yang diketahui.
          _arAnchor = _arHeldAnchor;
          _arMarkerLost = _arHeldAnchor != null;
        }
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _arLastLogMs > 1000) {
          _arLastLogMs = now;
          final a = _arAnchor;
          ArDebugLog.log(
            '[AR] markers=${markers.length} anchor=${a == null ? 'null' : '${a.left.round()},${a.top.round()},${a.width.round()}x${a.height.round()}'} lost=$_arMarkerLost',
          );
        }
      }
    });
  }

  /// Ruang gambar ternormalisasi (0..1) untuk overlay, atau null bila
  /// kamera belum siap. Dipakai bersamaan oleh preview (FittedBox.cover)
  /// dan proyeksi corner agar keduanya memakai geometri yang sama.
  ({double outW, double outH})? _coverSpace() {
    final s = _service;
    if (s == null) return null;
    final fw = s.frameWidth.toDouble();
    final fh = s.frameHeight.toDouble();
    if (fw <= 0 || fh <= 0) return null;
    final deviceRotationDeg = ArCameraProjector.deviceRotationToDegrees(
      s.controller?.value.deviceOrientation.index ?? 0,
    );
    return ArUcoService.previewSpace(
      imageWidth: fw,
      imageHeight: fh,
      sensorOrientationDeg: s.sensorOrientation,
      deviceRotationDeg: deviceRotationDeg,
    );
  }

  List<Offset>? _mapPreviewCorners(List<List<double>> rawCorners) {
    final w = _previewSize.width;
    final h = _previewSize.height;
    if (w <= 0 || h <= 0) return null;
    try {
      final s = _service;
      if (s == null) return null;
      final deviceRotationDeg = ArCameraProjector.deviceRotationToDegrees(
        s.controller?.value.deviceOrientation.index ?? 0,
      );
      final fw = s.frameWidth.toDouble();
      final fh = s.frameHeight.toDouble();
      final mapped = ArUcoService.mapCornersToPreview(
        corners: rawCorners,
        imageWidth: fw,
        imageHeight: fh,
        sensorOrientationDeg: s.sensorOrientation,
        deviceRotationDeg: deviceRotationDeg,
      );
      // Preview ditampilkan BoxFit.cover: terapkan transform yang sama
      // (skala + offset crop) agar overlay sejajar dengan gambar.
      final space = ArUcoService.previewSpace(
        imageWidth: fw,
        imageHeight: fh,
        sensorOrientationDeg: s.sensorOrientation,
        deviceRotationDeg: deviceRotationDeg,
      );
      final t = ArUcoService.coverTransform(
        outW: space.outW,
        outH: space.outH,
        previewWidth: w,
        previewHeight: h,
      );
      return mapped
          .map((p) => Offset(p[0] * space.outW * t.scale + t.dx,
              p[1] * space.outH * t.scale + t.dy))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _resolveMarker(String markerId) async {
    if (_showManualInput && _manualMarkerId?.isNotEmpty != true) {
      return;
    }

    setState(() {
      _showManualInput = false;
      _manualMarkerId = markerId;
      _isResolving = true;
    });

    ArDebugLog.log('Resolving marker: $markerId');

    final detectedMarker =
        _detectedMarkers.isNotEmpty ? _detectedMarkers.first : null;

    ArResolveResult? resolveResult;

    if (detectedMarker != null) {
      resolveResult = await ArContentResolver.resolveFromApi(
        arucoDictionary: detectedMarker.arucoDictionary,
        arucoId: detectedMarker.markerId,
      );
    }

    if (resolveResult == null) {
      int? arUcoId;
      try {
        arUcoId = int.parse(markerId);
      } catch (_) {
        arUcoId = null;
      }

      if (arUcoId != null) {
        final cachedItem = ArContentResolver.resolveByArucoId(arUcoId);
        if (cachedItem != null) {
          resolveResult = ArResolveResult(
            marker: ArResolveMarker(
              id: cachedItem.markers.isNotEmpty
                  ? cachedItem.markers.first.id
                  : 0,
              markerId: cachedItem.markers.isNotEmpty
                  ? cachedItem.markers.first.markerId
                  : '',
              markerType: 'pattern',
              status: 'active',
            ),
            model: ArResolveModel(
              id: cachedItem.id,
              modelName: cachedItem.modelName,
              description: cachedItem.description,
              category: cachedItem.category,
              version: cachedItem.version,
              glbUrl: cachedItem.glbUrl,
              glbPath: cachedItem.glbPath,
              thumbnailUrl: cachedItem.thumbnailUrl,
              thumbnailPath: cachedItem.thumbnailPath,
            ),
            hotspots: cachedItem.hotspots,
          );
        }
      }
    }

    if (resolveResult == null) {
      final cachedItem = ArContentResolver.resolveByMarkerId(markerId);
      if (cachedItem != null) {
        resolveResult = ArResolveResult(
          marker: ArResolveMarker(
            id: cachedItem.markers.isNotEmpty ? cachedItem.markers.first.id : 0,
            markerId: cachedItem.markers.isNotEmpty
                ? cachedItem.markers.first.markerId
                : markerId,
            markerType: 'pattern',
            status: 'active',
          ),
          model: ArResolveModel(
            id: cachedItem.id,
            modelName: cachedItem.modelName,
            description: cachedItem.description,
            category: cachedItem.category,
            version: cachedItem.version,
            glbUrl: cachedItem.glbUrl,
            glbPath: cachedItem.glbPath,
            thumbnailUrl: cachedItem.thumbnailUrl,
            thumbnailPath: cachedItem.thumbnailPath,
          ),
          hotspots: cachedItem.hotspots,
        );
      }
    }

    if (resolveResult == null) {
      ArDebugLog.error('No content found for marker: $markerId');
      if (mounted) {
        setState(() => _isResolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Marker tidak ditemukan. Pastikan marker sudah terdaftar di server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _enterArModeAfterResolve(resolveResult);
  }

  void _showManualIdInput() {
    setState(() {
      _showManualInput = true;
      _manualMarkerId = null;
    });
  }

  void _onManualIdSubmit(String markerId) async {
    setState(() {
      _showManualInput = false;
      _isResolving = true;
    });

    if (markerId.isEmpty) {
      if (mounted) {
        setState(() => _isResolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Masukkan marker ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    ArDebugLog.log('Manual marker resolution: $markerId');

    final resolveResult = await ArContentResolver.resolveFromApi(
      markerId: markerId,
    );

    if (resolveResult != null) {
      await _downloadAndNavigate(resolveResult);
      return;
    }

    final item = ArContentResolver.resolveByMarkerId(markerId);
    if (item == null) {
      if (mounted) {
        setState(() => _isResolving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Marker tidak ditemukan. Periksa ID marker dan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fallbackResult = ArResolveResult(
      marker: ArResolveMarker(
        id: item.markers.isNotEmpty ? item.markers.first.id : 0,
        markerId:
            item.markers.isNotEmpty ? item.markers.first.markerId : markerId,
        markerType: 'pattern',
        status: 'active',
      ),
      model: ArResolveModel(
        id: item.id,
        modelName: item.modelName,
        description: item.description,
        category: item.category,
        version: item.version,
        glbUrl: item.glbUrl,
        glbPath: item.glbPath,
        thumbnailUrl: item.thumbnailUrl,
        thumbnailPath: item.thumbnailPath,
      ),
      hotspots: item.hotspots,
    );

    await _downloadAndNavigate(fallbackResult);
  }

  Future<void> _enterArModeAfterResolve(ArResolveResult resolveResult) async {
    if (mounted) {
      setState(() => _isResolving = true);
    }
    final src = await _prepareModelSrc(resolveResult);
    if (!mounted) return;

    if (src == null) {
      setState(() => _isResolving = false);
      _downloadAndNavigate(resolveResult);
      return;
    }

    setState(() {
      _isResolving = false;
      _arResolve = resolveResult;
      _arModelSrc = src;
      _arModelName = resolveResult.model.modelName;
      _arAnchor = null;
      _arHeldAnchor = null;
      _arMarkerLost = false;
      _selectedHotspotId = null;
      _hotspotProjections.clear();
      _hotspotsError = false;
      // Indikator kecil "Memuat penjelasan..." hanya muncul jika model
      // memiliki hotspot; kondisi cleared setelah JS melaporkan 'ready'.
      _hotspotsLoading = resolveResult.hotspots.isNotEmpty;
    });
    _hotspotsTimer?.cancel();
    if (resolveResult.hotspots.isNotEmpty) {
      _hotspotsTimer = Timer(const Duration(seconds: 6), () {
        if (mounted && _hotspotsLoading) {
          setState(() {
            _hotspotsLoading = false;
            _hotspotsError = true;
          });
        }
      });
    }
    ArDebugLog.log(
        'AR overlay mode: model ${resolveResult.model.id} (${resolveResult.model.modelName})');

    if (!_isScanning) {
      _toggleScanning();
    } else {
      _onResultsChanged();
    }
  }

  void _exitArMode() {
    final wasScanning = _isScanning;
    if (wasScanning) _toggleScanning();
    _hotspotsTimer?.cancel();
    setState(() {
      _arResolve = null;
      _arModelSrc = null;
      _arModelName = null;
      _arAnchor = null;
      _arHeldAnchor = null;
      _arMarkerLost = false;
      _arWebViewController = null;
      _selectedHotspotId = null;
      _hotspotProjections.clear();
      _hotspotsLoading = false;
      _hotspotsError = false;
    });
    if (wasScanning) _toggleScanning();
  }

  void _openFullScreen() {
    final result = _arResolve;
    if (result == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelViewerScreen(
          arModelId: result.model.id,
          modelName: result.model.modelName,
          modelUrl: _arModelSrc?.isNotEmpty == true
              ? _arModelSrc
              : result.model.glbUrl,
          hotspots: result.hotspots,
        ),
      ),
    ).then((_) {
      ArContentResolver.refreshIfNeeded();
    });
  }

  Future<String?> _prepareModelSrc(ArResolveResult resolveResult) async {
    final cachedPath =
        await ContentSyncService.getCachedModelPath(resolveResult.model.id);
    if (cachedPath != null && await File(cachedPath).exists()) {
      ArDebugLog.log('Using cached model: $cachedPath');
      return cachedPath;
    }
    if (resolveResult.model.glbUrl == null) return null;
    ArDebugLog.log('Downloading GLB: ${resolveResult.model.glbUrl}');
    if (mounted) {
      setState(() => _isResolving = true);
    }
    final asset = AssetDownloadInfo(
      modelId: resolveResult.model.id,
      version: resolveResult.model.version,
      url: resolveResult.model.glbUrl!,
      assetType: 'model',
      fileName:
          'model_${resolveResult.model.id}_v${resolveResult.model.version}.glb',
    );
    final downloadResult = await ContentSyncService.downloadAsset(asset);
    if (downloadResult.success && downloadResult.localPath != null) {
      await ContentSyncService.updateManifestAfterDownload(
          asset, downloadResult.localPath!);
      ArDebugLog.log('Downloaded to: ${downloadResult.localPath}');
      return downloadResult.localPath;
    }
    ArDebugLog.error('Download failed: ${downloadResult.error}');
    return null;
  }

  Future<void> _downloadAndNavigate(ArResolveResult resolveResult) async {
    final result = resolveResult;

    final displayPath = await _prepareModelSrc(result);

    if (mounted) {
      setState(() => _isResolving = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModelViewerScreen(
            arModelId: result.model.id,
            modelName: result.model.modelName,
            modelUrl: displayPath ?? result.model.glbUrl,
            hotspots: result.hotspots,
          ),
        ),
      ).then((_) {
        ArContentResolver.refreshIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-bleed kamera: tanpa AppBar. Semua kontrol lebih kecil, transparan,
      // dan ditempatkan di safe area agar tidak menutupi AR/objek 3D.
      backgroundColor: Colors.black,
      body: _cameraPermissionDenied
          ? _buildPermissionDeniedUI()
          : LayoutBuilder(
              builder: (context, constraints) {
                _previewSize = constraints.biggest;
                return Stack(
                  children: [
                    if (_isInitialized && (_service?.controller != null))
                      Builder(builder: (context) {
                        final preview = CameraPreview(_service!.controller!);
                        final space = _coverSpace();
                        // Full-bleed: crop tepi (cover) alih-alih bar hitam.
                        // Geometri yang sama dipakai _mapPreviewCorners.
                        if (space == null) return preview;
                        return Positioned.fill(
                          child: ClipRect(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: space.outW,
                                height: space.outH,
                                child: preview,
                              ),
                            ),
                          ),
                        );
                      }),
                    if (!_isInitialized)
                      const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.greenAccent,
                        ),
                      ),
                    _buildArModelOverlay(),
                    _buildArHotspotLayer(),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopBar(),
                            const SizedBox(height: 6),
                            if (_arResolve == null)
                              Center(child: _buildScanStatusPill())
                            else ...[
                              Center(child: _buildArStatusPill()),
                              if (_hotspotsLoading || _hotspotsError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Center(
                                    child: _buildPill(
                                      _hotspotsLoading
                                          ? 'Memuat penjelasan...'
                                          : 'Gagal memuat penjelasan.',
                                      icon: _hotspotsLoading
                                          ? Icons.hourglass_top
                                          : Icons.info_outline,
                                      color: _hotspotsLoading
                                          ? Colors.cyanAccent
                                          : Colors.orangeAccent,
                                    ),
                                  ),
                                ),
                            ],
                            if (_showDebug) _buildDebugPanel(),
                          ],
                        ),
                      ),
                    ),
                    if (_arResolve == null && (_isScanning || _isResolving))
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          top: false,
                          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _buildScanBottomPanel(),
                        ),
                      ),
                    if (_arResolve != null) _buildArControlBar(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _circleIconBtn(
            Icons.arrow_back,
            20,
            () => Navigator.maybePop(context),
            tooltip: 'Kembali',
          ),
          const Spacer(),
          _circleIconBtn(
            Icons.tag,
            20,
            _showManualIdInput,
            tooltip: 'Marker ID manual',
          ),
          _circleIconBtn(
            _isScanning ? Icons.videocam_off : Icons.videocam,
            20,
            _isInitialized ? _toggleScanning : null,
            tooltip: _isScanning ? 'Hentikan scan' : 'Mulai scan',
          ),
          if (kDebugMode)
            _circleIconBtn(
              _showDebug ? Icons.info : Icons.info_outline,
              20,
              () => setState(() => _showDebug = !_showDebug),
              tooltip: 'Info debug',
            ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon, double size, VoidCallback? onTap,
      {String? tooltip}) {
    final button = Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildPill(
    String text, {
    IconData? icon,
    Color color = Colors.white,
    bool glowing = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
        border: glowing
            ? Border.all(
                color: color.withValues(alpha: 0.6),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanStatusPill() {
    if (!_isScanning && !_isResolving) {
      if (_isInitialized) return const SizedBox.shrink();
      return _buildPill('Menyiapkan kamera...', icon: Icons.hourglass_top);
    }
    if (_isResolving) {
      return _buildPill(
        'Menghubungi server...',
        icon: Icons.sync,
        color: Colors.greenAccent,
      );
    }
    if (_detectedMarkers.isNotEmpty) {
      return _buildPill(
        'Marker terdeteksi',
        icon: Icons.check_circle_outline,
        color: Colors.greenAccent,
        glowing: true,
      );
    }
    return _buildPill(
      'Scanning marker...',
      icon: Icons.qr_code_scanner,
      color: Colors.white70,
    );
  }

  Widget _buildArStatusPill() {
    final lost = _arMarkerLost;
    return _buildPill(
      lost ? 'Marker hilang - model dipertahankan' : '3D model dimuat',
      icon: lost ? Icons.touch_app : Icons.view_in_ar,
      color: lost ? Colors.amberAccent : Colors.greenAccent,
      glowing: !lost,
    );
  }

  Widget _buildDebugPanel() {
    final first = _detectedMarkers.isNotEmpty ? _detectedMarkers.first : null;
    final a = _arAnchor;
    final anchorTxt = a == null
        ? '-'
        : '${a.left.round()},${a.top.round()} ${a.width.round()}x${a.height.round()}';
    final text = 'markers: ${_detectedMarkers.length} | '
        'id: ${first?.markerId ?? '-'} | '
        'corners: ${first?.corners.length ?? 0}\n'
        'anchor: $anchorTxt | lost: $_arMarkerLost | '
        'lib: ${(_service?.nativeLibraryReady ?? false) ? 'ok' : 'missing'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
              if (!(_service?.nativeLibraryReady ?? false) && _isInitialized)
                TextButton.icon(
                  onPressed: _reinitService,
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Coba Lagi'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildScanBottomPanel() {
    if (_isResolving) {
      return _panel(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.greenAccent,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Menghubungi server...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_showManualInput) {
      return _panel(
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildManualInputField(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildManualSubmitButton()),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => setState(() => _showManualInput = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_detectedMarkers.isNotEmpty) {
      return _panel(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 16, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Text(
              'Marker #${_detectedMarkers.first.markerId}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            _buildResolveButton(),
          ],
        ),
      );
    }

    return _panel(
      const Text(
        'Arahkan kamera ke marker AR',
        style: TextStyle(color: Colors.white70, fontSize: 12.5),
      ),
    );
  }

  Widget _buildResolveButton() {
    if (_detectedMarkers.isEmpty) {
      return const SizedBox.shrink();
    }

    final markerId = _detectedMarkers.first.markerId.toString();
    return FilledButton(
      onPressed: _isResolving ? null : () => _resolveMarker(markerId),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.green.withValues(alpha: 0.5),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 36),
      ),
      child: const Text('Lihat 3D'),
    );
  }

  Widget _buildManualInputField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _manualMarkerId = value;
        });
      },
      decoration: const InputDecoration(
        labelText: 'Masukkan Marker ID',
        hintText: 'Contoh: CPU-001 atau numeric',
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: _manualMarkerId),
      enabled: true,
    );
  }

  Widget _buildManualSubmitButton() {
    return ElevatedButton(
      onPressed:
          _isResolving ? null : () => _onManualIdSubmit(_manualMarkerId ?? ''),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.blue.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Cari 3D'),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt, size: 64, color: Color(0xFFB0B8C1)),
            const SizedBox(height: 16),
            const Text(
              'Izin Kamera Diperlukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplikasi membutuhkan akses kamera untuk mendeteksi ArUco marker. '
              'Aktifkan izin kamera di pengaturan perangkat.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF637080),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isGranted || status.isLimited) {
                  if (mounted) {
                    setState(() => _cameraPermissionDenied = false);
                    _initService();
                  }
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A8477),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text('Buka Settings Sistem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArModelOverlay() {
    if (_arResolve == null || _arModelSrc == null) {
      return const SizedBox.shrink();
    }
    // Posisi model: ikuti marker jika terdeteksi; jika marker keluar kamera,
    // "tahan" di posisi terakhir agar model tetap stay dan tetap bisa
    // diputar/di-zoom/digeser.
    final anchor = _arAnchor;
    if (anchor == null || !anchor.isValid) {
      return const SizedBox.shrink();
    }

    final src = 'file://$_arModelSrc';
    final hotspots = _arResolve!.hotspots;
    return Positioned(
      left: anchor.left,
      top: anchor.top,
      width: anchor.width,
      height: anchor.height,
      child: ModelViewer(
        src: src,
        alt: _arModelName ?? 'Model 3D',
        ar: false,
        autoRotate: false,
        // Interaksi native model-viewer: drag = rotate, pinch = zoom,
        // dua jari geser = pan. Tidak mengubah tracking ArUco sama sekali.
        // Hotspot ditanam sebagai elemen slot `<button data-position=x y z>`,
        // sehingga secara native "menempel" pada koordinat 3D model (ikuti
        // rotate/zoom/pan) dan click-nya terpisah dari gesture kamera.
        cameraControls: true,
        disableZoom: false,
        cameraOrbit: _arInitialOrbit,
        cameraTarget: _arInitialTarget,
        fieldOfView: _arInitialFov,
        minFieldOfView: '20deg',
        maxFieldOfView: '60deg',
        minCameraOrbit: '-360deg 15deg auto',
        maxCameraOrbit: '360deg 90deg auto',
        backgroundColor: Colors.transparent,
        interactionPrompt: InteractionPrompt.none,
        id: 'ar-model',
        innerModelViewerHtml:
            hotspots.isEmpty ? null : _buildHotspotHtml(hotspots),
        relatedCss: hotspots.isEmpty ? null : _buildHotspotCss(),
        relatedJs: hotspots.isEmpty ? null : _buildHotspotJs(hotspots),
        javascriptChannels: hotspots.isEmpty
            ? null
            : <JavascriptChannel>{
                JavascriptChannel(
                  'ArHotspotChannel',
                  onMessageReceived: _onArHotspotMessage,
                ),
              },
        onWebViewCreated: (controller) => _arWebViewController = controller,
      ),
    );
  }

  /// Lapisan overlay speech bubble untuk hotspot yang sedang dipilih.
  ///
  /// Posisi bubble diturunkan dari proyeksi hotspot (fraksi di dalam WebView
  /// model-viewer) yang digabung dengan posisi anchor model saat ini. Karena
  /// keduanya diperbarui ketika kamera model berubah / marker bergerak, bubble
  /// selalu mengikuti model (Task 2 & 10) dan marker out-of-frame tetap
  /// berfungsi selama anchor ditahan (Task 11).
  Widget _buildArHotspotLayer() {
    final hotspotId = _selectedHotspotId;
    if (hotspotId == null) return const SizedBox.shrink();

    final anchor = _arAnchor;
    final resolveResult = _arResolve;
    if (anchor == null ||
        !anchor.isValid ||
        resolveResult == null ||
        _previewSize.width <= 0 ||
        _previewSize.height <= 0) {
      return const SizedBox.shrink();
    }

    ArHotspotData? selected;
    for (final h in resolveResult.hotspots) {
      if (h.id == hotspotId) {
        selected = h;
        break;
      }
    }
    if (selected == null) return const SizedBox.shrink();

    final projection = _hotspotProjections[hotspotId];
    final hotspotCenter = projection != null
        ? Offset(
            anchor.left + projection.dx * anchor.width,
            anchor.top + projection.dy * anchor.height,
          )
        // Fallback jika proyeksi belum tersedia (WebView belum melaporkan):
        // taruh dekat bagian atas model, akan dikoreksi saat proyeksi tiba.
        : Offset(
            anchor.left + anchor.width / 2,
            anchor.top + anchor.height * 0.25,
          );

    return ArHotspotSpeechBubble(
      anchorCenter: hotspotCenter,
      viewport: _previewSize,
      title: selected.title,
      description: selected.description,
      onClose: () => setState(() => _selectedHotspotId = null),
    );
  }

  /// Menghasilkan elemen hotspot model-viewer (`<button slot="hotspot-N">`).
  ///
  /// `data-position` memakai koordinat 3D dari backend (format
  /// `"x m, y m, z m"`) yang sama persis dengan mekanisme pada
  /// [ModelViewerScreen] (sudah
  /// terbukti berfungsi). Model-viewer secara native menambatkan tombol ini
  /// ke titik 3D tersebut sehingga melewati/mengikuti seluruh transformasi
  /// kamera (rotate/zoom/pan) serta perubahan sudut pandang.
  String _buildHotspotHtml(List<ArHotspotData> hotspots) {
    final buffer = StringBuffer();
    for (final h in hotspots) {
      final pos = '${h.positionX}m ${h.positionY}m ${h.positionZ}m';
      buffer.writeln(
        '<button slot="hotspot-${h.id}" data-position="$pos" '
        'data-visibility-attribute="visible" '
        'style="width:20px;height:20px;border-radius:50%;'
        'background:rgba(10,132,119,0.92);border:2px solid #ffffff;'
        'box-shadow:0 1px 6px rgba(0,0,0,0.45);cursor:pointer;'
        'display:flex;align-items:center;justify-content:center;'
        'padding:0;transition:transform 0.15s ease, background 0.15s ease;">'
        '<svg width="10" height="10" viewBox="0 0 24 24" fill="#ffffff">'
        '<path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 '
        '7-13c0-3.87-3.13-7-7-7z"/></svg></button>',
      );
    }
    return buffer.toString();
  }

  String _buildHotspotCss() {
    return '''
.mv-hotspot-selected {
  transform: scale(1.3);
}
''';
  }

  /// JavaScript untuk: (1) tap hotspot -> pilih, (2) laporkan posisi proyeksi
  /// hotspot (fraksi) ketika model di-rotate/zoom/pan, (3) tap area kosong
  /// model -> tutup bubble, (4) sinyal siap/gagal ke Flutter.
  ///
  /// Posisi yang dilaporkan berupa fraksi (0..1) relatif terhadap elemen
  /// `model-viewer`; Flutter menggabungkannya dengan rect anchor marker untuk
  /// mendapat koordinat layar speech bubble.
  String _buildHotspotJs(List<ArHotspotData> hotspots) {
    if (hotspots.isEmpty) return '';
    final ids = hotspots.map((h) => h.id).join(',');
    return '''
(function() {
  var H = window.ArHotspotChannel;
  function post(obj) {
    try {
      if (H) { H.postMessage(JSON.stringify(obj)); }
    } catch (e) {}
  }
  var ids = [$ids];
  var el = null;
  var rafPending = false;
  var lastPosted = 0;

  function readPositions() {
    if (!el) return [];
    var host = el.getBoundingClientRect();
    var out = [];
    ids.forEach(function(id) {
      var btn = document.querySelector('[slot="hotspot-' + id + '"]');
      if (!btn) return;
      var r = btn.getBoundingClientRect();
      if (r.width > 0 && r.height > 0 && host.width > 0 && host.height > 0) {
        out.push({
          id: id,
          fx: (r.left + r.width / 2 - host.left) / host.width,
          fy: (r.top + r.height / 2 - host.top) / host.height
        });
      }
    });
    return out;
  }

  function postCamera() {
    post({ type: 'camera', positions: readPositions() });
  }

  function schedulePost() {
    if (rafPending) return;
    rafPending = true;
    requestAnimationFrame(function() {
      rafPending = false;
      var now = Date.now();
      if (now - lastPosted >= 60) {
        lastPosted = now;
        postCamera();
      }
    });
  }

  function select(id) {
    var fx = null;
    var fy = null;
    var btn = document.querySelector('[slot="hotspot-' + id + '"]');
    if (btn) {
      document.querySelectorAll('[slot^="hotspot-"].mv-hotspot-selected')
        .forEach(function(b) { b.classList.remove('mv-hotspot-selected'); });
      btn.classList.add('mv-hotspot-selected');
      var r = btn.getBoundingClientRect();
      var host = el ? el.getBoundingClientRect() : null;
      if (r.width > 0 && host && host.width > 0 && host.height > 0) {
        fx = (r.left + r.width / 2 - host.left) / host.width;
        fy = (r.top + r.height / 2 - host.top) / host.height;
      }
    }
    post({ type: 'select', id: id, fx: fx, fy: fy });
  }

  function setup() {
    el = document.querySelector('model-viewer');
    if (!el) {
      setTimeout(setup, 200);
      return;
    }
    ids.forEach(function(id) {
      var btn = document.querySelector('[slot="hotspot-' + id + '"]');
      if (!btn) return;
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        select(id);
      });
    });

    var downX = 0, downY = 0, isDrag = false;
    el.addEventListener('pointerdown', function(e) {
      downX = e.clientX; downY = e.clientY; isDrag = false;
    });
    el.addEventListener('pointerup', function(e) {
      var dx = e.clientX - downX;
      var dy = e.clientY - downY;
      if (dx * dx + dy * dy > 36) { isDrag = true; }
    });
    el.addEventListener('click', function(e) {
      var t = e.target;
      if (t && t.getAttribute && t.getAttribute('slot') &&
          t.getAttribute('slot').indexOf('hotspot-') === 0) {
        return;
      }
      if (isDrag) return;
      post({ type: 'background' });
    });

    el.addEventListener('camera-change', schedulePost);
    el.addEventListener('load', schedulePost);
    el.addEventListener('poster-dismissed', schedulePost);
    window.addEventListener('resize', schedulePost);
    post({ type: 'ready' });
    schedulePost();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setup);
  } else {
    setup();
  }
})();
''';
  }

  /// Handler pesan dari WebView model-viewer (channel 'ArHotspotChannel').
  ///
  /// Pesan:
  ///  - select  : hotspot di-tap -> set sebagai selected (Task 4 & 7).
  ///  - camera  : proyeksi hotspot terkini -> ikuti model saat rotate/zoom/pan
  ///              (Task 10).
  ///  - background : tap area kosong -> tutup bubble (Task 8).
  ///  - ready/error : status pemuatan data hotspot (Task 12).
  void _onArHotspotMessage(JavaScriptMessage message) {
    if (!mounted) return;
    dynamic decoded;
    try {
      decoded = jsonDecode(message.message);
    } catch (_) {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    switch (decoded['type']) {
      case 'select':
        final id = (decoded['id'] as num?)?.toInt();
        if (id == null) return;
        final fx = (decoded['fx'] as num?)?.toDouble();
        final fy = (decoded['fy'] as num?)?.toDouble();
        if (fx != null && fy != null) {
          _hotspotProjections[id] = Offset(fx, fy);
        }
        setState(() => _selectedHotspotId = id);

      case 'camera':
        final positions = decoded['positions'] as List<dynamic>?;
        if (positions == null || positions.isEmpty) return;
        var changed = false;
        for (final raw in positions) {
          if (raw is! Map<String, dynamic>) continue;
          final id = (raw['id'] as num?)?.toInt();
          final fx = (raw['fx'] as num?)?.toDouble();
          final fy = (raw['fy'] as num?)?.toDouble();
          if (id != null && fx != null && fy != null) {
            _hotspotProjections[id] = Offset(fx, fy);
            changed = true;
          }
        }
        if (changed && _selectedHotspotId != null) setState(() {});

      case 'background':
        if (_selectedHotspotId != null) {
          setState(() => _selectedHotspotId = null);
        }

      case 'ready':
        _hotspotsTimer?.cancel();
        if (_hotspotsLoading || _hotspotsError) {
          setState(() {
            _hotspotsLoading = false;
            _hotspotsError = false;
          });
        }

      case 'error':
        _hotspotsTimer?.cancel();
        if (mounted) {
          setState(() {
            _hotspotsLoading = false;
            _hotspotsError = true;
          });
        }
    }
  }

  void _resetArView() {
    final controller = _arWebViewController;
    if (controller == null) return;
    unawaited(
      controller.runJavaScript('''
      (function() {
        const el = document.querySelector('model-viewer');
        if (!el) return;
        el.cameraOrbit = '$_arInitialOrbit';
        el.cameraTarget = '$_arInitialTarget';
        el.fieldOfView = '$_arInitialFov';
      })();
    '''),
    );
  }

  Widget _buildArControlBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const Icon(Icons.view_in_ar, size: 16, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _arModelName ?? 'Model 3D',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.restart_alt, size: 20),
                color: Colors.white,
                tooltip: 'Reset View',
                onPressed: _resetArView,
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                color: Colors.cyanAccent,
                tooltip: 'Layar Penuh',
                onPressed: _openFullScreen,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.redAccent,
                tooltip: 'Keluar',
                onPressed: _exitArMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
