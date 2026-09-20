import 'dart:async';

import 'package:camera/camera.dart';
import 'package:dartcv4/dartcv.dart' as cv;
import 'package:flutter/foundation.dart';

import '../models/models.dart';

class ArUcoService {
  CameraController? _controller;
  final ValueNotifier<List<ArUcoResult>> _resultsNotifier =
      ValueNotifier<List<ArUcoResult>>([]);
  bool _isScanning = false;
  Timer? _debounceTimer;
  int _frameCount = 0;
  bool _nativeLibraryReady = false;

  CameraController? get controller => _controller;
  ValueNotifier<List<ArUcoResult>> get resultsNotifier => _resultsNotifier;
  bool get isScanning => _isScanning;
  bool get nativeLibraryReady => _nativeLibraryReady;
  List<CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    final backCamera = _cameras?.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      backCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.setExposureMode(ExposureMode.locked);
    await _controller!.setFocusMode(FocusMode.locked);
    _nativeLibraryReady = true;
    if (kDebugMode) {
      print('Camera initialized: ${_controller?.description}');
      print('Native library ready: $_nativeLibraryReady');
    }
  }

  void startScanning() {
    if (_isScanning || _controller == null) return;
    if (!_nativeLibraryReady) {
      if (kDebugMode) print('Native library not ready!');
      return;
    }
    _isScanning = true;
    _frameCount = 0;
    _controller!.startImageStream(_onCameraFrame);
    if (kDebugMode) print('Scanning started');
  }

  void stopScanning() {
    _isScanning = false;
    _debounceTimer?.cancel();
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _resultsNotifier.value = [];
    if (kDebugMode) print('Scanning stopped');
  }

  void _onCameraFrame(CameraImage image) {
    if (!_isScanning) return;
    _frameCount++;
    if (_frameCount % 3 != 0) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isScanning) return;
      _processFrame(image);
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!_nativeLibraryReady) return;

    try {
      if (kDebugMode) print('Frame ${image.width}x${image.height} planes=${image.planes.length}');

      final mat = _convertCameraImageToMat(image);
      if (mat == null) return;

      final gray = cv.cvtColor(mat, 6);
      mat.dispose();

      final dict = cv.ArucoDictionary.predefined(
        cv.PredefinedDictionaryType.DICT_4X4_50,
      );
      final detectorParams = cv.ArucoDetectorParameters.empty();
      final detector = cv.ArucoDetector.create(dict, detectorParams);

      final detectResult = detector.detectMarkers(gray);
      gray.dispose();
      dict.dispose();
      detectorParams.dispose();

      final cornersVec = detectResult.$1;
      final idsVec = detectResult.$2;
      final rejectedVec = detectResult.$3;

      final cornersList = cornersVec.toList();
      final ids = idsVec.toList().cast<int>();

      if (kDebugMode) print('Detected ${ids.length} markers');

      if (ids.isNotEmpty) {
        final results = <ArUcoResult>[];
        for (int i = 0; i < ids.length; i++) {
          final cornerPoints = <List<double>>[];
          final markerCornersList = cornersList[i].toList();
          for (int c = 0; c < markerCornersList.length; c++) {
            final point = markerCornersList[c];
            cornerPoints.add([point.x, point.y]);
          }
          results.add(ArUcoResult(
            markerId: ids[i],
            corners: cornerPoints,
          ));
        }
        _resultsNotifier.value = results;
      } else {
        _resultsNotifier.value = [];
      }

      detector.dispose();
    } catch (e, stack) {
      if (kDebugMode) {
        print('ArUco detection error: $e');
        print('Stack: $stack');
      }
    }
  }

  cv.Mat? _convertCameraImageToMat(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      final plane = image.planes[0];
      final Uint8List yBytes = plane.bytes;

      if (yBytes.length >= width * height) {
        return cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, yBytes.toList());
      }

      final cropped = Uint8List(width * height);
      final int stride = yBytes.length ~/ height;
      for (int y = 0; y < height; y++) {
        final int srcOffset = y * stride;
        final int dstOffset = y * width;
        cropped.setRange(dstOffset, dstOffset + width, yBytes, srcOffset);
      }
      return cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, cropped.toList());
    } catch (e, stack) {
      if (kDebugMode) {
        print('Convert CameraImage to Mat error: $e');
        print('Stack: $stack');
      }
      return null;
    }
  }

  Future<void> dispose() async {
    stopScanning();
    await _controller?.dispose();
    _controller = null;
  }
}
