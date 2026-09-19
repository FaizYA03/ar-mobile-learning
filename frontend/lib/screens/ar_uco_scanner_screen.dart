import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/ar_uco_service.dart';
import '../models/models.dart';

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
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Markers detected: ${_detectedMarkers.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
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
                child: const Center(
                  child: Text(
                    'Point camera at ArUco marker\n(TYPE 4x4 50)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
