import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initService();
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
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _service?.stopScanning();
    } else if (state == AppLifecycleState.resumed && _isScanning) {
      _service?.startScanning();
    }
  }

  Future<void> _initService() async {
    try {
      _service = ArUcoService();
      await _service!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (!_service!.nativeLibraryReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OpenCV native library not loaded. ArUco detection unavailable.'),
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
    });

    ArDebugLog.log('Resolving marker: $markerId');

    // Try to resolve using markerId string first (manual input or direct)
    // Then fall back to ArUco ID mapping if it's a numeric ID
    int? arUcoId;
    try {
      arUcoId = int.parse(markerId);
    } catch (_) {
      arUcoId = null;
    }

    ArContentItem? item;
    if (arUcoId != null) {
      item = await ArContentResolver.resolveByArucoId(arUcoId);
    }

    if (item == null) {
      // Fall back to string marker ID resolution
      item = await ArContentResolver.resolveByMarkerId(markerId);
    }

    if (item == null) {
      ArDebugLog.error('No content found for marker: $markerId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marker/3D asset tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if model is cached locally
    final cachedPath = await ContentSyncService.getCachedModelPath(item.id);
    String displayPath;
    if (cachedPath != null && await File(cachedPath).exists()) {
      displayPath = cachedPath;
    } else {
      // Try to download if not cached
      // Note: In full implementation, would trigger download pipeline
      displayPath = item.glbUrl ?? item.glbPath ?? '';
    }

    if (!mounted) return;

    // Navigate to 3D viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelViewerScreen(
          arModelId: item.id,
          modelName: item.modelName,
          modelUrl: displayPath.isNotEmpty ? displayPath : item.glbUrl,
          hotspots: item.hotspots,
        ),
      ),
    ).then((_) {
      // Refresh content after returning from viewer
      ArContentResolver.refreshContent();
    });
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
    });

    if (markerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan marker ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ArDebugLog.log('Manual marker resolution: $markerId');

    final item = await ArContentResolver.resolveByMarkerId(markerId);
    if (item == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marker/3D asset tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModelViewerScreen(
          arModelId: item.id,
          modelName: item.modelName,
          modelUrl: item.glbUrl ?? item.glbPath ?? '',
          hotspots: item.hotspots,
        ),
      ),
    ).then((_) {
      ArContentResolver.refreshContent();
    });
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
      body: Stack(
        children: [
          if (_isInitialized && _service!.controller != null)
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
                      color: _service!.nativeLibraryReady
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !_service!.nativeLibraryReady
                        ? 'OpenCV library NOT loaded - detection unavailable'
                        : _detectedMarkers.isNotEmpty
                            ? 'Markers detected: ${_detectedMarkers.length}'
                            : 'No markers detected yet',
                    style: TextStyle(
                      color: _service!.nativeLibraryReady
                          ? Colors.white
                          : Colors.orangeAccent,
                      fontSize: 14,
                    ),
                  ),
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
                    final colorIndex = marker.markerId % _markerColors.length;
                    final color = _markerColors[colorIndex];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          if (_isScanning)
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
                    if (_showManualInput) ...[
                      const SizedBox(height: 8),
                      _buildManualInputField(),
                      const SizedBox(height: 8),
                      _buildManualSubmitButton(),
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
      onPressed: () => _resolveMarker(markerId),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
      onPressed: () => _onManualIdSubmit(_manualMarkerId ?? ''),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Cari 3D'),
    );
  }
}