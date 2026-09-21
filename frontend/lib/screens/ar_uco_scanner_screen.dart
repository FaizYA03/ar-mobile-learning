import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/debug/ar_debug_log.dart';
import '../models/models.dart';
import '../screens/model_viewer_screen.dart';
import '../services/ar_uco_service.dart';
import '../services/ar_content_resolver.dart';
import '../services/content_sync_service.dart';

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

  static const List<Color> _markerColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
  ];

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
      ArDebugLog.log('Camera initialized, refreshing content...');
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
        }
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
    if (mounted) {
      setState(() {
        _detectedMarkers = _service!.resultsNotifier.value;
      });
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

    await _downloadAndNavigate(resolveResult);
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

  Future<void> _downloadAndNavigate(ArResolveResult resolveResult) async {
    final result = resolveResult;

    final cachedPath =
        await ContentSyncService.getCachedModelPath(result.model.id);
    String displayPath;
    if (cachedPath != null && await File(cachedPath).exists()) {
      displayPath = cachedPath;
      ArDebugLog.log('Using cached model: $displayPath');
    } else if (result.model.glbUrl != null) {
      ArDebugLog.log('Downloading GLB: ${result.model.glbUrl}');
      if (mounted) {
        setState(() => _isResolving = true);
      }
      final asset = AssetDownloadInfo(
        modelId: result.model.id,
        version: result.model.version,
        url: result.model.glbUrl!,
        assetType: 'model',
        fileName: 'model_${result.model.id}_v${result.model.version}.glb',
      );
      final downloadResult = await ContentSyncService.downloadAsset(asset);
      if (downloadResult.success && downloadResult.localPath != null) {
        await ContentSyncService.updateManifestAfterDownload(
            asset, downloadResult.localPath!);
        displayPath = downloadResult.localPath!;
        ArDebugLog.log('Downloaded to: $displayPath');
      } else {
        ArDebugLog.error('Download failed: ${downloadResult.error}');
        displayPath = result.model.glbUrl ?? '';
      }
    } else {
      displayPath = result.model.glbPath ?? '';
    }

    if (mounted) {
      setState(() => _isResolving = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ModelViewerScreen(
            arModelId: result.model.id,
            modelName: result.model.modelName,
            modelUrl:
                displayPath.isNotEmpty ? displayPath : result.model.glbUrl,
            hotspots: result.hotspots,
          ),
        ),
      ).then((_) {
        ArContentResolver.refreshContent();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ArUco Marker Scanner'),
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _toggleScanning,
              tooltip: 'Stop',
            )
          else if (_isInitialized)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _toggleScanning,
              tooltip: 'Start',
            ),
        ],
      ),
      body: _cameraPermissionDenied
          ? _buildPermissionDeniedUI()
          : Stack(
              children: [
                if (_isInitialized && (_service?.controller != null))
                  CameraPreview(_service!.controller!),
                if (!_isInitialized)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isScanning ? 'Scanning...' : 'Ready',
                          style: TextStyle(
                            color: (_service?.nativeLibraryReady ?? false)
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !(_service?.nativeLibraryReady ?? false)
                              ? 'OpenCV library NOT loaded - detection unavailable'
                              : _detectedMarkers.isNotEmpty
                                  ? 'Markers detected: ${_detectedMarkers.length}'
                                  : 'No markers detected yet',
                          style: TextStyle(
                            color: (_service?.nativeLibraryReady ?? false)
                                ? Colors.white
                                : Colors.orangeAccent,
                            fontSize: 14,
                          ),
                        ),
                        if (!(_service?.nativeLibraryReady ?? false) &&
                            _isInitialized) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _reinitService,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_detectedMarkers.isNotEmpty && _isScanning)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.15,
                    left: 0,
                    right: 0,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _detectedMarkers.map((marker) {
                          final colorIndex =
                              marker.markerId % _markerColors.length;
                          final color = _markerColors[colorIndex];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color, width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Marker #${marker.markerId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${marker.corners.length ~/ 2} corners',
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                if (_isScanning || _isResolving)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isResolving) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Menghubungi server...',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Marker ID: ${_detectedMarkers.isNotEmpty ? _detectedMarkers.first.markerId : 'none detected'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildResolveButton(),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _showManualIdInput,
                              child: const Text(
                                'Masukkan Marker ID Manual',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            if (_showManualInput) ...[
                              const SizedBox(height: 8),
                              _buildManualInputField(),
                              const SizedBox(height: 8),
                              _buildManualSubmitButton(),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildResolveButton() {
    if (_detectedMarkers.isEmpty) {
      return const SizedBox.shrink();
    }

    final markerId = _detectedMarkers.first.markerId.toString();
    return ElevatedButton(
      onPressed: _isResolving ? null : () => _resolveMarker(markerId),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.green.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Resolve ke 3D Model'),
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
}
